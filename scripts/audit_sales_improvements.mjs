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
  assert.equal(options.length, 48, `${locale} full calculator catalog`);
  assert.equal(options.filter(option => option.props.value === '500SR').length, 1);
  assert.equal(models.find(model => model.slug === '150sc').price, 5490, 'User-confirmed 150SC price');
  const fullLinks = descendants(tree, node => hasClass(node, 'catalog-links'))[0];
  assert.equal(descendants(fullLinks, node => node.tag === 'a').length, 3);

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
    assert.equal(descendants(bank, node => hasClass(node, 'finance-total')).length, 0, 'Do not imply unknown bank total');
    assert(descendants(bank, node => node.tag === 'button').some(button => text(button) === (locale === 'az' ? '36 ay' : '36 мес.')), `${locale} 36-month bank option`);
    if (example.slug !== 'z10') {
      const note = text(descendants(bank, node => hasClass(node, 'model-finance-note'))[0]);
      assert(note.includes(locale === 'az' ? 'tələb olunmur' : 'не требуется'), `${locale} no A-license condition for bank`);
      assert(!note.includes(locale === 'az' ? 'gəlirin göstərilməsi tələb olunur' : 'подтверждение дохода за последние'), 'No internal requirements on bank tab');
    }
  }

  // Every React calculator must match its model, not just the selected examples.
  for (const model of models.filter(model => model.slug !== '500sr')) {
    const finance = componentModule(path.join(assets, files.finance)).default({ model: model.name, price: model.price, type: model.type, whatsapp: 'https://wa.me/994512332484' });
    const file = path.join(dist, locale === 'az' ? 'model' : 'ru/model', model.slug, 'index.html');
    assert(read(file).includes(render(finance)), `${locale} ${model.slug} finance HTML/client parity`);
  }
  const credit = read(path.join(dist, locale === 'az' ? 'kredit/index.html' : 'ru/kredit/index.html'));
  assert(credit.includes(locale === 'az' ? '36 ayadək' : '36 месяцев'));
  assert(credit.includes('finance-eligibility'));
  assert(!html.includes(locale === 'az' ? '35 ayadək' : '35 месяцев'));
}

const service = read(path.join(dist, 'servis/index.html'));
assert(service.includes("contact_area:declaredArea||(serviceContact?'service':'sales')"), 'Declared service area is respected');
const css = read(path.join(assets, 'sales-improvements-v1.css'));
assert(css.includes('.product-copy .hero-actions .button.primary'));
assert(css.includes('.product-copy .hero-actions .accessory-model-cta'));
assert.equal(manifest.bankMaxMonths, 36);
console.log('Sales audit passed: AZ/RU homepage parity, 48 calculator options, 94 React calculator initial states, internal totals, 36-month bank rules and service attribution');
