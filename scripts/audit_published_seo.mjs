// Audit the final deployment, not the imported snapshot. No network requests.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const dist = path.resolve(process.argv[2] || path.join(root, 'dist'));
const origin = 'https://cfmoto.az';
const read = file => fs.readFileSync(file, 'utf8');
const walk = directory => fs.readdirSync(directory, { withFileTypes: true }).flatMap(item =>
  item.isDirectory() ? walk(path.join(directory, item.name)) : path.join(directory, item.name));
const attributes = tag => Object.fromEntries([...tag.matchAll(/([\w:-]+)\s*=\s*["']([^"']*)["']/g)]
  .map(([, key, value]) => [key.toLowerCase(), value.replaceAll('&amp;', '&')]));
const tags = (html, name) => [...html.matchAll(new RegExp(`<${name}\\b[^>]*>`, 'gi'))].map(match => attributes(match[0]));
const publicFiles = walk(dist);
const htmlFiles = publicFiles.filter(file => file.endsWith('/index.html'));
const pages = new Map();
const schemas = [];
const localFile = url => {
  const pathname = decodeURIComponent(new URL(url, origin).pathname);
  const file = path.join(dist, pathname);
  assert(file.startsWith(dist + path.sep) || file === dist, `Path escapes published root: ${url}`);
  return pathname.endsWith('/') ? path.join(file, 'index.html') : file;
};

for (const file of htmlFiles) {
  const relative = path.relative(dist, file);
  const expected = origin + '/' + relative.replace(/index\.html$/, '');
  const html = read(file);
  const links = tags(html, 'link');
  const canonical = links.filter(link => link.rel === 'canonical').map(link => link.href);
  assert.deepEqual(canonical, [expected], `${relative}: exactly one self canonical`);
  assert(/<title>[^<]+<\/title>/.test(html), `${relative}: title missing`);
  assert.equal((html.match(/<h1\b/gi) || []).length, 1, `${relative}: one primary heading`);
  for (const meta of tags(html, 'meta')) {
    if (/^(robots|googlebot)$/i.test(meta.name || '')) {
      assert(!/\b(noindex|none)\b/i.test(meta.content || ''), `${relative}: indexing blocked`);
    }
  }
  for (const alternate of links.filter(link => link.rel === 'alternate' && link.hreflang)) {
    assert(alternate.href.startsWith(origin + '/'), `${relative}: wrong alternate origin`);
    assert(fs.existsSync(localFile(alternate.href)), `${relative}: missing alternate ${alternate.href}`);
  }
  // Module URLs are rewritten in the final sales step. Catch missing imports
  // and local CSS/JS/model routes introduced by any subsequent transformation.
  for (const element of [...links, ...tags(html, 'script'), ...tags(html, 'a')]) {
    const url = element.src || element.href;
    if (!url || !url.startsWith('/') || url.startsWith('//')) continue;
    const pathname = new URL(url, origin).pathname;
    if (/\.(js|css)$/.test(pathname) || /^(\/ru)?\/model\//.test(pathname)) {
      assert(fs.existsSync(localFile(url)), `${relative}: broken local dependency ${url}`);
    }
  }
  for (const match of html.matchAll(/<script\b[^>]*type=["']application\/ld\+json["'][^>]*>(.*?)<\/script>/gs)) {
    schemas.push([relative, JSON.parse(match[1])]);
  }
  pages.set(expected, { relative, links });
}

const sitemap = read(path.join(dist, 'sitemap.xml'));
const listed = [...sitemap.matchAll(/<loc>(.*?)<\/loc>/g)].map(match => match[1]);
assert.equal(new Set(listed).size, listed.length, 'Duplicate sitemap URLs');
assert.deepEqual([...listed].sort(), [...pages.keys()].sort(), 'Sitemap must list every final canonical page exactly once');
for (const [url, page] of pages) {
  for (const alternate of page.links.filter(link => link.rel === 'alternate' && link.hreflang !== 'x-default' && link.hreflang)) {
    const target = pages.get(alternate.href);
    assert(target?.links.some(link => link.rel === 'alternate' && link.href === url), `${page.relative}: non-reciprocal language link`);
  }
}
const robots = read(path.join(dist, 'robots.txt'));
assert(!/^Disallow:\s*\/\s*$/m.test(robots), 'robots.txt blocks the entire site');
assert(robots.includes(`Sitemap: ${origin}/sitemap.xml`), 'robots.txt sitemap missing');
assert(!/X-Robots-Tag:\s*.*\b(noindex|none)\b/i.test(read(path.join(dist, '_headers'))), 'Published headers block indexing');

let products = 0;
function inspectSchema(value, relative) {
  if (!value || typeof value !== 'object') return;
  if (value['@type'] === 'Product') {
    products++;
    const offer = value.offers;
    assert(offer?.['@type'] === 'Offer', `${relative}: Product offer missing`);
    assert.equal(offer.priceCurrency, 'AZN', `${relative}: Product currency`);
    assert(/^\d{4}-\d{2}-\d{2}$/.test(offer.validFrom || ''), `${relative}: offer start date missing`);
    assert(Number.isFinite(Date.parse(offer.validFrom)) && offer.validFrom <= offer.priceValidUntil, `${relative}: invalid offer dates`);
    assert(pages.has(offer.url), `${relative}: offer destination is not canonical`);
  }
  Object.values(value).forEach(child => inspectSchema(child, relative));
}
schemas.forEach(([relative, schema]) => inspectSchema(schema, relative));
assert(products >= 96, 'Missing localized Product schemas');

const redirects = new Map(read(path.join(dist, '_redirects')).split('\n')
  .filter(line => line.trim() && !line.startsWith('#')).map(line => {
    const [source, destination, status] = line.trim().split(/\s+/);
    assert.equal(status, '301', `Legacy redirect must be permanent: ${source}`);
    const target = new URL(destination, origin);
    assert(pages.has(target.origin + target.pathname), `Redirect target missing: ${source} -> ${destination}`);
    return [source, destination];
  }));
// Independent fixture from the GSC email, not derived from the generator map.
const oldCredit = encodeURI('/qi\u0307ymət-hi\u0307ssəvi\u0307-ödəni\u0307ş');
for (const source of [oldCredit, oldCredit + '/', encodeURI('/qiymət-hissəvi-ödəniş'), encodeURI('/qiymət-hissəvi-ödəniş/')]) {
  assert.equal(redirects.get(source), '/kredit/', `Missing traffic-bearing credit redirect: ${source}`);
}
for (const locale of ['', '/ru']) {
  const categoryPaths = locale ? ['/ru/motocikly/', '/ru/kvadrocikly/', '/ru/buggy/'] : ['/motosiklet/', '/kvadrosikl/', '/buggy/'];
  const linked = new Set(categoryPaths.flatMap(category => tags(read(localFile(category)), 'a')
    .map(link => link.href).filter(href => href?.startsWith(`${locale}/model/`))));
  assert.equal(linked.size, 48, `${locale || 'az'}: every model must have a full-category link`);
  for (const href of linked) assert(pages.has(origin + href), `Category model route is not canonical: ${href}`);
}
console.log(`Published SEO audit passed: ${pages.size} final canonical pages, reciprocal languages, sitemap, assets, ${products} Product offers, ${redirects.size} redirects and full AZ/RU category coverage.`);
