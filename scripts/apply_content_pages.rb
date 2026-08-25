#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "fileutils"
require "json"
require_relative "category_config"
require_relative "content_config"
require_relative "domain_config"

ROOT = File.expand_path("..", __dir__)
SITE_ORIGIN = DomainConfig::SITE_ORIGIN
SERVICE_PHONE = "+994102414299"
SERVICE_PHONE_DISPLAY = "+994 10 241 42 99"
SALES_WHATSAPP = "+994512332484"
SOCIAL_IMAGE = "#{SITE_ORIGIN}/official-800mtx-hero.webp"

INTERNAL_20_SLUGS = %w[
  125nk 150sc 250cl-c 250dual 250nk 250sr-fun 300nk 300sr aura-150
  cflite-230-dual papio-xo 450sr
].freeze
INTERNAL_40_SLUGS = %w[
  1000mt-x 800mt-explore 800mt-sport 800mt-x 800nk-advanced 750sr-s
  700cl-x-sport 700mt 675sr-r 675nk 500sr-voom 450cl-c-bobber 450cl-c
  450cl-c-amt 450sr-s 450mt 450nk
].freeze

def html_text(fragment)
  CGI.unescapeHTML(fragment.to_s.gsub(/<!--.*?-->/m, "").gsub(/<[^>]+>/, "").strip)
end

def format_amount(value)
  value.to_i.to_s.reverse.scan(/.{1,3}/).join(",").reverse
end

def parse_models
  home = File.read(File.join(ROOT, "index.html"), encoding: "UTF-8")
  cards = home.scan(%r{<article class="model-card">.*?</article>}m)
  abort "Expected 47 homepage model cards, found #{cards.size}" unless cards.size == 47

  cards.map do |card|
    slug = card[%r{href="/model/([^"]+)"}, 1]
    name = html_text(card[%r{<h3>(.*?)</h3>}m, 1])
    info = card[%r{<div class="model-info">.*?<p>(.*?)</p>}m, 1]
    type, engine = info.to_s.split(/<!-- -->\s*·\s*<!-- -->/, 2).map { |part| html_text(part) }
    segment = html_text(card[%r{<span class="model-type">(.*?)</span>}m, 1])
    price_label = html_text(card[%r{<div class="model-price">.*?<strong>(.*?)</strong>}m, 1])
    price = price_label[/[\d,]+/].to_s.delete(",").to_i
    percent = if INTERNAL_20_SLUGS.include?(slug)
      20
    elsif INTERNAL_40_SLUGS.include?(slug)
      40
    else
      50
    end
    term = (type == "Motosiklet" ? 18 : 12)

    {
      slug: slug,
      name: name,
      type: type,
      segment: segment,
      engine: engine,
      price: price,
      price_label: price_label,
      percent: percent,
      down_payment: (price * percent / 100.0).round,
      term: term
    }
  end
end

def breadcrumbs_schema(slug, label)
  {
    "@type" => "BreadcrumbList",
    "itemListElement" => [
      { "@type" => "ListItem", "position" => 1, "name" => "Ana səhifə", "item" => "#{SITE_ORIGIN}/" },
      { "@type" => "ListItem", "position" => 2, "name" => label, "item" => "#{SITE_ORIGIN}/#{slug}" }
    ]
  }
end

def page_schema(slug, title, description, label, extras = [])
  canonical = "#{SITE_ORIGIN}/#{slug}"
  {
    "@context" => "https://schema.org",
    "@graph" => [
      {
        "@type" => "WebPage",
        "@id" => "#{canonical}/#webpage",
        "url" => canonical,
        "name" => title,
        "description" => description,
        "inLanguage" => "az",
        "isPartOf" => { "@id" => "#{SITE_ORIGIN}/#website" },
        "about" => { "@id" => "#{SITE_ORIGIN}/#organization" }
      },
      breadcrumbs_schema(slug, label),
      *extras
    ]
  }
end

def page_html(slug:, title:, description:, eyebrow:, heading:, intro:, body:, schema:)
  canonical = "#{SITE_ORIGIN}/#{slug}"
  label = ContentConfig::LABELS.fetch(slug)
  content_links = ContentConfig::SLUGS.map do |item|
    current = item == slug ? %( aria-current="page") : ""
    %(<a href="/#{item}"#{current}>#{ContentConfig::LABELS.fetch(item)} →</a>)
  end.join
  category_links = CategoryConfig::SLUGS.map do |item|
    %(<a href="/#{item}/">#{CategoryConfig::LABELS.fetch(item)} →</a>)
  end.join

  <<~HTML
    <!doctype html>
    <html lang="az">
    <head>
      <meta charset="utf-8"/>
      <meta name="viewport" content="width=device-width,initial-scale=1"/>
      <title>#{title}</title>
      <meta name="description" content="#{description}"/>
      <link rel="canonical" href="#{canonical}"/>
      <meta property="og:title" content="#{title}"/>
      <meta property="og:description" content="#{description}"/>
      <meta property="og:url" content="#{canonical}"/>
      <meta property="og:type" content="website"/>
      <meta property="og:image" content="#{SOCIAL_IMAGE}"/>
      <meta property="og:image:alt" content="CFMOTO Azerbaijan"/>
      <meta property="og:locale" content="az_AZ"/>
      <meta property="og:site_name" content="CFMOTO Azerbaijan"/>
      <meta name="twitter:card" content="summary_large_image"/>
      <meta name="twitter:title" content="#{title}"/>
      <meta name="twitter:description" content="#{description}"/>
      <meta name="twitter:image" content="#{SOCIAL_IMAGE}"/>
      <meta name="twitter:image:alt" content="CFMOTO Azerbaijan"/>
      <link rel="icon" href="/favicon.svg"/>
      <link rel="stylesheet" href="/assets/content.css"/>
      <script type="application/ld+json">#{JSON.generate(schema)}</script>
    </head>
    <body>
      <div class="topline">CFMOTO-nun Azərbaycanda rəsmi nümayəndəsi</div>
      <header class="content-header">
        <a class="brand" href="/" aria-label="CFMOTO Azerbaijan ana səhifə"><img src="/cfmoto-logo-black.png" alt="CFMOTO" width="159" height="34"/><b>AZƏRBAYCAN</b></a>
        <nav class="content-nav" aria-label="Əsas menyu">
          <a href="/#modeller">Modellər</a><a href="/kredit">Kredit</a><a href="/servis">Servis</a><a href="/zemanet">Zəmanət</a><a href="/model-muqayisesi">Müqayisə</a>
        </nav>
        <a class="nav-cta" href="https://wa.me/#{SALES_WHATSAPP.delete('+')}?text=Salam%2C%20CFMOTO%20haqq%C4%B1nda%20m%C9%99lumat%20almaq%20ist%C9%99yir%C9%99m" target="_blank" rel="noreferrer">Əlaqə</a>
      </header>
      <main>
        <section class="content-hero">
          <nav class="breadcrumbs" aria-label="Naviqasiya yolu"><a href="/">Ana səhifə</a><span>›</span><span>#{label}</span></nav>
          <p class="eyebrow">#{eyebrow}</p>
          <h1>#{heading}</h1>
          <p>#{intro}</p>
        </section>
        <div class="content-main"><div class="content-wrap">#{body}</div></div>
      </main>
      <aside class="content-links" aria-label="Faydalı məlumatlar"><div>#{category_links}#{content_links}</div></aside>
      <footer class="content-footer">
        <a class="brand" href="/"><img src="/cfmoto-logo-black.png" alt="CFMOTO" width="159" height="34"/><b>AZƏRBAYCAN</b></a>
        <div><a href="/motosiklet/">Motosikletlər</a><a href="/kvadrosikl/">Kvadrosikllər</a><a href="/buggy/">Buggy və UTV</a><a href="/kredit">Kredit</a><a href="/servis">Servis</a><a href="/ehtiyat-hisseleri">Ehtiyat hissələri</a><a href="#{DomainConfig::INSTAGRAM_URL}" target="_blank" rel="noreferrer">Instagram</a></div>
        <small>© 2026 CFMOTO Azerbaijan · SAZMOTO MMC. Bütün hüquqlar qorunur.</small>
      </footer>
    </body>
    </html>
  HTML
end

models = parse_models

credit_faq = [
  ["Hansı motosikletlərdə ilkin ödəniş 20%-dir?", "Mühərrik həcmi 300 cc-dək olan motosikletlərdə və istisna olaraq 450SR modelində minimum ilkin ödəniş 20%-dir."],
  ["Digər motosikletlərdə ilkin ödəniş nə qədərdir?", "300 cc-dən böyük digər motosikletlərdə minimum ilkin ödəniş 40%-dir."],
  ["ATV və buggy üçün şərtlər necədir?", "ATV və buggy modellərində daxili hissəli ödəniş üçün minimum ilkin ödəniş 50%, maksimal müddət 12 aydır."],
  ["Bank krediti müddəti nə qədər ola bilər?", "Bank krediti 10%-dən başlayan ilkin ödənişlə 35 ayadək hesablana bilər. Yekun bank şərtləri ayrıca təsdiqlənir."]
]
credit_schema = page_schema(
  "kredit",
  "CFMOTO Kredit və Hissəli Ödəniş | Azərbaycan",
  "CFMOTO motosiklet, ATV və buggy modelləri üçün daxili hissəli ödəniş və bank krediti şərtləri. İlkin ödənişləri və müddətləri öyrənin.",
  ContentConfig::LABELS.fetch("kredit"),
  [{ "@type" => "FAQPage", "mainEntity" => credit_faq.map { |question, answer| { "@type" => "Question", "name" => question, "acceptedAnswer" => { "@type" => "Answer", "text" => answer } } } }]
)
credit_body = <<~HTML
  <p class="lead">Model kateqoriyasına uyğun minimum ilkin ödənişi və maksimal müddəti əvvəlcədən müqayisə edin. Saytdakı kalkulyator ilkin planlama üçündür.</p>
  <div class="info-grid">
    <article class="info-card"><span>≤ 300 cc və 450SR</span><h2>Motosikletlər</h2><strong>20% · 18 ayadək</strong><p>Daxili hissəli ödəniş üçün minimum ilkin ödəniş və maksimal müddət.</p></article>
    <article class="info-card"><span>Digər motosikletlər</span><h2>300 cc-dən yuxarı</h2><strong>40% · 18 ayadək</strong><p>450SR istisna olmaqla digər motosiklet modelləri üçün.</p></article>
    <article class="info-card"><span>Off-road</span><h2>ATV və buggy</h2><strong>50% · 12 ayadək</strong><p>Kvadrosikl və buggy modelləri üçün daxili hissəli ödəniş.</p></article>
  </div>
  <section class="prose"><h2>Bank krediti</h2><p>Bank krediti 10%-dən başlayan ilkin ödənişlə 35 ayadək mümkündür. Bank faizi, komissiya, tələb olunan sənədlər və yekun təsdiq bankın şərtlərinə əsasən müəyyən olunur.</p><div class="notice">Hesablama məlumat xarakterlidir; bank faizi və komissiyalar daxil deyil. Yekun şərtlər fərqlənə bilər.</div></section>
  <div class="cta-box"><div><h2>Seçdiyiniz modeli hesablayın</h2><p>Ana səhifədə model, ilkin ödəniş və müddəti dəyişərək təxmini aylıq məbləği görün.</p></div><div class="cta-actions"><a class="button primary" href="/#kredit-kalkulyator">Kalkulyatoru aç</a><a class="button ghost" data-contact-area="finance" href="https://wa.me/#{SALES_WHATSAPP.delete('+')}?text=Salam%2C%20CFMOTO%20kredit%20%C5%9F%C9%99rtl%C9%99ri%20haqq%C4%B1nda%20m%C9%99lumat%20almaq%20ist%C9%99yir%C9%99m" target="_blank" rel="noreferrer">Təklif al</a></div></div>
  <section class="faq"><h2>Tez-tez verilən suallar</h2>#{credit_faq.map { |question, answer| "<details><summary>#{question}</summary><p>#{answer}</p></details>" }.join}</section>
HTML

service_schema = page_schema(
  "servis",
  "CFMOTO Rəsmi Servis Bakı | Texniki Qulluq və Təmir",
  "CFMOTO standartlarına uyğun diaqnostika, texniki qulluq və təmir. Servis: +994 10 241 42 99; bazar ertəsi xaric hər gün 10:00–19:00.",
  ContentConfig::LABELS.fetch("servis"),
  [{ "@type" => "Service", "@id" => "#{SITE_ORIGIN}/servis/#service", "name" => "CFMOTO rəsmi servis xidməti", "serviceType" => ["Diaqnostika", "Texniki qulluq", "Təmir"], "provider" => { "@id" => "#{SITE_ORIGIN}/#organization" }, "areaServed" => { "@type" => "Country", "name" => "Azərbaycan" }, "telephone" => SERVICE_PHONE }]
)
service_body = <<~HTML
  <p class="lead">CFMOTO standartlarına uyğun diaqnostika, planlı texniki qulluq və təmir üçün rəsmi servis komandası ilə əlaqə saxlayın.</p>
  <div class="info-grid"><article class="info-card"><span>01</span><h2>Diaqnostika</h2><p>Modelin texniki vəziyyətinin yoxlanması və tələb olunan işlərin dəqiqləşdirilməsi.</p></article><article class="info-card"><span>02</span><h2>Texniki qulluq</h2><p>Model və istifadə şəraitinə uyğun planlı servis əməliyyatları.</p></article><article class="info-card"><span>03</span><h2>Təmir</h2><p>CFMOTO texnikası üçün peşəkar texniki xidmət və təmir.</p></article></div>
  <section class="prose"><h2>İş saatları və əlaqə</h2><p>Bazar ertəsi istisna olmaqla servis hər gün saat 10:00–19:00 arasında fəaliyyət göstərir. Qəbul vaxtını və lazım olan xidməti əvvəlcədən dəqiqləşdirmək üçün <a href="tel:#{SERVICE_PHONE}" data-contact-area="service"><strong>#{SERVICE_PHONE_DISPLAY}</strong></a> nömrəsinə zəng edin.</p><h2>Şəhərdaxili aparıb-gətirmə</h2><p>Motosikletin servisə aparılması və geri qaytarılması xidməti şəhər daxilində 45 AZN-dir.</p><div class="notice">Servis ünvanını, qəbul vaxtını və ehtiyac duyulan işi telefonla əvvəlcədən dəqiqləşdirin.</div></section>
  <div class="cta-box"><div><h2>Servis qəbulu üçün əlaqə</h2><p>Bazar ertəsi xaric hər gün 10:00–19:00.</p></div><div class="cta-actions"><a class="button primary" href="tel:#{SERVICE_PHONE}" data-contact-area="service">#{SERVICE_PHONE_DISPLAY}</a><a class="button ghost" href="/ehtiyat-hisseleri">Ehtiyat hissələri</a></div></div>
HTML

warranty_schema = page_schema("zemanet", "CFMOTO Zəmanət Şərtləri | Azərbaycan", "CFMOTO motosikletləri üçün 2 il və ya 24.000 km zəmanət məlumatı. ATV və buggy şərtləri model və istifadə rejiminə görə dəqiqləşdirilir.", ContentConfig::LABELS.fetch("zemanet"))
warranty_body = <<~HTML
  <p class="lead">Zəmanət müddəti texnikanın kateqoriyasına, modelinə və istifadə rejiminə görə qiymətləndirilir. Yekun şərtlər satış və zəmanət sənədlərində göstərilir.</p>
  <div class="info-grid"><article class="info-card"><span>Motosikletlər</span><h2>Zəmanət müddəti</h2><strong>2 il / 24.000 km</strong><p>Hansı göstərici daha tez tamamlanarsa, həmin hədd əsas götürülür.</p></article><article class="info-card"><span>ATV və buggy</span><h2>Modelə görə</h2><p>Zəmanət şərtləri model və istifadə rejiminə görə ayrıca dəqiqləşdirilir.</p></article><article class="info-card"><span>Rəsmi servis</span><h2>Texniki qulluq</h2><p>Servis tarixçəsi və istehsalçı tələblərinə uyğun qulluq zəmanət prosesində əhəmiyyətlidir.</p></article></div>
  <section class="prose"><h2>Zəmanət məlumatını necə dəqiqləşdirmək olar?</h2><ul><li>Modelin tam adını və istehsal ilini qeyd edin.</li><li>Satış və zəmanət sənədlərindəki şərtləri yoxlayın.</li><li>Texniki qulluq intervallarını rəsmi servis ilə dəqiqləşdirin.</li><li>Konkret hal üzrə servis komandası ilə əlaqə saxlayın.</li></ul><div class="notice">Bu səhifə ümumi məlumat verir. Əhatə dairəsi, istisnalar və yekun şərtlər təqdim olunan rəsmi sənədlərlə müəyyən olunur.</div></section>
  <div class="cta-box"><div><h2>Modeliniz üzrə zəmanəti soruşun</h2><p>Servis komandası model və istifadə məlumatına əsasən yönləndirmə verəcək.</p></div><div class="cta-actions"><a class="button primary" href="tel:#{SERVICE_PHONE}" data-contact-area="service">#{SERVICE_PHONE_DISPLAY}</a><a class="button ghost" href="/servis">Servis məlumatı</a></div></div>
HTML

parts_schema = page_schema("ehtiyat-hisseleri", "CFMOTO Ehtiyat Hissələri və Aksesuarlar | Bakı", "CFMOTO modellərinə uyğun orijinal ehtiyat hissələri, yağlar və aksesuarlar. Uyğunluğu dəqiqləşdirmək üçün +994 10 241 42 99 ilə əlaqə saxlayın.", ContentConfig::LABELS.fetch("ehtiyat-hisseleri"))
parts_body = <<~HTML
  <p class="lead">Modelinizə uyğun orijinal ehtiyat hissələri, yağlar və aksesuarlar haqqında məlumat almaq üçün texnikanın tam modelini əvvəlcədən hazırlayın.</p>
  <div class="info-grid"><article class="info-card"><span>Orijinal</span><h2>Ehtiyat hissələri</h2><p>CFMOTO modelinə uyğun hissənin seçilməsi üçün model məlumatı ilə müraciət edin.</p></article><article class="info-card"><span>Texniki qulluq</span><h2>Yağlar</h2><p>Model və servis intervalına uyğun məhsulu servis komandası ilə dəqiqləşdirin.</p></article><article class="info-card"><span>Fərdiləşdirmə</span><h2>Aksesuarlar</h2><p>Modelə uyğun aksesuar variantları barədə məlumat alın.</p></article></div>
  <section class="prose"><h2>Sorğu zamanı hansı məlumatlar lazımdır?</h2><ul><li>CFMOTO modelinin tam adı</li><li>İstehsal ili</li><li>Axtardığınız hissənin adı və ya mövcuddursa kodu</li><li>Uyğunluğu dəqiqləşdirmək üçün texniki məlumat</li></ul><div class="notice">Məhsul uyğunluğu, qiymət və mövcudluq telefon sorğusu zamanı dəqiqləşdirilir.</div></section>
  <div class="cta-box"><div><h2>Ehtiyat hissəsi sorğusu</h2><p>Model məlumatını qeyd edib servis və ehtiyat hissələri komandası ilə əlaqə saxlayın.</p></div><div class="cta-actions"><a class="button primary" href="tel:#{SERVICE_PHONE}" data-contact-area="service">#{SERVICE_PHONE_DISPLAY}</a><a class="button ghost" href="/servis">Rəsmi servis</a></div></div>
HTML

comparison_items = models.each_with_index.map do |model, index|
  { "@type" => "ListItem", "position" => index + 1, "name" => model[:name], "url" => "#{SITE_ORIGIN}/model/#{model[:slug]}" }
end
comparison_schema = page_schema(
  "model-muqayisesi",
  "CFMOTO Modellərinin Müqayisəsi | Qiymət və Kateqoriya",
  "CFMOTO motosiklet, kvadrosikl və buggy modellərini kateqoriya, nağd qiymət, ilkin ödəniş və müddətə görə müqayisə edin.",
  ContentConfig::LABELS.fetch("model-muqayisesi"),
  [{ "@type" => "CollectionPage", "@id" => "#{SITE_ORIGIN}/model-muqayisesi/#collection", "name" => "CFMOTO model müqayisəsi", "mainEntity" => { "@type" => "ItemList", "numberOfItems" => models.size, "itemListElement" => comparison_items } }]
)
comparison_rows = models.map do |model|
  type_label = [model[:type], model[:segment], model[:engine]].reject(&:empty?).join(" · ")
  <<~ROW.delete("\n")
    <tr><th scope="row"><a href="/model/#{model[:slug]}">#{CGI.escapeHTML(model[:name])}</a></th><td>#{CGI.escapeHTML(type_label)}</td><td>#{format_amount(model[:price])} AZN</td><td>#{model[:percent]}% · #{format_amount(model[:down_payment])} AZN</td><td>#{model[:term]} ayadək</td><td><a href="/model/#{model[:slug]}">Ətraflı →</a></td></tr>
  ROW
end.join
comparison_body = <<~HTML
  <p class="lead">47 aktual modeli kateqoriya, mühərrik sinfi, nağd qiymət və daxili hissəli ödənişin minimum şərtlərinə görə bir cədvəldə müqayisə edin.</p>
  <p class="table-note">Cədvəli mobil telefonda sağa-sola sürüşdürə bilərsiniz. Hesablamalar məlumat xarakterlidir.</p>
  <div class="table-wrap"><table><thead><tr><th>Model</th><th>Kateqoriya</th><th>Nağd qiymət</th><th>Minimum ilkin ödəniş</th><th>Maksimal müddət</th><th>Keçid</th></tr></thead><tbody>#{comparison_rows}</tbody></table></div>
  <div class="notice">Bank faizi və komissiyalar cədvələ daxil deyil. Yekun qiymət və maliyyələşmə şərtləri satış mütəxəssisi tərəfindən dəqiqləşdirilir.</div>
  <div class="cta-box"><div><h2>Seçiminizi daraldın</h2><p>Kateqoriya filtri və model səhifələrindəki texniki məlumatlarla uyğun variantı tapın.</p></div><div class="cta-actions"><a class="button primary" href="/#modeller">Bütün modellər</a><a class="button ghost" href="/kredit">Kredit şərtləri</a></div></div>
HTML

pages = {
  "kredit" => page_html(slug: "kredit", title: "CFMOTO Kredit və Hissəli Ödəniş | Azərbaycan", description: "CFMOTO motosiklet, ATV və buggy modelləri üçün daxili hissəli ödəniş və bank krediti şərtləri. İlkin ödənişləri və müddətləri öyrənin.", eyebrow: "Maliyyələşmə", heading: "CFMOTO kredit və hissəli ödəniş şərtləri", intro: "Motosiklet, ATV və buggy üçün ilkin ödənişləri, müddətləri və hesablama qaydasını aydın şəkildə öyrənin.", body: credit_body, schema: credit_schema),
  "servis" => page_html(slug: "servis", title: "CFMOTO Rəsmi Servis Bakı | Texniki Qulluq və Təmir", description: "CFMOTO standartlarına uyğun diaqnostika, texniki qulluq və təmir. Servis: +994 10 241 42 99; bazar ertəsi xaric hər gün 10:00–19:00.", eyebrow: "Rəsmi texniki xidmət", heading: "CFMOTO servis, texniki qulluq və təmir", intro: "Diaqnostikadan planlı qulluğa qədər CFMOTO texnikanız üçün rəsmi servis dəstəyi.", body: service_body, schema: service_schema),
  "zemanet" => page_html(slug: "zemanet", title: "CFMOTO Zəmanət Şərtləri | Azərbaycan", description: "CFMOTO motosikletləri üçün 2 il və ya 24.000 km zəmanət məlumatı. ATV və buggy şərtləri model və istifadə rejiminə görə dəqiqləşdirilir.", eyebrow: "Rəsmi məlumat", heading: "CFMOTO zəmanət şərtləri", intro: "Motosiklet, ATV və buggy modelləri üçün zəmanət məlumatını və dəqiqləşdirmə qaydasını öyrənin.", body: warranty_body, schema: warranty_schema),
  "ehtiyat-hisseleri" => page_html(slug: "ehtiyat-hisseleri", title: "CFMOTO Ehtiyat Hissələri və Aksesuarlar | Bakı", description: "CFMOTO modellərinə uyğun orijinal ehtiyat hissələri, yağlar və aksesuarlar. Uyğunluğu dəqiqləşdirmək üçün +994 10 241 42 99 ilə əlaqə saxlayın.", eyebrow: "Modelə uyğun seçim", heading: "CFMOTO ehtiyat hissələri və aksesuarlar", intro: "Orijinal hissələr, qulluq məhsulları və aksesuarlar üçün modelə uyğun məlumat alın.", body: parts_body, schema: parts_schema),
  "model-muqayisesi" => page_html(slug: "model-muqayisesi", title: "CFMOTO Modellərinin Müqayisəsi | Qiymət və Kateqoriya", description: "CFMOTO motosiklet, kvadrosikl və buggy modellərini kateqoriya, nağd qiymət, ilkin ödəniş və müddətə görə müqayisə edin.", eyebrow: "47 aktual model", heading: "CFMOTO modellərini müqayisə et", intro: "Qiymət, kateqoriya, mühərrik sinfi və maliyyələşmə şərtlərini bir baxışda müqayisə edin.", body: comparison_body, schema: comparison_schema)
}

ContentConfig::SLUGS.each do |slug|
  directory = File.join(ROOT, slug)
  FileUtils.mkdir_p(directory)
  File.write(File.join(directory, "index.html"), pages.fetch(slug), encoding: "UTF-8")
end

puts "Generated #{pages.size} SEO content pages and #{models.size} comparison rows"
