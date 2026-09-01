#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "fileutils"
require "json"

ROOT = File.expand_path("..", __dir__)
ASSETS = File.join(ROOT, "assets")
SLUG = "500sr"
MODEL_NAME = "500SR"
MODEL_PRICE = 13_490
MODEL_URL = "https://cfmoto.az/model/500sr/"
RU_MODEL_URL = "https://cfmoto.az/ru/model/500sr/"
OFFICIAL_URL = "https://www.cfmoto.com/global/motorcycles/sportracing/500sr.html"
WHATSAPP_URL = "https://wa.me/994512332484?text=Salam%2C%20CFMOTO%20500SR%20modeli%20haqq%C4%B1nda%20m%C9%99lumat%20v%C9%99%20sat%C4%B1%C5%9F%20t%C9%99klifi%20almaq%20ist%C9%99yir%C9%99m."

def read(path)
  File.read(path, encoding: "UTF-8")
end

def write(path, content)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content, encoding: "UTF-8")
end

def add_500sr_mega_item!(html)
  html.gsub!("29<!-- --> model", "30<!-- --> model")
  html.gsub!("29 model", "30 model")
  existing = %r{<a href="/model/500sr/" class="mega-model" role="menuitem">.*?</a>}m
  if html.match?(existing)
    html.sub!(existing) { |item| item.sub(/<p>.*?<!-- --> <b>/m, '<p>13,490 AZN<!-- --> <b>') }
    return html
  end

  anchor = %r{<a href="/model/500sr-voom/" class="mega-model" role="menuitem">.*?</a>}m
  abort "500SR VOOM mega-menu anchor not found" unless html.match?(anchor)
  item = <<~HTML.delete("\n")
    <a href="/model/500sr/" class="mega-model" role="menuitem"><div><img src="/models/cards/500sr.webp" alt="500SR rəsmi foto" loading="lazy" decoding="async" fetchpriority="low"/><em>Yeni</em></div><span>Sport Racing<!-- --> · <!-- -->500 cc</span><h3>500SR</h3><p>13,490 AZN<!-- --> <b>↗︎</b></p></a>
  HTML
  html.sub!(anchor) { |match| "#{item}#{match}" }
  html
end

def add_500sr_home_card!(home)
  home.gsub!("47<!-- --> aktual model", "48<!-- --> aktual model")
  home.gsub!("47 aktual model", "48 aktual model")
  existing = %r{<article class="model-card"><a href="/model/500sr/" class="model-visual".*?</article>}m
  if home.match?(existing)
    home.sub!(existing) { |card| card.sub(%r{<div class="model-price">.*?</div>}m, '<div class="model-price"><small>Qiymət</small><strong>13,490 AZN</strong></div>') }
    return home
  end

  anchor = %r{<article class="model-card"><a href="/model/500sr-voom/" class="model-visual".*?</article>}m
  abort "500SR VOOM homepage card anchor not found" unless home.match?(anchor)
  card = <<~HTML.delete("\n")
    <article class="model-card"><a href="/model/500sr/" class="model-visual" aria-label="500SR modelinə bax"><img src="/models/cards/500sr.webp" alt="500SR rəsmi model fotosu" loading="lazy" decoding="async" fetchpriority="low"/><span class="badge">Yeni</span><span class="model-type">Sport Racing</span></a><div class="model-info"><div><h3>500SR</h3><p>Motosiklet<!-- --> · <!-- -->500 cc</p></div><div class="model-price"><small>Qiymət</small><strong>13,490 AZN</strong></div></div><a href="/model/500sr/" class="card-link">Modeli kəşf et <span>↗︎</span></a></article>
  HTML
  home.sub!(anchor) { |match| "#{card}#{match}" }
  home
end

def patch_model_bundle!(javascript, path)
  existing = %r{\{slug:`500sr`,[^{}]+\}}
  if javascript.match?(existing)
    javascript.sub!(existing) { |entry| entry.sub('price:null', 'price:13490') }
    return javascript
  end

  anchor = javascript[%r{\{slug:`500sr-voom`,[^{}]+\}}]
  abort "#{File.basename(path)}: 500SR VOOM data anchor not found" unless anchor
  entry = '{slug:`500sr`,name:`500SR`,type:`Motosiklet`,segment:`Sport Racing`,engineClass:`500 cc`,price:13490,image:`/models/500sr.webp`,officialPage:`https://www.cfmoto.com/global/motorcycles/sportracing/500sr.html`,badge:`Yeni`}'
  javascript.sub!(anchor, "#{entry},#{anchor}")
  javascript
end

def tracking_head(template)
  template[/<head>(.*?)(?=<meta charSet=)/m, 1].to_s
end

def tracking_body(template)
  template[/<body[^>]*>(.*?)(?=<main\b)/m, 1].to_s
end

def custom_page(template)
  prepared = add_500sr_mega_item!(template.dup)
  header = prepared[%r{<div class="topline">.*?</header>}m]
  footer = prepared[%r{<footer>.*?</footer>}m]
  abort "500SR template header/footer not found" unless header && footer
  header.sub!(%r{(<a class="nav-cta" href=")[^"]+}, "\\1#{WHATSAPP_URL}")

  schema = {
    "@context" => "https://schema.org",
    "@graph" => [
      {
        "@type" => "WebPage",
        "url" => MODEL_URL,
        "name" => "500SR | CFMOTO Azerbaijan",
        "description" => "Yeni CFMOTO 500SR: 500 cc sıralı dörd silindr, 58 kW güc, 49 Nm fırlanma anı, 187 kq çəki və müasir yarış texnologiyaları.",
        "inLanguage" => "az"
      },
      {
        "@type" => "BreadcrumbList",
        "itemListElement" => [
          { "@type" => "ListItem", "position" => 1, "name" => "Ana səhifə", "item" => "https://cfmoto.az/" },
          { "@type" => "ListItem", "position" => 2, "name" => "Motosikletlər", "item" => "https://cfmoto.az/motosiklet/" },
          { "@type" => "ListItem", "position" => 3, "name" => MODEL_NAME, "item" => MODEL_URL }
        ]
      },
      {
        "@type" => "Product",
        "name" => "CFMOTO 500SR",
        "model" => "500SR",
        "sku" => "500sr",
        "brand" => { "@type" => "Brand", "name" => "CFMOTO" },
        "category" => "Motosiklet · Sport Racing",
        "image" => [
          "https://cfmoto.az/models/500sr.webp",
          "https://cfmoto.az/gallery/500sr-1.webp",
          "https://cfmoto.az/gallery/500sr-2.webp"
        ],
        "url" => MODEL_URL,
        "description" => "500 cc maye soyutmalı DOHC sıralı dörd silindrli CFMOTO sport motosikleti.",
        "offers" => {
          "@type" => "Offer",
          "priceCurrency" => "AZN",
          "price" => MODEL_PRICE.to_s,
          "availability" => "https://schema.org/InStock",
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
    <link rel="preload" href="/cfmoto-logo-black.png" as="image"/><link rel="preload" as="image" href="/models/500sr.webp" fetchpriority="high"/>
    <link rel="stylesheet" href="/assets/index-CfmotoPolicyFixV10.css"/><link rel="stylesheet" href="/assets/language.css"/><link rel="stylesheet" href="/assets/cfmoto-typography-v1.css"/><link rel="stylesheet" href="/assets/500sr-model-v1.css"/>
    <link rel="modulepreload" href="/assets/index-CfmotoPolicyFixV10.js" crossorigin=""/>
    <title>500SR | CFMOTO Azerbaijan</title>
    <meta name="description" content="Yeni CFMOTO 500SR — 13,490 AZN. 500 cc sıralı dörd silindr, 58 kW güc, 49 Nm fırlanma anı və kredit kalkulyatoru."/>
    <meta property="og:title" content="500SR | CFMOTO Azerbaijan"/><meta property="og:description" content="500SR — sıralı dörd silindrin saf yarış xarakteri. Rəsmi foto, texniki göstəricilər və satış məlumatı."/><meta property="og:url" content="#{MODEL_URL}"/><meta property="og:type" content="website"/><meta property="og:locale" content="az_AZ"/><meta property="og:site_name" content="CFMOTO Azerbaijan"/><meta property="og:image" content="https://cfmoto.az/gallery/500sr-banner.webp"/><meta property="og:image:alt" content="Yeni CFMOTO 500SR"/>
    <meta name="twitter:card" content="summary_large_image"/><meta name="twitter:title" content="500SR | CFMOTO Azerbaijan"/><meta name="twitter:description" content="500 cc sıralı dörd silindr, 58 kW güc və 49 Nm fırlanma anı."/><meta name="twitter:image" content="https://cfmoto.az/gallery/500sr-banner.webp"/>
    <link rel="canonical" href="#{MODEL_URL}"/><link rel="alternate" hreflang="az" href="#{MODEL_URL}"/><link rel="alternate" hreflang="ru" href="#{RU_MODEL_URL}"/><link rel="alternate" hreflang="x-default" href="#{MODEL_URL}"/><link rel="icon" href="https://cfmoto.az/favicon.svg"/>
    <script defer src="/assets/500sr-finance-v1.js"></script>
    </head><body class="antialiased">#{tracking_body(template)}<main class="model-page" data-model="500sr"><script type="application/ld+json">#{JSON.generate(schema)}</script>
    #{header}
    <section class="product-hero" id="icmal"><div class="product-copy"><div class="breadcrumb"><a href="/">Ana səhifə</a><span>/</span><a href="/motosiklet/">Motosikletlər</a><span>/</span><b>500SR</b></div><p class="eyebrow dark"><span></span> Motosiklet · Sport Racing</p><h1 class="product-title">500SR</h1><p class="product-tagline">Sıralı dörd silindrin saf yarış xarakteri.</p><p class="product-summary">500SR aerodinamik SR dizaynını, yüksək dövrlü dörd silindrli mühərriki və dəqiq şassi idarəetməsini bir araya gətirir.</p><div class="product-price"><small>Nağd satış qiyməti</small><strong>13,490 AZN</strong></div><div class="hero-actions"><a class="button primary" href="#{WHATSAPP_URL}" target="_blank" rel="noreferrer">Satış təklifi al <span>↗︎</span></a><a class="button ghost" href="#odenis">Ödənişi hesabla</a></div></div><div class="product-image-wrap"><span class="product-badge">Yeni</span><img class="model-color-image" src="/models/500sr.webp" alt="Yeni CFMOTO 500SR rəsmi model fotosu" width="882" height="588"/></div></section>
    <section class="product-specs" aria-label="500SR əsas göstəriciləri"><div><span>Mühərrik</span><strong>500 cc</strong></div><div><span>Maksimum güc</span><strong>58 kW</strong></div><div><span>Fırlanma anı</span><strong>49 Nm</strong></div><div><span>Hazır çəki</span><strong>187 kq</strong></div></section>
    <nav class="model-subnav" aria-label="Model səhifəsi bölmələri"><strong>500SR</strong><div><a href="#icmal">İcmal</a><a href="#xususiyyetler">Xüsusiyyətlər</a><a href="#texniki">Texniki göstəricilər</a><a href="#odenis">Kredit</a><a href="#qalereya">Qalereya</a></div><a class="model-subnav-cta" href="#odenis">Kredit hesabla ↘</a></nav>
    <section class="model-500sr-banner" id="xususiyyetler"><div class="model-500sr-banner-copy"><span>Racing Core</span><h2>Dəqiqlik instinktə çevrilir.</h2><p>Yüksək dövrlərdə davamlı güc, döngələrdə balans və SR ailəsinin tanınan aerodinamik silueti.</p></div></section>
    <section class="model-overview section"><div class="model-overview-head"><div><p class="eyebrow dark"><span></span> Model haqqında</p><h2>Şəhərdən trekə qədər dörd silindrli performans.</h2></div><p>CFMOTO-nun 500 cc sıralı dörd silindrli platforması aşağı dövrlərdə hamar idarəetmə, yüksək dövrlərdə isə güclü və xətti sürətlənmə təqdim edir.</p></div><div class="model-feature-grid feature-count-3"><article class="model-feature-card"><div class="model-feature-image"><img src="/gallery/500sr-1.webp" alt="500SR yolda dinamik sürüş" loading="lazy" width="1280" height="853"/></div><div class="model-feature-copy"><span>01</span><h3>58 kW dörd silindrli güc</h3><p>500 cc DOHC mühərrik 12.500 dövr/dəqiqədə 58 kW, 10.000 dövr/dəqiqədə 49 Nm hasil edir.</p></div></article><article class="model-feature-card"><div class="model-feature-image"><img src="/gallery/500sr-2.webp" alt="500SR yanacaq çəni və sürücü zonası" loading="lazy" width="1280" height="853"/></div><div class="model-feature-copy"><span>02</span><h3>Yüngül və balanslı şassi</h3><p>187 kq hazır çəki, xrom-molibden polad çərçivə və tənzimlənən asqı dəqiq reaksiyaya kömək edir.</p></div></article><article class="model-feature-card"><div class="model-feature-image"><img src="/gallery/500sr-3.webp" alt="500SR arxa işıq və iki çıxışlı egzoz" loading="lazy" width="1280" height="853"/></div><div class="model-feature-copy"><span>03</span><h3>Yarış texnologiyaları</h3><p>Bir istiqamətli quickshifter, iki rejimli TCS, söndürülə bilən arxa ABS və 24 pilləli sükan damperi sürücüyə nəzarət verir.</p></div></article></div></section>
    <section class="model-tech section" id="texniki"><div class="section-head"><div><p class="eyebrow dark"><span></span> Texniki göstəricilər</p><h2>500SR,<br/>bir baxışda.</h2></div><p>Göstəricilər CFMOTO-nun rəsmi 500SR məhsul səhifəsi əsasında hazırlanıb. Bazar və komplektasiyaya görə fərqlər mümkündür.</p></div><div class="model-static-spec-grid"><article class="model-static-spec-group"><h3>Mühərrik</h3><dl><div><dt>Tip</dt><dd>Maye soyutmalı DOHC sıralı 4 silindr</dd></div><div><dt>İş həcmi</dt><dd>500 cc</dd></div><div><dt>Maksimum güc</dt><dd>58 kW / 12.500 dövr/dəq</dd></div><div><dt>Maksimum fırlanma anı</dt><dd>49 Nm / 10.000 dövr/dəq</dd></div><div><dt>Sıxılma dərəcəsi</dt><dd>12,3:1</dd></div><div><dt>Transmissiya</dt><dd>6 pillə, sürüşən mufta</dd></div></dl></article><article class="model-static-spec-group"><h3>Ölçülər və çəki</h3><dl><div><dt>Uzunluq × en × hündürlük</dt><dd>2010 × 720 × 1185 mm</dd></div><div><dt>Təkər bazası</dt><dd>1395 mm</dd></div><div><dt>Oturacaq hündürlüyü</dt><dd>805 mm</dd></div><div><dt>Minimum klirens</dt><dd>140 mm</dd></div><div><dt>Hazır çəki</dt><dd>187 kq</dd></div><div><dt>Yanacaq çəni</dt><dd>15,5 L</dd></div></dl></article><article class="model-static-spec-group"><h3>Şassi və texnologiya</h3><dl><div><dt>Ön asqı</dt><dd>41 mm USD, tam tənzimlənən</dd></div><div><dt>Ön əyləc</dt><dd>300 mm iki disk, NISSIN 4 porşen</dd></div><div><dt>Arxa əyləc</dt><dd>220 mm disk</dd></div><div><dt>ABS / TCS</dt><dd>Standart / 2 rejim, söndürülə bilən</dd></div><div><dt>Ekran</dt><dd>6,2 düym TFT, MotoPlay</dd></div><div><dt>Təkərlər</dt><dd>120/70 ZR17 · 160/60 ZR17</dd></div></dl></article></div><p class="model-500sr-note">Rənglər, komplektasiya və çatdırılma vaxtı satış komandası tərəfindən ayrıca təsdiqlənir.</p><p class="model-500sr-source">Mənbə: CFMOTO Global 500SR rəsmi məhsul səhifəsi.</p></section>
    <section class="model-finance section" id="odenis"><div class="section-head"><div><p class="eyebrow dark"><span></span> Ödəniş imkanları</p><h2>Kredit<br/>kalkulyatoru.</h2></div><p>13,490 AZN satış qiymətinə əsasən daxili hissəli ödənişi və ya bank krediti üzrə təxmini aylıq ödənişi hesablayın.</p></div><div class="model-500sr-finance" data-500sr-finance data-price="13490"><div class="model-500sr-finance-tabs"><button type="button" class="is-active" data-finance-mode="internal" aria-pressed="true">Daxili hissəli ödəniş</button><button type="button" data-finance-mode="bank" aria-pressed="false">Bank krediti</button></div><div class="model-500sr-finance-body"><div class="model-500sr-finance-controls"><label class="model-500sr-range"><span>İlkin ödəniş</span><strong><span data-down-percent>40</span>% · <span data-down-amount>5,396</span> AZN</strong><input data-down type="range" min="40" max="80" step="5" value="40"/></label><div class="model-500sr-terms" data-internal-terms><span>Müddət</span><div><button type="button" data-term="6">6<!-- --> ay</button><button type="button" data-term="12">12<!-- --> ay</button><button type="button" class="is-active" data-term="18">18<!-- --> ay</button></div></div><label class="model-500sr-range is-hidden" data-bank-term-wrap><span>Müddət</span><strong><span data-bank-term-value>35</span><!-- --> ay</strong><input data-bank-term type="range" min="3" max="35" step="1" value="35"/></label></div><div class="model-500sr-finance-result"><small>Aylıq ödəniş</small><strong><span data-monthly>553</span> <em>AZN / ay</em></strong><div><small data-debt-label>Faiz daxil borc</small><b><span data-total-debt>9,956</span> AZN</b></div></div></div><p data-internal-policy>Daxili ödəniş: 40%-dən başlayan ilkin ödəniş</p><p data-internal-note>Daxili ödəniş faizləri: 6 ay 8%, 12 ay 15%, 18 ay 23%. Yekun şərtlər satış mütəxəssisi tərəfindən təsdiqlənir.</p><p class="is-hidden" data-bank-note>Bank faizi və komissiyası daxil deyil. Yekun aylıq ödəniş bank tərəfindən hesablanır.</p><a class="button primary" href="#{WHATSAPP_URL}" target="_blank" rel="noreferrer">Fərdi təklif al <span>↗︎</span></a></div></section>
    <section class="model-gallery-section section" id="qalereya"><div class="section-head"><div><p class="eyebrow"><span></span> Rəsmi fotolar</p><h2>500SR<br/>qalereyası.</h2></div><p>Yeni 500SR-nin aerodinamik quruluşu, sürücü zonası və tanınan iki çıxışlı egzoz dizaynı.</p></div><div class="model-500sr-gallery"><figure><img src="/gallery/500sr-1.webp" alt="CFMOTO 500SR yolda" loading="lazy" width="1280" height="853"/></figure><figure><img src="/gallery/500sr-2.webp" alt="CFMOTO 500SR yanacaq çəni" loading="lazy" width="1280" height="853"/></figure><figure><img src="/gallery/500sr-3.webp" alt="CFMOTO 500SR arxa görünüş" loading="lazy" width="1280" height="853"/></figure></div></section>
    <section class="related section"><div class="section-head"><div><p class="eyebrow dark"><span></span> Digər seçimlər</p><h2>Sənə uyğun SR modelləri.</h2></div><a class="text-link" href="/motosiklet/">Bütün motosikletlər <span>→</span></a></div><div class="related-grid"><a class="related-card" href="/model/500sr-voom/"><div><img src="/models/500sr-voom.webp" alt="500SR VOOM rəsmi foto" loading="lazy"/></div><span>Sport Racing</span><h3>500SR VOOM</h3><p>13,490 AZN <b>↗︎</b></p></a><a class="related-card" href="/model/675sr-r/"><div><img src="/models/675sr-r.webp" alt="675SR-R rəsmi foto" loading="lazy"/></div><span>Sport Racing</span><h3>675SR-R</h3><p>15,490 AZN <b>↗︎</b></p></a><a class="related-card" href="/model/450sr-s/"><div><img src="/models/450sr-s.webp" alt="450SR-S rəsmi foto" loading="lazy"/></div><span>Sport Racing</span><h3>450SR-S</h3><p>11,490 AZN <b>↗︎</b></p></a></div></section>
    <section class="product-cta section"><div><p class="eyebrow"><span></span> CFMOTO Azerbaijan</p><h2>500SR üçün fərdi təklif al.</h2><p>Satış, rəng, komplektasiya, çatdırılma və ödəniş imkanlarını satış komandamızla dəqiqləşdirin.</p></div><a class="button primary" href="#{WHATSAPP_URL}" target="_blank" rel="noreferrer">WhatsApp-la əlaqə <span>↗︎</span></a></section>
    #{footer}<div class="model-mobile-cta"><a href="#odenis">Aylıq ödəniş</a></div><a class="whatsapp model-whatsapp" href="#{WHATSAPP_URL}" target="_blank" rel="noreferrer" aria-label="WhatsApp ilə əlaqə">WA</a></main></body></html>
  HTML
end

required_images = %w[
  models/500sr.webp
  models/cards/500sr.webp
  gallery/500sr-banner.webp
  gallery/500sr-1.webp
  gallery/500sr-2.webp
  gallery/500sr-3.webp
]
missing = required_images.reject { |path| File.file?(File.join(ROOT, path)) }
abort "Missing 500SR images: #{missing.join(', ')}" unless missing.empty?

template_path = File.join(ROOT, "model", "500sr-voom", "index.html")
abort "500SR VOOM template not found" unless File.file?(template_path)

html_paths = [File.join(ROOT, "index.html"), *Dir.glob(File.join(ROOT, "model", "*", "index.html"))]
html_paths.each do |path|
  html = add_500sr_mega_item!(read(path))
  html = add_500sr_home_card!(html) if path == File.join(ROOT, "index.html")
  write(path, html)
end

target = File.join(ROOT, "model", SLUG, "index.html")
write(target, custom_page(read(template_path)))

bundle_paths = Dir.glob(File.join(ASSETS, "ProductMegaMenu-*.js"))
  .reject { |path| File.basename(path).include?("Russian") }
  .select { |path| read(path).include?('slug:`500sr-voom`') }
abort "No Azerbaijani product mega-menu bundle found" if bundle_paths.empty?
bundle_paths.each { |path| write(path, patch_model_bundle!(read(path), path)) }

puts "500SR model added: standalone AZ page, official imagery, homepage card and product-menu data"
