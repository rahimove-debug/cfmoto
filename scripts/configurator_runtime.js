/* Inserted into the existing configurator module by apply_configurator_improvements.mjs. */
const cfDraftKey = "cfmoto-configurator-draft-v1";
const cfCatalogRequests = new Map();
const cfKnownModel = id => ei.find(model => model.id === id);
const cfResolveId = id => {
  const canonical = ({"800mt":"800mt-explore","800nk":"800nk-advanced","450cl-c":"450clc"})[id] || id;
  return cfKnownModel(canonical) ? canonical : null;
};
function cfReadDraft() {
  try {
    const saved = JSON.parse(window.localStorage.getItem(cfDraftKey) || "null");
    if (!saved || saved.version !== 1 || typeof saved.savedAt !== "number" || Date.now() - saved.savedAt > 90 * 86400000) return {selections:{}, bikes:{}};
    const selections = {}, bikes = {};
    ei.forEach(model => {
      if (Array.isArray(saved.selections?.[model.id])) selections[model.id] = [...new Set(saved.selections[model.id].filter(id => typeof id === "string" && id.length <= 200))].slice(0, 200);
      if (typeof saved.bikes?.[model.id] === "boolean") bikes[model.id] = saved.bikes[model.id];
    });
    return {modelId:cfResolveId(saved.modelId), selections, bikes};
  } catch (_) { return {selections:{}, bikes:{}}; }
}
function cfSaveDraft(modelId, selections, bikes) {
  try { window.localStorage.setItem(cfDraftKey, JSON.stringify({version:1, modelId, selections, bikes, savedAt:Date.now()})); } catch (_) {}
}
function cfValidSelections(model, ids) {
  const allowed = new Set(model.accessories.map(item => item.id));
  return [...new Set(Array.isArray(ids) ? ids : [])].filter(id => allowed.has(id));
}
function cfLoadModel(model) {
  if (model.cfLoaded) return Promise.resolve(model);
  if (cfCatalogRequests.has(model.id)) return cfCatalogRequests.get(model.id);
  const request = fetch(model.catalogUrl, {credentials:"same-origin"})
    .then(response => { if (!response.ok) throw new Error("catalog response"); return response.json(); })
    .then(data => {
      if (data.version !== 1 || data.modelId !== model.id || !Array.isArray(data.accessories) || data.accessories.length !== model.accessoryCount) throw new Error("catalog shape");
      const ids = new Set();
      data.accessories.forEach(item => {
        if (!item || typeof item.id !== "string" || ids.has(item.id) || typeof item.name !== "string" || (item.priceAzn !== null && (!Number.isFinite(item.priceAzn) || item.priceAzn < 0))) throw new Error("accessory shape");
        ids.add(item.id);
      });
      model.accessories = data.accessories;
      model.cfLoaded = true;
      return model;
    }).catch(error => { cfCatalogRequests.delete(model.id); throw error; });
  cfCatalogRequests.set(model.id, request);
  return request;
}
function cfEvent(name, model, items = [], extra = {}) {
  const knownTotal = items.reduce((sum,item) => sum + (Number.isFinite(item.priceAzn) ? item.priceAzn : 0), 0);
  const params = {model_id:model.id, model_name:model.name, currency:"AZN", ...(items.some(item => Number.isFinite(item.priceAzn)) ? {value:Math.round(knownTotal*100)/100} : {}),
    items:items.map(item => ({item_id:item.partNumber || item.id, item_name:item.name, item_category:model.id, quantity:1, ...(Number.isFinite(item.priceAzn) ? {price:item.priceAzn} : {})})),
    unpriced_count:items.filter(item => item.priceAzn === null).length, ...extra};
  if (typeof window.gtag === "function") window.gtag("event", name, params);
}
function cfPackageEvent(name, model, ids, includeBike) {
  const selected = model.accessories.filter(item => ids.includes(item.id));
  const items = includeBike ? [{id:`vehicle:${model.id}`,name:model.name,priceAzn:model.basePriceAzn},...selected] : selected;
  cfEvent(name, model, items, {include_vehicle:includeBike, accessory_count:selected.length,
    ...(name === "share" ? {method:"copy_link",content_type:"accessory_package",item_id:model.id} : {}),
    ...(name === "generate_lead" ? {lead_type:"whatsapp_package"} : {})});
}
function cfPackageUrl(model, ids, includeBike) {
  const url = new URL("/aksesuar-konfiquratoru/", window.location.origin);
  url.searchParams.set("model", model.id);
  url.searchParams.set("accessories", cfValidSelections(model, ids).join(","));
  url.searchParams.set("bike", includeBike ? "1" : "0");
  return url.href;
}
async function cfCopyPackage(model, ids, includeBike) {
  const url = cfPackageUrl(model, ids, includeBike);
  try {
    await navigator.clipboard.writeText(url);
    cfPackageEvent("share", model, ids, includeBike);
    return {url, message:"Paket keçidi kopyalandı."};
  } catch (_) { return {url, message:"Keçidi seçib kopyalaya bilərsiniz."}; }
}
function cfRoute() {
  const params = (0,i.useSearchParams)();
  const query = params.toString();
  const [route, setRoute] = (0,s.useState)(null);
  const [failed, setFailed] = (0,s.useState)(false);
  const [retry, setRetry] = (0,s.useState)(0);
  (0,s.useEffect)(() => {
    let cancelled = false;
    setRoute(null); setFailed(false);
    const saved = cfReadDraft();
    const requested = new URLSearchParams(query);
    const id = requested.has("model") ? (cfResolveId(requested.get("model")) || ei[0].id) : (saved.modelId || ei[0].id);
    const model = cfKnownModel(id);
    cfLoadModel(model).then(() => {
      if (cancelled) return;
      const ids = requested.has("accessories") ? requested.get("accessories").split(",").map(id => id.trim()) : saved.selections[id] || [];
      const selected = cfValidSelections(model, ids);
      const bike = requested.has("bike") ? requested.get("bike") !== "0" : (saved.bikes[id] ?? true);
      setRoute({requestedModelId:id, requestedAccessories:selected.join(","), requestedBike:bike?"1":"0",
        lockedMode:requested.get("lock") === "1" && !!cfResolveId(requested.get("model")),
        requestedSelections:{...saved.selections,[id]:selected}, requestedBikes:{...saved.bikes,[id]:bike}});
    }).catch(() => { if (!cancelled) setFailed(true); });
    return () => { cancelled = true; };
  }, [query,retry]);
  if (!route) return (0,o.jsxs)("main", {className:"loading-shell cf-catalog-loading", children:[
    (0,o.jsx)("h1", {children:"CFMOTO Aksesuar Konfiquratoru"}),
    (0,o.jsx)("p", {role:"status", children:failed?"Aksesuarlar yüklənmədi. Yenidən cəhd edin.":"Aksesuarlar hazırlanır…"}),
    failed && (0,o.jsx)("button", {type:"button", onClick:()=>setRetry(value=>value+1), children:"Yenidən yüklə"})
  ]});
  return (0,o.jsx)(ep, route, `${query}|${route.requestedModelId}`);
}
