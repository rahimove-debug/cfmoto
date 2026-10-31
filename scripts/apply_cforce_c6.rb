#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "fileutils"
require "json"
require "uri"

ROOT = File.expand_path("..", __dir__)
ASSETS = File.join(ROOT, "assets")
SLUG = "cforce-c6-pro"
MODEL_NAME = "CFORCE C6 PRO"
FULL_MODEL_NAME = "CFORCE C6 PRO TOURING"
MODEL_PRICE = 16_900
MODEL_URL = "https://cfmoto.az/model/#{SLUG}/"
RU_MODEL_URL = "https://cfmoto.az/ru/model/#{SLUG}/"
OFFICIAL_URL = "https://cfmoto.ca/en/atv/cforce-c6-pro-touring-2027"
WHATSAPP_TEXT = "Salam. CFORCE C6 PRO modeli üçün 16,900 AZN qiymətlə ön sifariş və aksesuar hədiyyəsi barədə məlumat almaq istəyirəm."
WHATSAPP_URL = "https://wa.me/994512332484?text=#{URI.encode_www_form_component(WHATSAPP_TEXT)}"

def read(path)
  File.read(path, encoding: "UTF-8")
end

def write(path, content)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content, encoding: "UTF-8")
end

def add_c6_static_mega_item!(html)
  html.gsub!(%r{(<span>Kvadrosikl</span><small>)\d+(<!-- --> model</small>)}) { "#{$1}10#{$2}" }
  html.gsub!(%r{(<span>Kvadrosikl</span><small>)\d+( model</small>)}) { "#{$1}10#{$2}" }
  existing = %r{<a href="/model/cforce-c6-pro/" class="mega-model" role="menuitem">.*?</a>}m
  return html if html.match?(existing)

  anchor = %r{<a href="/model/cforce-c5/" class="mega-model" role="menuitem">.*?</a>}m
  return html unless html.match?(anchor)

  item = <<~HTML.delete("\n")
    <a href="/model/cforce-c6-pro/" class="mega-model" role="menuitem"><div><img src="/models/cards/cforce-c6-pro.webp" alt="CFORCE C6 PRO rəsmi foto" loading="lazy" decoding="async" fetchpriority="low"/><em>Ön sifariş</em></div><span>Utility ATV<!-- --> · <!-- -->647 cc</span><h3>CFORCE C6 PRO</h3><p>16,900 AZN<!-- --> <b>↗︎</b></p></a>
  HTML
  html.sub!(anchor) { |match| "#{match}#{item}" }
  html
end

def add_c6_home_card!(home)
  card = <<~HTML.delete("\n")
    <article class="model-card"><a href="/model/cforce-c6-pro/" class="model-visual" aria-label="CFORCE C6 PRO modelinə bax"><img src="/models/cards/cforce-c6-pro.webp" alt="CFORCE C6 PRO rəsmi model fotosu" loading="lazy" decoding="async" fetchpriority="low"/><span class="badge">Ön sifariş</span><span class="model-type">Utility ATV</span></a><div class="model-info"><div><h3>CFORCE C6 PRO</h3><p>Kvadrosikl<!-- --> · <!-- -->647 cc</p></div><div class="model-price"><small>Ön sifariş qiyməti</small><strong>16,900 AZN</strong></div></div><a href="/model/cforce-c6-pro/" class="card-link">Modeli kəşf et <span>↗︎</span></a></article>
  HTML
  existing = %r{<article class="model-card"><a href="/model/cforce-c6-pro/".*?</article>}m
  if home.match?(existing)
    home.sub!(existing, card)
    model_count = home.scan('class="model-card"').size
    home.gsub!(/\d+<!-- --> aktual model/, "#{model_count}<!-- --> aktual model")
    home.gsub!(/\d+ aktual model/, "#{model_count} aktual model")
    return home
  end

  anchor = %r{<article class="model-card"><a href="/model/cforce-c5/".*?</article>}m
  abort "CFORCE C5 homepage card anchor not found" unless home.match?(anchor)
  home.sub!(anchor) { |match| "#{match}#{card}" }
  model_count = home.scan('class="model-card"').size
  home.gsub!(/\d+<!-- --> aktual model/, "#{model_count}<!-- --> aktual model")
  home.gsub!(/\d+ aktual model/, "#{model_count} aktual model")
  home
end

def patch_model_bundle!(javascript, path)
  entry = '{slug:`cforce-c6-pro`,name:`CFORCE C6 PRO`,type:`Kvadrosikl`,segment:`Utility ATV`,engineClass:`647 cc`,price:16900,image:`/models/cforce-c6-pro.webp`,officialPage:`https://cfmoto.ca/en/atv/cforce-c6-pro-touring-2027`,badge:`Ön sifariş`,financeEligible:!1}'
  existing = %r{\{slug:`cforce-c6-pro`,[^{}]+\}}
  if javascript.match?(existing)
    javascript.sub!(existing, entry)
    return javascript
  end

  anchor = javascript[%r{\{slug:`cforce-c5`,[^{}]+\}}]
  abort "#{File.basename(path)}: CFORCE C5 data anchor not found" unless anchor
  javascript.sub!(anchor, "#{anchor},#{entry}")
  javascript
end

def tracking_head(template)
  template[/<head>(.*?)(?=<meta charSet=)/m, 1].to_s
end

def tracking_body(template)
  template[/<body[^>]*>(.*?)(?=<main\b)/m, 1].to_s
end

def custom_page(template)
  prepared = add_c6_static_mega_item!(template.dup)
  header = prepared[%r{<div class="topline">.*?</header>}m]
  footer = prepared[%r{<footer>.*?</footer>}m]
  abort "C6 template header/footer not found" unless header && footer
  header.sub!(%r{(<a class="nav-cta" href=")[^"]+}, "\\1#{WHATSAPP_URL}")

  schema = {
    "@context" => "https://schema.org",
    "@graph" => [
      {
        "@type" => "WebPage",
        "url" => MODEL_URL,
        "name" => "#{FULL_MODEL_NAME} | Ön sifariş | CFMOTO Azerbaijan",
        "description" => "CFORCE C6 PRO TOURING üçün ön sifariş açıqdır. Ön sifariş qiyməti 16,900 AZN, əlavə aksesuar hədiyyə.",
        "inLanguage" => "az"
      },
      {
        "@type" => "BreadcrumbList",
        "itemListElement" => [
          { "@type" => "ListItem", "position" => 1, "name" => "Ana səhifə", "item" => "https://cfmoto.az/" },
          { "@type" => "ListItem", "position" => 2, "name" => "Kvadrosikllər", "item" => "https://cfmoto.az/kvadrosikl/" },
          { "@type" => "ListItem", "position" => 3, "name" => FULL_MODEL_NAME, "item" => MODEL_URL }
        ]
      },
      {
        "@type" => "Product",
        "name" => "CFMOTO #{FULL_MODEL_NAME}",
        "model" => "CFORCE C6 PRO TOURING",
        "sku" => SLUG,
        "brand" => { "@type" => "Brand", "name" => "CFMOTO" },
        "category" => "Kvadrosikl · Utility ATV",
        "image" => [
          "https://cfmoto.az/models/cforce-c6-pro.webp",
          "https://cfmoto.az/gallery/cforce-c6-pro-side.webp",
          "https://cfmoto.az/gallery/cforce-c6-pro-display.webp"
        ],
        "url" => MODEL_URL,
        "description" => "647 cc mühərrikli, iki nəfərlik CFMOTO CFORCE C6 PRO TOURING utility ATV.",
        "offers" => {
          "@type" => "Offer",
          "priceCurrency" => "AZN",
          "price" => MODEL_PRICE.to_s,
          "availability" => "https://schema.org/PreOrder",
          "itemCondition" => "https://schema.org/NewCondition",
          "url" => MODEL_URL,
          "seller" => {
            "@type" => "Organization",
            "name" => "CFMOTO Azerbaijan — SAZMOTO MMC",
            "url" => "https://cfmoto.az/"
          }
        }
      }
    ]
  }

  <<~HTML
    <!DOCTYPE html><html lang="az"><head>#{tracking_head(template)}
    <meta charSet="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1"/>
    <link rel="preload" href="/cfmoto-logo-black.png" as="image"/><link rel="preload" as="image" href="/models/cforce-c6-pro.webp" fetchpriority="high"/>
    <link rel="stylesheet" href="/assets/index-CfmotoPolicyFixV10.css"/><link rel="stylesheet" href="/assets/language.css"/><link rel="stylesheet" href="/assets/cfmoto-typography-v1.css"/><link rel="stylesheet" href="/assets/500sr-model-v1.css"/><link rel="stylesheet" href="/assets/cforce-c6-pro-v1.css"/>
    <link rel="modulepreload" href="/assets/index-CfmotoPolicyFixV10.js" crossorigin=""/>
    <title>CFORCE C6 PRO TOURING | Ön sifariş | CFMOTO Azerbaijan</title>
    <meta name="description" content="CFORCE C6 PRO TOURING üçün ön sifariş açıqdır. Qiymət 16,900 AZN. Ön sifariş verənlərə əlavə aksesuar hədiyyə."/>
    <meta property="og:title" content="CFORCE C6 PRO TOURING | Ön sifariş"/><meta property="og:description" content="16,900 AZN ön sifariş qiyməti və əlavə aksesuar hədiyyəsi. C6 PRO-nun rəsmi fotoları və texniki icmalı."/><meta property="og:url" content="#{MODEL_URL}"/><meta property="og:type" content="website"/><meta property="og:locale" content="az_AZ"/><meta property="og:site_name" content="CFMOTO Azerbaijan"/><meta property="og:image" content="https://cfmoto.az/gallery/cforce-c6-pro-side.webp"/><meta property="og:image:alt" content="CFMOTO CFORCE C6 PRO TOURING"/>
    <meta name="twitter:card" content="summary_large_image"/><meta name="twitter:title" content="CFORCE C6 PRO TOURING | Ön sifariş"/><meta name="twitter:description" content="16,900 AZN ön sifariş qiyməti və əlavə aksesuar hədiyyəsi."/><meta name="twitter:image" content="https://cfmoto.az/gallery/cforce-c6-pro-side.webp"/>
    <link rel="canonical" href="#{MODEL_URL}"/><link rel="alternate" hreflang="az" href="#{MODEL_URL}"/><link rel="alternate" hreflang="ru" href="#{RU_MODEL_URL}"/><link rel="alternate" hreflang="x-default" href="#{MODEL_URL}"/><link rel="icon" href="https://cfmoto.az/favicon.svg"/>
    </head><body class="antialiased">#{tracking_body(template)}<main class="model-page" data-model="cforce-c6-pro"><script type="application/ld+json">#{JSON.generate(schema)}</script>
    #{header}
    <section class="product-hero" id="icmal"><div class="product-copy"><div class="breadcrumb"><a href="/">Ana səhifə</a><span>/</span><a href="/kvadrosikl/">Kvadrosikllər</a><span>/</span><b>CFORCE C6 PRO</b></div><p class="eyebrow dark"><span></span> Kvadrosikl · Utility ATV</p><h1 class="product-title">CFORCE C6 PRO TOURING</h1><p class="product-tagline">Yeni nəsil güc. Ön sifarişlə gəlir.</p><p class="product-summary">İki nəfərlik Touring quruluşu, 647 cc mühərrik və müasir idarəetmə texnologiyaları ilə gündəlik işə və yolsuzluq macərasına hazırdır.</p><div class="product-price"><small>Ön sifariş qiyməti</small><strong>16,900 AZN</strong></div><div class="c6-preorder-note"><strong>Əlavə aksesuar hədiyyə</strong><span>Ön sifariş verənlər üçün. Hədiyyə aksesuarın növü və təqdim edilmə şərtləri satış mütəxəssisi ilə dəqiqləşdirilir.</span></div><div class="hero-actions"><a class="button primary" href="#{WHATSAPP_URL}" target="_blank" rel="noreferrer">Ön sifariş et <span>↗︎</span></a><a class="button ghost" href="#xususiyyetler">Modeli kəşf et</a></div></div><div class="product-image-wrap"><span class="product-badge">ÖN SİFARİŞ</span><img class="model-color-image" src="/models/cforce-c6-pro.webp" alt="CFMOTO CFORCE C6 PRO TOURING — Skyforge Blue" width="1400" height="820" loading="eager" fetchpriority="high"/></div></section>
    <section class="product-specs" aria-label="CFORCE C6 PRO əsas göstəriciləri"><div><span>Mühərrik</span><strong>647 cc</strong></div><div><span>Maksimum güc</span><strong>54 a.g.</strong></div><div><span>Fırlanma anı</span><strong>57 Nm</strong></div><div><span>Ötürmə</span><strong>2WD / 4WD / kilid</strong></div></section>
    <nav class="model-subnav" aria-label="Model səhifəsi bölmələri"><strong>CFORCE C6 PRO</strong><div><a href="#icmal">İcmal</a><a href="#xususiyyetler">Xüsusiyyətlər</a><a href="#texniki">Texniki göstəricilər</a><a href="#qalereya">Qalereya</a></div><a class="model-subnav-cta" href="#{WHATSAPP_URL}" target="_blank" rel="noreferrer">Ön sifariş et ↗︎</a></nav>
    <section class="c6-feature-lead" id="xususiyyetler"><figure><img src="/gallery/cforce-c6-pro-side.webp" alt="CFORCE C6 PRO TOURING Skyforge Blue yan görünüş" loading="lazy" width="1400" height="820"/></figure><div class="c6-feature-lead-copy"><span>2027 yeni nəsil</span><h2>İş üçün güclü, səfər üçün rahat.</h2><p>Elektron ötürmə seçicisi, iki nəfərlik Touring oturacağı və 2WD/4WD idarəetməsi C6 PRO-nu müxtəlif istifadə ssenarilərinə uyğunlaşdırır.</p></div></section>
    <section class="model-overview section"><div class="model-overview-head"><div><p class="eyebrow dark"><span></span> Model haqqında</p><h2>Rahatlıq, nəzarət və güc bir platformada.</h2></div><p>CFORCE C6 PRO TOURING funksional saxlama imkanlarını, güclü utility xarakterini və sürücü ilə sərnişin üçün düşünülmüş erqonomikanı birləşdirir.</p></div><div class="model-feature-grid feature-count-3"><article class="model-feature-card"><div class="model-feature-image"><img src="/gallery/cforce-c6-pro-display.webp" alt="CFORCE C6 PRO 6,2 düymlük MMI ekran" loading="lazy" width="1072" height="1072"/></div><div class="model-feature-copy"><span>01</span><h3>6,2 düymlük MMI ekran</h3><p>Rəsmi regional spesifikasiyada Apple CarPlay və MotoPlay dəstəyi ilə məlumat və bağlantı imkanları təqdim olunur.</p></div></article><article class="model-feature-card"><div class="model-feature-image"><img src="/gallery/cforce-c6-pro-storage.webp" alt="CFORCE C6 PRO saxlama bölməsi və 24 litrlik çən" loading="lazy" width="1072" height="1072"/></div><div class="model-feature-copy"><span>02</span><h3>Praktik saxlama və 24 L çən</h3><p>Gündəlik iş və uzun marşrutlar üçün düşünülmüş saxlama sahəsi utility funksionallığını tamamlayır.</p></div></article><article class="model-feature-card"><div class="model-feature-image"><img src="/gallery/cforce-c6-pro-design.webp" alt="CFORCE C6 PRO Touring dizayn detalları" loading="lazy" width="1072" height="1072"/></div><div class="model-feature-copy"><span>03</span><h3>Touring rahatlığı</h3><p>İki nəfərlik oturacaq, EPS və 320 mm klirens dəyişən relyefdə rahatlıq və nəzarət üçün hazırlanıb.</p></div></article></div></section>
    <section class="model-tech section" id="texniki"><div class="section-head"><div><p class="eyebrow dark"><span></span> Texniki göstəricilər</p><h2>C6 PRO,<br/>bir baxışda.</h2></div><p>Göstəricilər CFMOTO Canada-nın 2027 CFORCE C6 PRO TOURING rəsmi məhsul məlumatına əsaslanır.</p></div><div class="model-static-spec-grid"><article class="model-static-spec-group"><h3>Mühərrik və ötürmə</h3><dl><div><dt>Tip</dt><dd>Təksilindrli, maye soyutmalı DOHC</dd></div><div><dt>İş həcmi</dt><dd>647 cc</dd></div><div><dt>Maksimum güc</dt><dd>54 a.g. / 7.500 dövr/dəq</dd></div><div><dt>Fırlanma anı</dt><dd>57 Nm / 5.000 dövr/dəq</dd></div><div><dt>Ötürmə sistemi</dt><dd>2WD / 4WD / elektron diferensial kilidi</dd></div><div><dt>Ötürmə seçicisi</dt><dd>Elektron</dd></div></dl></article><article class="model-static-spec-group"><h3>Şassi və funksionallıq</h3><dl><div><dt>Oturacaq</dt><dd>2 nəfərlik Touring</dd></div><div><dt>Minimum klirens</dt><dd>320 mm</dd></div><div><dt>Yanacaq çəni</dt><dd>24 L</dd></div><div><dt>Disklər</dt><dd>14 düym alüminium</dd></div><div><dt>Bucurqad</dt><dd>3.500 lb</dd></div><div><dt>Sükan dəstəyi</dt><dd>EPS</dd></div></dl></article><article class="model-static-spec-group"><h3>Texnologiya</h3><dl><div><dt>Ekran</dt><dd>6,2 düymlük MMI</dd></div><div><dt>Telefon bağlantısı</dt><dd>Apple CarPlay / MotoPlay</dd></div><div><dt>Rəsmi rənglər</dt><dd>Skyforge Blue · Granite Ridge · Magma Red</dd></div><div><dt>Model ili</dt><dd>2027</dd></div><div><dt>Kateqoriya</dt><dd>Utility / Touring ATV</dd></div><div><dt>Əyləc sistemi</dt><dd>Hidravlik disk</dd></div></dl></article></div><p class="c6-spec-note">Vacib: yuxarıdakı avadanlıq və texniki göstəricilər Kanada bazarı üçün rəsmi spesifikasiyadan götürülüb. Azərbaycan üçün gətiriləcək komplektasiya, rəng və çatdırılma vaxtı satış mütəxəssisi tərəfindən ayrıca təsdiqlənir.</p><p class="c6-source">Mənbə: <a href="#{OFFICIAL_URL}" target="_blank" rel="noreferrer">CFMOTO Canada — 2027 CFORCE C6 PRO TOURING</a>.</p></section>
    <section class="c6-preorder section"><div><p class="eyebrow"><span></span> Ön sifariş kampaniyası</p><h2>C6 PRO-nu ilk əldə edənlərdən ol.</h2><p>Ön sifariş qiyməti 16,900 AZN-dir. Ön sifariş verənlərə əlavə aksesuar hədiyyə təqdim olunur; hədiyyənin növü və kampaniya şərtləri satış mütəxəssisi ilə dəqiqləşdirilir.</p></div><div class="c6-preorder-card"><small>Ön sifariş qiyməti</small><strong>16,900 AZN</strong><b>Əlavə aksesuar hədiyyə</b><a class="button primary" href="#{WHATSAPP_URL}" target="_blank" rel="noreferrer">WhatsApp-la ön sifariş et <span>↗︎</span></a></div></section>
    <section class="model-gallery-section section" id="qalereya"><div class="section-head"><div><p class="eyebrow"><span></span> Rəsmi fotolar</p><h2>CFORCE C6 PRO<br/>qalereyası.</h2></div><p>CFMOTO-nun rəsmi Skyforge Blue model və texnologiya görüntüləri.</p></div><div class="c6-gallery"><figure><img src="/gallery/cforce-c6-pro-side.webp" alt="CFORCE C6 PRO TOURING Skyforge Blue" loading="lazy" width="1400" height="820"/></figure><figure><img src="/gallery/cforce-c6-pro-display.webp" alt="CFORCE C6 PRO MMI ekranı" loading="lazy" width="1072" height="1072"/></figure><figure><img src="/gallery/cforce-c6-pro-storage.webp" alt="CFORCE C6 PRO saxlama detalları" loading="lazy" width="1072" height="1072"/></figure><figure><img src="/gallery/cforce-c6-pro-design.webp" alt="CFORCE C6 PRO dizayn detalı" loading="lazy" width="1072" height="1072"/></figure></div></section>
    <section class="related section"><div class="section-head"><div><p class="eyebrow dark"><span></span> Digər seçimlər</p><h2>Sənə uyğun CFORCE modelləri.</h2></div><a class="text-link" href="/kvadrosikl/">Bütün kvadrosikllər <span>→</span></a></div><div class="related-grid"><a class="related-card" href="/model/cforce-c5/"><div><img src="/models/cforce-c5.webp" alt="CFORCE C5 rəsmi foto" loading="lazy"/></div><span>Utility ATV</span><h3>CFORCE C5</h3><p>13,900 AZN <b>↗︎</b></p></a><a class="related-card" href="/model/cforce-520-l/"><div><img src="/models/cforce-520-l.webp" alt="CFORCE 520 L rəsmi foto" loading="lazy"/></div><span>Utility ATV</span><h3>CFORCE 520 L</h3><p>12,900 AZN <b>↗︎</b></p></a><a class="related-card" href="/model/cforce625eps-touring/"><div><img src="/models/cforce625eps-touring.webp" alt="CFORCE 625 EPS Touring rəsmi foto" loading="lazy"/></div><span>Touring ATV</span><h3>CFORCE 625 EPS Touring</h3><p>14,500 AZN <b>↗︎</b></p></a></div></section>
    <section class="product-cta section"><div><p class="eyebrow"><span></span> CFMOTO Azerbaijan</p><h2>CFORCE C6 PRO üçün ön sifariş ver.</h2><p>Rəng, Azərbaycan komplektasiyası, çatdırılma vaxtı və hədiyyə aksesuarın şərtlərini satış komandamızla dəqiqləşdirin.</p></div><a class="button primary" href="#{WHATSAPP_URL}" target="_blank" rel="noreferrer">WhatsApp-la əlaqə <span>↗︎</span></a></section>
    #{footer}<div class="model-mobile-cta"><a href="#{WHATSAPP_URL}" target="_blank" rel="noreferrer">Ön sifariş et ↗︎</a></div><a class="whatsapp model-whatsapp" href="#{WHATSAPP_URL}" target="_blank" rel="noreferrer" aria-label="WhatsApp ilə əlaqə">WA</a></main></body></html>
  HTML
end

required_files = %w[
  models/cforce-c6-pro.webp
  models/cards/cforce-c6-pro.webp
  gallery/cforce-c6-pro-side.webp
  gallery/cforce-c6-pro-display.webp
  gallery/cforce-c6-pro-storage.webp
  gallery/cforce-c6-pro-design.webp
  assets/cforce-c6-pro-v1.css
]
missing = required_files.reject { |path| File.file?(File.join(ROOT, path)) }
abort "Missing C6 assets: #{missing.join(', ')}" unless missing.empty?

template_path = File.join(ROOT, "model", "cforce-c5", "index.html")
abort "CFORCE C5 template not found" unless File.file?(template_path)

html_paths = [File.join(ROOT, "index.html"), *Dir.glob(File.join(ROOT, "model", "*", "index.html"))]
html_paths.each do |path|
  html = add_c6_static_mega_item!(read(path))
  html = add_c6_home_card!(html) if path == File.join(ROOT, "index.html")
  write(path, html)
end

write(File.join(ROOT, "model", SLUG, "index.html"), custom_page(read(template_path)))

bundle_paths = Dir.glob(File.join(ASSETS, "ProductMegaMenu-*.js"))
  .reject { |path| File.basename(path).include?("Russian") }
  .select { |path| read(path).include?('slug:`cforce-c5`') }
abort "No Azerbaijani product mega-menu bundle found" if bundle_paths.empty?
bundle_paths.each { |path| write(path, patch_model_bundle!(read(path), path)) }

puts "CFORCE C6 PRO added: preorder page, 16,900 AZN offer, accessory-gift campaign and official imagery"
