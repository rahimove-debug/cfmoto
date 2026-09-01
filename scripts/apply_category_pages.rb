#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "fileutils"
require "json"
require_relative "category_config"
require_relative "domain_config"

ROOT = File.expand_path("..", __dir__)
SITE_ORIGIN = DomainConfig::SITE_ORIGIN
SOCIAL_IMAGE = "#{SITE_ORIGIN}/official-800mtx-hero.webp"
SALES_WHATSAPP = "994512332484"
CLEAN_CARD_IMAGE_SLUGS = %w[1000mt-x 750sr-s cforce-c4 cforce1000-touring].freeze

def category_card_image_source(slug)
  suffix = CLEAN_CARD_IMAGE_SLUGS.include?(slug) ? "-clean" : ""
  "/models/cards/#{slug}#{suffix}.webp"
end

CONFIG = {
  "motosiklet" => {
    type: "Motosiklet",
    title: "Motosiklet Satışı və Qiymətləri | CFMOTO Azerbaijan",
    description: "CFMOTO motosiklet modelləri və Azərbaycandakı nağd satış qiymətləri. Naked, sport, touring, adventure, cruiser və scooter seçimlərini müqayisə edin.",
    eyebrow: "29 aktual motosiklet",
    heading: "CFMOTO motosiklet satışı və qiymətləri",
    intro: "Şəhər, touring, adventure, sport və gündəlik istifadə üçün CFMOTO motosikletlərini aktual qiymətlərlə bir səhifədə müqayisə edin.",
    body_heading: "Hansı CFMOTO motosikleti sizə uyğundur?",
    body: "Naked modellər şəhərdə çevik idarəetmə, SR seriyası sport xarakteri, MT modelləri isə uzun marşrut və dəyişən yol şəraiti üçün hazırlanıb. Cruiser, scooter və dual-sport seçimləri də fərqli sürüş tərzinə uyğun alternativlər təqdim edir.",
    finance: "Mühərrik həcmi 300 cc-dək olan motosikletlərdə və 450SR modelində daxili hissəli ödəniş üçün minimum ilkin ödəniş 20%-dir. Digər motosikletlərdə minimum ilkin ödəniş 40%, maksimal müddət 18 aydır.",
    faqs: [
      ["CFMOTO motosiklet qiymətləri neçə AZN-dən başlayır?", "Səhifədəki aktual model siyahısında hər motosikletin nağd satış qiyməti ayrıca göstərilir. Qiymət və komplektasiya satış zamanı dəqiqləşdirilir."],
      ["Motosikletlər üçün ilkin ödəniş neçə faizdir?", "300 cc-dək motosikletlər və 450SR üçün minimum ilkin ödəniş 20%, digər motosikletlər üçün 40%-dir."],
      ["Motosikletlərə zəmanət verilirmi?", "CFMOTO motosikletləri üçün zəmanət 2 il və ya 24.000 km-dir; hansı hədd daha tez tamamlanarsa, o əsas götürülür."],
      ["Modeli harada yaxından görə bilərəm?", "Modellərlə Babək prospekti 188 ünvanındakı CFMOTO Azerbaijan satış mərkəzində tanış ola bilərsiniz."]
    ]
  },
  "kvadrosikl" => {
    type: "Kvadrosikl",
    title: "Kvadrosikl (ATV) Satışı və Qiymətləri | CFMOTO Azerbaijan",
    description: "CFMOTO kvadrosikl və ATV modelləri, xüsusiyyətləri və Azərbaycandakı nağd satış qiymətləri. Utility, touring, premium və youth ATV seçimləri.",
    eyebrow: "9 aktual kvadrosikl",
    heading: "CFMOTO kvadrosikl və ATV qiymətləri",
    intro: "İş, təsərrüfat, istirahət və çətin relyef üçün CFMOTO CFORCE və GOES kvadrosikllərini qiymət və mühərrik sinfinə görə müqayisə edin.",
    body_heading: "Kvadrosikl seçərkən nələrə baxmaq lazımdır?",
    body: "Mühərrik sinfi, oturacaq quruluşu, yük və yedəkləmə ehtiyacı, asqı və istifadə ediləcək relyef əsas seçim meyarlarıdır. Utility və touring modelləri işlə istirahət arasında fərqli balans təqdim edir.",
    finance: "Kvadrosikl modellərində daxili hissəli ödəniş üçün minimum ilkin ödəniş 50%, maksimal müddət 12 aydır. Yekun maliyyələşmə şərtləri satış mütəxəssisi tərəfindən təsdiqlənir.",
    faqs: [
      ["CFMOTO kvadrosikl qiymətləri necə müqayisə olunur?", "Bütün aktual ATV modellərinin nağd satış qiyməti və mühərrik sinfi bu səhifədə göstərilir."],
      ["Kvadrosikl üçün ilkin ödəniş nə qədərdir?", "Daxili hissəli ödənişdə minimum ilkin ödəniş 50%, maksimal müddət 12 aydır."],
      ["ATV modeli seçərkən hansı məlumatlar vacibdir?", "İstifadə məqsədi, mühərrik sinfi, oturacaq sayı, yük və yedəkləmə tələbi, asqı və təkər ölçüləri nəzərə alınmalıdır."],
      ["Kvadrosikl servisi və ehtiyat hissələri varmı?", "Rəsmi servis və ehtiyat hissələri üçün +994 10 241 42 99 nömrəsi ilə əlaqə saxlaya bilərsiniz."]
    ]
  },
  "buggy" => {
    type: "Buggy",
    title: "Buggy və UTV Modelləri | CFMOTO Azerbaijan",
    description: "CFMOTO buggy, SSV və UTV modelləri və Azərbaycandakı nağd satış qiymətləri. ZFORCE, UFORCE və U10 seriyalarını müqayisə edin.",
    eyebrow: "9 aktual buggy və UTV",
    heading: "CFMOTO buggy, SSV və UTV modelləri",
    intro: "Sport off-road, iş, yük və çoxnəfərlik marşrutlar üçün ZFORCE, UFORCE və U10 modellərini aktual qiymətlərlə müqayisə edin.",
    body_heading: "Sport buggy və utility UTV fərqi nədir?",
    body: "ZFORCE modelləri dinamik off-road sürüşünə, UFORCE və U10 modelləri isə iş, yükdaşıma və çoxməqsədli istifadəyə fokuslanır. Oturacaq sayı, yük platforması, mühərrik və asqı quruluşu seçim zamanı əsas göstəricilərdir.",
    finance: "Buggy və UTV modellərində daxili hissəli ödəniş üçün minimum ilkin ödəniş 50%, maksimal müddət 12 aydır. Bank krediti şərtləri ayrıca təsdiqlənir.",
    faqs: [
      ["Buggy və UTV qiymətləri harada göstərilir?", "Bu səhifədə bütün aktual CFMOTO buggy və UTV modellərinin nağd satış qiymətləri göstərilir."],
      ["Buggy üçün ilkin ödəniş nə qədərdir?", "Daxili hissəli ödənişdə minimum ilkin ödəniş 50%, maksimal müddət 12 aydır."],
      ["ZFORCE və UFORCE arasında fərq nədir?", "ZFORCE sport off-road istifadə, UFORCE isə iş, yük və utility ssenariləri üçün hazırlanıb."],
      ["Çoxnəfərlik CFMOTO UTV varmı?", "U10 XL PRO və UFORCE 1000 XL kimi modellər daha çox sərnişin və çoxməqsədli istifadə üçün nəzərdə tutulub."]
    ]
  }
}.freeze

def html_text(fragment)
  CGI.unescapeHTML(fragment.to_s.gsub(/<!--.*?-->/m, "").gsub(/<[^>]+>/, "").gsub(/\s+/, " ").strip)
end

def models
  home = File.read(File.join(ROOT, "index.html"), encoding: "UTF-8")
  cards = home.scan(%r{<article class="model-card">.*?</article>}m)
  abort "Expected 48 model cards, found #{cards.size}" unless cards.size == 48
  cards.map do |card|
    slug = card[%r{href="/model/([^"/]+)/?"}, 1]
    name = html_text(card[%r{<h3>(.*?)</h3>}m, 1])
    type, engine = card[%r{<div class="model-info">.*?<p>(.*?)</p>}m, 1].to_s
      .split(/<!-- -->\s*·\s*<!-- -->/, 2).map { |part| html_text(part) }
    {
      slug: slug,
      name: name,
      type: type,
      engine: engine,
      segment: html_text(card[%r{<span class="model-type">(.*?)</span>}m, 1]),
      price: html_text(card[%r{<div class="model-price">.*?<strong>(.*?)</strong>}m, 1])
    }
  end
end

def schema_for(slug, config, items)
  canonical = "#{SITE_ORIGIN}/#{slug}/"
  {
    "@context" => "https://schema.org",
    "@graph" => [
      {
        "@type" => "WebPage",
        "@id" => "#{canonical}#webpage",
        "url" => canonical,
        "name" => config[:title],
        "description" => config[:description],
        "inLanguage" => "az",
        "isPartOf" => { "@id" => "#{SITE_ORIGIN}/#website" },
        "about" => { "@id" => "#{SITE_ORIGIN}/#organization" }
      },
      {
        "@type" => "BreadcrumbList",
        "itemListElement" => [
          { "@type" => "ListItem", "position" => 1, "name" => "Ana səhifə", "item" => "#{SITE_ORIGIN}/" },
          { "@type" => "ListItem", "position" => 2, "name" => CategoryConfig::LABELS.fetch(slug), "item" => canonical }
        ]
      },
      {
        "@type" => "CollectionPage",
        "@id" => "#{canonical}#collection",
        "name" => config[:heading],
        "mainEntity" => {
          "@type" => "ItemList",
          "numberOfItems" => items.size,
          "itemListElement" => items.each_with_index.map do |model, index|
            { "@type" => "ListItem", "position" => index + 1, "name" => model[:name], "url" => "#{SITE_ORIGIN}/model/#{model[:slug]}/" }
          end
        }
      },
      {
        "@type" => "FAQPage",
        "mainEntity" => config[:faqs].map do |question, answer|
          { "@type" => "Question", "name" => question, "acceptedAnswer" => { "@type" => "Answer", "text" => answer } }
        end
      }
    ]
  }
end

def page_html(slug, config, items)
  canonical = "#{SITE_ORIGIN}/#{slug}/"
  cards = items.map do |model|
    <<~HTML.delete("\n")
      <article class="category-model-card"><a class="visual" href="/model/#{model[:slug]}/"><img src="#{category_card_image_source(model[:slug])}" alt="#{CGI.escapeHTML(model[:name])} rəsmi model fotosu" width="680" height="510" loading="lazy" decoding="async"/><span>#{CGI.escapeHTML(model[:segment])}</span></a><div class="category-model-copy"><h2>#{CGI.escapeHTML(model[:name])}</h2><p>#{CGI.escapeHTML(model[:type])} · #{CGI.escapeHTML(model[:engine])}</p><strong>#{CGI.escapeHTML(model[:price])}</strong><a href="/model/#{model[:slug]}/">Model haqqında →</a></div></article>
    HTML
  end.join
  faq = config[:faqs].map { |question, answer| "<details><summary>#{question}</summary><p>#{answer}</p></details>" }.join
  category_links = CategoryConfig::SLUGS.map do |category|
    current = category == slug ? ' aria-current="page"' : ""
    %(<a href="/#{category}/"#{current}>#{CategoryConfig::LABELS.fetch(category)}</a>)
  end.join

  <<~HTML
    <!doctype html>
    <html lang="az">
    <head>
      <meta charset="utf-8"/>
      <meta name="viewport" content="width=device-width,initial-scale=1"/>
      <title>#{config[:title]}</title>
      <meta name="description" content="#{config[:description]}"/>
      <link rel="canonical" href="#{canonical}"/>
      <meta property="og:title" content="#{config[:title]}"/>
      <meta property="og:description" content="#{config[:description]}"/>
      <meta property="og:url" content="#{canonical}"/>
      <meta property="og:type" content="website"/>
      <meta property="og:image" content="#{SOCIAL_IMAGE}"/>
      <meta property="og:image:alt" content="#{config[:heading]}"/>
      <meta property="og:locale" content="az_AZ"/>
      <meta property="og:site_name" content="CFMOTO Azerbaijan"/>
      <meta name="twitter:card" content="summary_large_image"/>
      <meta name="twitter:title" content="#{config[:title]}"/>
      <meta name="twitter:description" content="#{config[:description]}"/>
      <meta name="twitter:image" content="#{SOCIAL_IMAGE}"/>
      <meta name="twitter:image:alt" content="#{config[:heading]}"/>
      <link rel="icon" href="/favicon.svg"/>
      <link rel="stylesheet" href="/assets/content.css"/>
      <link rel="stylesheet" href="/assets/category.css"/>
      <script type="application/ld+json">#{JSON.generate(schema_for(slug, config, items))}</script>
    </head>
    <body>
      <div class="topline">CFMOTO-nun Azərbaycanda rəsmi nümayəndəsi</div>
      <header class="content-header"><a class="brand" href="/" aria-label="CFMOTO Azerbaijan ana səhifə"><img src="/cfmoto-logo-black.png" alt="CFMOTO" width="159" height="34"/><b>AZƏRBAYCAN</b></a><nav class="content-nav" aria-label="Əsas menyu">#{category_links}<a href="/kredit/">Kredit</a><a href="/servis/">Servis</a></nav><a class="nav-cta" href="https://wa.me/#{SALES_WHATSAPP}?text=Salam%2C%20CFMOTO%20modeli%20haqq%C4%B1nda%20m%C9%99lumat%20almaq%20ist%C9%99yir%C9%99m" target="_blank" rel="noreferrer">Əlaqə</a></header>
      <main><section class="content-hero"><nav class="breadcrumbs" aria-label="Naviqasiya yolu"><a href="/">Ana səhifə</a><span>›</span><span>#{CategoryConfig::LABELS.fetch(slug)}</span></nav><p class="eyebrow">#{config[:eyebrow]}</p><h1>#{config[:heading]}</h1><p>#{config[:intro]}</p></section><div class="content-main"><div class="content-wrap"><div class="category-summary"><p class="lead">#{config[:intro]}</p><div class="category-stat"><strong>#{items.size}</strong><span>aktual model və nağd satış qiyməti</span></div></div><section class="category-model-grid" aria-label="#{CategoryConfig::LABELS.fetch(slug)} model siyahısı">#{cards}</section><section class="category-copy-block prose"><h2>#{config[:body_heading]}</h2><p>#{config[:body]}</p><h2>Maliyyələşmə şərtləri</h2><p>#{config[:finance]}</p><div class="notice">Qiymətlər və məlumatlar yenilənə bilər. Yekun qiymət, komplektasiya və maliyyələşmə şərtlərini satış mütəxəssisi ilə dəqiqləşdirin.</div></section><section class="faq category-faq"><h2>Tez-tez verilən suallar</h2>#{faq}</section><div class="cta-box"><div><h2>Uyğun modeli seçin</h2><p>Modeli müqayisə edin və fərdi təklif üçün satış komandası ilə əlaqə saxlayın.</p></div><div class="cta-actions"><a class="button primary" href="/model-muqayisesi/">Modelləri müqayisə et</a><a class="button ghost" href="https://wa.me/#{SALES_WHATSAPP}" target="_blank" rel="noreferrer">Təklif al</a></div></div></div></div></main>
      <aside class="content-links" aria-label="Faydalı məlumatlar"><div><a href="/motosiklet/">Motosikletlər →</a><a href="/kvadrosikl/">Kvadrosikllər →</a><a href="/buggy/">Buggy və UTV →</a><a href="/kredit/">Kredit şərtləri →</a><a href="/servis/">Rəsmi servis →</a></div></aside>
      <footer class="content-footer"><a class="brand" href="/"><img src="/cfmoto-logo-black.png" alt="CFMOTO" width="159" height="34"/><b>AZƏRBAYCAN</b></a><div><a href="/motosiklet/">Motosikletlər</a><a href="/kvadrosikl/">Kvadrosikllər</a><a href="/buggy/">Buggy və UTV</a><a href="/kredit/">Kredit</a><a href="/servis/">Servis</a></div><small>© 2026 CFMOTO Azerbaijan · SAZMOTO MMC. Bütün hüquqlar qorunur.</small></footer>
    </body>
    </html>
  HTML
end

all_models = models
CategoryConfig::SLUGS.each do |slug|
  config = CONFIG.fetch(slug)
  items = all_models.select { |model| model[:type] == config[:type] }
  expected = { "motosiklet" => 30, "kvadrosikl" => 9, "buggy" => 9 }.fetch(slug)
  abort "#{slug}: expected #{expected} models, found #{items.size}" unless items.size == expected
  directory = File.join(ROOT, slug)
  FileUtils.mkdir_p(directory)
  File.write(File.join(directory, "index.html"), page_html(slug, config, items), encoding: "UTF-8")
end

puts "Generated 3 category pages with 48 model cards"
