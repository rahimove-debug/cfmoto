#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import crypto from "node:crypto";
import zlib from "node:zlib";
import {fileURLToPath} from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const dist = process.env.CFMOTO_BUILD_DIR || path.join(root,"dist");
const configRoot = path.join(dist,"aksesuar-konfiquratoru");
const sourcePath = path.join(configRoot,"_next/static/chunks/app/page-cfmoto-godaddy-localprices-v9.js");
const source = fs.readFileSync(sourcePath,"utf8");
const hash = text => crypto.createHash("sha256").update(text).digest("hex").slice(0,16);
const assert = (condition,message) => { if (!condition) throw new Error(message); };
function once(text, anchor, replacement) {
  assert(text.split(anchor).length === 2, `Expected one configurator anchor: ${anchor.slice(0,100)}`);
  return text.replace(anchor,replacement);
}
function filesUnder(directory) {
  return fs.readdirSync(directory,{withFileTypes:true}).flatMap(entry => entry.isDirectory() ? filesUnder(path.join(directory,entry.name)) : [path.join(directory,entry.name)]);
}

// 1. Resolve the exact deployed catalog, including the local retail-price overrides.
let input = source;
if (!input.includes('"675nk","500sr","500sr-voom"')) input = once(input,'"675nk","500sr-voom"','"675nk","500sr","500sr-voom"');
const capture = once(input,";function em(){",";globalThis.cfExtractedCatalog=ei;function em(){");
const context = {self:{webpackChunk_N_E:[]}, Intl};
vm.createContext(context);
vm.runInContext(capture, context, {timeout:5000});
const module = context.self.webpackChunk_N_E[0][1][9170];
const requireStub = () => ({}); requireStub.d = () => {};
module({}, {}, requireStub);
const catalog = JSON.parse(JSON.stringify(context.cfExtractedCatalog));
const srIndex = catalog.findIndex(model => model.id === "500sr");
assert(catalog.length === 48 && srIndex >= 0 && catalog[srIndex+1].id === "500sr-voom", "48-model catalog must include 500SR directly before VOOM");
assert(catalog[srIndex].basePriceAzn === 13490, "500SR retail price changed");

// 2. Replace the old conversion claims in HTML, RSC and the interactive component.
const neutral = "Göstərilən qiymətlər AZN ilə yerli satış qiymətləridir. Qiyməti göstərilməyən aksesuarlar üçün satış komandasına müraciət edin. Uyğunluq, stok və yekun qiymət sifarişdən əvvəl təsdiqlənir.";
const copyPairs = [
  ["CFMOTO motosiklet, kvadrosikl (ATV), buggy və UTV modelləri üçün uyğun orijinal aksesuarları seçin. ATV və Buggy uyğunluğu CFMOTO USA 2027 kataloquna, qiymətlər CFMoto USA Parts-a əsaslanır və AZN-ə çevrilir.", "CFMOTO motosiklet, ATV və Buggy modelləri üçün orijinal aksesuarları seçin, yerli AZN qiymətləri ilə paket hazırlayın və satış komandası ilə paylaşın."],
  ["ATV və Buggy aksesuarlarının SKU və uyğunluq məlumatları CFMOTO USA 2027 Off-Road Accessories kataloqundan, qiymətlər isə CFMoto USA Parts mağazasından götürülüb. USD qiyməti 28.08.2026 tarixli Azərbaycan Mərkəzi Bankının 1 USD = 1.7000 AZN məzənnəsi ilə çevrilir. Çatdırılma, gömrük, stok və Azərbaycan üzrə yekun satış qiyməti sifarişdən əvvəl təsdiqlənir.", neutral],
  ["CFMoto USA Parts qiyməti AZN-ə necə çevrilir?", "Aksesuar qiymətləri necə göstərilir?"],
  ["CFMoto USA Parts-da göstərilən USD qiyməti 28.08.2026 tarixli rəsmi 1 USD = 1.7000 AZN məzənnəsi ilə vurulur və iki rəqəmədək yuvarlaqlaşdırılır. Məsələn, $159.99 → 271.98 ₼. Çatdırılma, gömrük və yerli yekun satış qiyməti bu hesablamaya daxil deyil.", neutral]
];
function cleanCopy(text) {
  for (const [before,after] of copyPairs) text = text.split(before).join(after);
  return text;
}

// 3. Publish only the selected model's final accessory data on demand.
const dataDir = path.join(configRoot,"catalog");
fs.mkdirSync(dataDir,{recursive:true});
const metadata = catalog.map(model => {
  const accessories = model.accessories.map(item => {
    const {priceNote, priceSourceUrl, contentSourceUrl, ...publicItem} = item;
    if (/USA Parts|DMS/i.test(publicItem.contentSourceLabel || "")) publicItem.contentSourceLabel = "CFMOTO";
    return publicItem;
  });
  const text = JSON.stringify({version:1,modelId:model.id,accessories});
  const filename = `${model.id}.${hash(text)}.json`;
  fs.writeFileSync(path.join(dataDir,filename),text);
  return {...model, accessories:[], accessoryCount:accessories.length, catalogUrl:`/aksesuar-konfiquratoru/catalog/${filename}`,cfLoaded:accessories.length===0};
});
const dataStart = input.indexOf("let n=JSON.parse(");
const formatterStart = input.indexOf('es=new Intl.NumberFormat("az-AZ"');
assert(dataStart > 0 && formatterStart > dataStart, "Catalog/formatter boundary missing");
let output = input.slice(0,dataStart) + `let ee="994512332484",ei=${JSON.stringify(metadata)},` + input.slice(formatterStart);
output = output.replace(/"(?:ATV və Buggy qiymətləri|Aksesuar məbləğləri) CFMoto USA Parts[^"\n]*"/g,JSON.stringify(neutral));
assert(!output.includes("CFMoto USA Parts") && !output.includes("1.7000"), "Old price-conversion text remains in UI bundle");
const runtime = fs.readFileSync(path.join(root,"scripts/configurator_runtime.js"),"utf8");
output = once(output,";function em(){",`;${runtime}\nfunction em(){`);
const routeStart = output.indexOf("function eu(){");
const componentStart = output.indexOf("function ep({");
assert(routeStart > 0 && componentStart > routeStart,"Configurator route boundary missing");
output = output.slice(0,routeStart) + "function eu(){return(0,o.jsx)(cfRoute,{})}" + output.slice(componentStart);
output = once(output,"function ep({requestedModelId:e,requestedAccessories:r,requestedBike:t,lockedMode:i})", "function ep({requestedModelId:e,requestedAccessories:r,requestedBike:t,lockedMode:i,requestedSelections:cfInitialSelections={},requestedBikes:cfInitialBikes={}})");
output = once(output,"[k,E]=(0,s.useState)(null===r?{}:{[h.id]:g})","[k,E]=(0,s.useState)({...cfInitialSelections,[h.id]:g})");
output = once(output,'[R,V]=(0,s.useState)("Hamısı"),F=', '[R,V]=(0,s.useState)("Hamısı"),[cfLoading,cfSetLoading]=(0,s.useState)(""),[cfLoadError,cfSetLoadError]=(0,s.useState)(null),[cfShared,cfSetShared]=(0,s.useState)(null),cfSequence=(0,s.useRef)(0),cfShareSequence=(0,s.useRef)(0),cfBikes=(0,s.useRef)(cfInitialBikes),F=');
output = once(output,'0===e.accessories.length&&(0,o.jsx)("span",{className:"inquiry-badge"','0===e.accessoryCount&&(0,o.jsx)("span",{className:"inquiry-badge"');

// 4/5. Keep React's established state/modal implementation; attach persistence and events.
output = once(output,';(0,s.useEffect)(()=>{if(!S)return;',`; (0,s.useEffect)(()=>{cfBikes.current[b]=w;cfSaveDraft(b,k,cfBikes.current)},[b,k,w]);(0,s.useEffect)(()=>()=>{cfSequence.current+=1;cfShareSequence.current+=1},[]);(0,s.useEffect)(()=>{cfShareSequence.current+=1;cfSetShared(null)},[b,k,w]);(0,s.useEffect)(()=>{if(!S)return;`);
output = once(output,'eo=(e,r)=>{_.current=r,v(e),U(!1),T(e)}', 'eo=(e,r)=>{_.current=r,v(e),U(!1),T(e);let item=N.accessories.find(item=>item.id===e);if(item)cfEvent("view_item",N,[item])}');
output = once(output,'ea=e=>{q(e.vehicleType),y(e.id),v(e.accessories[0]?.id??null),U(!1),T(null)}', `ea=async e=>{const request=++cfSequence.current;cfSetLoadError(null);if(e.id===b){cfSetLoading("");return}cfSetLoading(e.name);try{await cfLoadModel(e);if(request!==cfSequence.current)return;E(current=>({...current,[e.id]:cfValidSelections(e,current[e.id]||[])}));q(e.vehicleType);y(e.id);v(e.accessories[0]?.id??null);A(cfBikes.current[e.id]??true);U(!1);T(null);V("Hamısı");cfSetLoading("");cfEvent("configurator_model_select",e,[],{value:e.basePriceAzn})}catch(_){if(request===cfSequence.current){cfSetLoading("");cfSetLoadError(e)}}}`);
output = once(output,'en=e=>{E(r=>{let t=r[N.id]??[],o=t.includes(e)?t.filter(r=>r!==e):[...t,e];return{...r,[N.id]:o}})}', 'en=e=>{let item=N.accessories.find(item=>item.id===e);if(!item)return;cfEvent(I.includes(e)?"remove_from_cart":"add_to_cart",N,[item]);E(r=>{let t=r[N.id]??[],o=t.includes(e)?t.filter(r=>r!==e):[...t,e];return{...r,[N.id]:o}})}');
output = once(output,'className:"clear-button",onClick:()=>{E(e=>({...e,[N.id]:[]}))}', 'className:"clear-button",onClick:()=>{cfEvent("remove_from_cart",N,L);E(e=>({...e,[N.id]:[]}))}');
output = once(output,'className:"quote-button",disabled:!W,onClick:()=>{T(null),U(!0)}','className:"quote-button",disabled:!W,onClick:()=>{T(null),U(!0);cfPackageEvent("begin_checkout",N,I,w)}');
output = once(output,'className:"whatsapp-button",href:Z,target:"_blank",rel:"noreferrer",children:', 'className:"whatsapp-button",href:Z,target:"_blank",rel:"noreferrer",onClick:()=>cfPackageEvent("generate_lead",N,I,w),children:');
output = once(output,'className:`site-shell ${i?"model-locked":""}`,children:[', 'className:`site-shell ${i?"model-locked":""}`,children:[cfLoading&&(0,o.jsx)("div",{className:"cf-model-status",role:"status",children:`${cfLoading} aksesuarları yüklənir…`}),cfLoadError&&(0,o.jsxs)("div",{className:"cf-model-status cf-model-error",role:"alert",children:["Aksesuarlar yüklənmədi. ",(0,o.jsx)("button",{type:"button",onClick:()=>ea(cfLoadError),children:"Yenidən cəhd et"})]}),');
output = once(output,'(0,o.jsxs)("p",{className:"summary-disclaimer",id:"summary-disclaimer"', `(0,o.jsxs)("div",{className:"cf-package-share",children:[(0,o.jsx)("button",{type:"button",className:"cf-share-button",onClick:async()=>{const request=++cfShareSequence.current;const shared=await cfCopyPackage(N,I,w);if(request===cfShareSequence.current)cfSetShared(shared)},children:"Paket keçidini kopyala"}),cfShared&&cfShared.url===cfPackageUrl(N,I,w)&&(0,o.jsxs)("div",{children:[(0,o.jsx)("p",{role:"status",children:cfShared.message}),(0,o.jsx)("input",{type:"text",readOnly:true,value:cfShared.url,"aria-label":"Paketin paylaşım keçidi",onFocus:event=>event.target.select()})]})]}),(0,o.jsxs)("p",{className:"summary-disclaimer",id:"summary-disclaimer"`);
new vm.Script(output);
const filename = `page-cfmoto-improvements-${hash(output)}.js`;
const publicBundle = `/aksesuar-konfiquratoru/_next/static/chunks/app/${filename}`;
fs.writeFileSync(path.join(path.dirname(sourcePath),filename),output);
const css = `.cf-model-status{position:fixed;bottom:20px;left:50%;transform:translateX(-50%);z-index:1200;max-width:calc(100vw - 32px);padding:14px 20px;background:#10191b;color:#fff;box-shadow:0 5px 25px #0004;font-size:14px}.cf-model-error button,.cf-catalog-loading button{background:#00cfc3;color:#10191b;border:0;padding:10px 16px;cursor:pointer}.cf-package-share{margin:16px 0}.cf-share-button{width:100%;min-height:48px;padding:14px;border:1px solid #142023;background:#fff;color:#142023;font:inherit;font-weight:700;cursor:pointer}.cf-package-share p{margin:10px 0 6px;font-size:13px}.cf-package-share input{width:100%;padding:10px;border:1px solid #c6cecf;background:#fff;color:#142023;font-size:13px;box-sizing:border-box}.cf-share-button:focus-visible,.cf-model-status button:focus-visible{outline:3px solid #00cfc3;outline-offset:3px}.cf-catalog-loading{min-height:60vh;padding:60px 24px;text-align:center}.cf-catalog-loading h1{font-size:clamp(24px,5vw,42px)}.summary-sheet,.summary-sheet .summary-bike-toggle{color:#f5f7f7}.summary-sheet :is(h2,strong,b),.summary-sheet .cf-package-share p{color:#f5f7f7}`;
// Catalog photos mix transparent cutouts and white studio backgrounds. A white
// stage removes the visible photo rectangle without tinting paintwork with a
// blend/filter or modifying official product images. Keep the orange NEW badge.
const modelStageCss = `.simple-bike-image{background:#fff}.simple-bike-image>span:not(.simple-model-new-badge){display:none}`;
const finalCss = css + modelStageCss;
const cssName = `configurator-improvements-${hash(finalCss)}.css`;
fs.writeFileSync(path.join(dist,"assets",cssName),finalCss);
const cssTag = `<link rel="stylesheet" href="/assets/${cssName}"/>`;
let updated = 0;
for (const file of filesUnder(configRoot).filter(file => /\.(html|txt|json)$/.test(file) && !file.includes(`${path.sep}catalog${path.sep}`))) {
  const original = fs.readFileSync(file,"utf8");
  let text = cleanCopy(original).replace(/page-cfmoto-(?:godaddy-localprices-v9|improvements-[a-f0-9]+)\.js/g,filename);
  text = text.replace(/<script\b[^>]*src="\/assets\/accessory-model-preselect-[^"]+\.js"[^>]*><\/script>/g,"");
  if (file.endsWith(".html")) {
    text = text.replace(/<link rel="stylesheet" href="\/assets\/configurator-improvements-[a-f0-9]+\.css"\/>/g,"");
    text = once(text,"</head>",`${cssTag}</head>`);
  }
  assert(!/CFMoto USA Parts|1 USD = 1\.7000|\$159\.99/.test(text),`Stale conversion claim remains: ${file}`);
  if (text !== original) { fs.writeFileSync(file,text); updated++; }
}
const manifest = {version:1, models:catalog.length, accessories:catalog.reduce((sum,model)=>sum+model.accessories.length,0),bundle:publicBundle,stylesheet:`/assets/${cssName}`,sourceBytes:Buffer.byteLength(source),bundleBytes:Buffer.byteLength(output),sourceGzip:zlib.gzipSync(source).length,bundleGzip:zlib.gzipSync(output).length,defaultModelJsonGzip:zlib.gzipSync(fs.readFileSync(path.join(dist,metadata[0].catalogUrl))).length};
fs.writeFileSync(path.join(root,"work-configurator-improvements-report.json"),JSON.stringify(manifest,null,2));
console.log(`Configurator improvements: ${manifest.models} models, ${manifest.accessories} accessories; bundle ${manifest.sourceBytes} → ${manifest.bundleBytes} bytes (${manifest.sourceGzip} → ${manifest.bundleGzip} gzip); ${updated} HTML/RSC files updated.`);
