import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';
import { componentModule, descendants, homeModule, render } from './sales_render.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const dist = path.join(root, 'dist');
const assets = path.join(dist, 'assets');
const read = file => fs.readFileSync(file, 'utf8');
const manifest = JSON.parse(read(path.join(dist, 'sales-build.json')));
const text = node => typeof node === 'string' || typeof node === 'number' ? String(node) : Array.isArray(node) ? node.map(text).join('') : node?.props ? text(node.props.children) : '';
const hasClass = (node, name) => node.props?.className?.split(' ').includes(name);

for (const [locale, files] of Object.entries(manifest.locales)) {
  const { tree, models } = homeModule(assets, files.page, files.menu);
  const html = read(path.join(dist, files.home));
  assert.equal(html.match(/<main>.*?<\/main>/s)?.[0], render(tree), `${locale} home HTML/client parity`);
  const cards = descendants(tree, node => hasClass(node, 'model-card'));
  assert.equal(cards.length, 8, `${locale} featured model count`);
  assert.equal(new Set(cards.map(card => text(descendants(card, node => node.tag === 'h3')[0]))).size, 8);
  const select = descendants(tree, node => node.tag === 'select')[0];
  const options = descendants(select, node => node.tag === 'option');
  assert.equal(options.length, 49, `${locale} full calculator catalog`);
  assert.equal(models.length, 49, `${locale} full catalogue`);
  assert.equal(models.filter(model => model.slug === 'zeeho-ez4').length, 1, `${locale} EZ4 catalogue entry`);
  assert.equal(options.filter(option => option.props.value === 'ZEEHO EZ4').length, 1, `${locale} EZ4 finance option`);
  assert.equal(options.filter(option => option.props.value === '500SR').length, 1);
  assert.equal(models.find(model => model.slug === '150sc').price, 5490, 'User-confirmed 150SC price');
  const fullLinks = descendants(tree, node => hasClass(node, 'catalog-links'))[0];
  assert.equal(descendants(fullLinks, node => node.tag === 'a').length, 3);
  const categoryPaths = locale === 'az' ? ['/motosiklet/', '/kvadrosikl/', '/buggy/'] : ['/ru/motocikly/', '/ru/kvadrocikly/', '/ru/buggy/'];
  const hero = descendants(tree, node => hasClass(node, 'category-hero'))[0];
  const topAnchor = descendants(tree, node => hasClass(node, 'home-top-anchor'))[0];
  assert.equal(topAnchor.props.id, 'top');
  assert.equal(hero.props.id, undefined, `${locale} desktop hero no longer owns the shared anchor`);
  const heroLinks = descendants(hero, node => node.tag === 'a' && hasClass(node, 'primary'));
  assert.deepEqual(heroLinks.map(link => link.props.href), categoryPaths, `${locale} hero opens full categories`);
  const mobileEntry = descendants(tree, node => hasClass(node, 'home-mobile-entry'))[0];
  assert(mobileEntry, `${locale} mobile sales entry`);
  const mobileTitle = descendants(mobileEntry, node => hasClass(node, 'home-mobile-title'))[0];
  assert.equal(mobileTitle.props.role, 'heading');
  assert.equal(mobileTitle.props['aria-level'], 1);
  assert.equal(descendants(tree, node => node.tag === 'h1').length, 1, `${locale} keeps one semantic h1`);
  const mobilePrimary = descendants(mobileEntry, node => hasClass(node, 'home-mobile-primary'))[0];
  assert.equal(mobilePrimary.props.href, '#modeller');
  const mobileWhatsapp = descendants(mobileEntry, node => hasClass(node, 'home-mobile-whatsapp'))[0];
  assert(mobileWhatsapp.props.href.startsWith('https://wa.me/994512332484?text='));
  assert.equal(mobileWhatsapp.props['data-contact-area'], 'sales');
  const mobileCategories = descendants(mobileEntry, node => hasClass(node, 'home-mobile-categories'))[0];
  assert.deepEqual(descendants(mobileCategories, node => node.tag === 'a').map(link => link.props.href), categoryPaths, `${locale} mobile categories open full catalogues`);
  const campaignModel = models.find(model => model.slug === '800mt-x');
  const mobileCampaign = descendants(mobileEntry, node => hasClass(node, 'home-mobile-campaign'))[0];
  assert.equal(mobileCampaign.props.href, locale === 'az' ? '/model/800mt-x/' : '/ru/model/800mt-x/');
  assert(text(mobileCampaign).includes(new Intl.NumberFormat('en-US').format(campaignModel.price)), `${locale} mobile campaign price follows catalogue`);
  const taskbar = descendants(tree, node => hasClass(node, 'home-mobile-taskbar'))[0];
  assert(taskbar, `${locale} mobile taskbar`);
  assert.deepEqual(descendants(taskbar, node => node.tag === 'a').map(link => link.props.href).slice(0, 2), ['#modeller', '#kredit-kalkulyator']);
  const taskWhatsapp = descendants(taskbar, node => node.tag === 'a').at(-1);
  assert(taskWhatsapp.props.href.startsWith('https://wa.me/994512332484?text='));
  assert.equal(taskWhatsapp.props['data-contact-area'], 'sales');
  // Selecting a category must not silently omit its ninth (or thirtieth) model.
  for (const category of [...new Set(models.map(model => model.type))]) {
    const filtered = homeModule(assets, files.page, files.menu, [false, 'moto', category]).tree;
    const filteredCards = descendants(filtered, node => hasClass(node, 'model-card'));
    assert.equal(filteredCards.length, models.filter(model => model.type === category).length, `${locale} complete ${category} filter`);
  }

  const internalExamples = [
    { slug: '150sc', down: 20, monthly: '421', total: '6,149' },
    { slug: '750sr-s', down: 40, monthly: '972', total: '18,421' },
    { slug: 'z10', down: 50, monthly: '2,199', total: '49,343' },
  ];
  for (const example of internalExamples) {
    const model = models.find(model => model.slug === example.slug);
    const props = { model: model.name, price: model.price, type: model.type, whatsapp: 'https://wa.me/994512332484' };
    const finance = componentModule(path.join(assets, files.finance)).default(props);
    const slider = descendants(finance, node => node.tag === 'input')[0];
    assert.equal(slider.props.min, example.down);
    const result = text(descendants(finance, node => hasClass(node, 'model-calc-result'))[0]);
    assert(result.includes(example.monthly), `${locale} ${example.slug} monthly result`);
    assert(text(descendants(finance, node => hasClass(node, 'finance-total'))[0]).includes(example.total), `${locale} ${example.slug} total includes down payment`);
    const file = path.join(dist, locale === 'az' ? 'model' : 'ru/model', example.slug, 'index.html');
    assert(read(file).includes(render(finance)), `${locale} ${example.slug} initial finance parity`);

    const bank = componentModule(path.join(assets, files.finance), {}, ['bank', 36, 10]).default(props);
    assert.equal(descendants(bank, node => node.tag === 'input')[0].props.min, 10);
    assert.equal(descendants(bank, node => hasClass(node, 'finance-total')).length, 1, `${locale} estimated bank total is visible`);
    assert(text(descendants(bank, node => hasClass(node, 'finance-total'))[0]).includes(locale === 'az' ? 'Təxmini' : 'Примерная'), `${locale} bank total is explicitly estimated`);
    assert(descendants(bank, node => node.tag === 'button').some(button => text(button) === (locale === 'az' ? '36 ay' : '36 мес.')), `${locale} 36-month bank option`);
    if (example.slug !== 'z10') {
      const note = text(descendants(bank, node => hasClass(node, 'model-finance-note'))[0]);
      assert(note.includes(locale === 'az' ? 'tələb olunmur' : 'не требуется'), `${locale} no A-license condition for bank`);
      assert(!note.includes(locale === 'az' ? 'gəlirin göstərilməsi tələb olunur' : 'подтверждение дохода за последние'), 'No internal requirements on bank tab');
    }
  }

  // EZ4 participates in the homepage calculator as an explicitly confirmed
  // 40% motorcycle, while its standalone model page remains outside the React
  // model-page adapter.
  const ez4Model = models.find(model => model.slug === 'zeeho-ez4');
  const ez4Props = { model: ez4Model.name, price: ez4Model.price, type: ez4Model.type, whatsapp: 'https://wa.me/994512332484' };
  const ez4Internal = componentModule(path.join(assets, files.finance), {}, ['internal', 18, 40]).default(ez4Props);
  assert.equal(descendants(ez4Internal, node => node.tag === 'input')[0].props.min, 40, `${locale} EZ4 internal down payment`);
  assert(descendants(ez4Internal, node => node.tag === 'button').some(button => text(button) === (locale === 'az' ? '18 ay' : '18 мес.')), `${locale} EZ4 18-month internal term`);
  assert(text(descendants(ez4Internal, node => hasClass(node, 'model-calc-result'))[0]).includes('118'), `${locale} EZ4 18-month internal payment`);
  assert(text(descendants(ez4Internal, node => hasClass(node, 'finance-total'))[0]).includes('3,289'), `${locale} EZ4 internal total`);
  const ez4Bank = componentModule(path.join(assets, files.finance), {}, ['bank', 36, 10]).default(ez4Props);
  assert.equal(descendants(ez4Bank, node => node.tag === 'input')[0].props.min, 10, `${locale} EZ4 bank down payment`);
  assert(text(descendants(ez4Bank, node => hasClass(node, 'model-calc-result'))[0]).includes('89'), `${locale} EZ4 36-month bank payment`);
  assert(text(descendants(ez4Bank, node => hasClass(node, 'finance-total'))[0]).includes('3,488'), `${locale} EZ4 bank total`);

  // Bank interest must be charged to the post-down-payment balance using the
  // same term tiers as internal finance. 150SC: 5,490 AZN, 10% down = 4,941
  // AZN remaining before interest. The hard-coded totals prevent a regression
  // back to charging interest on the cash price or omitting it entirely.
  const bankTierModel = models.find(model => model.slug === '150sc');
  const bankTierProps = { model: bankTierModel.name, price: bankTierModel.price, type: bankTierModel.type, whatsapp: 'https://wa.me/994512332484' };
  const bankTiers = [
    { months: 6, monthly: '889', total: '5,885', rate: '8%' },
    { months: 12, monthly: '474', total: '6,231', rate: '15%' },
    { months: 18, monthly: '338', total: '6,626', rate: '23%' },
    { months: 36, monthly: '169', total: '6,626', rate: '23%' },
  ];
  for (const tier of bankTiers) {
    const bank = componentModule(path.join(assets, files.finance), {}, ['bank', tier.months, 10]).default(bankTierProps);
    const result = text(descendants(bank, node => hasClass(node, 'model-calc-result'))[0]);
    const total = text(descendants(bank, node => hasClass(node, 'finance-total'))[0]);
    assert(result.includes(tier.monthly), `${locale} ${tier.months}-month bank payment uses ${tier.rate} on remaining balance`);
    assert(total.includes(tier.total), `${locale} ${tier.months}-month bank total uses ${tier.rate} on remaining balance`);
    assert(result.includes(tier.rate), `${locale} ${tier.months}-month bank copy identifies ${tier.rate} tier`);
  }

  // Every React calculator must match its model, not just the selected examples.
  for (const model of models.filter(model => !['500sr', 'zeeho-ez4'].includes(model.slug))) {
    const finance = componentModule(path.join(assets, files.finance)).default({ model: model.name, price: model.price, type: model.type, whatsapp: 'https://wa.me/994512332484' });
    const file = path.join(dist, locale === 'az' ? 'model' : 'ru/model', model.slug, 'index.html');
    const modelHtml = read(file);
    assert(modelHtml.includes(render(finance)), `${locale} ${model.slug} finance HTML/client parity`);
    const header = modelHtml.match(/<header class="site-header detail-header">.*?<\/header>/s)?.[0];
    assert.equal(header?.match(/class="menu-button"/g)?.length, 1, 'Model menu button is server-rendered');
    assert.equal(header?.match(/class="language-switcher"/g)?.length, 1, 'Model language switcher is server-rendered');
    assert(!modelHtml.includes('<!-- CFMOTO:LANGUAGE:START -->'), 'No duplicate body switcher');
    const rows = [...modelHtml.matchAll(/__VINEXT_RSC_CHUNKS__\.push\(("(?:\\.|[^"\\])*")\)/g)].flatMap(match => JSON.parse(match[1]).split('\n'));
    const main = JSON.parse(rows.find(row => row.startsWith('1:')).slice(2));
    const rscHeader = main[3].children.find(node => node?.[1] === 'header');
    assert.equal(rscHeader[3].children.length, 4, 'Model header has identical hydrated controls');
    const [brand, nav, switcher, button] = rscHeader[3].children;
    assert.equal(nav[3].id, 'site-primary-navigation');
    assert.equal(switcher[3].className, 'language-switcher');
    assert.equal(button[3].className, 'menu-button');
    assert.equal(button[3]['aria-controls'], nav[3].id);
  }
  const credit = read(path.join(dist, locale === 'az' ? 'kredit/index.html' : 'ru/kredit/index.html'));
  assert(credit.includes(locale === 'az' ? '36 ayadək' : '36 месяцев'));
  assert(credit.includes('finance-eligibility'));
  assert(!html.includes(locale === 'az' ? '35 ayadək' : '35 месяцев'));

  const standaloneHtml = read(path.join(dist, locale === 'az' ? 'model/500sr/index.html' : 'ru/model/500sr/index.html'));
  assert(standaloneHtml.includes(locale === 'az' ? 'faiz cədvəli qalıq borca tətbiq olunur' : 'к остатку долга применяется та же шкала процентов'), `${locale} 500SR bank balance note`);
  assert(standaloneHtml.includes(`data-internal-total-label="${locale === 'az' ? 'Ümumi ödəniş · ilkin ödəniş daxil' : 'Всего к оплате · включая первоначальный взнос'}"`), `${locale} 500SR internal total label`);
  assert(standaloneHtml.includes(`data-bank-total-label="${locale === 'az' ? 'Təxmini ümumi ödəniş · ilkin ödəniş daxil' : 'Примерная общая сумма · включая первоначальный взнос'}"`), `${locale} 500SR bank total label`);
  assert(standaloneHtml.includes(`<span data-installment-total-label>${locale === 'az' ? 'Ümumi ödəniş · ilkin ödəniş daxil' : 'Всего к оплате · включая первоначальный взнос'}</span>`), `${locale} 500SR starts with internal total label`);
  const ez4Html = read(path.join(dist, locale === 'az' ? 'model/zeeho-ez4/index.html' : 'ru/model/zeeho-ez4/index.html'));
  assert(ez4Html.includes('2,890 AZN'), `${locale} EZ4 confirmed cash price`);
  assert(!ez4Html.includes('class="model-calculator"') && ez4Html.includes('id="odenis"') && ez4Html.includes('data-ez4-finance'), `${locale} EZ4 standalone calculator`);
  assert(ez4Html.includes('data-down type="range" min="40" max="80" step="5" value="40"'), `${locale} EZ4 standalone 40% down payment`);
  assert(ez4Html.includes('data-bank-term type="range" min="3" max="36" step="1" value="36"'), `${locale} EZ4 standalone 36-month bank term`);
  assert(ez4Html.includes('<span data-monthly>118</span>') && ez4Html.includes('<strong data-installment-total>3,289</strong>'), `${locale} EZ4 standalone initial calculation`);
  assert(/\/assets\/ez4-finance-v1-sales-[a-f0-9]{12}\.js/.test(ez4Html), `${locale} fingerprinted EZ4 finance module`);
}

const service = read(path.join(dist, 'servis/index.html'));
assert(service.includes("contact_area:declaredArea||(serviceContact?'service':'sales')"), 'Declared service area is respected');
const css = read(path.join(assets, 'sales-improvements-v1.css'));
assert(css.includes('.product-copy .hero-actions .button.primary'));
assert(css.includes('.product-copy .hero-actions .accessory-model-cta'));
const mobileCss = read(path.join(assets, 'mobile-home-sales-v1.css'));
assert(mobileCss.includes('.home-mobile-entry'));
assert(mobileCss.includes('url("/gallery/800mt-x-1.webp")'));
assert(mobileCss.includes('.whatsapp'));
const standaloneFinance = fs.readdirSync(assets).find(name => /^500sr-finance-v1-sales-[a-f0-9]{12}\.js$/.test(name));
assert(standaloneFinance, 'Fingerprint for 500SR finance module');
const standaloneFinanceSource = read(path.join(assets, standaloneFinance));
assert(standaloneFinanceSource.includes('const rateForMonths=months=>months<=6?.08:months<=12?.15:.23;'), '500SR bank rate tiers');
assert(standaloneFinanceSource.includes('const debt=balance*(1+rateForMonths(months));'), '500SR bank interest applies to remaining balance');
assert(standaloneFinanceSource.includes("mode==='bank'?root.dataset.bankTotalLabel:root.dataset.internalTotalLabel"), '500SR total label follows finance mode');
assert(standaloneFinanceSource.includes("toggle(root.querySelector('[data-installment-total-row]'),false);"), '500SR bank total remains visible');
const ez4StandaloneFinance = fs.readdirSync(assets).find(name => /^ez4-finance-v1-sales-[a-f0-9]{12}\.js$/.test(name));
assert(ez4StandaloneFinance, 'Fingerprint for EZ4 finance module');
const ez4StandaloneFinanceSource = read(path.join(assets, ez4StandaloneFinance));
assert(ez4StandaloneFinanceSource.includes('const rateForMonths=months=>months<=6?.08:months<=12?.15:.23;'), 'EZ4 finance rate tiers');
assert(ez4StandaloneFinanceSource.includes('const debt=balance*(1+rateForMonths(months));'), 'EZ4 interest applies to remaining balance');
assert(ez4StandaloneFinanceSource.includes('down.min=bank?"10":"40";'), 'EZ4 mode-specific down payment');
assert(ez4StandaloneFinanceSource.includes('installmentTotal.textContent=format.format(paid+debt);'), 'EZ4 total includes down payment');
assert.equal(manifest.bankMaxMonths, 36);
console.log('Sales audit passed: AZ/RU homepage parity, 49 catalogue and calculator models, 94 React model-page states, EZ4 40%/18-month finance and bank balance rates');
