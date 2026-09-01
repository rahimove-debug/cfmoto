#!/usr/bin/env ruby
require "fileutils"

ROOT = File.expand_path("..", __dir__)
ACCESSORY_URL = "/aksesuar-konfiquratoru/"
ACCESSORY_CANONICAL = "https://cfmoto.az#{ACCESSORY_URL}"
STYLESHEET = "/assets/accessory-entry-v1.css"
PRESELECT_SCRIPT = "/assets/accessory-model-preselect-v2.js"
HOME_BUNDLE_SOURCE = "/assets/page-CfmotoFinanceFixV12.js"
HOME_BUNDLE_PUBLIC = "/assets/page-CfmotoAccessoryV16.js"
APP_LOADER_SOURCE = "/assets/index-CfmotoPolicyFixV10.js"
APP_LOADER_PUBLIC = "/assets/index-CfmotoAccessoryV16.js"
LAYOUT_SOURCE = "/assets/layout-segment-context-CfmotoPolicyFixV10.js"
LAYOUT_PUBLIC = "/assets/layout-segment-context-CfmotoAccessoryV16.js"
LINK_SOURCE = "/assets/link-CfmotoPolicyFixV10.js"
LINK_PUBLIC = "/assets/link-CfmotoAccessoryV16.js"
ROUTER_SOURCE = "/assets/router-CfmotoPolicyFixV10.js"
ROUTER_PUBLIC = "/assets/router-CfmotoAccessoryV16.js"
MEGA_MENU_SOURCE = "/assets/ProductMegaMenu-CfmotoPolicyFixV10.js"
MEGA_MENU_PUBLIC = "/assets/ProductMegaMenu-CfmotoAccessoryV16.js"

AZ_PROMO_HTML = <<~HTML.strip
  <section class="accessory-promo section" id="aksesuarlar"><div class="accessory-promo-copy"><p class="eyebrow"><span></span> CFMOTO AKSESUAR KONFİQURATORU</p><h2>Motosikletini özünə uyğun qur.</h2><p>Modelini seç, uyğun orijinal aksesuarları müqayisə et, şəxsi paketini hazırla və təklifi birbaşa WhatsApp ilə göndər.</p><a class="button primary" href="#{ACCESSORY_URL}">Konfiquratoru aç <span>↗︎</span></a></div><div class="accessory-promo-steps" aria-label="Konfiqurator addımları"><div><small>01</small><strong>Modeli seç</strong><span>→</span></div><div><small>02</small><strong>Aksesuarları əlavə et</strong><span>→</span></div><div><small>03</small><strong>Paketi göndər</strong><span>↗︎</span></div></div></section>
HTML

AZ_PROMO_JSX = <<~JS.strip
  (0,c.jsxs)(`section`,{className:`accessory-promo section`,id:`aksesuarlar`,children:[(0,c.jsxs)(`div`,{className:`accessory-promo-copy`,children:[(0,c.jsxs)(`p`,{className:`eyebrow`,children:[(0,c.jsx)(`span`,{}),` CFMOTO AKSESUAR KONFİQURATORU`]}),(0,c.jsx)(`h2`,{children:`Motosikletini özünə uyğun qur.`}),(0,c.jsx)(`p`,{children:`Modelini seç, uyğun orijinal aksesuarları müqayisə et, şəxsi paketini hazırla və təklifi birbaşa WhatsApp ilə göndər.`}),(0,c.jsxs)(`a`,{className:`button primary`,href:`#{ACCESSORY_URL}`,children:[`Konfiquratoru aç `,(0,c.jsx)(`span`,{children:`↗︎`})]})]}),(0,c.jsxs)(`div`,{className:`accessory-promo-steps`,"aria-label":`Konfiqurator addımları`,children:[(0,c.jsxs)(`div`,{children:[(0,c.jsx)(`small`,{children:`01`}),(0,c.jsx)(`strong`,{children:`Modeli seç`}),(0,c.jsx)(`span`,{children:`→`})]}),(0,c.jsxs)(`div`,{children:[(0,c.jsx)(`small`,{children:`02`}),(0,c.jsx)(`strong`,{children:`Aksesuarları əlavə et`}),(0,c.jsx)(`span`,{children:`→`})]}),(0,c.jsxs)(`div`,{children:[(0,c.jsx)(`small`,{children:`03`}),(0,c.jsx)(`strong`,{children:`Paketi göndər`}),(0,c.jsx)(`span`,{children:`↗︎`})]})]})]})
JS

def read(path)
  File.read(path, encoding: "UTF-8")
end

def write(path, content)
  File.write(path, content, encoding: "UTF-8")
end

def require_replace!(content, source, replacement, label)
  return content if content.include?(replacement)
  abort "#{label}: anchor not found" unless content.include?(source)
  content.sub(source, replacement)
end

def add_stylesheet!(html)
  tag = %(<link rel="stylesheet" href="#{STYLESHEET}"/>)
  return html if html.include?(tag)
  abort "Accessory stylesheet: closing head not found" unless html.include?("</head>")
  html.sub("</head>", "#{tag}</head>")
end

def add_script!(html, source)
  tag = %(<script defer src="#{source}"></script>)
  return html if html.include?(tag)
  abort "Accessory script: closing body not found" unless html.include?("</body>")
  html.sub("</body>", "#{tag}</body>")
end

def fix_configurator_seo!(html)
  # Query-string configurator states share this static document and canonicalize
  # to the base URL. Alternates on that document therefore create hreflang /
  # canonical conflicts, and there is no equivalent Russian configurator page.
  html.gsub!(
    %r{<link rel="alternate" hrefLang="(?:az-AZ|x-default)" href="#{Regexp.escape(ACCESSORY_CANONICAL)}"/>},
    ""
  )
  html.gsub!(
    %r{,\[\\"\$\\",\\"link\\",\\"\d+\\",\{\\"rel\\":\\"alternate\\",\\"hrefLang\\":\\"(?:az-AZ|x-default)\\",\\"href\\":\\"#{Regexp.escape(ACCESSORY_CANONICAL)}\\"\}\]},
    ""
  )

  # The client-rendered configurator has its own H1. The loading shell exists
  # only before hydration, so giving it an H1 fixes no-JS crawls without
  # leaving two H1 elements in the live application.
  html.gsub!('<h1 id="configurator-seo-title">', '<h2 id="configurator-seo-title">')
  html.gsub!('</h1><p>Konfiquratorda', '</h2><p>Konfiquratorda')
  html.gsub!(
    '[\\"$\\",\\"h1\\",null,{\\"id\\":\\"configurator-seo-title\\"',
    '[\\"$\\",\\"h2\\",null,{\\"id\\":\\"configurator-seo-title\\"'
  )
  loading_shell = '<main class="loading-shell">Konfiqurator hazırlanır…</main>'
  loading_shell_with_h1 = '<main class="loading-shell"><h1>CFMOTO Aksesuar Konfiquratoru</h1><p>Konfiqurator hazırlanır…</p></main>'
  unless html.include?(loading_shell_with_h1)
    abort "Configurator loading shell not found" unless html.include?(loading_shell)
    html.sub!(loading_shell, loading_shell_with_h1)
  end

  abort "Configurator hreflang metadata remains" if html.include?("hrefLang")
  abort "Configurator must expose exactly one visible H1" unless html.scan(/<h1\b/i).size == 1
  abort "Configurator SEO heading must remain H2 after hydration" unless html.include?('<h2 id="configurator-seo-title">')
  html
end

def create_cache_variant!(source_url, public_url, replacements)
  source_path = File.join(ROOT, source_url.delete_prefix("/"))
  public_path = File.join(ROOT, public_url.delete_prefix("/"))
  content = read(source_path)
  replacements.each do |source, replacement|
    abort "#{public_url}: dependency #{source} not found" unless content.include?(source)
    content.gsub!(source, replacement)
  end
  write(public_path, content)
end

home_bundle_source_path = File.join(ROOT, HOME_BUNDLE_SOURCE.delete_prefix("/"))
home_bundle_public_path = File.join(ROOT, HOME_BUNDLE_PUBLIC.delete_prefix("/"))
home_bundle = read(home_bundle_source_path)
home_bundle = require_replace!(
  home_bundle,
  'l=[[`Kredit`,`#kredit-kalkulyator`],[`Servis`,`#servis`],[`Satış mərkəzi`,`#showroom`]]',
  'l=[[`Aksesuarlar`,`/aksesuar-konfiquratoru/`],[`Kredit`,`#kredit-kalkulyator`],[`Servis`,`#servis`],[`Satış mərkəzi`,`#showroom`]]',
  "AZ navigation"
)
unless home_bundle.include?('className:`accessory-promo section`')
  service_anchor = '(0,c.jsxs)(`section`,{className:`service section`,id:`servis`'
  abort "AZ accessory promo: service anchor not found" unless home_bundle.include?(service_anchor)
  home_bundle.sub!(service_anchor, "#{AZ_PROMO_JSX},#{service_anchor}")
end
home_bundle = require_replace!(
  home_bundle,
  '(0,c.jsx)(`a`,{className:`button ghost`,href:`#kredit-kalkulyator`,tabIndex:t?0:-1,children:`Kredit hesabla`})',
  '(0,c.jsx)(`a`,{className:e.key===`moto`?`button accessory-hero-button`:`button ghost`,href:e.key===`moto`?`/aksesuar-konfiquratoru/`:`#kredit-kalkulyator`,tabIndex:t?0:-1,children:e.key===`moto`?`Aksesuar seç →`:`Kredit hesabla`})',
  "AZ accessory hero CTA"
)
home_bundle = require_replace!(
  home_bundle,
  '(0,c.jsx)(`a`,{href:`/ehtiyat-hisseleri/`,children:`Ehtiyat hissələri`})',
  '(0,c.jsx)(`a`,{href:`/aksesuar-konfiquratoru/`,children:`Aksesuarlar`}),(0,c.jsx)(`a`,{href:`/ehtiyat-hisseleri/`,children:`Ehtiyat hissələri`})',
  "AZ footer"
)
[LINK_SOURCE, MEGA_MENU_SOURCE].zip([LINK_PUBLIC, MEGA_MENU_PUBLIC]).each do |source, public_path|
  source_name = File.basename(source)
  public_name = File.basename(public_path)
  abort "AZ cache-busted home dependency #{source_name} not found" unless home_bundle.include?(source_name)
  home_bundle.gsub!(source_name, public_name)
end
write(home_bundle_public_path, home_bundle)

create_cache_variant!(APP_LOADER_SOURCE, APP_LOADER_PUBLIC, {
  File.basename(HOME_BUNDLE_SOURCE) => File.basename(HOME_BUNDLE_PUBLIC),
  File.basename(LAYOUT_SOURCE) => File.basename(LAYOUT_PUBLIC),
  File.basename(LINK_SOURCE) => File.basename(LINK_PUBLIC),
  File.basename(MEGA_MENU_SOURCE) => File.basename(MEGA_MENU_PUBLIC)
})
create_cache_variant!(LAYOUT_SOURCE, LAYOUT_PUBLIC, {
  File.basename(APP_LOADER_SOURCE) => File.basename(APP_LOADER_PUBLIC)
})
create_cache_variant!(LINK_SOURCE, LINK_PUBLIC, {
  File.basename(APP_LOADER_SOURCE) => File.basename(APP_LOADER_PUBLIC),
  File.basename(ROUTER_SOURCE) => File.basename(ROUTER_PUBLIC)
})
create_cache_variant!(ROUTER_SOURCE, ROUTER_PUBLIC, {
  File.basename(APP_LOADER_SOURCE) => File.basename(APP_LOADER_PUBLIC),
  File.basename(LINK_SOURCE) => File.basename(LINK_PUBLIC)
})
create_cache_variant!(MEGA_MENU_SOURCE, MEGA_MENU_PUBLIC, {
  File.basename(LINK_SOURCE) => File.basename(LINK_PUBLIC)
})

home_path = File.join(ROOT, "index.html")
home = add_stylesheet!(read(home_path))
[
  [APP_LOADER_SOURCE, APP_LOADER_PUBLIC],
  [LAYOUT_SOURCE, LAYOUT_PUBLIC],
  [LINK_SOURCE, LINK_PUBLIC],
  [MEGA_MENU_SOURCE, MEGA_MENU_PUBLIC]
].each do |source, public_path|
  next if home.include?(public_path)
  abort "AZ cache-busted dependency #{source}: source URL not found" unless home.include?(source)
  home.gsub!(source, public_path)
end
home = require_replace!(
  home,
  %(<link rel="modulepreload" href="#{HOME_BUNDLE_SOURCE}" crossorigin=""/>),
  %(<link rel="modulepreload" href="#{HOME_BUNDLE_PUBLIC}" crossorigin=""/>),
  "AZ cache-busted home bundle"
)
home = require_replace!(
  home,
  '<a href="#kredit-kalkulyator">Kredit</a>',
  '<a href="/aksesuar-konfiquratoru/">Aksesuarlar</a><a href="#kredit-kalkulyator">Kredit</a>',
  "AZ prerendered navigation"
)
unless home.include?('class="accessory-promo section"')
  service_anchor = '<section class="service section" id="servis">'
  abort "AZ prerendered promo: service anchor not found" unless home.include?(service_anchor)
  home.sub!(service_anchor, "#{AZ_PROMO_HTML}#{service_anchor}")
end
home = require_replace!(
  home,
  '<a class="button ghost" href="#kredit-kalkulyator" tabindex="0">Kredit hesabla</a>',
  '<a class="button accessory-hero-button" href="/aksesuar-konfiquratoru/" tabindex="0">Aksesuar seç →</a>',
  "AZ prerendered accessory hero CTA"
)
home = require_replace!(
  home,
  '<a href="/ehtiyat-hisseleri/">Ehtiyat hissələri</a>',
  '<a href="/aksesuar-konfiquratoru/">Aksesuarlar</a><a href="/ehtiyat-hisseleri/">Ehtiyat hissələri</a>',
  "AZ prerendered footer"
)
write(home_path, home)

ru_bundle_path = Dir.glob(File.join(ROOT, "assets", "page-CfmotoRussianV*.js")).max
abort "Russian home bundle not found" unless ru_bundle_path
ru_bundle = read(ru_bundle_path)
ru_bundle = require_replace!(
  ru_bundle,
  'l=[[`Кредит`,`#kredit-kalkulyator`],[`Сервис`,`#servis`],[`Салон`,`#showroom`]]',
  'l=[[`Аксессуары`,`/aksesuar-konfiquratoru/`],[`Кредит`,`#kredit-kalkulyator`],[`Сервис`,`#servis`],[`Салон`,`#showroom`]]',
  "RU navigation"
)
ru_bundle = require_replace!(
  ru_bundle,
  '(0,c.jsx)(`a`,{href:`/ru/zapchasti/`,children:`Запчасти`})',
  '(0,c.jsx)(`a`,{href:`/aksesuar-konfiquratoru/`,children:`Аксессуары`}),(0,c.jsx)(`a`,{href:`/ru/zapchasti/`,children:`Запчасти`})',
  "RU footer"
)
write(ru_bundle_path, ru_bundle)

ru_home_path = File.join(ROOT, "ru", "index.html")
ru_home = add_stylesheet!(read(ru_home_path))
ru_home = require_replace!(
  ru_home,
  '<a href="#kredit-kalkulyator">Кредит</a>',
  '<a href="/aksesuar-konfiquratoru/">Аксессуары</a><a href="#kredit-kalkulyator">Кредит</a>',
  "RU prerendered navigation"
)
ru_home = require_replace!(
  ru_home,
  '<a href="/ru/zapchasti/">Запчасти</a>',
  '<a href="/aksesuar-konfiquratoru/">Аксессуары</a><a href="/ru/zapchasti/">Запчасти</a>',
  "RU prerendered footer"
)
write(ru_home_path, ru_home)

configurator_path = File.join(ROOT, "aksesuar-konfiquratoru", "index.html")
configurator = fix_configurator_seo!(read(configurator_path))
configurator.gsub!(%r{<script defer src="/assets/accessory-model-preselect-v\d+\.js"></script>}, "")
configurator = add_script!(configurator, PRESELECT_SCRIPT)
write(configurator_path, configurator)

model_pages = Dir.glob(File.join(ROOT, "model", "*", "index.html"))
abort "Expected 48 model pages, found #{model_pages.size}" unless model_pages.size == 48

model_pages.each do |path|
  slug = File.basename(File.dirname(path))
  configurator_url = "#{ACCESSORY_URL}?model=#{slug}&bike=0&lock=1"
  html = add_stylesheet!(read(path))

  # 500SR uses the configurator's query-only model entry until a verified
  # compatible SKU catalogue is published. The standalone model page has no
  # hydrated RSC payload, so only its visible desktop/mobile CTAs are added.
  if slug == "500sr"
    unless html.include?(%(class="button accessory-model-cta" href="#{configurator_url}"))
      visible_anchor = '<a class="button ghost" href="#odenis">Ödənişi hesabla</a></div>'
      visible_cta = %(<a class="button accessory-model-cta" href="#{configurator_url}">Aksesuar paketini qur <span>↗︎</span></a>)
      abort "500sr: visible model CTA anchor not found" unless html.include?(visible_anchor)
      html.sub!(visible_anchor, %(<a class="button ghost" href="#odenis">Ödənişi hesabla</a>#{visible_cta}</div>))
    end
    unless html.include?(%(<a href="#{configurator_url}">Aksesuar seç</a>))
      mobile_anchor = '<div class="model-mobile-cta"><a href="#odenis">Aylıq ödəniş</a>'
      abort "500sr: visible mobile CTA anchor not found" unless html.include?(mobile_anchor)
      html.sub!(mobile_anchor, %(#{mobile_anchor}<a href="#{configurator_url}">Aksesuar seç</a>))
    end
    write(path, html)
    next
  end

  # Migrate links generated by the first configurator integration. Keeping
  # this here makes the script safe to run directly as well as after the
  # cleanup step used by build_cloudflare.rb.
  html.gsub!("#{ACCESSORY_URL}?model=#{slug}#models", configurator_url)

  # Model pages must use the same cache-busted application graph as the
  # homepage. The base loader is served with a one-year immutable cache and
  # changing it in place leaves returning visitors on the previous finance
  # component even when the HTML preloads the new bundle.
  [
    [APP_LOADER_SOURCE, APP_LOADER_PUBLIC],
    [LAYOUT_SOURCE, LAYOUT_PUBLIC],
    [LINK_SOURCE, LINK_PUBLIC],
    [MEGA_MENU_SOURCE, MEGA_MENU_PUBLIC]
  ].each do |source, public_path|
    next if html.include?(public_path)
    abort "#{slug}: cache-busted dependency #{source} not found" unless html.include?(source)
    html.gsub!(source, public_path)
  end

  unless html.include?(%(class="button accessory-model-cta" href="#{configurator_url}"))
    visible_anchor = '<a class="button ghost" href="#odenis">Ödənişi hesabla</a></div>'
    visible_cta = %(<a class="button accessory-model-cta" href="#{configurator_url}">Aksesuar paketini qur <span>↗︎</span></a>)
    abort "#{slug}: visible model CTA anchor not found" unless html.include?(visible_anchor)
    html.sub!(visible_anchor, %(<a class="button ghost" href="#odenis">Ödənişi hesabla</a>#{visible_cta}</div>))

    rsc_anchor = '[\\"$\\",\\"a\\",null,{\\"className\\":\\"button ghost\\",\\"href\\":\\"#odenis\\",\\"children\\":\\"Ödənişi hesabla\\"}]]}]]}'
    rsc_cta = '}],[\\"$\\",\\"a\\",null,{\\"className\\":\\"button accessory-model-cta\\",\\"href\\":\\"' + configurator_url + '\\",\\"children\\":[\\"Aksesuar paketini qur \\", [\\"$\\",\\"span\\",null,{\\"children\\":\\"↗︎\\"}]]}]]}]]}'
    abort "#{slug}: hydrated model CTA anchor not found" unless html.include?(rsc_anchor)
    html.sub!(rsc_anchor, rsc_anchor.sub('}]]}]]}', rsc_cta))
  end

  unless html.include?(%(<div class="model-mobile-cta"><a href="#{configurator_url}">Aksesuar seç</a>))
    mobile_anchor = '<div class="model-mobile-cta"><a href="#odenis">Aylıq ödəniş</a>'
    abort "#{slug}: visible mobile CTA anchor not found" unless html.include?(mobile_anchor)
    html.sub!(mobile_anchor, %(<div class="model-mobile-cta"><a href="#{configurator_url}">Aksesuar seç</a>))

    mobile_rsc_anchor = '\\"className\\":\\"model-mobile-cta\\",\\"children\\":[[\\"$\\",\\"a\\",null,{\\"href\\":\\"#odenis\\",\\"children\\":\\"Aylıq ödəniş\\"}]'
    mobile_rsc_replacement = %!\\"className\\":\\"model-mobile-cta\\",\\"children\\":[[\\"$\\",\\"a\\",null,{\\"href\\":\\"#{configurator_url}\\",\\"children\\":\\"Aksesuar seç\\"}]!
    abort "#{slug}: hydrated mobile CTA anchor not found" unless html.include?(mobile_rsc_anchor)
    html.sub!(mobile_rsc_anchor, mobile_rsc_replacement)
  end

  write(path, html)
end

{
  "kvadrosikl" => {
    model: "cforce-c4",
    label: "ATV aksesuarlarını seç"
  },
  "buggy" => {
    model: "z10",
    label: "Buggy / UTV aksesuarlarını seç"
  }
}.each do |category, entry|
  path = File.join(ROOT, category, "index.html")
  abort "#{category}: category page not found" unless File.file?(path)

  html = read(path)
  url = "#{ACCESSORY_URL}?model=#{entry[:model]}&bike=0#models"
  cta = %(<a class="button primary accessory-category-cta" href="#{url}">#{entry[:label]}</a>)
  unless html.include?(cta)
    anchor = '<div class="cta-actions">'
    abort "#{category}: category CTA anchor not found" unless html.include?(anchor)
    html.sub!(anchor, "#{anchor}#{cta}")
  end
  write(path, html)
end

sitemap_path = File.join(ROOT, "sitemap.xml")
sitemap = read(sitemap_path)
sitemap.gsub!(%r{\s*<url><loc>#{Regexp.escape(ACCESSORY_CANONICAL)}</loc>.*?</url>\n?}, "")
entry = %(  <url><loc>#{ACCESSORY_CANONICAL}</loc></url>\n)
abort "Sitemap closing tag not found" unless sitemap.include?("</urlset>")
sitemap.sub!("</urlset>", "#{entry}</urlset>")
write(sitemap_path, sitemap)

puts "Accessory configurator linked from AZ/RU navigation, sales hero, #{model_pages.size - 1} verified model pages, 1 enquiry-only model page, 2 off-road category pages and AZ homepage promo"
