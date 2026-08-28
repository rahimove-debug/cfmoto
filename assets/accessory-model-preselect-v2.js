(() => {
  const search = new URLSearchParams(window.location.search);
  const slug = search.get("model")?.trim();
  if (!slug) return;
  if (search.get("lock") === "1") {
    document.documentElement.dataset.preselectedModel = slug;
    return;
  }

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
    const modelButtons = [...document.querySelectorAll("button[data-model-id]")];
    const exactButton = modelButtons.find((candidate) => candidate.dataset.modelId === slug);
    const fallbackButton = [...document.querySelectorAll("button")].find((candidate) => {
      const name = candidate.querySelector("strong")?.textContent?.trim();
      return name && normalize(name) === target;
    });
    const button = exactButton || fallbackButton;

    if (!button) {
      if (attempts > 80) observer?.disconnect();
      return false;
    }

    if (button.getAttribute("aria-pressed") !== "true") button.click();
    document.documentElement.dataset.preselectedModel = slug;
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
