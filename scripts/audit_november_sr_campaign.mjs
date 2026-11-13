import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
import {campaigns} from './november_sr_campaign.mjs';
import {componentModule, homeModule, descendants, render} from './sales_render.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../dist');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const manifest=JSON.parse(read('sales-build.json'));
const klass=(node,name)=>node.props?.className?.split(' ').includes(name);
const plain=node=>render(node).replace(/<[^>]*>/g,'');
for(const [locale,files] of Object.entries(manifest.locales)) {
  const ru=locale==='ru',prefix=ru?'ru/':'';
  const {models}=homeModule(path.join(root,'assets'),files.page,files.menu);
  for(const c of campaigns) {
    const model=models.find(m=>m.slug===c.slug);
    const comparison=read(ru?'ru/sravnenie-modeley/index.html':'model-muqayisesi/index.html');
    const row=[...comparison.matchAll(/<tr.*?<\/tr>/gs)].map(m=>m[0]).find(r=>r.includes(`/model/${c.slug}/`));
    assert(row.includes(ru?'12 месяцев без процентов':'12 ay faizsiz'));
    assert(row.includes(ru?'Сумма рассрочки':'Hissəli ödənişin cəmi'));

    assert.equal(model.price,c.cash);assert.equal(model.listPrice,c.total);
    const props={model:c.name,price:c.cash,type:model.type,whatsapp:'https://wa.me/994512332484'};
    const calculator=componentModule(path.join(root,'assets',files.finance)).default(props);
    const result=plain(descendants(calculator,n=>klass(n,'model-calc-result'))[0]);
    assert(result.includes(c.monthly%1?c.monthly.toFixed(2):String(c.monthly)));
    assert(result.includes(ru?'12 месяцев без процентов':'12 ay faizsiz'));
    assert(result.includes('30.11.2026'));
    const slider=descendants(calculator,n=>n.tag==='input')[0];
    assert.equal(slider.props.disabled,true);assert.equal(slider.props.value,40);
    const months=descendants(calculator,n=>klass(n,'month-options'))[0];
    assert.equal(descendants(months,n=>n.tag==='button').length,1);
    const html=read(`${prefix}model/${c.slug}/index.html`);
    for(const other of campaigns.filter(m=>m.slug!==c.slug)) {
      const related=[...html.matchAll(/<a\b[^>]*>.*?<\/a>/gs)].map(m=>m[0]).filter(a=>a.includes(`/model/${other.slug}\"`)||a.includes(`/model/${other.slug}/\"`));
      assert(related.some(a=>a.includes(new Intl.NumberFormat('en-US').format(other.cash))),`${locale} related-model cash price`);
    }
    assert(html.includes(render(calculator)),`${locale}/${c.slug} SSR/client parity`);
    const schema=[...html.matchAll(/<script type="application\/ld\+json">(.*?)<\/script>/gs)].map(m=>JSON.parse(m[1])).find(s=>s['@type']==='Product');
    assert.equal(schema.offers.price,c.cash);assert.equal(schema.offers.priceValidUntil,'2026-11-30');
    const rows=[...html.matchAll(/__VINEXT_RSC_CHUNKS__\.push\(("(?:\\.|[^"\\])*")\)/g)].flatMap(m=>JSON.parse(m[1]).split('\n'));
    let financeProps=0,hero=0;
    const visit=node=>{
      if(!node||typeof node!=='object')return;
      if(node.model===c.name&&node.price!==undefined){financeProps++;assert.equal(node.price,c.cash);}
      if(node.className==='product-price is-campaign sr-november-offer')hero++;
      Object.values(node).forEach(visit);
    };
    rows.filter(r=>/^[0-9a-f]+:[\[{]/.test(r)).forEach(r=>visit(JSON.parse(r.slice(r.indexOf(':')+1))));
    assert.equal(financeProps,1);assert.equal(hero,1);
    // A campaign selected after an 18-month model must snap to 12 months/40%.
    const home=homeModule(path.join(root,'assets'),files.page,files.menu,[false,'moto',ru?'Все':'Hamısı',c.name,ru?'Внутренняя рассрочка':'Daxili hissəli',75,18]).tree;
    const homeDown=descendants(home,n=>n.props?.id==='down')[0];
    const homeTerm=descendants(home,n=>n.props?.id==='term')[0];
    assert.equal(homeDown.props.value,40);assert.equal(homeTerm.props.value,12);
    assert.equal(homeTerm.props.disabled,true);
    assert(plain(descendants(home,n=>klass(n,'calc-result'))[0]).includes(c.monthly%1?c.monthly.toFixed(2):String(c.monthly)));
    // The ordinary bank tab must continue charging its existing interest tiers.
    const bank=componentModule(path.join(root,'assets',files.finance),{},['bank',12,10]).default(props);
    assert.equal(descendants(bank,n=>n.tag==='input')[0].props.disabled,false);
    assert(plain(descendants(bank,n=>klass(n,'model-calc-result'))[0]).includes('15%'));
  }
}
const report=JSON.parse(fs.readFileSync(path.resolve(root,'../work-configurator-improvements-report.json'),'utf8'));
const config=read(report.bundle.replace(/^\//,''));
for(const c of campaigns)assert(new RegExp(`"id":"${c.slug}"[^}]*"basePriceAzn":${c.cash}`).test(config),`${c.name} configurator cash price`);
console.log('November SR audit passed: exact cash/credit amounts, 0%/12 months/40%, AZ/RU HTML/RSC parity, home selection, ordinary bank interest, configurator and offer expiry.');
