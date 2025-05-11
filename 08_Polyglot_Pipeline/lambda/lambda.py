# Import required modules: re for regex, urllib.parse for URL parsing
import re, urllib.parse as up

# Supported language codes
SUPPORTED = {"en", "es", "zh", "ar", "hi", "fr"}
# Default language code
DEFAULT   = "en"
# Cookie name for preferred language
COOKIE    = "prefLang"

# ---------- helpers ----------

# Parse the prefLang cookie from headers and return the language code
def _parse_lang_cookie(headers):
    """Return the two-letter code from prefLang cookie, or None."""
    # Get the 'cookie' header
    cookie = headers.get("cookie")
    # If no cookie header, return None
    if not cookie:
        return None
    # Split cookies and look for prefLang
    for kv in cookie[0]["value"].split(";"):
        name, _, val = kv.strip().partition("=")
        # If cookie name matches, return code if supported
        if name == COOKIE:
            code = val[:2].lower()
            return code if code in SUPPORTED else None
    # If not found, return None
    return None

# Parse the Accept-Language header and pick the best supported language
def _pick_from_accept_language(headers):
    # Get the 'accept-language' header
    al = headers.get("accept-language")
    # If not present, return default
    if not al:
        return DEFAULT
    langs = []
    # Parse each language entry
    for part in al[0]["value"].split(","):
        m = re.match(r"\s*([A-Za-z\-]{2,})(?:;\s*q=([0-9.]+))?", part)
        if m:
            code = m.group(1).lower()[:2]
            q    = float(m.group(2)) if m.group(2) else 1.0
            langs.append((code, q))
    # Sort by q value and return first supported
    for code, _ in sorted(langs, key=lambda x: x[1], reverse=True):
        if code in SUPPORTED:
            return code
    # If none supported, return default
    return DEFAULT

# Build a redirect response for CloudFront
def _redirect(loc, set_cookie=None, permanent=False):
    # Prepare headers for redirect
    hdrs = {
        "location":      [{"key": "Location", "value": loc}],
        "cache-control": [{"key": "Cache-Control", "value": "public,max-age=0"}],
    }
    # Optionally set a cookie
    if set_cookie:
        hdrs["set-cookie"] = [{"key": "Set-Cookie", "value": set_cookie}]
    # Return the redirect response dict
    return {
        "status": "301" if permanent else "302",
        "statusDescription": "Moved Permanently" if permanent else "Found",
        "headers": hdrs,
    }

# ---------- Lambda handler ----------

# Main Lambda handler for CloudFront events
def handler(event, context):
    # Extract request and headers from event
    req     = event["Records"][0]["cf"]["request"]
    headers = req["headers"]
    uri     = req["uri"]

    # 1) Honour cookie first
    cookie_lang = _parse_lang_cookie(headers)
    # Use cookie language if present, else pick from Accept-Language
    if cookie_lang:
        lang = cookie_lang
    else:
        lang = _pick_from_accept_language(headers)

    # 2) Requests that *already specify* a language stay as-is
    for l in SUPPORTED - {DEFAULT}:
        # If URI matches a supported language
        if uri == f"/{l}" or uri.startswith(f"/{l}/"):
            # Normalise bare "/es" → "/es/index.html"
            if uri == f"/{l}":
                return _redirect(f"/{l}/index.html", permanent=True)
            # If user browsed to a *different* language than the cookie,
            # refresh the cookie so future root requests match.
            if cookie_lang != l:
                return _redirect(
                    uri,
                    set_cookie=f"{COOKIE}={l}; Path=/; Max-Age=31536000; SameSite=Lax",
                    permanent=True,
                )
            # Otherwise, just return the request as-is
            return req

    # 3) Root request: maybe redirect to preferred non-English language
    if uri in ("", "/", "/index.html") and lang != DEFAULT:
        return _redirect(
            f"/{lang}/index.html",
            set_cookie=f"{COOKIE}={lang}; Path=/; Max-Age=31536000; SameSite=Lax",
        )

    # 4) Everything else (English paths) — ensure cookie is set to en
    if cookie_lang != DEFAULT:
        # keep serving the object but refresh the cookie once
        return _redirect(
            uri,
            set_cookie=f"{COOKIE}=en; Path=/; Max-Age=31536000; SameSite=Lax",
            permanent=True,
        )

    # Return the request unchanged if no redirect is needed
    return req
