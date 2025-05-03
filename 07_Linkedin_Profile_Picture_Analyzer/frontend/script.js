/* =========================================================
   1.  Bootstrap – wait for Clerk SDK + DOM
   ========================================================= */
   document.addEventListener('DOMContentLoaded', async () => {
    await waitForClerk();          // poll until the <script> tag has loaded
    await Clerk.load();            // initialise Clerk
    mountClerkUI();                // decide whether to show app or redirect
    setupPreview();                // wire thumbnail preview
  });
  
  /* helper: resolve when window.Clerk exists */
  function waitForClerk() {
    return new Promise(res => {
      if (window.Clerk) return res();
      const id = setInterval(() => {
        if (window.Clerk) { clearInterval(id); res(); }
      }, 25);
    });
  }
  
  /* =========================================================
     2.  Show/hide the main app & auth redirect
     ========================================================= */
  function mountClerkUI() {
    const appDiv   = document.getElementById('app');
    const mainPane = document.querySelector('.container');
  
    if (Clerk.user) {
      /* ----- signed‑in view -------------------------------- */
      mainPane.style.display = 'block';
      appDiv.innerHTML       = '<div id="user-button"></div>';
      Clerk.mountUserButton(document.getElementById('user-button'));
    } else {
      /* ----- not signed in → redirect to hosted page ------ */
      mainPane.style.display = 'none';
      appDiv.innerHTML       = '';
  
      Clerk.redirectToSignIn({
        /* return here after sign‑in / sign‑up */
        afterSignInUrl: window.location.href,
        afterSignUpUrl: window.location.href
      });                                         // Clerk docs :contentReference[oaicite:0]{index=0}
    }
  }
  
  /* =========================================================
     3.  Load API endpoints from config.json
     ========================================================= */
  let BASE_URL, UPLOAD_ENDPOINT, RESULT_ENDPOINT;
  
  fetch('config.json')
    .then(r => r.ok ? r.json() : Promise.reject('config load error'))
    .then(cfg => {
      BASE_URL        = cfg.base_url;
      UPLOAD_ENDPOINT = `${BASE_URL}/upload`;
      RESULT_ENDPOINT = `${BASE_URL}/result`;
    })
    .catch(err => console.error('Configuration error:', err));
  
  /* =========================================================
     4.  Thumbnail preview logic
     ========================================================= */
  function setupPreview() {
    const imgInp  = document.getElementById('imageInput');
    const preview = document.getElementById('preview');
  
    imgInp.addEventListener('change', () => {
      const file = imgInp.files[0];
      if (!file) { preview.style.display = 'none'; return; }
  
      const url = URL.createObjectURL(file);
      preview.src           = url;
      preview.style.display = 'block';
      preview.onload        = () => URL.revokeObjectURL(url);
    });
  }
  
  /* =========================================================
     5.  Main “Analyze” flow
     ========================================================= */
  async function analyzeImage() {
    if (!Clerk.user) {
      /* User somehow clicked before auth finished */
      return Clerk.redirectToSignIn({
        afterSignInUrl: window.location.href
      });
    }
  
    const imgInp = document.getElementById('imageInput');
    if (!imgInp.files.length) return alert('Please select an image file.');
  
    const file     = imgInp.files[0];
    const reader   = new FileReader();
    const resultEl = document.getElementById('result');
  
    reader.onload = async () => {
      const base64 = reader.result.split(',')[1];
  
      /* 1 ─ upload ---------------------------------------------------- */
      const jwt  = await Clerk.session.getToken({
        template: 'linkedin-photo-api'
      });               // bearer token
      const resp = await fetch(UPLOAD_ENDPOINT, {
        method : 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization : `Bearer ${jwt}`
        },
        body   : JSON.stringify({ file_name: file.name, file_content: base64 })
      });
  
      const data = await resp.json();
      if (!resp.ok) {
        resultEl.innerHTML = `<p class="error">Upload failed: ${data.error}</p>`;
        return;
      }
  
      const imageId = data.s3_path.split('/').pop();
      resultEl.textContent = '🕑 Analyzing your photo…';
  
      /* 2 ─ poll until analysis ready ------------------------------- */
      const poll = async () => {
        const r = await fetch(
          `${RESULT_ENDPOINT}?image_id=${encodeURIComponent(imageId)}`,
          { headers: { Authorization: `Bearer ${jwt}` } }
        );
        const j = await r.json();
  
        if (!r.ok)        return resultEl.textContent = `Error ${r.status}`;
        if (!j.ready)     return setTimeout(poll, 2000);
        renderResult(j.data);
      };
      poll();
    };
    reader.readAsDataURL(file);
  }
  
  /* expose for button’s onclick */
  window.analyzeImage = analyzeImage;
  
  /* =========================================================
     6.  Render helper
     ========================================================= */
  function renderResult({ status, issues = [], scores = {} }) {
    const good = status === 'Good';
    let html   = `<h2>${good ? '✅ Looks good!' : '❌ Needs work'}</h2>`;
    html      += `<p><strong>Status:</strong> ${status}</p>`;
  
    if (issues.length) {
      html += '<p><strong>Issues:</strong></p><ul>' +
              issues.map(i => `<li>${i}</li>`).join('') + '</ul>';
    }
    if (Object.keys(scores).length) {
      html += '<p><strong>Scores:</strong></p><ul>' +
              Object.entries(scores)
                    .map(([k,v]) => `<li>${k}: ${v}</li>`).join('') + '</ul>';
    }
    document.getElementById('result').innerHTML = html;
  }
  
  // Reset the result box
  function resetImage() {
    const imageInput = document.getElementById('imageInput');
    const preview = document.getElementById('preview');
    const result = document.getElementById('result');

    imageInput.value = "";
    preview.style.display = "none";
    preview.src = "";
    result.innerHTML = "";
}