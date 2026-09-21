(() => {
  const entryForLocale = () => {
    const russian = document.documentElement.lang.toLowerCase().startsWith("ru");
    return russian
      ? { href: "/ru/kalkulyator-podveski/", label: "Подвеска" }
      : { href: "/asqi-kalkulyatoru/", label: "Asqı" };
  };

  const directLinks = (navigation) =>
    Array.from(navigation.children).filter((child) => child.tagName === "A");

  const ensureEntry = (navigation) => {
    const entry = entryForLocale();
    const existing = directLinks(navigation).find((link) => {
      const href = link.getAttribute("href");
      return href === entry.href || link.dataset.suspensionEntry === "true";
    });

    if (existing) {
      existing.setAttribute("href", entry.href);
      existing.textContent = entry.label;
      existing.dataset.suspensionEntry = "true";
      return;
    }

    const link = document.createElement("a");
    link.href = entry.href;
    link.textContent = entry.label;
    link.dataset.suspensionEntry = "true";

    const links = directLinks(navigation);
    const credit = links.find((candidate) => {
      const href = candidate.getAttribute("href") || "";
      return /(?:^|\/)kredit\/?(?:$|#)/.test(href) || href.includes("#kredit");
    });
    const callToAction = links.find((candidate) => candidate.classList.contains("nav-cta"));

    if (credit) credit.after(link);
    else if (callToAction) navigation.insertBefore(link, callToAction);
    else navigation.append(link);
  };

  const ensureAllEntries = () => {
    document.querySelectorAll(".site-header .main-nav").forEach(ensureEntry);
  };

  const startHydratedSync = () => {
    let framePending = false;
    const schedule = () => {
      if (framePending) return;
      framePending = true;
      window.requestAnimationFrame(() => {
        framePending = false;
        ensureAllEntries();
      });
    };

    ensureAllEntries();
    const observer = new MutationObserver((mutations) => {
      if (mutations.some((mutation) => mutation.addedNodes.length > 0)) schedule();
    });
    observer.observe(document.documentElement, { childList: true, subtree: true });
    window.setTimeout(() => observer.disconnect(), 30000);
    window.setTimeout(schedule, 500);
    window.setTimeout(schedule, 2000);
  };

  if (document.readyState === "complete") startHydratedSync();
  else window.addEventListener("load", startHydratedSync, { once: true });
  window.addEventListener("pageshow", ensureAllEntries);
})();
