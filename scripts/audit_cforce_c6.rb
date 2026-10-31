#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

ROOT = File.expand_path(ARGV.fetch(0, ".."), __dir__)
PUBLISHED = File.basename(ROOT) == "dist"
SLUG = "cforce-c6-pro"
AZ_URL = "https://cfmoto.az/model/#{SLUG}/"
RU_URL = "https://cfmoto.az/ru/model/#{SLUG}/"
errors = []

def read(path)
  File.read(path, encoding: "UTF-8")
end

def walk_json(value, &block)
  yield value
  case value
  when Hash
    value.each_value { |child| walk_json(child, &block) }
  when Array
    value.each { |child| walk_json(child, &block) }
  end
end

def product_nodes(html)
  nodes = []
  html.scan(%r{<script type="application/ld\+json">(.*?)</script>}m).flatten.each do |source|
    schema = JSON.parse(source)
    walk_json(schema) { |node| nodes << node if node.is_a?(Hash) && node["@type"] == "Product" }
  end
  nodes
end

pages = {
  "AZ" => [File.join(ROOT, "model", SLUG, "index.html"), "az", AZ_URL, %r{Ön sifariş}i, %r{aksesuar hədiyyə}i],
  "RU" => [File.join(ROOT, "ru", "model", SLUG, "index.html"), "ru", RU_URL, %r{Предзаказ}i, %r{аксессуар.*подар}i]
}

pages.each do |locale, (path, language, canonical, preorder_text, gift_text)|
  unless File.file?(path)
    errors << "#{locale}: C6 page is missing"
    next
  end

  html = read(path)
  errors << "#{locale}: html language is wrong" unless html.match?(%r{<html\s+lang="#{language}"})
  errors << "#{locale}: canonical is wrong" unless html.scan(%(<link rel="canonical" href="#{canonical}"/>)).size == 1
  expected_alternates = [["az", AZ_URL], ["ru", RU_URL], ["x-default", AZ_URL]]
  alternates = html.scan(%r{<link rel="alternate" hreflang="([^"]+)" href="([^"]+)"\s*/?>})
  errors << "#{locale}: hreflang set is wrong" unless alternates == expected_alternates
  errors << "#{locale}: page must contain exactly one H1" unless html.scan(/<h1\b/i).size == 1
  errors << "#{locale}: full model name is missing" unless html.include?("CFORCE C6 PRO TOURING")
  errors << "#{locale}: confirmed 16,900 AZN preorder price is missing" unless html.match?(/16(?:,|\s)900 AZN/)
  errors << "#{locale}: preorder language is missing" unless html.match?(preorder_text)
  errors << "#{locale}: accessory gift is missing" unless html.match?(gift_text)
  errors << "#{locale}: WhatsApp sales number is missing" unless html.include?("994512332484")
  errors << "#{locale}: C6 stylesheet is missing" unless html.include?("/assets/cforce-c6-pro-v1.css")
  errors << "#{locale}: model identifier is missing" unless html.include?('data-model="cforce-c6-pro"')
  errors << "#{locale}: finance content must not be advertised before confirmation" if html.include?('id="odenis"') || html.include?("Kredit kalkulyatoru")
  errors << "#{locale}: configurator must not claim unverified C6 accessories" if html.include?("aksesuar-konfiquratoru/?model=cforce-c6-pro")
  errors << "#{locale}: VAT inclusion must not be claimed without confirmation" if html.match?(/Ön sifariş qiyməti.{0,20}ƏDV daxil|Цена по предзаказу.{0,20}НДС включён/i)
  errors << "#{locale}: a remote product image is hotlinked" if html.match?(%r{<img[^>]+src="https?://}i)

  begin
    products = product_nodes(html)
    errors << "#{locale}: expected exactly one Product schema" unless products.size == 1
    products.each do |product|
      offer = product["offers"]
      errors << "#{locale}: Product model is wrong" unless product["model"] == "CFORCE C6 PRO TOURING"
      errors << "#{locale}: Product SKU is wrong" unless product["sku"] == SLUG
      errors << "#{locale}: Product brand is wrong" unless product.dig("brand", "name") == "CFMOTO"
      errors << "#{locale}: Product offer price must be 16900 AZN" unless offer.is_a?(Hash) && offer["price"].to_s == "16900" && offer["priceCurrency"] == "AZN"
      errors << "#{locale}: Product availability must be PreOrder" unless offer.is_a?(Hash) && offer["availability"] == "https://schema.org/PreOrder"
      errors << "#{locale}: campaign end date must not be invented" if offer.is_a?(Hash) && (offer.key?("priceValidUntil") || offer.key?("validFrom"))
    end
  rescue JSON::ParserError => error
    errors << "#{locale}: invalid structured data (#{error.message})"
  end
end

az_path = pages.dig("AZ", 0)
if File.file?(az_path)
  az = read(az_path)
  {
    "engine" => "647 cc",
    "power" => "54 a.g.",
    "torque" => "57 Nm",
    "clearance" => "320 mm",
    "fuel tank" => "24 L",
    "display" => "6,2 düymlük MMI",
    "regional disclaimer" => "Kanada bazarı üçün rəsmi spesifikasiyadan götürülüb"
  }.each do |label, text|
    errors << "AZ: #{label} is missing" unless az.include?(text)
  end
end

ru_path = pages.dig("RU", 0)
if File.file?(ru_path)
  ru = read(ru_path)
  {
    "drive system" => "Система привода",
    "differential lock" => "электронная блокировка дифференциала",
    "electronic selector" => "<dd>Электронный</dd>",
    "touring seat" => "Двухместное сиденье Touring",
    "fuel tank unit" => "<dd>24 л</dd>",
    "technology heading" => "Технологии",
    "model year" => "Модельный год"
  }.each do |label, text|
    errors << "RU: #{label} translation is missing" unless ru.include?(text)
  end

  %w[sistemi diferensial kilidi Texnologiya].each do |text|
    errors << "RU: Azerbaijani text leaked into the technical table (#{text})" if ru.include?(text)
  end
  errors << "RU: untranslated electronic selector leaked" if ru.include?("<dd>Elektron</dd>")
  errors << "RU: untranslated Touring seat leaked" if ru.include?("2 nəfərlik Touring")
  errors << "RU: untranslated model-year label leaked" if ru.include?("Model ili")
  errors << "RU: preorder-and-gift meta description is missing" unless ru.match?(%r{<meta name="description" content="[^"]*предзаказ в Азербайджане за 16 900 AZN[^"]*аксессуар в подарок})
  whatsapp_links = ru.scan(%r{href="(https://wa\.me/994512332484\?text=[^"]+)"}).flatten
  errors << "RU: C6-specific WhatsApp preorder message is missing" if whatsapp_links.empty? || whatsapp_links.any? { |link| !link.include?("CFORCE+C6+PRO") || !link.include?("16+900+AZN") }
end

{
  "AZ home" => File.join(ROOT, "index.html"),
  "RU home" => File.join(ROOT, "ru", "index.html")
}.each do |label, path|
  next errors << "#{label}: page is missing" unless File.file?(path)

  html = read(path)
  expected_cards = PUBLISHED ? 8 : 50
  errors << "#{label}: expected #{expected_cards} model cards" unless html.scan('class="model-card"').size == expected_cards
  card_pattern = %r{<article class="model-card">(?:(?!</article>).)*href="/(?:ru/)?model/cforce-c6-pro/"(?:(?!</article>).)*</article>}m
  errors << "#{label}: C6 homepage card must appear exactly once" unless html.scan(card_pattern).size == 1
  errors << "#{label}: C6 card image is missing" unless html.include?("/models/cards/cforce-c6-pro.webp")
  atv_count = label.start_with?("AZ") ? %r{<span>Kvadrosikl</span><small>10<!-- --> model</small>} : %r{<span>Квадроцикл</span><small>10<!-- --> моделей</small>}
  errors << "#{label}: mega-menu ATV count must be 10" unless html.match?(atv_count)
end

menu_bundles = Dir.glob(File.join(ROOT, "assets", "ProductMegaMenu-*.js"))
{
  "AZ catalogue bundle" => menu_bundles.reject { |path| File.basename(path).include?("Russian") },
  "RU catalogue bundle" => menu_bundles.select { |path| File.basename(path).include?("Russian") }
}.each do |label, paths|
  matching = paths.select { |path| read(path).include?('slug:`cforce-c6-pro`') }
  errors << "#{label}: C6 data record is missing" if matching.empty?
  matching.each do |path|
    record = read(path)[%r{\{slug:`cforce-c6-pro`,[^{}]+\}}]
    errors << "#{label}: malformed C6 record in #{File.basename(path)}" unless record
    next unless record
    errors << "#{label}: C6 price is wrong in #{File.basename(path)}" unless record.include?("price:16900")
    errors << "#{label}: C6 must be excluded from the confirmed-finance calculator" unless record.include?("financeEligible:!1")
    errors << "#{label}: C6 image is wrong" unless record.include?("image:`/models/cforce-c6-pro.webp`")
  end
end

required_assets = %w[
  models/cforce-c6-pro.webp
  models/cards/cforce-c6-pro.webp
  gallery/cforce-c6-pro-side.webp
  gallery/cforce-c6-pro-display.webp
  gallery/cforce-c6-pro-storage.webp
  gallery/cforce-c6-pro-design.webp
  assets/cforce-c6-pro-v1.css
]
required_assets.each do |relative|
  path = File.join(ROOT, relative)
  errors << "Missing or empty C6 asset: #{relative}" unless File.file?(path) && File.size(path) > (relative.end_with?(".css") ? 1_000 : 10_000)
end

c6_css_path = File.join(ROOT, "assets", "cforce-c6-pro-v1.css")
if File.file?(c6_css_path)
  c6_css = read(c6_css_path)
  errors << "C6 hero image background must be pure white" unless c6_css.include?('.product-image-wrap{isolation:isolate;background:#fff}')
  errors << "C6 hero image background decoration must be disabled" unless c6_css.include?('.product-image-wrap:after{display:none}')
  errors << "C6 hero image must not retain the blue-grey gradient" if c6_css.include?("#dce9ec")
end

sitemap_path = File.join(ROOT, "sitemap.xml")
if File.file?(sitemap_path)
  [AZ_URL, RU_URL].each do |url|
    entry = read(sitemap_path)[%r{<url><loc>#{Regexp.escape(url)}</loc>.*?</url>}m]
    errors << "Sitemap entry is missing for #{url}" unless entry
    next unless entry
    errors << "Sitemap lastmod is wrong for #{url}" unless entry.include?("<lastmod>2026-10-31</lastmod>")
    errors << "Sitemap alternates are incomplete for #{url}" unless entry.include?(%(hreflang="az" href="#{AZ_URL}")) && entry.include?(%(hreflang="ru" href="#{RU_URL}")) && entry.include?(%(hreflang="x-default" href="#{AZ_URL}"))
  end
else
  errors << "Sitemap is missing"
end

if errors.empty?
  puts "CFORCE C6 PRO audit passed: localized preorder pages, 16,900 AZN offer, gift disclaimer, official assets, PreOrder schema and sitemap"
else
  warn errors.join("\n")
  exit 1
end
