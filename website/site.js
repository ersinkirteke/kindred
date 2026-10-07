// Shared behaviour for kindredcook.app: language switch (EN/TR), footer year, copy buttons.
(function () {
  var KEY = 'kindred-lang';
  var html = document.documentElement;

  function read() { try { return localStorage.getItem(KEY); } catch (e) { return null; } }
  function save(v) { try { localStorage.setItem(KEY, v); } catch (e) {} }

  function apply(lang) {
    if (typeof T === 'undefined' || !T[lang]) return;
    html.lang = lang;
    document.querySelectorAll('[data-i18n]').forEach(function (el) {
      var v = T[lang][el.getAttribute('data-i18n')];
      if (v === undefined) return;
      // only the privacy sentence carries a link, everything else is plain text
      if (v.indexOf('<a ') !== -1) el.innerHTML = v; else el.textContent = v;
    });
    document.querySelectorAll('[data-lang-toggle]').forEach(function (b) {
      b.textContent = lang === 'tr' ? 'EN' : 'TR';
    });
  }

  var initial = read() || ((navigator.language || '').toLowerCase().indexOf('tr') === 0 ? 'tr' : 'en');
  apply(initial);

  document.querySelectorAll('[data-lang-toggle]').forEach(function (b) {
    b.addEventListener('click', function () {
      var next = html.lang === 'tr' ? 'en' : 'tr';
      save(next);
      apply(next);
    });
  });

  document.querySelectorAll('[data-year]').forEach(function (el) { el.textContent = new Date().getFullYear(); });

  document.querySelectorAll('[data-copy]').forEach(function (b) {
    b.addEventListener('click', function () {
      var text = b.getAttribute('data-copy');
      var done = function () {
        var lang = html.lang === 'tr' ? 'tr' : 'en';
        var original = b.textContent;
        b.textContent = (typeof T !== 'undefined' && T[lang]['s.copied']) || 'Copied';
        setTimeout(function () { b.textContent = original; }, 1600);
      };
      if (navigator.clipboard) navigator.clipboard.writeText(text).then(done, done); else done();
    });
  });
})();
