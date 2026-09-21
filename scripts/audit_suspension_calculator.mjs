#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(process.argv[2] || path.join(SCRIPT_DIR, '..'));
const ORIGIN = 'https://cfmoto.az';

const ROUTES = [
  {
    language: 'az',
    file: 'asqi-kalkulyatoru/index.html',
    canonical: `${ORIGIN}/asqi-kalkulyatoru/`,
  },
  {
    language: 'ru',
    file: 'ru/kalkulyator-podveski/index.html',
    canonical: `${ORIGIN}/ru/kalkulyator-podveski/`,
  },
];

const ALTERNATES = {
  az: `${ORIGIN}/asqi-kalkulyatoru/`,
  ru: `${ORIGIN}/ru/kalkulyator-podveski/`,
  'x-default': `${ORIGIN}/asqi-kalkulyatoru/`,
};

const MANUALS = {
  '1000mt-x': 'https://cfimages.cfmoto.com/cfmoto/1000_MT_X_CF_900_2_2_A_6_WXV_380101_2002_11_CN_262_20260429_b73ad233af.pdf',
  '800mt-x': 'https://cfimages.cfmoto.com/cfmoto/800_MT_X_CF_800_11_11_A_6_WWV_380101_8000_11_CN_249_20260310_d146c3982b.pdf',
  '800mt': 'https://cfimages.cfmoto.com/cfmoto/CF_800_5_CF_800_5_A_6_WWV_380101_5_A00_11_CN_248_20260310_f9054e92c0.pdf',
  '700mt': 'https://cfimages.cfmoto.com/cfmoto/700_MT_CF_700_9_A_9_B_6_GUV_380101_2000_11_CN_249_20251010_6ddf70826f.pdf',
  '450mt': 'https://cfimages.cfmoto.com/cfmoto/450_MT_CF_400_8_8_A_6_AQV_380101_6000_11_CN_23_A_20260526_526d9d775f.pdf',
};

function fail(message) {
  throw new Error(message);
}

function assert(condition, message) {
  if (!condition) fail(message);
}

function read(relativePath) {
  const absolutePath = path.join(ROOT, relativePath);
  assert(fs.existsSync(absolutePath), `Missing required file: ${relativePath}`);
  return fs.readFileSync(absolutePath, 'utf8');
}

function attributes(tag) {
  return Object.fromEntries(
    [...tag.matchAll(/([:\w-]+)\s*=\s*(["'])(.*?)\2/gs)].map((match) => [match[1].toLowerCase(), match[3]]),
  );
}

function matchingTags(html, tagName, predicate) {
  const tags = html.match(new RegExp(`<${tagName}\\b[^>]*>`, 'gi')) || [];
  return tags.map((tag) => ({ tag, attrs: attributes(tag) })).filter(({ attrs }) => predicate(attrs));
}

function validateRoute(route) {
  const html = read(route.file);
  const pageLabel = route.file;

  assert(
    new RegExp(`<html\\b[^>]*\\blang=["']${route.language}(?:-[^"']+)?["']`, 'i').test(html),
    `${pageLabel}: document language is not ${route.language}`,
  );

  const canonicals = matchingTags(html, 'link', (attrs) => attrs.rel === 'canonical');
  assert(canonicals.length === 1, `${pageLabel}: expected one canonical, found ${canonicals.length}`);
  assert(canonicals[0].attrs.href === route.canonical, `${pageLabel}: incorrect canonical ${canonicals[0].attrs.href || '(missing)'}`);

  const alternates = matchingTags(html, 'link', (attrs) => attrs.rel === 'alternate' && attrs.hreflang);
  assert(alternates.length === 3, `${pageLabel}: expected three hreflang links, found ${alternates.length}`);
  for (const [language, href] of Object.entries(ALTERNATES)) {
    const candidates = alternates.filter(({ attrs }) => attrs.hreflang === language);
    assert(candidates.length === 1, `${pageLabel}: expected one ${language} hreflang, found ${candidates.length}`);
    assert(candidates[0].attrs.href === href, `${pageLabel}: incorrect ${language} hreflang ${candidates[0].attrs.href || '(missing)'}`);
  }

  const roots = html.match(/<div\b[^>]*\bdata-cfmoto-suspension-calculator(?:\s|=|>)[^>]*>/gi) || [];
  assert(roots.length === 1, `${pageLabel}: expected one calculator root, found ${roots.length}`);
  assert(!/data-(?:price|finance|credit|installment|payment)\b/i.test(roots[0]), `${pageLabel}: calculator root is coupled to finance or price data`);

  for (const [model, url] of Object.entries(MANUALS)) {
    const attr = `data-source-${model}="${url}"`;
    const count = html.split(attr).length - 1;
    assert(count === 1, `${pageLabel}: expected one official ${model} manual source, found ${count}`);
  }

  const styles = matchingTags(html, 'link', (attrs) => attrs.rel === 'stylesheet' && /\/assets\/suspension-calculator-v1\.css$/.test(attrs.href || ''));
  assert(styles.length === 1, `${pageLabel}: expected one suspension calculator stylesheet, found ${styles.length}`);
  const stylePath = styles[0].attrs.href.replace(/^\//, '');
  assert(fs.existsSync(path.join(ROOT, stylePath)), `${pageLabel}: referenced stylesheet does not exist: ${styles[0].attrs.href}`);

  const scripts = matchingTags(html, 'script', (attrs) => /\/assets\/suspension-calculator-v1(?:-sales-[a-f0-9]{12})?\.js$/.test(attrs.src || ''));
  assert(scripts.length === 1, `${pageLabel}: expected one suspension calculator script, found ${scripts.length}`);
  assert(/(?:\s|^)defer(?:\s|=|>)/i.test(scripts[0].tag), `${pageLabel}: calculator script must be deferred`);
  const scriptPath = scripts[0].attrs.src.replace(/^\//, '');
  assert(fs.existsSync(path.join(ROOT, scriptPath)), `${pageLabel}: referenced calculator script does not exist: ${scripts[0].attrs.src}`);

  return { html, scriptPath };
}

function loadCalculatorAuditApi(scriptPath) {
  const source = read(scriptPath);
  const financePatterns = [
    /\bAZN\b/i,
    /\bprice\b/i,
    /\bkredit\b/iu,
    /\bcredit\b/i,
    /\binstallments?\b/i,
    /\bdown[-_ ]?payments?\b/i,
    /\bfaiz\b/iu,
    /\bmaliyy/iu,
  ];
  for (const pattern of financePatterns) {
    assert(!pattern.test(source), `${scriptPath}: suspension logic contains forbidden finance/price token ${pattern}`);
  }

  const exposureAnchor = 'window.CFMotoSuspensionCalculator = {';
  assert(source.includes(exposureAnchor), `${scriptPath}: public calculator initializer is missing`);
  const instrumented = source.replace(
    exposureAnchor,
    'window.__CFSC_AUDIT__ = { MODELS: MODELS, LOAD_POINTS: LOAD_POINTS.slice(), interpolate: interpolate, roundSetting: roundSetting, calculate: calculate, calculate450: calculate450 };\n  ' + exposureAnchor,
  );

  const document = {
    readyState: 'loading',
    addEventListener() {},
  };
  const window = {};
  const context = {
    document,
    window,
    Intl,
    Promise,
    WeakMap,
    navigator: {},
    console: { log() {}, warn() {}, error() {} },
  };
  vm.runInNewContext(instrumented, context, { filename: scriptPath, timeout: 1_000 });
  assert(window.__CFSC_AUDIT__, `${scriptPath}: audit instrumentation did not initialize`);
  return window.__CFSC_AUDIT__;
}

function plain(value) {
  return JSON.parse(JSON.stringify(value));
}

function assertEqual(actual, expected, label) {
  const actualJson = JSON.stringify(plain(actual));
  const expectedJson = JSON.stringify(expected);
  assert(actualJson === expectedJson, `${label}: expected ${expectedJson}, received ${actualJson}`);
}

function validateCalculator(api) {
  const expectedModels = ['1000mt-x', '800mt-x', '800mt-sport', '800mt-explore', '700mt', '450mt'];
  assertEqual(Object.keys(api.MODELS).sort(), [...expectedModels].sort(), 'Model coverage');
  assertEqual(api.LOAD_POINTS, [75, 115, 150, 190], 'Official load points');

  const expectedTables = {
    '1000mt-x': {
      road: [
        { fp: 11.5, fc: 10, fr: 10, rp: 12, rc: 10, rr: 10 },
        { fp: 9.5, fc: 10, fr: 10, rp: 10, rc: 8, rr: 7 },
        { fp: 8.5, fc: 7, fr: 7, rp: 8, rc: 6, rr: 5 },
        { fp: 5.5, fc: 5, fr: 5, rp: 6, rc: 4, rr: 3 },
      ],
      rough: { fp: 11.5, fc: 10, fr: 7, rp: 12, rc: 6, rr: 7 },
    },
    '800mt-x': {
      road: [
        { fp: 4, fc: 10, fr: 10, rp: 3, rc: 8, rr: 12 },
        { fp: 4, fc: 10, fr: 10, rp: 5, rc: 10, rr: 15 },
        { fp: 5, fc: 13, fr: 13, rp: 6, rc: 12, rr: 17 },
        { fp: 6, fc: 15, fr: 15, rp: 8, rc: 14, rr: 19 },
      ],
      rough: { fp: 4, fc: 10, fr: 13, rp: 3, rc: 12, rr: 15 },
    },
    '800mt-sport': {
      road: [
        { fp: 4, fc: 10, fr: 10, rp: 3, rc: null, rr: 10 },
        { fp: 4, fc: 10, fr: 10, rp: 5, rc: null, rr: 15 },
        { fp: 5, fc: 13, fr: 13, rp: 6, rc: null, rr: 17 },
        { fp: 6, fc: 15, fr: 15, rp: 7, rc: null, rr: 19 },
      ],
    },
    '800mt-explore': {
      road: [
        { fp: 4, fc: 10, fr: 10, rp: 3, rc: null, rr: 10 },
        { fp: 4, fc: 10, fr: 10, rp: 5, rc: null, rr: 15 },
        { fp: 5, fc: 13, fr: 13, rp: 6, rc: null, rr: 17 },
        { fp: 6, fc: 15, fr: 15, rp: 7, rc: null, rr: 19 },
      ],
    },
    '700mt': {
      road: [
        { fp: null, fc: 10, fr: 10, rp: 6, rc: null, rr: 7 },
        { fp: null, fc: 10, fr: 10, rp: 9, rc: null, rr: 4 },
        { fp: null, fc: 14, fr: 14, rp: 10, rc: null, rr: 3 },
        { fp: null, fc: 16, fr: 16, rp: 12, rc: null, rr: 1 },
      ],
      rough: { fp: null, fc: 8, fr: 8, rp: 6, rc: null, rr: 8 },
    },
  };

  for (const [modelId, table] of Object.entries(expectedTables)) {
    assertEqual(api.MODELS[modelId].road, table.road, `${modelId} official road table`);
    if (table.rough) assertEqual(api.MODELS[modelId].rough, table.rough, `${modelId} official rough-road row`);
    else assert(api.MODELS[modelId].rough === undefined, `${modelId}: unexpected rough-road row`);
  }
  assert(api.MODELS['450mt'].special === true, '450MT special/manual mode is missing');
  assert(api.MODELS['800mt-sport'].sourceKey === '800mt', '800MT SPORT must use the shared official manual');
  assert(api.MODELS['800mt-explore'].sourceKey === '800mt', '800MT EXPLORE must use the shared official manual');

  const exact75 = api.interpolate(api.MODELS['800mt-x'], 75);
  assertEqual(exact75.settings, expectedTables['800mt-x'].road[0], '800MT-X exact 75 kg calculation');
  assert(exact75.detailType === 'exact' && exact75.lower === 75 && exact75.upper === 75, '800MT-X exact 75 kg metadata is incorrect');

  const exact115 = api.interpolate(api.MODELS['800mt-x'], 115);
  assertEqual(exact115.settings, expectedTables['800mt-x'].road[1], '800MT-X exact 115 kg calculation');
  assert(exact115.detailType === 'exact-upper' && exact115.lower === 75 && exact115.upper === 115, '800MT-X exact 115 kg metadata is incorrect');

  const midpoint95 = api.interpolate(api.MODELS['800mt-x'], 95);
  assertEqual(midpoint95.settings, { fp: 4, fc: 10, fr: 10, rp: 4, rc: 9, rr: 14 }, '800MT-X interpolated 95 kg calculation');
  assert(midpoint95.detailType === 'between' && midpoint95.ratio === 0.5, '800MT-X 95 kg interpolation metadata is incorrect');

  const midpoint132 = api.interpolate(api.MODELS['800mt-x'], 132.5);
  assertEqual(midpoint132.settings, { fp: 4.5, fc: 12, fr: 12, rp: 5.5, rc: 11, rr: 16 }, '800MT-X interpolated 132.5 kg calculation');

  const thousandMidpoint = api.interpolate(api.MODELS['1000mt-x'], 95);
  assertEqual(thousandMidpoint.settings, { fp: 10.5, fc: 10, fr: 10, rp: 11, rc: 9, rr: 9 }, '1000MT-X interpolated 95 kg calculation');

  const low = api.interpolate(api.MODELS['700mt'], 40);
  assertEqual(low.settings, expectedTables['700mt'].road[0], '700MT low-load clamp');
  assert(low.detailType === 'low', 'Low-load result is not marked as clamped');

  const high = api.interpolate(api.MODELS['700mt'], 240);
  assertEqual(high.settings, expectedTables['700mt'].road[3], '700MT high-load clamp');
  assert(high.detailType === 'high', 'High-load result is not marked as clamped');

  const rough = api.calculate({
    language: 'az',
    model: '800mt-x',
    mode: 'rough',
    scenario: 'solo',
    weightsKg: { rider: 120, passenger: 0, luggage: 0 },
  });
  assertEqual(rough.settings, expectedTables['800mt-x'].rough, '800MT-X fixed rough-road calculation');
  assert(rough.fixed === true && rough.rough === true && rough.loadKg === null, 'Rough-road row must remain fixed and non-interpolated');

  const mt450Standard = api.calculate450({ language: 'az', model: '450mt', scenario: 'solo', seat: 'standard' });
  assertEqual(mt450Standard.settings, {
    fp: { text: 'visibleSleeve12' },
    fc: null,
    fr: { value: 10, unit: 'click' },
    rp: { text: 'springLength204' },
    rc: null,
    rr: { value: 10, unit: 'click' },
  }, '450MT standard-seat calculation');
  const mt450LoweredLuggage = api.calculate450({ language: 'az', model: '450mt', scenario: 'luggage', seat: 'lowered' });
  assertEqual(mt450LoweredLuggage.settings.rp, { text: 'plus6Turns' }, '450MT lowered-seat luggage calculation');

  assert(api.roundSetting(10.5, 'click') === 11, 'Click values must round half up to a whole click');
  assert(api.roundSetting(4.25, 'turn') === 4.5, 'Turn values must round half up to a half turn');
  assert(api.roundSetting(9.24, 'mm') === 9, 'Millimetre values must round to a half-millimetre step');
}

function validateHeaders() {
  const headers = read('_headers');
  const required = ['/asqi-kalkulyatoru*', '/ru/kalkulyator-podveski*'];
  for (const route of required) {
    const escaped = route.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const match = headers.match(new RegExp(`(?:^|\\n)${escaped}\\r?\\n((?:[ \\t]+[^\\r\\n]+(?:\\r?\\n|$))+)`));
    assert(match, `_headers: missing explicit cache block for ${route}`);
    assert(/^[ \t]+Cache-Control:\s*public,\s*max-age=0,\s*must-revalidate\s*$/mi.test(match[1]), `_headers: ${route} must use revalidated HTML caching`);
  }
}

const auditedRoutes = ROUTES.map(validateRoute);
assert(
  auditedRoutes[0].scriptPath === auditedRoutes[1].scriptPath,
  `Localized routes reference different calculator scripts: ${auditedRoutes.map(({ scriptPath }) => scriptPath).join(', ')}`,
);
validateCalculator(loadCalculatorAuditApi(auditedRoutes[0].scriptPath));
validateHeaders();

console.log(`Suspension calculator audit passed for ${ROOT}: ${ROUTES.length} routes, 6 models, ${Object.keys(MANUALS).length} official manuals`);
