(() => {
  const source = document.currentScript;
  if (!source) return;

  const language = source.dataset.language === "ru" ? "ru" : "az";
  const counterpart = source.dataset.counterpart || (language === "ru" ? "/" : "/ru/");
  const seo = {
    canonical: source.dataset.canonical || window.location.href,
    az: source.dataset.az || (language === "az" ? window.location.href : counterpart),
    ru: source.dataset.ru || (language === "ru" ? window.location.href : counterpart),
    default: source.dataset.default || source.dataset.az || window.location.href
  };

  const buildSwitcher = () => {
    const nav = document.createElement("nav");
    nav.className = "language-switcher";
    nav.setAttribute("aria-label", language === "ru" ? "Выбор языка" : "Dil seçimi");

    const current = document.createElement("span");
    current.setAttribute("aria-current", "page");
    current.textContent = language === "ru" ? "RU" : "AZ";

    const alternate = document.createElement("a");
    alternate.href = counterpart;
    alternate.lang = language === "ru" ? "az" : "ru";
    alternate.hreflang = alternate.lang;
    alternate.textContent = language === "ru" ? "AZ" : "RU";

    if (language === "ru") nav.append(alternate, current);
    else nav.append(current, alternate);
    return nav;
  };

  const ensureUniqueLink = (rel, href, hreflang = null) => {
    const candidates = Array.from(document.head.querySelectorAll(`link[rel="${rel}"]`))
      .filter((link) => hreflang === null || link.hreflang.toLowerCase() === hreflang);
    let link = candidates.shift();
    candidates.forEach((duplicate) => duplicate.remove());
    if (!link) {
      link = document.createElement("link");
      document.head.append(link);
    }
    link.rel = rel;
    link.href = href;
    if (hreflang === null) link.removeAttribute("hreflang");
    else link.hreflang = hreflang;
  };

  const ensureSeo = () => {
    ensureUniqueLink("canonical", seo.canonical);
    ensureUniqueLink("alternate", seo.az, "az");
    ensureUniqueLink("alternate", seo.ru, "ru");
    ensureUniqueLink("alternate", seo.default, "x-default");

    const allowed = new Set(["az", "ru", "x-default"]);
    document.head.querySelectorAll('link[rel="alternate"][hreflang]').forEach((link) => {
      if (!allowed.has(link.hreflang.toLowerCase())) return;
      const expected = link.hreflang.toLowerCase() === "az" ? seo.az :
        link.hreflang.toLowerCase() === "ru" ? seo.ru : seo.default;
      if (link.href !== new URL(expected, document.baseURI).href) link.href = expected;
    });
  };

  const ensureStylesheet = () => {
    const href = "/assets/language-v3.css";
    const matches = Array.from(document.head.querySelectorAll('link[rel="stylesheet"]'))
      .filter((link) => new URL(link.href, document.baseURI).pathname === href);
    const stylesheet = matches.shift() || document.createElement("link");
    matches.forEach((duplicate) => duplicate.remove());
    stylesheet.rel = "stylesheet";
    stylesheet.href = href;
    if (!stylesheet.parentElement) document.head.append(stylesheet);
  };

  const mountSwitcher = () => {
    const header = document.querySelector(".site-header");
    const menuButton = header?.querySelector(".menu-button") || null;
    let switcher = document.querySelector(".language-switcher");
    if (!switcher) switcher = buildSwitcher();

    if (header) {
      if (switcher.parentElement !== header || switcher.nextElementSibling !== menuButton) {
        header.insertBefore(switcher, menuButton);
      }
    } else if (switcher.parentElement !== document.body) {
      document.body.append(switcher);
    }
  };

  const reconcile = () => {
    ensureSeo();
    ensureStylesheet();
    mountSwitcher();
  };

  const start = () => {
    reconcile();
    let scheduled = false;
    const observer = new MutationObserver(() => {
      if (scheduled) return;
      scheduled = true;
      window.requestAnimationFrame(() => {
        scheduled = false;
        reconcile();
      });
    });
    observer.observe(document.documentElement, { childList: true, subtree: true });
    window.setTimeout(() => {
      reconcile();
      observer.disconnect();
    }, 15_000);
  };

  let started = false;
  const launch = () => {
    if (started) return;
    started = true;
    window.requestAnimationFrame(() => window.requestAnimationFrame(start));
  };

  const launchAfterHydration = () => {
    window.requestAnimationFrame(() => window.requestAnimationFrame(launch));
  };

  // React hydrates the full document. Mutating <head> or the site header before
  // hydration finishes makes React discard the server tree (error #418).
  // Waiting for window.load keeps the static SEO links available immediately,
  // while mounting the interactive switcher only after hydration is stable.
  if (document.readyState === "complete") launchAfterHydration();
  else window.addEventListener("load", launchAfterHydration, { once: true });
})();
