// The imported snapshot remains complete for the existing category/SEO build.
// This final, deterministic step updates the public HTML and its client modules
// together, then gives the module graph new URLs for returning visitors.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { componentModule, homeModule, render } from './sales_render.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const dist = path.join(root, 'dist');
const assets = path.join(dist, 'assets');
const featured = ['750sr-s', '450mt', '150sc', 'aura-150', 'cforce-c4', 'cforce-c5', 'z10', 'z10-4'];
const read = file => fs.readFileSync(file, 'utf8');
const write = (file, text) => fs.writeFileSync(file, text);
const assert = (condition, message) => { if (!condition) throw new Error(message); };
const replace = (source, from, to, label) => {
  assert(source.includes(from), `Missing ${label} anchor`);
  return source.replace(from, to);
};
const walk = folder => fs.readdirSync(folder, { withFileTypes: true }).flatMap(item => item.isDirectory() ? walk(path.join(folder, item.name)) : path.join(folder, item.name));
const originalModules = Object.fromEntries(fs.readdirSync(assets).filter(name => name.endsWith('.js')).map(name => [name, read(path.join(assets, name))]));

// The navigation/language controllers used to insert children before React
// hydrated model pages. Author those same controls in both render sources.
function modelHeader(html, language, slug) {
  const ru = language === 'ru';
  const element = (tag, props) => ['$', tag, null, props];
  const alternate = element('a', { href: `${ru ? '' : '/ru'}/model/${slug}/`, lang: ru ? 'az' : 'ru', hrefLang: ru ? 'az' : 'ru', children: ru ? 'AZ' : 'RU' });
  const current = element('span', { 'aria-current': 'page', children: ru ? 'RU' : 'AZ' });
  const switcher = element('nav', { className: 'language-switcher', 'aria-label': ru ? 'Выбор языка' : 'Dil seçimi', children: ru ? [alternate, current] : [current, alternate] });
  const button = element('button', { className: 'menu-button', type: 'button', 'aria-label': ru ? 'Открыть меню' : 'Menyunu aç', 'aria-expanded': 'false', 'aria-controls': 'site-primary-navigation', children: [element('span', {}), element('span', {})] });
  const toTree = node => Array.isArray(node) && node[0] === '$'
    ? { tag: node[1], props: { ...node[3], children: toTree(node[3].children) } }
    : Array.isArray(node) ? node.map(toTree) : node;
  html = html.replace(/<!-- CFMOTO:LANGUAGE:START -->.*?<!-- CFMOTO:LANGUAGE:END -->/gs, '');
  let visibleHeaders = 0;
  html = html.replace(/<header class="site-header detail-header">.*?<\/header>/gs, header => {
    visibleHeaders++;
    return header.replace('class="main-nav detail-nav"', 'class="main-nav detail-nav" id="site-primary-navigation"')
      .replace('</header>', render(toTree(switcher)) + render(toTree(button)) + '</header>');
  });
  let payloadHeaders = 0;
  const visit = node => {
    if (!node || typeof node !== 'object') return;
    if (Array.isArray(node) && node[0] === '$' && node[1] === 'header' && node[3]?.className === 'site-header detail-header') {
      const nav = node[3].children.find(child => child?.[1] === 'nav');
      nav[3].id = 'site-primary-navigation';
      node[3].children.push(switcher, button);
      payloadHeaders++;
      return;
    }
    Object.values(node).forEach(visit);
  };
  html = html.replace(/(__VINEXT_RSC_CHUNKS__\.push\()("(?:\\.|[^"\\])*")(\))/g, (_, before, value, after) => {
    const chunk = JSON.parse(value).split('\n').map(line => {
      const match = line.match(/^([0-9a-f]+:)([\[{].*)$/);
      if (!match) return line;
      const node = JSON.parse(match[2]);
      visit(node);
      return match[1] + JSON.stringify(node);
    }).join('\n');
    return before + JSON.stringify(chunk).replaceAll('<', '\\u003c') + after;
  });
  assert(visibleHeaders === 1 && payloadHeaders === 1, `${language} ${slug} model header parity`);
  return html;
}

const locales = {
  az: {
    home: 'index.html', page: 'page-CfmotoHomeNewsV5.js', menu: 'ProductMegaMenu-CfmotoHomeNewsV5.js', finance: 'ModelFinance-CfmotoFinanceFixV12.js',
    all: 'Hamısı', motorcycle: 'Motosiklet',
    oldCatalogNote: ' aktual model · Hər modelin ayrıca məlumat səhifəsi mövcuddur.',
    catalogNote: ' seçilmiş model. Tam model sırasına kateqoriyalar üzrə baxın.',
    catalogLabel: 'Tam model sırası',
    categories: [['Motosikletlər', '/motosiklet/'], ['Kvadrosikllər', '/kvadrosikl/'], ['Buggy və UTV', '/buggy/']],
    oldCashLabel: 'Yekun nağd qiymət', cashLabel: 'Nağd qiymət', totalLabel: 'Ümumi ödəniş · ilkin ödəniş daxil', surchargeLabel: 'Hissəli ödəniş üzrə əlavə məbləğ',
    oldEligibility: 'A kateqoriyalı sürücülük vəsiqəsi tələb olunur. Zəmanət: 2 il və ya 24.000 km.',
    internalEligibility: 'Daxili hissəli ödəniş üçün A kateqoriyası və son 6 ay üzrə gəlirin göstərilməsi tələb olunur. Gəlirin rəsmi olması şərt deyil.',
    bankEligibility: 'Bank krediti üçün A kateqoriyalı sürücülük vəsiqəsi tələb olunmur. Sənədlər və yekun təsdiq bankın şərtlərinə əsasən müəyyən olunur.',
    warranty: 'Zəmanət: 2 il və ya 24.000 km.',
    bankMode: 'Bank krediti', internalMode: 'Daxili hissəli',
    oldHomeNote: 'Daxili ödəniş faizləri: 6 ay 8%, 12 ay 15%, 18 ay 23%. Bank şərtləri ayrıca hesablanır.',
    bankNote: 'Bank faizi və komissiyası daxil deyil. Yekun aylıq ödəniş bank tərəfindən hesablanır.',
    creditRoute: 'kredit/index.html', creditHeading: 'Alış üçün tələb olunan məlumatlar', internalHeading: 'Daxili hissəli ödəniş', bankHeading: 'Bank krediti',
  },
  ru: {
    home: 'ru/index.html', page: 'page-CfmotoRussianV7.js', menu: 'ProductMegaMenu-CfmotoRussianV7.js', finance: 'ModelFinance-CfmotoRussianV7.js',
    all: 'Все', motorcycle: 'Мотоцикл',
    oldCatalogNote: ' актуальных моделей · У каждой модели есть отдельная страница с информацией.',
    catalogNote: ' избранных моделей. Полный модельный ряд — в разделах каталога.',
    catalogLabel: 'Полный модельный ряд',
    categories: [['Мотоциклы', '/ru/motocikly/'], ['Квадроциклы', '/ru/kvadrocikly/'], ['Багги и UTV', '/ru/buggy/']],
    oldCashLabel: 'Итоговая цена при оплате наличными', cashLabel: 'Цена при оплате наличными', totalLabel: 'Всего к оплате · включая первоначальный взнос', surchargeLabel: 'Переплата по рассрочке',
    oldEligibility: 'Требуется водительское удостоверение категории A. Гарантия: 2 года или 24 000 км.',
    internalEligibility: 'Для внутренней рассрочки нужны водительское удостоверение категории A и подтверждение дохода за последние 6 месяцев. Официальное трудоустройство не обязательно.',
    bankEligibility: 'Для банковского кредита водительское удостоверение категории A не требуется. Документы и окончательное решение определяются условиями банка.',
    warranty: 'Гарантия: 2 года или 24 000 км.',
    bankMode: 'Банковский кредит', internalMode: 'Внутренняя рассрочка',
    oldHomeNote: 'Проценты по рассрочке: 6 месяцев — 8%, 12 месяцев — 15%, 18 месяцев — 23%. Банковские условия рассчитываются отдельно.',
    bankNote: 'Банковский процент и комиссия не включены. Итоговый ежемесячный платёж рассчитывается банком.',
    creditRoute: 'ru/kredit/index.html', creditHeading: 'Что нужно для покупки', internalHeading: 'Внутренняя рассрочка', bankHeading: 'Банковский кредит',
  },
};

// User-confirmed bank term; change only credit wording/control bounds, never
// prices or unrelated measurements that happen to contain 35.
function bankTerm(text) {
  return text.replaceAll('35 ayadək', '36 ayadək').replaceAll('35 месяцев', '36 месяцев')
    .replaceAll('24,35]', '24,36]').replaceAll('?35:', '?36:')
    .replaceAll('max="35"', 'max="36"').replaceAll('data-bank-term-value>35<', 'data-bank-term-value>36<')
    .replaceAll('data-bank-term type="range" min="3" max="36" step="1" value="35"', 'data-bank-term type="range" min="3" max="36" step="1" value="36"')
    .replaceAll('Bütün modellər', 'Seçilmiş modellər').replaceAll('Все модели', 'Избранные модели');
}
for (const file of walk(dist).filter(file => /\.(html|js|txt)$/.test(file))) {
  const original = read(file), updated = bankTerm(original);
  if (updated !== original) write(file, updated);
}

for (const [language, copy] of Object.entries(locales)) {
  const financeFile = path.join(assets, copy.finance);
  let finance = read(financeFile);
  finance = replace(finance, `s?\`${copy.oldEligibility}\``, `s?(c===\`bank\`?\`${copy.bankEligibility} ${copy.warranty}\`:\`${copy.internalEligibility} ${copy.warranty}\`)`, `${language} finance eligibility`);
  finance = replace(finance, `children:\`${copy.oldCashLabel}\``, `children:\`${copy.cashLabel}\``, `${language} cash price label`);
  const summaryEnd = '(0,i.jsxs)(`strong`,{children:[a(t),` AZN`]})]})]})';
  const summaryRows = `(0,i.jsxs)(\`strong\`,{children:[a(t),\` AZN\`]})]}),c===\`internal\`&&(0,i.jsxs)(\`div\`,{children:[(0,i.jsx)(\`small\`,{children:\`${copy.surchargeLabel}\`}),(0,i.jsxs)(\`strong\`,{children:[a(y.financed-(t-y.downPayment)),\` AZN\`]})]}),c===\`internal\`&&(0,i.jsxs)(\`div\`,{className:\`finance-total\`,children:[(0,i.jsx)(\`small\`,{children:\`${copy.totalLabel}\`}),(0,i.jsxs)(\`strong\`,{children:[a(y.downPayment+y.financed),\` AZN\`]})]})]})`;
  finance = replace(finance, summaryEnd, summaryRows, `${language} finance totals`);
  write(financeFile, finance);

  // Keep all 48 models available to the calculator and mega-menu. Only the
  // displayed homepage selection is capped, with direct routes to full lists.
  const pageFile = path.join(assets, copy.page);
  let page = read(pageFile);
  const selection = `C=(0,s.useMemo)(()=>p===\`${copy.all}\`?a:a.filter(e=>e.type===p),[p])`;
  const selectionNew = `C=(0,s.useMemo)(()=>{const featured=${JSON.stringify(featured)},ordered=[...featured.map(slug=>a.find(model=>model.slug===slug)),...a.filter(model=>!featured.includes(model.slug))].filter(Boolean);return(p===\`${copy.all}\`?ordered:ordered.filter(model=>model.type===p)).slice(0,8)},[p])`;
  page = replace(page, selection, selectionNew, `${language} catalog selection`);
  // The translated snapshot's exact catalog note is read from its component;
  // this preserves compatibility with wording improvements in the importer.
  const notePattern = /\(0,c\.jsxs\)\(`p`,\{className:`catalog-note`,children:\[C\.length,`[^`]+`\]\}\)/;
  assert(notePattern.test(page), `${language} catalog note not found`);
  const links = copy.categories.map(([label, href]) => `(0,c.jsx)(\`a\`,{className:\`button ghost\`,href:\`${href}\`,children:\`${label} →\`})`).join(',');
  page = page.replace(notePattern, `(0,c.jsxs)(\`p\`,{className:\`catalog-note\`,children:[C.length,\`${copy.catalogNote}\`]}),(0,c.jsxs)(\`nav\`,{className:\`catalog-links\`,\"aria-label\":\`${copy.catalogLabel}\`,children:[${links}]})`);
  const homeResult = /\(0,c\.jsxs\)\(`p`,\{children:\[_===`[^`]+`\?`[^`]+`:`[^`]+`,o\(financedWithInterest\),` AZN`\]\}\)/;
  assert(homeResult.test(page), `${language} home result not found`);
  page = page.replace(homeResult, match => `${match},_!==\`${copy.bankMode}\`&&(0,c.jsxs)(\`p\`,{className:\`finance-total\`,children:[\`${copy.totalLabel}: \`,o(M+financedWithInterest),\` AZN\`]})`);
  const homeNote = /\(0,c\.jsx\)\(`small`,\{className:`calc-note`,children:_===`[^`]+`\?`[^`]+`:`[^`]+`\}\)/;
  assert(homeNote.test(page), `${language} home finance note not found`);
  page = page.replace(homeNote, `(0,c.jsx)(\`small\`,{className:\`calc-note\`,children:(_===\`${copy.bankMode}\`?\`${copy.bankNote}\`:\`${copy.oldHomeNote}\`)+(T.type===\`${copy.motorcycle}\`?\` \`+(_===\`${copy.bankMode}\`?\`${copy.bankEligibility}\`:\`${copy.internalEligibility}\`):\`\`)})`);
  write(pageFile, page);

  const { tree, models } = homeModule(assets, copy.page, copy.menu);
  assert(models.length === 48, `${language} full catalog changed`);
  const homeFile = path.join(dist, copy.home);
  let home = read(homeFile);
  assert(/<main>.*?<\/main>/s.test(home), `${language} home main missing`);
  home = home.replace(/<main>.*?<\/main>/s, render(tree));
  // The complete catalog remains in category pages; homepage schema must only
  // describe the models actually displayed in its initial selection.
  home = home.replace(/<script type="application\/ld\+json">(.*?)<\/script>/gs, (match, json) => {
    let schema;
    try { schema = JSON.parse(json); } catch { return match; }
    const visit = node => {
      if (!node || typeof node !== 'object') return;
      if (node['@type'] === 'ItemList' && Array.isArray(node.itemListElement) && node.itemListElement.length === 48) {
        node.itemListElement = featured.map((slug, index) => {
          const item = node.itemListElement.find(item => JSON.stringify(item).includes(`/model/${slug}/`));
          return item ? { ...item, position: index + 1 } : null;
        }).filter(Boolean);
        node.numberOfItems = node.itemListElement.length;
      }
      Object.values(node).forEach(visit);
    };
    visit(schema);
    return `<script type="application/ld+json">${JSON.stringify(schema)}</script>`;
  });
  write(homeFile, home);

  const modelRoot = path.join(dist, language === 'az' ? 'model' : 'ru/model');
  let modelCount = 0;
  for (const slug of fs.readdirSync(modelRoot)) {
    if (slug === '500sr') continue; // This standalone model uses the DOM adapter below.
    const file = path.join(modelRoot, slug, 'index.html');
    let html = read(file);
    const model = models.find(model => model.slug === slug);
    assert(model, `Missing ${language} ${slug} data`);
    const fragment = /<div class="model-calculator">.*?<small class="model-finance-note">.*?<\/small><\/div>/s;
    assert(fragment.test(html), `Missing ${language} ${slug} finance markup`);
    // Instantiate fresh hooks for every model so initial state is independent.
    const component = componentModule(financeFile).default;
    const markup = render(component({ model: model.name, price: model.price, type: model.type, whatsapp: 'https://wa.me/994512332484' }));
    html = html.replace(fragment, markup);
    html = modelHeader(html, language, slug);
    write(file, html);
    modelCount++;
  }
  assert(modelCount === 47, `${language} calculator coverage incomplete`);

  const creditFile = path.join(dist, copy.creditRoute);
  let credit = read(creditFile);
  const internalCreditHeading = language === 'az' ? 'Motosikletlər üçün daxili hissəli ödəniş' : 'Внутренняя рассрочка для мотоциклов';
  const eligibility = `<section class="prose finance-eligibility"><h2>${copy.creditHeading}</h2><h3>${internalCreditHeading}</h3><p>${copy.internalEligibility}</p><h3>${copy.bankHeading}</h3><p>${copy.bankEligibility}</p></section>`;
  credit = replace(credit, '<div class="cta-box">', eligibility + '<div class="cta-box">', `${language} credit eligibility`);
  write(creditFile, credit);
}

// The separately authored 500SR calculator uses data attributes instead of
// React. Add the same total and eligibility information through that adapter.
for (const [language, copy] of Object.entries(locales)) {
  const file = path.join(dist, language === 'az' ? 'model/500sr/index.html' : 'ru/model/500sr/index.html');
  let html = read(file);
  const anchor = /(<p[^>]*data-bank-note[^>]*>.*?<\/p>)/s;
  assert(anchor.test(html), `${language} 500SR bank note missing`);
  const total500sr = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 }).format(13490 * .4 + 13490 * .6 * 1.23);
  html = html.replace(anchor, `$1<p data-eligibility-internal>${copy.internalEligibility}</p><p class="is-hidden" data-eligibility-bank>${copy.bankEligibility}</p><p class="finance-total" data-installment-total-row>${copy.totalLabel}: <strong data-installment-total>${total500sr}</strong> AZN</p>`);
  write(file, html);
}
const standaloneFinance = path.join(assets, '500sr-finance-v1.js');
let standalone = read(standaloneFinance);
standalone = replace(standalone, 'totalDebt.textContent=format.format(debt);', `totalDebt.textContent=format.format(debt);
    root.querySelector('[data-installment-total]').textContent=format.format(paid+debt);
    toggle(root.querySelector('[data-installment-total-row]'),mode==='bank');
    toggle(root.querySelector('[data-eligibility-internal]'),mode==='bank');
    toggle(root.querySelector('[data-eligibility-bank]'),mode!=='bank');`, '500SR totals and eligibility');
write(standaloneFinance, standalone);

// Fingerprint the full top-level module graph so a cached loader cannot mix
// previous finance/home components with new server-rendered markup.
const moduleFiles = fs.readdirSync(assets).filter(name => name.endsWith('.js'));
const revision = createHash('sha256').update(moduleFiles.sort().map(name => name + read(path.join(assets, name))).join('\n')).digest('hex').slice(0, 12);
const names = Object.fromEntries(moduleFiles.map(name => [name, name.replace(/\.js$/, `-sales-${revision}.js`)]));
const rewriteReferences = text => {
  for (const [name, updated] of Object.entries(names)) text = text.replaceAll(name, updated);
  return text;
};
for (const name of moduleFiles) write(path.join(assets, names[name]), rewriteReferences(read(path.join(assets, name))));
// Open tabs from the previous deployment may still request old module URLs.
// Preserve those originals; all new HTML uses the fingerprinted graph above.
for (const [name, content] of Object.entries(originalModules)) write(path.join(assets, name), content);
for (const file of walk(dist).filter(file => /\.(html|txt)$/.test(file))) {
  let content = rewriteReferences(read(file));
  if (file.endsWith('.html')) content = content.replace('</head>', '<link rel="stylesheet" href="/assets/sales-improvements-v1.css"/></head>');
  write(file, content);
}
write(path.join(dist, 'sales-build.json'), JSON.stringify({ revision, featured, bankMaxMonths: 36, price150SC: 5490, locales: Object.fromEntries(Object.entries(locales).map(([language, copy]) => [language, { home: copy.home, page: names[copy.page], menu: names[copy.menu], finance: names[copy.finance] }])) }, null, 2));
console.log(`Sales improvements ready: 8 featured models, 48 calculator options, 96 localized model finance sections; revision ${revision}`);
