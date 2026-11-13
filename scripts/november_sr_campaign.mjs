// Approved November offers: cash discount OR 40% down + 12 interest-free payments.
// Run on the deployment tree before sales rendering/fingerprinting so HTML,
// RSC, catalogues and interactive calculators all use the same offer.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { render } from './sales_render.mjs';

export const campaigns = [
  { slug: '675sr-r', name: '675SR-R', cash: 14490, total: 15490, down: 6196, monthly: 774.5 },
  { slug: '750sr-s', name: '750SR-S', cash: 15900, total: 16900, down: 6760, monthly: 845 },
];
const prices = Object.fromEntries(campaigns.map(c => [c.name, c.total]));
const fmt = value => new Intl.NumberFormat('en-US', {minimumFractionDigits: value%1?2:0, maximumFractionDigits: 2}).format(value);
const once = (source, before, after) => {
  if (source.split(before).length !== 2) throw new Error(`SR campaign anchor: ${before.slice(0,100)}`);
  return source.replace(before, after);
};
export const campaignCopy = ru => ru
  ? 'До 30.11.2026: 12 месяцев без процентов, первоначальный взнос 40%. Рассрочка рассчитывается от полной цены; скидка 1,000 AZN действует только при оплате наличными. Предложения не суммируются. На выбранные единицы в наличии, требуется одобрение.'
  : '30.11.2026-dək: 12 ay faizsiz, 40% ilkin ödəniş. Hissəli ödəniş tam qiymətdən hesablanır; 1,000 AZN endirim yalnız nağd alış üçündür. Təkliflər birləşdirilmir. Seçilmiş stok üçün keçərlidir, kredit təsdiqi tələb olunur.';

export function campaignFinance(source, ru) {
  source = once(source, 'function o({model:e,price:t,type:n,whatsapp:o}){let s=', `function o({model:e,price:t,type:n,whatsapp:o}){const srPrice=${JSON.stringify(prices)}[e];let s=`);
  source = once(source, 'm=s?[6,12,18]:[6,12]', 'm=srPrice?[12]:s?[6,12,18]:[6,12]');
  source = once(source, 'let e=f/100*t,n=Math.max(0,t-e),interestRate=rateForMonths(u)', 'let base=srPrice&&c===`internal`?srPrice:t,e=(srPrice&&c===`internal`?40:f)/100*base,n=Math.max(0,base-e),interestRate=srPrice&&c===`internal`?0:rateForMonths(u)');
  source = once(source, 'a(y.financed-(t-y.downPayment))', 'a(y.financed-((srPrice&&c===`internal`?srPrice:t)-y.downPayment))');
  source = once(source, 'children:[f,`% · `', 'children:[srPrice&&c===`internal`?40:f,`% · `');
  source = once(source, 'max:`80`,step:`5`,value:f', 'max:srPrice&&c===`internal`?40:80,disabled:!!srPrice&&c===`internal`,step:`5`,value:srPrice&&c===`internal`?40:f');
  source = once(source, 'children:`80%`', 'children:srPrice&&c===`internal`?`40%`:`80%`');
  source = once(source, '(${f}%),', '(${srPrice&&c===`internal`?40:f}%),');
  source = once(source, 'a(y.monthly)', '(srPrice&&c===`internal`?new Intl.NumberFormat(`en-US`,{minimumFractionDigits:y.monthly%1?2:0,maximumFractionDigits:2}).format(y.monthly):a(y.monthly))');
  const note = ru ? 'Проценты по рассрочке: 6 месяцев — 8%, 12 месяцев — 15%, 18 месяцев — 23%. Итоговые условия подтверждает специалист по продажам.' : 'Daxili ödəniş faizləri: 6 ay 8%, 12 ay 15%, 18 ay 23%. Yekun şərtlər satış mütəxəssisi tərəfindən təsdiqlənir.';
  source = once(source, '`'+note+'`', 'srPrice?'+JSON.stringify(campaignCopy(ru))+':`'+note+'`');
  const slider = ru ? 'При изменении ползунка ежемесячный платёж пересчитывается с учётом первоначального взноса.' : 'Slider dəyişdikcə ilkin ödənişə görə aylıq ödəniş hesablanır.';
  source = once(source, '`'+slider+'`', 'srPrice&&c===`internal`?'+JSON.stringify(ru?'Акция: 40% первоначальный взнос · 12 месяцев без процентов':'Kampaniya: 40% ilkin ödəniş · 12 ay faizsiz')+':`'+slider+'`');
  const tab = ru ? 'Рассрочка' : 'Daxili ödəniş';
  source = once(source, 'children:`'+tab+'`', 'children:srPrice?'+JSON.stringify(ru?'12 месяцев без процентов':'12 ay faizsiz')+':`'+tab+'`');
  return source;
}

export function campaignHome(source, ru) {
  const bank = ru ? 'Банковский кредит' : 'Bank krediti';
  source = once(source, 'E=T.price??0', `srPrice=${JSON.stringify(prices)}[T.name],srOffer=!!srPrice&&_!==\`${bank}\`,E=srOffer?srPrice:T.price??0`);
  source = once(source, 'A=Math.max(y,O),j=Math.min(x,k)', 'A=srOffer?40:Math.max(y,O),j=srOffer?12:Math.min(x,k)');
  source = once(source, 'interestRate=rateForMonths(j)', 'interestRate=srOffer?0:rateForMonths(j)');
  source = once(source, 'id:`down`,type:`range`,min:O,max:`80`,step:`5`,value:A', 'id:`down`,type:`range`,min:O,max:srOffer?40:80,disabled:srOffer,step:`5`,value:A');
  source = once(source, `id:\`term\`,type:\`range\`,min:_===\`${bank}\`?3:6,max:k`, `id:\`term\`,type:\`range\`,min:srOffer?12:_===\`${bank}\`?3:6,max:srOffer?12:k,disabled:srOffer`);
  source = once(source, 'o(P)', '(srOffer?new Intl.NumberFormat(`en-US`,{minimumFractionDigits:P%1?2:0,maximumFractionDigits:2}).format(P):o(P))');
  const note = ru ? 'Проценты по рассрочке: 6 месяцев — 8%, 12 месяцев — 15%, 18 месяцев — 23%. Проценты начисляются на остаток после первоначального взноса.' : 'Daxili ödəniş faizləri: 6 ay 8%, 12 ay 15%, 18 ay 23%. Faiz ilkin ödənişdən sonra qalan borca tətbiq olunur.';
  source = once(source, '`'+note+'`', 'srOffer?'+JSON.stringify(campaignCopy(ru))+':`'+note+'`');
  return source;
}

const element = (tag, props) => ['$', tag, null, props];
const toTree = node => Array.isArray(node) && node[0] === '$' ? {tag:node[1], props:{...node[3],children:toTree(node[3].children)}} : Array.isArray(node) ? node.map(toTree) : node;
function priceBlock(c, ru) {
  return element('div', {className:'product-price is-campaign sr-november-offer', children:[
    element('small',{children:ru?'Цена наличными · до 30 ноября':'Nağd qiymət · 30 noyabradək'}),
    element('del',{children:fmt(c.total)+' AZN'}),
    element('strong',{children:fmt(c.cash)+' AZN'}),
    element('span',{className:'campaign-saving',children:ru?'Скидка 1,000 AZN':'1,000 AZN endirim'}),
    element('p',{className:'sr-interest-free',children:ru?'или 12 месяцев без процентов':'və ya 12 ay faizsiz'}),
    element('p',{children:ru?`40% взнос: ${fmt(c.down)} AZN · ${fmt(c.monthly)} AZN × 12 мес.`:`40% ilkin: ${fmt(c.down)} AZN · ${fmt(c.monthly)} AZN × 12 ay`}),
    element('small',{children:(ru?'Общая сумма рассрочки: ':'Hissəli ödənişin ümumi məbləği: ')+fmt(c.total)+' AZN'}),
    element('small',{className:'sr-offer-terms',children:ru?'До 30.11.2026. Предложения не суммируются. На выбранные единицы в наличии. Требуется одобрение. НДС включён.':'30.11.2026-dək. Təkliflər birləşdirilmir. Seçilmiş stok üçün keçərlidir. Kredit təsdiqi tələb olunur. ƏDV daxildir.'}),
  ]});
}
function cashTokens(text,c) { return text.replaceAll(fmt(c.total),fmt(c.cash)).replace(new RegExp(`(?<!\\d)${c.total}(?!\\d)`,'g'),String(c.cash)); }
function identify(node,c) {return node&&(node.slug===c.slug||node.id===c.slug||node.model===c.name||node.value===c.name||node.name===c.name||node.href?.match(new RegExp(`/model/${c.slug}/?$`)));}
function transformNode(node,c,detail,ru) {
  if (!node||typeof node!=='object') return;
  if (Array.isArray(node)&&node[0]==='$') {
    const props=node[3];
    if(detail&&/^product-price(?: |$)/.test(props?.className||'')) {node.splice(0,node.length,...priceBlock(c,ru));return;}
    if(identify(props,c)&&props.price!==undefined)props.price=c.cash;
    if(identify(props,c)&&props.children)props.children=deepCash(props.children,c);
  }
  if (node.dangerouslySetInnerHTML?.__html?.startsWith('{')) {
    try {const schema=JSON.parse(node.dangerouslySetInnerHTML.__html);transformNode(schema,c,false,ru);node.dangerouslySetInnerHTML.__html=JSON.stringify(schema);} catch {}
  }
  if (node['@type']==='Product' && (node.name===c.name||node.url?.includes(`/model/${c.slug}/`)) && node.offers) {
    node.offers.price=c.cash;node.offers.priceValidUntil='2026-11-30';
  }
  if(identify(node,c))for(const key of ['price','basePriceAzn'])if(node[key]!==undefined)node[key]=c.cash;
  for(const [key,value]of Object.entries(node)) {
    if(detail&&typeof value==='string')node[key]=value.replaceAll('18 ayadək daxili hissəli ödəniş','12 ay faizsiz · 30 noyabradək').replaceAll('Рассрочка на срок до 18 месяцев','12 месяцев без процентов · до 30 ноября');
    transformNode(node[key],c,detail,ru);
  }
}
function deepCash(value,c) {
  if(typeof value==='string')return cashTokens(value,c);
  if(typeof value==='number')return value===c.total?c.cash:value;
  if(Array.isArray(value))return value.map(v=>deepCash(v,c));
  if(value&&typeof value==='object')return Object.fromEntries(Object.entries(value).map(([k,v])=>[k,deepCash(v,c)]));
  return value;
}
export function applyCampaignPrices(dist) {
  const walk=dir=>fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(dir,e.name)):[path.join(dir,e.name)]);
  for(const file of walk(dist).filter(f=>/\.(html|js|txt|json)$/.test(f))) {
    let source=fs.readFileSync(file,'utf8'), original=source;
    const ru=file.includes('/ru/');
    for(const c of campaigns) {
      if(file.endsWith('.html')) {
        const detail=file.endsWith(`/model/${c.slug}/index.html`);
        // Scoped cards, comparison rows and select options, never arbitrary prices.
        for(const tag of ['article','tr','option','a'])source=source.replace(new RegExp(`<${tag}\\b[^>]*>.*?</${tag}>`,'gs'),fragment=> {
          if(!fragment.includes(`/model/${c.slug}/`)&&!fragment.includes(`/model/${c.slug}"`)&&!fragment.includes(`value="${c.name}"`))return fragment;
          let updated=cashTokens(fragment,c);
          if(tag==='a'&&fragment.includes('class="mega-model"')) {
            const price=element('p',{className:'campaign-menu-price',children:[element('del',{children:fmt(c.total)+' AZN'}),element('span',{children:fmt(c.cash)+(ru?' AZN · Акция':' AZN · Kampaniya')}),' ',element('b',{children:'↗︎'})]});
            updated=updated.replace(/<p\b[^>]*>.*?<\/p>/s,render(toTree(price)));
          }
          if(tag==='tr')updated=updated.replace('18 ayadək','12 ay faizsiz · 30.11.2026-dək').replace(/(?:До|до) 18 (?:месяцев|мес\.)/g,'12 месяцев без процентов · до 30.11.2026')
            .replace(`<td>${fmt(c.cash)} AZN</td>`,`<td>${fmt(c.cash)} AZN · ${ru?'наличными':'nağd'}</td>`)
            .replace(`<td>40% · ${fmt(c.down)} AZN</td>`,`<td>40% · ${fmt(c.down)} AZN<small style="display:block">${ru?'Сумма рассрочки':'Hissəli ödənişin cəmi'}: ${fmt(c.total)} AZN</small></td>`);
          return updated;
        });
        source=source.replace(/<script type="application\/ld\+json">(.*?)<\/script>/gs,(match,json)=>{
          let node;try{node=JSON.parse(json);}catch{return match;}transformNode(node,c,false,ru);return `<script type="application/ld+json">${JSON.stringify(node)}</script>`;
        });
        if(detail)source=source.replace(/<div class="product-price[^\"]*"[^>]*>.*?<\/div>/s,render(toTree(priceBlock(c,ru)))).replaceAll('18 ayadək daxili hissəli ödəniş','12 ay faizsiz · 30 noyabradək').replaceAll('Рассрочка на срок до 18 месяцев','12 месяцев без процентов · до 30 ноября');
        source=source.replace(/(__VINEXT_RSC_CHUNKS__\.push\()("(?:\\.|[^"\\])*")(\))/g,(_,before,encoded,after)=>{
          const chunk=JSON.parse(encoded).split('\n').map(line=>{const m=line.match(/^([0-9a-f]+:)([\[{].*)$/);if(!m)return line;const node=JSON.parse(m[2]);transformNode(node,c,detail,ru);return m[1]+JSON.stringify(node);}).join('\n');
          return before+JSON.stringify(chunk).replaceAll('<','\\u003c')+after;
        });
      } else if(file.includes('/assets/')) {
        source=source.replace(new RegExp(`\\{slug:\`${c.slug}\`,[^{}]*\\}`,'g'),record=>cashTokens(record,c).replace(`price:${c.cash},`,`price:${c.cash},listPrice:${c.total},campaign:!0,`));
      } else if(file.includes('/aksesuar-konfiquratoru/')) {
        source=source.replace(new RegExp(`\\{id:"${c.slug}",[^{}]*`,'g'),record=>record.replace(`basePriceAzn:${c.total}`,`basePriceAzn:${c.cash}`));
      }
    }
    if(file.endsWith('/kredit/index.html')) {
      const cards=campaigns.map(c=>`<h3>${c.name}</h3>${render(toTree(priceBlock(c,ru)))}`).join('');
      source=source.replace('<div class="cta-box">',`<section class="prose sr-credit-campaign"><h2>${ru?'Ноябрь: наличными или без процентов':'Noyabr: nağd endirim və ya faizsiz ödəniş'}</h2>${cards}</section><div class="cta-box">`);
    }
    if(/\/(?:model\/(?:675sr-r|750sr-s)|kredit)\/index\.html$/.test(file))source=source.replace('</head>','<link rel="stylesheet" href="/assets/sr-november-2026.css"/></head>');
    if(source!==original)fs.writeFileSync(file,source);
  }
  fs.writeFileSync(path.join(dist,'assets/sr-november-2026.css'),'.sr-november-offer{display:flex;flex-direction:column;align-items:flex-start;gap:7px}.sr-november-offer p{margin:0;font-size:16px;line-height:1.45}.sr-november-offer .sr-interest-free{font-size:21px;font-weight:700;margin-top:8px}.sr-november-offer .sr-offer-terms{max-width:510px;font-size:12px;line-height:1.5;opacity:.76;text-transform:none;letter-spacing:0}.sr-credit-campaign .sr-november-offer{margin-bottom:28px}.model-calculator input:disabled,#kredit-kalkulyator input:disabled{opacity:.5;cursor:default}');
  console.log('November SR offers applied: 675SR-R 14,490 / 15,490; 750SR-S 15,900 / 16,900; 12 months at 0%, 40% down.');
}
if(process.argv[1]===fileURLToPath(import.meta.url))applyCampaignPrices(path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../dist'));
