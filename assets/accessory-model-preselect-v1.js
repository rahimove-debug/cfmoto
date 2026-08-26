(() => {
  const slug = new URLSearchParams(window.location.search).get("model");
  if (!slug) return;

  const normalize = (value) => value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/^cfmoto[\s-]+/, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");

  const target = normalize(slug);
  let attempts = 0;
  let observer;

  const selectModel = () => {
    attempts += 1;
    const button = [...document.querySelectorAll("button")].find((candidate) => {
      const name = candidate.querySelector("strong")?.textContent?.trim();
      return name && normalize(name) === target;
    });

    if (!button) {
      if (attempts > 80) observer?.disconnect();
      return false;
    }

    if (button.getAttribute("aria-pressed") !== "true") button.click();
    document.documentElement.dataset.preselectedModel = target;
    observer?.disconnect();

    if (window.location.hash === "#models") {
      requestAnimationFrame(() => {
        document.getElementById("models")?.scrollIntoView({ block: "start" });
      });
    }
    return true;
  };

  if (selectModel()) return;
  observer = new MutationObserver(selectModel);
  observer.observe(document.documentElement, { childList: true, subtree: true });
})();
