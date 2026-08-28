(() => {
  const toggleSelector = ".site-header .menu-button";
  const focusableSelector = "a[href],button:not([disabled]),[tabindex]:not([tabindex='-1'])";

  const visible = (element) => {
    const rect = element.getBoundingClientRect();
    const style = window.getComputedStyle(element);
    return rect.width > 0 && rect.height > 0 && style.display !== "none" && style.visibility !== "hidden";
  };

  const navigationFor = (button) => button.closest(".site-header")?.querySelector(".main-nav");

  const wireControls = () => {
    document.querySelectorAll(toggleSelector).forEach((button, index) => {
      const navigation = navigationFor(button);
      if (!navigation) return;
      if (!navigation.id) navigation.id = `site-primary-navigation-${index + 1}`;
      button.setAttribute("aria-controls", navigation.id);
    });
  };

  const start = () => {
    wireControls();

    document.addEventListener("click", (event) => {
      const button = event.target.closest?.(toggleSelector);
      if (!button) return;

      window.requestAnimationFrame(() => {
        if (button.getAttribute("aria-expanded") !== "true") return;
        const navigation = navigationFor(button);
        const firstItem = navigation
          ? [...navigation.querySelectorAll(focusableSelector)].find(visible)
          : null;
        firstItem?.focus({ preventScroll: true });
      });
    });

    document.addEventListener("keydown", (event) => {
      if (event.key !== "Escape") return;
      const openButton = [...document.querySelectorAll(toggleSelector)]
        .find((button) => button.getAttribute("aria-expanded") === "true" && visible(button));
      if (!openButton) return;

      event.preventDefault();
      openButton.click();
      window.requestAnimationFrame(() => openButton.focus({ preventScroll: true }));
    });

    const observer = new MutationObserver(wireControls);
    observer.observe(document.documentElement, { childList: true, subtree: true });
    window.setTimeout(() => observer.disconnect(), 12000);
  };

  const startAfterHydration = () => {
    window.requestAnimationFrame(() => window.requestAnimationFrame(start));
  };

  if (document.readyState === "complete") startAfterHydration();
  else window.addEventListener("load", startAfterHydration, { once: true });
})();
