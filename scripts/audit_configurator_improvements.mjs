#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import assert from "node:assert/strict";
import {fileURLToPath} from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)),"..");
const dist = process.env.CFMOTO_BUILD_DIR || path.join(root,"dist");
const report = JSON.parse(fs.readFileSync(path.join(root,"work-configurator-improvements-report.json"),"utf8"));
const script = fs.readFileSync(path.join(dist,report.bundle),"utf8");
new vm.Script(script);
const capture = script.replace("function em(){","globalThis.auditModels=ei;function em(){");
const production = {self:{webpackChunk_N_E:[]},Intl,Map,Set};
vm.createContext(production); vm.runInContext(capture,production);
const requireStub = () => ({}); requireStub.d = () => {};
production.self.webpackChunk_N_E[0][1][9170]({}, {}, requireStub);
const models = JSON.parse(JSON.stringify(production.auditModels));
let originalScript = fs.readFileSync(path.join(dist,"aksesuar-konfiquratoru/_next/static/chunks/app/page-cfmoto-godaddy-localprices-v9.js"),"utf8");
originalScript = originalScript.replace('"675nk","500sr-voom"','"675nk","500sr","500sr-voom"').replace(";function em(){",";globalThis.auditOriginal=ei;function em(){");
const originalContext = {self:{webpackChunk_N_E:[]},Intl};
vm.createContext(originalContext);vm.runInContext(originalScript,originalContext);
originalContext.self.webpackChunk_N_E[0][1][9170]({}, {}, requireStub);
const originalModels = JSON.parse(JSON.stringify(originalContext.auditOriginal));
assert.equal(models.length,48);
assert.equal(models[models.findIndex(model=>model.id==="500sr")+1].id,"500sr-voom");
assert.equal(models.find(model=>model.id==="500sr").accessoryCount,0);
assert.equal(models.find(model=>model.id==="500sr").basePriceAzn,13490);
let accessoryCount=0;
const blackLuggageModels=[];
for (const model of models) {
  const json = JSON.parse(fs.readFileSync(path.join(dist,model.catalogUrl),"utf8"));
  assert.equal(json.modelId,model.id); assert.equal(json.accessories.length,model.accessoryCount);
  const original = originalModels.find(item=>item.id===model.id);
  assert.ok(original,`Original model missing: ${model.id}`);
  assert.equal(model.basePriceAzn,original.basePriceAzn);
  assert.equal(model.image,original.image);
  const expectedAccessories = original.accessories.map(item=>{
    const {priceNote,priceSourceUrl,contentSourceUrl,...publicItem}=item;
    if(/USA Parts|DMS/i.test(publicItem.contentSourceLabel||""))publicItem.contentSourceLabel="CFMOTO";
    return publicItem;
  });
  assert.deepEqual(json.accessories,expectedAccessories,`${model.id}: retail prices, SKU, images or compatibility changed during extraction`);
  assert.equal(new Set(json.accessories.map(item=>item.id)).size,json.accessories.length);
  accessoryCount += json.accessories.length;
  for (const item of json.accessories) {
    assert.ok(item.priceAzn === null || (Number.isFinite(item.priceAzn) && item.priceAzn >= 0));
    assert.ok(!("priceNote" in item));
    if (item.partNumber === "6WWV-808000-5002-10") {
      assert.equal(item.name,"Kit Luggage Cases Black");
      assert.equal(item.priceAzn,2000,`${model.id}: confirmed black luggage retail price must be 2,000 AZN`);
      blackLuggageModels.push(model.id);
    }
  }
}
assert.deepEqual(blackLuggageModels.sort(),["1000mt-x","800mt-x"]);
assert.equal(accessoryCount,594);
assert.ok(report.bundleBytes < 60000);
const html = fs.readFileSync(path.join(dist,"aksesuar-konfiquratoru/index.html"),"utf8");
assert.ok(html.includes(path.basename(report.bundle)));
assert.ok(!html.includes("page-cfmoto-godaddy-localprices-v9"));
assert.ok(!html.includes("accessory-model-preselect-"));
assert.ok(!/CFMoto USA Parts|1 USD = 1\.7000|\$159\.99/.test(html+script));

// Opaque studio photos and transparent model cutouts must share a seamless,
// color-neutral stage. Scope this fix away from accessory/DMS price redaction.
const stylesheet = fs.readFileSync(path.join(dist,report.stylesheet),"utf8");
assert.ok(html.includes(report.stylesheet), "Cache-versioned configurator CSS missing");
assert.ok(stylesheet.includes(".simple-bike-image{background:#fff}"), "White model stage missing");
assert.ok(stylesheet.includes(".simple-bike-image>span:not(.simple-model-new-badge){display:none}"), "Model watermark must not expose the photo rectangle or hide the NEW badge");
assert.ok(!/mix-blend-mode|\bfilter:/.test(stylesheet), "Model paintwork must retain its original colors");
const redactionPath = "aksesuar-konfiquratoru/_next/static/css/cfmoto-configurator-offroad-noprice-v5.css";
assert.equal(fs.readFileSync(path.join(dist,redactionPath),"utf8"),fs.readFileSync(path.join(root,redactionPath),"utf8"), "Existing DMS price masking changed");

// Run the authored helpers with isolated storage/fetch/analytics; never send network events.
const fixtures = [
  {id:"a",name:"A",basePriceAzn:1000,accessoryCount:2,accessories:[],catalogUrl:"/a.json"},
  {id:"b",name:"B",basePriceAzn:2000,accessoryCount:0,accessories:[],catalogUrl:"/b.json",cfLoaded:true}
];
const accessories = [{id:"known",partNumber:"SKU-1",name:"Known",priceAzn:25},{id:"unknown",partNumber:"SKU-2",name:"Unknown",priceAzn:null}];
let saved=null, query="", fetchCount=0;
const events=[];
const states=[], refs=[], effects=[];
let stateIndex=0,refIndex=0,effectIndex=0;
const dependencies=[];
const runtime = {
  ei:fixtures,URL,URLSearchParams,Map,Set,Date,Promise,
  window:{location:{origin:"https://cfmoto.az"},localStorage:{getItem:()=>saved,setItem:(_,value)=>{saved=value;}},gtag:(...event)=>events.push(event)},
  navigator:{clipboard:{writeText:async()=>{}}},
  fetch:async()=>{fetchCount++;return{ok:true,json:async()=>({version:1,modelId:"a",accessories})};},
  ep:"component",
  o:{jsx:(type,props,key)=>({type,props,key}),jsxs:(type,props,key)=>({type,props,key})},
  i:{useSearchParams:()=>new URLSearchParams(query)},
  s:{
    useState(initial){const index=stateIndex++;if(!(index in states))states[index]=typeof initial==="function"?initial():initial;return[states[index],value=>{states[index]=typeof value==="function"?value(states[index]):value;}];},
    useRef(initial){const index=refIndex++;return refs[index]||(refs[index]={current:initial});},
    useEffect(fn,deps){const index=effectIndex++;if(!dependencies[index]||deps.some((dep,n)=>dep!==dependencies[index][n])){dependencies[index]=deps;effects.push(fn);}}
  }
};
vm.createContext(runtime);vm.runInContext(fs.readFileSync(path.join(root,"scripts/configurator_runtime.js"),"utf8"),runtime);
const plain=value=>JSON.parse(JSON.stringify(value));
assert.equal(runtime.cfLoadModel(fixtures[0]),runtime.cfLoadModel(fixtures[0]));
await runtime.cfLoadModel(fixtures[0]); assert.equal(fetchCount,1);
assert.deepEqual(plain(runtime.cfValidSelections(fixtures[0],["known","bad","known"])),["known"]);
saved="broken json";assert.deepEqual(plain(runtime.cfReadDraft()),{selections:{},bikes:{}});
saved=JSON.stringify({version:1,savedAt:Date.now(),modelId:"a",selections:{a:["known","invalid","known"],invalid:["x"]},bikes:{a:false,b:true}});
assert.deepEqual(plain(runtime.cfReadDraft().selections),{a:["known","invalid"]});
function render(){stateIndex=0;refIndex=0;effectIndex=0;const tree=runtime.cfRoute();const pending=effects.splice(0);pending.forEach(fn=>fn());return tree;}
const settle=()=>new Promise(resolve=>setImmediate(resolve));
query="model=a&accessories=unknown,invalid&bike=1";render();await settle();let tree=render();
assert.equal(tree.type,"component");assert.equal(tree.props.requestedAccessories,"unknown");assert.equal(tree.props.requestedBike,"1");
query="model=b&accessories=&bike=0";render();await settle();tree=render();assert.equal(tree.props.requestedModelId,"b");assert.equal(tree.props.requestedAccessories,"");assert.equal(tree.props.requestedBike,"0");
query="model=a";render();await settle();tree=render();assert.equal(tree.props.requestedAccessories,"known");assert.equal(tree.props.requestedBike,"0");
query="";render();await settle();tree=render();assert.equal(tree.props.requestedModelId,"a");
runtime.cfEvent("add_to_cart",fixtures[0],[accessories[1]]);
assert.equal(events.at(-1)[1],"add_to_cart");assert.ok(!("value" in events.at(-1)[2]));assert.ok(!("price" in events.at(-1)[2].items[0]));
runtime.cfPackageEvent("begin_checkout",fixtures[0],["known","unknown"],false);assert.equal(events.at(-1)[2].value,25);assert.equal(events.at(-1)[2].unpriced_count,1);
runtime.cfPackageEvent("begin_checkout",fixtures[0],["known"],true);assert.equal(events.at(-1)[2].value,1025);assert.equal(events.at(-1)[2].items[0].item_id,"vehicle:a");assert.equal(events.at(-1)[2].items.reduce((sum,item)=>sum+item.price*item.quantity,0),1025);
runtime.cfPackageEvent("generate_lead",fixtures[0],["unknown"],false);assert.ok(!("value" in events.at(-1)[2]));assert.equal(events.at(-1)[2].lead_type,"whatsapp_package");
assert.equal(events.at(-1)[2].lead_stage,"contact_click");
assert.equal(events.at(-1)[2].value_basis,"quoted_package");
assert.equal(runtime.cfPackageUrl(fixtures[0],["known","invalid"],false),"https://cfmoto.az/aksesuar-konfiquratoru/?model=a&accessories=known&bike=0");
runtime.navigator.clipboard.writeText=async()=>{throw new Error("blocked")};
const copy=await runtime.cfCopyPackage(fixtures[0],["known"],true);assert.ok(copy.url.includes("accessories=known"));assert.ok(copy.message.includes("seçib"));
runtime.window.localStorage.getItem=()=>{throw new Error("storage unavailable")};
runtime.window.localStorage.setItem=()=>{throw new Error("storage unavailable")};
assert.doesNotThrow(()=>runtime.cfReadDraft());assert.doesNotThrow(()=>runtime.cfSaveDraft("a",{},{}));
assert.ok(events.every(event=>!JSON.stringify(event).includes("wa.me")&&!JSON.stringify(event).includes("phone")));
console.log("Configurator audit passed: 48 models/594 accessories, hashed lazy catalog, 500SR, explicit URL precedence, saved selections, blocked storage/clipboard, unpriced analytics, no network events.");
