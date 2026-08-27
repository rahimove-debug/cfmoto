(() => {
  const source = document.currentScript;
  if (!source) return;

  const language = source.dataset.language === "ru" ? "ru" : "az";
  const counterpart = source.dataset.counterpart || (language === "ru" ? "/" : "/ru/");

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

  const mount = () => {
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

  const start = () => {
    mount();
    const observer = new MutationObserver(mount);
    observer.observe(document.body, { childList: true, subtree: true });
    window.setTimeout(() => {
      mount();
      observer.disconnect();
    }, 10_000);
  };

  let started = false;
  const launch = () => {
    if (started) return;
    started = true;
    window.requestAnimationFrame(() => window.requestAnimationFrame(start));
  };

  if (document.readyState === "complete") launch();
  else document.addEventListener("DOMContentLoaded", launch, { once: true });
  window.addEventListener("load", () => {
    if (started) mount();
    else launch();
  }, { once: true });
})();
