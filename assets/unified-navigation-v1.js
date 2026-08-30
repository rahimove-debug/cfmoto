(() => {
  const focusableSelector = "a[href],button:not([disabled]),summary,[tabindex]:not([tabindex='-1'])";

  const ensureDetailMenuButton = (header) => {
    if (!header.classList.contains("detail-header") || header.querySelector(".menu-button")) return;
    const button = document.createElement("button");
    button.className = "menu-button";
    button.type = "button";
    button.setAttribute("aria-label", "Menyunu aç");
    button.setAttribute("aria-expanded", "false");
    button.innerHTML = "<span></span><span></span>";
    header.append(button);
  };

  const moveLanguageSwitcher = (header) => {
    const switcher = document.querySelector("body > .language-switcher");
    if (switcher && !header.contains(switcher)) header.insertBefore(switcher, header.querySelector(".menu-button"));
  };

  const closeMenu = (header, returnFocus = false) => {
    const button = header.querySelector(".menu-button");
    const navigation = header.querySelector(".main-nav");
    if (!button || !navigation) return;
    navigation.classList.remove("is-open");
    button.setAttribute("aria-expanded", "false");
    button.setAttribute("aria-label", document.documentElement.lang === "ru" ? "Открыть меню" : "Menyunu aç");
    document.body.classList.remove("unified-nav-open");
    if (returnFocus) button.focus({ preventScroll: true });
  };

  const wireHeader = (header) => {
    if (header.dataset.unifiedNavigationWired === "true") return;
    ensureDetailMenuButton(header);
    moveLanguageSwitcher(header);

    const button = header.querySelector(".menu-button");
    const navigation = header.querySelector(".main-nav");
    if (!button || !navigation) return;

    /* The React homepage owns its button state. Static and model-detail
       headers use this shared controller. */
    if (!header.classList.contains("home-header")) {
      if (!navigation.id) navigation.id = "site-primary-navigation";
      button.setAttribute("aria-controls", navigation.id);
      button.addEventListener("click", () => {
        const opening = !navigation.classList.contains("is-open");
        navigation.classList.toggle("is-open", opening);
        button.setAttribute("aria-expanded", String(opening));
        button.setAttribute("aria-label", opening
          ? (document.documentElement.lang === "ru" ? "Закрыть меню" : "Menyunu bağla")
          : (document.documentElement.lang === "ru" ? "Открыть меню" : "Menyunu aç"));
        document.body.classList.toggle("unified-nav-open", opening);
        if (opening) window.requestAnimationFrame(() => navigation.querySelector(focusableSelector)?.focus({ preventScroll: true }));
      });
      navigation.addEventListener("click", (event) => {
        if (event.target.closest("a[href]")) closeMenu(header);
      });
    }

    header.dataset.unifiedNavigationWired = "true";
  };

  const start = () => {
    document.querySelectorAll(".site-header").forEach(wireHeader);

    document.addEventListener("keydown", (event) => {
      if (event.key !== "Escape") return;
      const openHeader = [...document.querySelectorAll(".site-header")]
        .find((header) => header.querySelector(".main-nav.is-open"));
      if (openHeader) {
        event.preventDefault();
        closeMenu(openHeader, true);
      }
    });

    document.addEventListener("click", (event) => {
      document.querySelectorAll(".unified-products-menu[open]").forEach((details) => {
        if (!details.contains(event.target)) details.removeAttribute("open");
      });
    });

    const observer = new MutationObserver(() => document.querySelectorAll(".site-header").forEach(wireHeader));
    observer.observe(document.documentElement, { childList: true, subtree: true });
    window.setTimeout(() => observer.disconnect(), 15000);
  };

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", start, { once: true });
  else start();
})();
