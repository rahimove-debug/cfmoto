// Render the initial state of the exported React components without changing
// their event handlers. Used by the build and parity audit, never by browsers.
import fs from 'node:fs';
import vm from 'node:vm';

export function componentModule(file, extra = {}, states = []) {
  let stateIndex = 0;
  const hooks = {
    useState: value => [states[stateIndex++] ?? (typeof value === 'function' ? value() : value), () => {}],
    useMemo: fn => fn(), useEffect: () => {},
  };
  const jsx = (type, props) => typeof type === 'function' ? type(props) : { tag: type, props: props || {} };
  const context = {
    e: value => value, t: () => hooks, n: () => ({ jsx, jsxs: jsx }),
    r: props => jsx('a', props), ...extra,
  };
  vm.createContext(context);
  const source = fs.readFileSync(file, 'utf8').replace(/import[^;]+;/g, '').replace(/export\{([^}]+)\};?/, (_, entries) => {
    const pairs = entries.split(',').map(entry => {
      const [name, alias = name] = entry.trim().split(/\s+as\s+/);
      return `${JSON.stringify(alias)}:${name}`;
    });
    return `;exports={${pairs.join(',')}};`;
  });
  vm.runInContext(source, context, { timeout: 3000, filename: file });
  return context.exports;
}

const escapeText = value => String(value).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
const escapeAttribute = value => escapeText(value).replaceAll('"', '&quot;');
const voidTags = new Set(['area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta', 'param', 'source', 'track', 'wbr']);
const booleanAttrs = new Set(['checked', 'disabled', 'hidden', 'multiple', 'selected', 'autoFocus', 'required', 'readOnly']);
const aliases = { className: 'class', htmlFor: 'for', tabIndex: 'tabindex', fetchPriority: 'fetchpriority', dateTime: 'datetime', crossOrigin: 'crossorigin', charSet: 'charset' };

export function render(node, selectedValue) {
  if (node == null || typeof node === 'boolean') return '';
  if (Array.isArray(node)) return children(node, selectedValue);
  if (typeof node !== 'object') return escapeText(node);
  const { tag, props = {} } = node;
  if (tag === 'select') selectedValue = props.value;
  let attrs = '';
  for (let [key, value] of Object.entries(props)) {
    if (key === 'children' || key === 'key' || key === 'ref' || key.startsWith('on') || value == null || (tag === 'select' && key === 'value')) continue;
    if (booleanAttrs.has(key)) { if (value) attrs += ` ${key.toLowerCase()}=""`; continue; }
    if (key === 'style') value = Object.entries(value).map(([k, v]) => `${k.replace(/[A-Z]/g, c => '-' + c.toLowerCase())}:${v}`).join(';');
    attrs += ` ${aliases[key] || key}="${escapeAttribute(value)}"`;
  }
  if (tag === 'option' && props.value === selectedValue) attrs += ' selected=""';
  if (voidTags.has(tag)) return `<${tag}${attrs}/>`;
  return `<${tag}${attrs}>${children([props.children], selectedValue)}</${tag}>`;
}

function children(values, selectedValue) {
  let textBefore = false;
  return values.flat(Infinity).filter(value => value != null && typeof value !== 'boolean').map(value => {
    const isText = typeof value !== 'object';
    const separator = textBefore && isText ? '<!-- -->' : '';
    textBefore = isText;
    return separator + render(value, selectedValue);
  }).join('');
}

export function descendants(node, predicate, found = []) {
  if (!node || typeof node !== 'object') return found;
  if (Array.isArray(node)) { node.forEach(child => descendants(child, predicate, found)); return found; }
  if (predicate(node)) found.push(node);
  descendants(node.props?.children, predicate, found);
  return found;
}

export function homeModule(assets, pageFile, menuFile, states = []) {
  const menu = componentModule(`${assets}/${menuFile}`);
  const page = componentModule(`${assets}/${pageFile}`, { i: menu.default, a: menu.n, o: menu.t }, states);
  return { tree: page.default(), models: menu.n };
}
