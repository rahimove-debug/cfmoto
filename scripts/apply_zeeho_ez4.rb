#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "fileutils"
require "json"

ROOT = File.expand_path("..", __dir__)
ASSETS = File.join(ROOT, "assets")
SLUG = "zeeho-ez4"
MODEL_NAME = "ZEEHO EZ4"
MODEL_PRICE = 2_890
MODEL_URL = "https://cfmoto.az/model/#{SLUG}/"
RU_MODEL_URL = "https://cfmoto.az/ru/model/#{SLUG}/"
OFFICIAL_URL = "https://www.zeehoev.com/global/products/ez/ez4.html"
WHATSAPP_URL = "https://wa.me/994512332484?text=#{CGI.escape('Salam, ZEEHO EZ4 elektrik skuteri haqqında məlumat və satış təklifi almaq istəyirəm.')}"
IMAGE_CACHE_VERSION = "20261027-2"
EZ4_PUBLIC_IMAGES = %w[
  /models/zeeho-ez4.webp
  /models/cards/zeeho-ez4.webp
  /gallery/zeeho-ez4-ergonomics.webp
  /gallery/zeeho-ez4-practicality.webp
  /gallery/zeeho-ez4-storage.webp
].freeze

def read(path)
  File.read(path, encoding: "UTF-8")
end

def write(path, content)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content, encoding: "UTF-8")
end

def version_ez4_images!(content)
  content = content.dup
  EZ4_PUBLIC_IMAGES.each do |source|
    content.gsub!(%r{#{Regexp.escape(source)}(?:\?v=[A-Za-z0-9._-]+)?}, "#{source}?v=#{IMAGE_CACHE_VERSION}")
  end
  content
end

def add_ez4_mega_item!(html)
  html.gsub!("30<!-- --> model", "31<!-- --> model")
  html.gsub!("30 model", "31 model")
  existing = %r{<a href="/model/zeeho-ez4/" class="mega-model" role="menuitem">.*?</a>}m
  if html.match?(existing)
    html.sub!(existing) do |item|
      item.sub(%r{<p>.*?<!-- --> <b>}m, '<p>2,890 AZN<!-- --> <b>')
    end
    return version_ez4_images!(html)
  end

  anchor = %r{<a href="/model/aura-150/" class="mega-model" role="menuitem">.*?</a>}m
  abort "AURA 150 mega-menu anchor not found" unless html.match?(anchor)
  item = <<~HTML.delete("\n")
    <a href="/model/zeeho-ez4/" class="mega-model" role="menuitem"><div><img src="/models/cards/zeeho-ez4.webp" alt="ZEEHO EZ4 rəsmi foto" loading="lazy" decoding="async" fetchpriority="low"/><em>Yeni</em></div><span>Scooter<!-- --> · <!-- -->Elektrik</span><h3>ZEEHO EZ4</h3><p>2,890 AZN<!-- --> <b>↗︎</b></p></a>
  HTML
  html.sub!(anchor) { |match| "#{match}#{item}" }
  version_ez4_images!(html)
end

def add_ez4_home_card!(home)
  home.gsub!("48<!-- --> aktual model", "49<!-- --> aktual model")
  home.gsub!("48 aktual model", "49 aktual model")
  existing = %r{<article class="model-card"><a href="/model/zeeho-ez4/" class="model-visual".*?</article>}m
  if home.match?(existing)
    home.sub!(existing) do |card|
      card.sub(%r{<div class="model-price">.*?</div>}m, '<div class="model-price"><small>Qiymət</small><strong>2,890 AZN</strong></div>')
    end
    return version_ez4_images!(home)
  end

  anchor = %r{<article class="model-card"><a href="/model/aura-150/" class="model-visual".*?</article>}m
  abort "AURA 150 homepage card anchor not found" unless home.match?(anchor)
  card = <<~HTML.delete("\n")
    <article class="model-card"><a href="/model/zeeho-ez4/" class="model-visual" aria-label="ZEEHO EZ4 modelinə bax"><img src="/models/cards/zeeho-ez4.webp" alt="ZEEHO EZ4 rəsmi model fotosu" loading="lazy" decoding="async" fetchpriority="low"/><span class="badge">Yeni</span><span class="model-type">Scooter</span></a><div class="model-info"><div><h3>ZEEHO EZ4</h3><p>Motosiklet<!-- --> · <!-- -->Elektrik</p></div><div class="model-price"><small>Qiymət</small><strong>2,890 AZN</strong></div></div><a href="/model/zeeho-ez4/" class="card-link">Modeli kəşf et <span>↗︎</span></a></article>
  HTML
  home.sub!(anchor) { |match| "#{match}#{card}" }
  version_ez4_images!(home)
end

def patch_model_bundle!(javascript, path)
  existing = %r{\{slug:`zeeho-ez4`,[^{}]+\}}
  if javascript.match?(existing)
    javascript.sub!(existing) do |entry|
      entry.sub(/price:\d+/, "price:2890")
        .sub(/image:`[^`]+`/, "image:`/models/zeeho-ez4.webp?v=#{IMAGE_CACHE_VERSION}`")
        .sub(/financeEligible:(?:true|false)/, "financeEligible:true")
    end
    return version_ez4_images!(javascript)
  end

  anchor = javascript[%r{\{slug:`aura-150`,[^{}]+\}}]
  abort "#{File.basename(path)}: AURA 150 data anchor not found" unless anchor
  entry = '{slug:`zeeho-ez4`,name:`ZEEHO EZ4`,type:`Motosiklet`,segment:`Scooter`,engineClass:`Elektrik`,price:2890,image:`/models/zeeho-ez4.webp`,officialPage:`https://www.zeehoev.com/global/products/ez/ez4.html`,badge:`Yeni`,financeEligible:true}'
  javascript.sub!(anchor, "#{anchor},#{entry}")
  version_ez4_images!(javascript)
end

def exclude_ez4_from_home_finance!(javascript, path)
  source = 'w=(0,s.useMemo)(()=>a.filter(e=>e.price!==null),[])'
  replacement = 'w=(0,s.useMemo)(()=>a.filter(e=>e.price!==null&&e.financeEligible!==false),[])'
  return javascript if javascript.include?(replacement)
  abort "#{File.basename(path)}: homepage finance-model anchor not found" unless javascript.include?(source)
  javascript.sub(source, replacement)
end

def tracking_head(template)
  template[/<head>(.*?)(?=<meta charSet=)/m, 1].to_s
end

def tracking_body(template)
  template[/<body[^>]*>(.*?)(?=<main\b)/m, 1].to_s
end

def custom_page(template)
  prepared = add_ez4_mega_item!(template.dup)
  header = prepared[%r{<div class="topline">.*?</header>}m]
  footer = prepared[%r{<footer>.*?</footer>}m]
  abort "EZ4 template header/footer not found" unless header && footer
  header.sub!(%r{(<a class="nav-cta" href=")[^"]+}, "\\1#{WHATSAPP_URL}")

  schema = {
    "@context" => "https://schema.org",
    "@graph" => [
      {
        "@type" => "WebPage",
        "url" => MODEL_URL,
        "name" => "ZEEHO EZ4 elektrik skuter | CFMOTO Azerbaijan",
        "description" => "ZEEHO EZ4 elektrik skuter — 2 890 AZN. 1,3 kW nominal, 2,4 kW pik güc, 53 km/saatadək sürət və 63 km-dən başlayan yürüş ehtiyatı.",
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
        "name" => "ZEEHO EZ4",
        "model" => "EZ4",
        "sku" => "ZH1300DT-3",
        "brand" => { "@type" => "Brand", "name" => "ZEEHO" },
        "category" => "Elektrik skuter",
        "image" => [
          "https://cfmoto.az/models/zeeho-ez4.webp",
          "https://cfmoto.az/gallery/zeeho-ez4-ergonomics.webp",
          "https://cfmoto.az/gallery/zeeho-ez4-practicality.webp"
        ],
        "url" => MODEL_URL,
        "description" => "Gündəlik şəhər hərəkəti üçün 72 V 23 Ah batareyalı ZEEHO EZ4 elektrik skuter.",
        "offers" => {
          "@type" => "Offer",
          "priceCurrency" => "AZN",
          "price" => MODEL_PRICE.to_s,
          "validFrom" => "2026-10-27",
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

  html = <<~HTML
    <!DOCTYPE html><html lang="az"><head>#{tracking_head(template)}
    <meta charSet="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1"/>
    <link rel="preload" href="/cfmoto-logo-black.png" as="image"/><link rel="preload" as="image" href="/models/zeeho-ez4.webp" fetchpriority="high"/>
    <link rel="stylesheet" href="/assets/index-CfmotoPolicyFixV10.css"/><link rel="stylesheet" href="/assets/language.css"/><link rel="stylesheet" href="/assets/cfmoto-typography-v1.css"/><link rel="stylesheet" href="/assets/500sr-model-v1.css"/><link rel="stylesheet" href="/assets/zeeho-ez4-model-v1.css?v=#{IMAGE_CACHE_VERSION}"/><link rel="stylesheet" href="/assets/accessory-entry-v1.css"/>
    <link rel="modulepreload" href="/assets/index-CfmotoPolicyFixV10.js" crossorigin=""/>
    <title>ZEEHO EZ4 Elektrik Skuter | Qiymət 2 890 AZN</title>
    <meta name="description" content="ZEEHO EZ4 elektrik skuter — 2 890 AZN. 1,3 kW nominal, 2,4 kW pik güc, 53 km/saatadək sürət, 72 V 23 Ah batareya və 63 km-dən başlayan yürüş ehtiyatı."/>
    <meta property="og:title" content="ZEEHO EZ4 Elektrik Skuter | CFMOTO Azerbaijan"/><meta property="og:description" content="Şəhər üçün çevik ZEEHO EZ4: rəsmi fotolar, texniki göstəricilər və 2 890 AZN satış qiyməti."/><meta property="og:url" content="#{MODEL_URL}"/><meta property="og:type" content="website"/><meta property="og:locale" content="az_AZ"/><meta property="og:site_name" content="CFMOTO Azerbaijan"/><meta property="og:image" content="https://cfmoto.az/gallery/zeeho-ez4-ergonomics.webp"/><meta property="og:image:alt" content="ZEEHO EZ4 elektrik skuter"/>
    <meta name="twitter:card" content="summary_large_image"/><meta name="twitter:title" content="ZEEHO EZ4 Elektrik Skuter | CFMOTO Azerbaijan"/><meta name="twitter:description" content="ZEEHO EZ4 — 2 890 AZN. Elektrik şəhər skuteri."/><meta name="twitter:image" content="https://cfmoto.az/gallery/zeeho-ez4-ergonomics.webp"/>
    <link rel="canonical" href="#{MODEL_URL}"/><link rel="alternate" hreflang="az" href="#{MODEL_URL}"/><link rel="alternate" hreflang="ru" href="#{RU_MODEL_URL}"/><link rel="alternate" hreflang="x-default" href="#{MODEL_URL}"/><link rel="icon" href="https://cfmoto.az/favicon.svg"/>
    </head><body class="antialiased">#{tracking_body(template)}<main class="model-page" data-model="zeeho-ez4"><script type="application/ld+json">#{JSON.generate(schema)}</script>
    #{header}
    <section class="product-hero" id="icmal"><div class="product-copy"><div class="breadcrumb"><a href="/">Ana səhifə</a><span>/</span><a href="/motosiklet/">Motosikletlər</a><span>/</span><b>ZEEHO EZ4</b></div><p class="eyebrow dark"><span></span> Elektrik · Scooter</p><h1 class="product-title">ZEEHO EZ4</h1><p class="product-tagline">Şəhərin ritmi artıq elektriklidir.</p><p class="product-summary">Yığcam ölçülər, səssiz elektrik ötürməsi və gündəlik istifadə üçün düşünülmüş ağıllı funksiyalar.</p><div class="product-price"><small>Nağd satış qiyməti</small><strong>2,890 AZN</strong></div><div class="hero-actions"><a class="button primary" href="#{WHATSAPP_URL}" target="_blank" rel="noreferrer">Satış təklifi al <span>↗︎</span></a><a class="button ghost" href="#odenis">Ödənişi hesabla</a><a class="button accessory-model-cta" href="/aksesuar-konfiquratoru/?model=zeeho-ez4&amp;bike=0&amp;lock=1">Aksesuar uyğunluğunu soruş <span>↗︎</span></a></div></div><div class="product-image-wrap"><span class="product-badge">Yeni</span><span class="zeeho-mark">ZEEHO</span><img class="model-color-image" src="/models/zeeho-ez4.webp" alt="ZEEHO EZ4 elektrik skuter — Velocity Gray" width="960" height="640" loading="eager" fetchpriority="high"/></div></section>
    <section class="product-specs" aria-label="ZEEHO EZ4 əsas göstəriciləri"><div><span>Nominal güc</span><strong>1,3 kW</strong></div><div><span>Pik güc</span><strong>2,4 kW</strong></div><div><span>Maksimal sürət</span><strong>≥ 53 km/saat</strong></div><div><span>Yürüş ehtiyatı</span><strong>≥ 63 km</strong></div></section>
    <nav class="model-subnav" aria-label="Model səhifəsi bölmələri"><strong>ZEEHO EZ4</strong><div><a href="#icmal">İcmal</a><a href="#xususiyyetler">Xüsusiyyətlər</a><a href="#texniki">Texniki göstəricilər</a><a href="#qalereya">Qalereya</a></div><a class="model-subnav-cta" href="#{WHATSAPP_URL}" target="_blank" rel="noreferrer">Təklif al ↗︎</a></nav>
    <section class="zeeho-ez4-banner" id="xususiyyetler"><div class="zeeho-ez4-banner-copy"><span>Pure Electric</span><h2>Gündəlik azadlıq üçün yaradılıb.</h2><p>EZ4 şəhər hərəkətində rahat oturuşu, sadə enerji idarəetməsini və ZEEHO RIDE bağlantısını bir araya gətirir.</p></div></section>
    <section class="model-overview section"><div class="model-overview-head"><div><p class="eyebrow dark"><span></span> Model haqqında</p><h2>Yığcam, ağıllı və tam elektrik.</h2></div><p>120 kq hazır çəki, 755 mm oturacaq hündürlüyü və 30 litrlik oturacaqaltı saxlama bölməsi gündəlik şəhər marşrutlarında praktik istifadə təqdim edir.</p></div><div class="model-feature-grid feature-count-3"><article class="model-feature-card"><div class="model-feature-image"><img src="/models/cards/zeeho-ez4.webp" alt="ZEEHO EZ4 elektrik skuter, üçdörddəbir görünüş" loading="lazy" width="680" height="510"/></div><div class="model-feature-copy"><span>01</span><h3>Elektrik şəhər çevikliyi</h3><p>2,4 kW pik güclü arxa göbək mühərriki və 53 km/saatadək sürət gündəlik hərəkət üçün nəzərdə tutulub.</p></div></article><article class="model-feature-card"><div class="model-feature-image"><img src="/gallery/zeeho-ez4-storage.webp" alt="ZEEHO EZ4 30 litrlik saxlama bölməsi" loading="lazy" width="512" height="272"/></div><div class="model-feature-copy"><span>02</span><h3>30 litrlik saxlama bölməsi</h3><p>Oturacaqaltı bölmə dəbilqə və gündəlik əşyalar üçün praktik yer təqdim edir.</p></div></article><article class="model-feature-card"><div class="model-feature-image"><img src="/gallery/zeeho-ez4-practicality.webp" alt="ZEEHO EZ4 ayaq platforması və praktik quruluş" loading="lazy" width="1036" height="520"/></div><div class="model-feature-copy"><span>03</span><h3>Gündəlik praktik detallar</h3><p>410 × 390 mm ayaq platforması və 18 W USB-A + USB-C çıxışları rahatlığı artırır.</p></div></article></div></section>
    <section class="model-tech section" id="texniki"><div class="section-head"><div><p class="eyebrow dark"><span></span> Texniki göstəricilər</p><h2>EZ4,<br/>bir baxışda.</h2></div><p>Göstəricilər ZEEHO-nun rəsmi EZ4 məhsul səhifəsi və broşürü əsasında hazırlanıb. Bazar və komplektasiyaya görə fərqlər mümkündür.</p></div><div class="ez4-static-spec-grid"><article class="ez4-static-spec-group"><h3>Elektrik sistemi</h3><dl><div><dt>Mühərrik</dt><dd>Arxa göbək mühərriki</dd></div><div><dt>Nominal / pik güc</dt><dd>1,3 / 2,4 kW</dd></div><div><dt>Batareya</dt><dd>72 V · 23 Ah, qurğuşun-turşu</dd></div><div><dt>Yürüş ehtiyatı</dt><dd>≥ 63 km</dd></div><div><dt>Maksimal sürət</dt><dd>≥ 53 km/saat</dd></div><div><dt>0–40 km/saat</dt><dd>≤ 9 saniyə</dd></div></dl></article><article class="ez4-static-spec-group"><h3>Ölçülər və çəki</h3><dl><div><dt>Uzunluq × en × hündürlük</dt><dd>1850 × 760 × 1120 mm</dd></div><div><dt>Təkər bazası</dt><dd>1335 mm</dd></div><div><dt>Oturacaq hündürlüyü</dt><dd>755 mm</dd></div><div><dt>Minimum klirens</dt><dd>125 mm</dd></div><div><dt>Hazır çəki</dt><dd>120 kq</dd></div><div><dt>Dırmanma qabiliyyəti</dt><dd>10°</dd></div></dl></article><article class="ez4-static-spec-group"><h3>Şassi və texnologiya</h3><dl><div><dt>Ön asqı</dt><dd>Hidravlik teleskopik</dd></div><div><dt>Arxa asqı</dt><dd>İki yaylı, 5 səviyyəli tənzim</dd></div><div><dt>Əyləclər</dt><dd>Ø220 mm ön · Ø180 mm arxa disk</dd></div><div><dt>Təkərlər</dt><dd>80/90-12 ön · 3.0-10 arxa</dd></div><div><dt>Ekran</dt><dd>6,2 düym LCD</dd></div><div><dt>Elektronika</dt><dd>E-TCS · ZEEHO RIDE · OTA</dd></div></dl></article></div><p class="ez4-model-note">Rəng, komplektasiya və mövcudluq satış komandası tərəfindən ayrıca təsdiqlənir. Standart EZ4 üçün ABS və ya CBS istehsalçı spesifikasiyasında göstərilmir.</p><p class="ez4-model-source">Mənbə: <a href="#{OFFICIAL_URL}" target="_blank" rel="noreferrer">ZEEHO Global EZ4 rəsmi məhsul səhifəsi</a>.</p></section>
    <section class="model-finance section" id="odenis"><div class="section-head"><div><p class="eyebrow dark"><span></span> Ödəniş imkanları</p><h2>Kredit<br/>kalkulyatoru.</h2></div><p>2,890 AZN satış qiymətinə əsasən daxili hissəli ödənişi və ya bank krediti üzrə təxmini aylıq ödənişi hesablayın.</p></div><div class="model-500sr-finance" data-ez4-finance data-price="2890" data-bank-debt-label="Faiz daxil qalıq borc · bank komissiyası daxil deyil" data-internal-total-label="Ümumi ödəniş · ilkin ödəniş daxil" data-bank-total-label="Təxmini ümumi ödəniş · ilkin ödəniş daxil"><div class="model-500sr-finance-tabs"><button type="button" class="is-active" data-finance-mode="internal" aria-pressed="true">Daxili hissəli ödəniş</button><button type="button" data-finance-mode="bank" aria-pressed="false">Bank krediti</button></div><div class="model-500sr-finance-body"><div class="model-500sr-finance-controls"><label class="model-500sr-range"><span>İlkin ödəniş</span><strong><span data-down-percent>40</span>% · <span data-down-amount>1,156</span> AZN</strong><input data-down type="range" min="40" max="80" step="5" value="40"/></label><div class="model-500sr-terms" data-internal-terms><span>Müddət</span><div><button type="button" data-term="6">6<!-- --> ay</button><button type="button" data-term="12">12<!-- --> ay</button><button type="button" class="is-active" data-term="18">18<!-- --> ay</button></div></div><label class="model-500sr-range is-hidden" data-bank-term-wrap><span>Müddət</span><strong><span data-bank-term-value>36</span><!-- --> ay</strong><input data-bank-term type="range" min="3" max="36" step="1" value="36"/></label></div><div class="model-500sr-finance-result"><small>Aylıq ödəniş</small><strong><span data-monthly>118</span> <em>AZN / ay</em></strong><div><small data-debt-label>Faiz daxil borc</small><b><span data-total-debt>2,133</span> AZN</b></div></div></div><p data-internal-policy>Daxili ödəniş: 40%-dən başlayan ilkin ödəniş</p><p data-internal-note>Daxili ödəniş faizləri: 6 ay 8%, 12 ay 15%, 18 ay 23%. Yekun şərtlər satış mütəxəssisi tərəfindən təsdiqlənir.</p><p class="is-hidden" data-bank-note>Bank hesablamasında daxili ödənişlə eyni faiz cədvəli qalıq borca tətbiq olunur: 6 ayadək 8%, 12 ayadək 15%, 12 aydan çox 23%. Bank komissiyası daxil deyil; yekun təsdiq bank tərəfindən verilir.</p><p data-eligibility-internal>Daxili hissəli ödəniş üçün A kateqoriyası və son 6 ay üzrə gəlirin göstərilməsi tələb olunur. Gəlirin rəsmi olması şərt deyil.</p><p class="is-hidden" data-eligibility-bank>Bank krediti üçün A kateqoriyalı sürücülük vəsiqəsi tələb olunmur. Sənədlər və yekun təsdiq bankın şərtlərinə əsasən müəyyən olunur.</p><p class="finance-total" data-installment-total-row><span data-installment-total-label>Ümumi ödəniş · ilkin ödəniş daxil</span>: <strong data-installment-total>3,289</strong> AZN</p><a class="button primary" href="#{WHATSAPP_URL}" target="_blank" rel="noreferrer">Fərdi təklif al <span>↗︎</span></a></div></section>
    <section class="model-gallery-section section" id="qalereya"><div class="section-head"><div><p class="eyebrow"><span></span> Rəsmi fotolar</p><h2>ZEEHO EZ4<br/>qalereyası.</h2></div><p>ZEEHO Global tərəfindən yayımlanmış rəsmi model və praktik istifadə görüntüləri.</p></div><div class="ez4-gallery"><figure><img src="/gallery/zeeho-ez4-ergonomics.webp" alt="ZEEHO EZ4 erqonomik ayaq platforması" loading="lazy" width="1920" height="940"/></figure><figure><img src="/gallery/zeeho-ez4-practicality.webp" alt="ZEEHO EZ4 gündəlik yük imkanı" loading="lazy" width="1036" height="520"/></figure><figure><img src="/gallery/zeeho-ez4-storage.webp" alt="ZEEHO EZ4 saxlama bölməsi" loading="lazy" width="512" height="272"/></figure></div></section>
    <section class="related section"><div class="section-head"><div><p class="eyebrow dark"><span></span> Digər seçimlər</p><h2>Şəhər üçün skuter modelləri.</h2></div><a class="text-link" href="/motosiklet/">Bütün motosikletlər <span>→</span></a></div><div class="related-grid"><a class="related-card" href="/model/150sc/"><div><img src="/models/150sc.webp" alt="150SC rəsmi foto" loading="lazy"/></div><span>Scooter</span><h3>150SC</h3><p>5,490 AZN <b>↗︎</b></p></a><a class="related-card" href="/model/aura-150/"><div><img src="/models/aura-150-ivory-white-official-v1.png" alt="AURA 150 rəsmi foto" loading="lazy"/></div><span>Scooter</span><h3>AURA 150</h3><p>5,590 AZN <b>↗︎</b></p></a><a class="related-card" href="/model/papio-xo/"><div><img src="/models/papio-xo.webp" alt="PAPIO XO rəsmi foto" loading="lazy"/></div><span>Mini Bike</span><h3>PAPIO XO</h3><p>4,750 AZN <b>↗︎</b></p></a></div></section>
    <section class="product-cta section"><div><p class="eyebrow"><span></span> CFMOTO Azerbaijan</p><h2>EZ4 üçün fərdi təklif al.</h2><p>Rəng, komplektasiya, mövcudluq və çatdırılma vaxtını satış komandamızla dəqiqləşdirin.</p></div><a class="button primary" href="#{WHATSAPP_URL}" target="_blank" rel="noreferrer">WhatsApp-la əlaqə <span>↗︎</span></a></section>
    #{footer}<div class="model-mobile-cta ez4-mobile-cta"><a href="/aksesuar-konfiquratoru/?model=zeeho-ez4&amp;bike=0&amp;lock=1">Aksesuar sorğusu</a><a href="#odenis">Aylıq ödəniş</a></div><a class="whatsapp model-whatsapp" href="#{WHATSAPP_URL}" target="_blank" rel="noreferrer" aria-label="WhatsApp ilə əlaqə">WA</a><script defer src="/assets/ez4-finance-v1.js"></script></main></body></html>
  HTML
  version_ez4_images!(html)
end

required_images = %w[
  models/zeeho-ez4.webp
  models/cards/zeeho-ez4.webp
  gallery/zeeho-ez4-ergonomics.webp
  gallery/zeeho-ez4-practicality.webp
  gallery/zeeho-ez4-storage.webp
]
missing = required_images.reject { |path| File.file?(File.join(ROOT, path)) }
abort "Missing ZEEHO EZ4 images: #{missing.join(', ')}" unless missing.empty?

style_path = File.join(ASSETS, "zeeho-ez4-model-v1.css")
abort "Missing ZEEHO EZ4 stylesheet" unless File.file?(style_path)
write(style_path, version_ez4_images!(read(style_path)))

template_path = File.join(ROOT, "model", "aura-150", "index.html")
abort "AURA 150 template not found" unless File.file?(template_path)

html_paths = [File.join(ROOT, "index.html"), *Dir.glob(File.join(ROOT, "model", "*", "index.html"))]
html_paths.each do |path|
  html = add_ez4_mega_item!(read(path))
  html = add_ez4_home_card!(html) if path == File.join(ROOT, "index.html")
  write(path, html)
end

write(File.join(ROOT, "model", SLUG, "index.html"), custom_page(read(template_path)))

bundle_paths = Dir.glob(File.join(ASSETS, "ProductMegaMenu-*.js"))
  .reject { |path| File.basename(path).include?("Russian") }
  .select { |path| read(path).include?('slug:`aura-150`') }
abort "No Azerbaijani product mega-menu bundle found" if bundle_paths.empty?
bundle_paths.each { |path| write(path, patch_model_bundle!(read(path), path)) }

home_bundle_paths = Dir.glob(File.join(ASSETS, "page-*.js"))
  .reject { |path| File.basename(path).include?("Russian") }
  .select { |path| read(path).include?('w=(0,s.useMemo)(()=>a.filter(e=>e.price!==null)') || read(path).include?('e.financeEligible!==false') }
abort "No Azerbaijani homepage finance bundle found" if home_bundle_paths.empty?
home_bundle_paths.each { |path| write(path, exclude_ez4_from_home_finance!(read(path), path)) }

puts "ZEEHO EZ4 added: 2,890 AZN price, scooter catalogue, standalone finance calculator and accessory enquiry"
