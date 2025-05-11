(function () {
  const picker = document.getElementById('lang-picker');
  const supported = ['en','es','zh','ar','hi','fr'];
  const COOKIE    = 'prefLang';
  const YEAR      = 60*60*24*365;

  /* -------- helper: read a cookie -------- */
  const readCookie = name =>
    document.cookie.split(';').map(v => v.trim())
      .find(c => c.startsWith(name + '='))?.split('=')[1];

  /* -------- initial value -------- */
  const cookie = readCookie(COOKIE);
  const pathMatch = location.pathname.match(/^\/(en|es|zh|ar|hi|fr)(?=\/)/);
  picker.value = cookie || (pathMatch ? pathMatch[1] : 'en');

  /* -------- change handler -------- */
  picker.addEventListener('change', e => {
    const lang = e.target.value;

    /* Save the preference for one year (SameSite=Lax avoids 3rd‑party issues) */
    document.cookie = `${COOKIE}=${lang}; Max-Age=${YEAR}; Path=/; SameSite=Lax`;

    /* Strip any existing prefix from the current path */
    let rest = location.pathname.replace(/^\/(en|es|zh|ar|hi|fr)(?=\/)/, '');
    if (rest === '' || rest === '/') rest = '/index.html';

    const newPath = lang === 'en'
      ? rest                           // English lives at root
      : `/${lang}${rest}`;

    location.replace(newPath);         // avoid extra history entry
  });
})();
