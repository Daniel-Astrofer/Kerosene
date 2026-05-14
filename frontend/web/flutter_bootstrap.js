(function () {
  function hasWebGl() {
    try {
      var canvas = document.createElement('canvas');
      return !!(
        canvas.getContext('webgl2') ||
        canvas.getContext('webgl') ||
        canvas.getContext('experimental-webgl')
      );
    } catch (_) {
      return false;
    }
  }

  function renderBlockedRuntime() {
    var paint = function () {
      document.body.style.margin = '0';
      document.body.style.background = '#0E0E10';
      document.body.style.color = '#F5F5F7';
      document.body.style.fontFamily =
        'Inter, system-ui, -apple-system, BlinkMacSystemFont, sans-serif';
      document.body.innerHTML =
        '<main style="min-height:100vh;display:flex;align-items:center;justify-content:center;padding:32px;">' +
        '<section style="max-width:520px;border:1px solid #2C2C32;background:#17171B;padding:24px;border-radius:6px;">' +
        '<h1 style="font-size:18px;line-height:1.3;margin:0 0 12px;">Kerosene web runtime blocked</h1>' +
        '<p style="font-size:14px;line-height:1.6;margin:0;color:#B6B6C0;">Tor Browser is blocking WebAssembly or WebGL, which this Flutter web console needs to render. Set Tor Browser Security Level to Standard for this onion and reload.</p>' +
        '</section>' +
        '</main>';
    };

    if (document.body) {
      paint();
    } else {
      window.addEventListener('DOMContentLoaded', paint, { once: true });
    }
  }

  if (typeof WebAssembly === 'undefined' || !hasWebGl()) {
    renderBlockedRuntime();
    return;
  }

  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.getRegistrations()
      .then(function (registrations) {
        registrations.forEach(function (registration) {
          registration.unregister();
        });
      })
      .catch(function () {});
  }

  {{flutter_js}}
  {{flutter_build_config}}

  _flutter.loader.load({
    config: {
      useLocalCanvasKit: true
    }
  });
})();
