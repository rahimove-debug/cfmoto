#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

ROOT = File.expand_path("..", __dir__)
SLUG = "zeeho-ez4"
AZ_URL = "https://cfmoto.az/model/#{SLUG}/"
RU_URL = "https://cfmoto.az/ru/model/#{SLUG}/"
IMAGE_CACHE_VERSION = "20261027-2"
VERSIONED_MODEL_IMAGES = %w[
  /models/zeeho-ez4.webp
  /models/cards/zeeho-ez4.webp
  /gallery/zeeho-ez4-ergonomics.webp
  /gallery/zeeho-ez4-practicality.webp
  /gallery/zeeho-ez4-storage.webp
].map { |url| "#{url}?v=#{IMAGE_CACHE_VERSION}" }.freeze
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
  "AZ" => [File.join(ROOT, "model", SLUG, "index.html"), "az", AZ_URL],
  "RU" => [File.join(ROOT, "ru", "model", SLUG, "index.html"), "ru", RU_URL]
}

pages.each do |locale, (path, language, canonical)|
  unless File.file?(path)
    errors << "#{locale}: EZ4 page is missing"
    next
  end

  html = read(path)
  errors << "#{locale}: html language is wrong" unless html.match?(%r{<html\s+lang="#{language}"})
  errors << "#{locale}: canonical is wrong" unless html.scan(%(<link rel="canonical" href="#{canonical}"/>)).size == 1
  expected_alternates = [
    ["az", AZ_URL],
    ["ru", RU_URL],
    ["x-default", AZ_URL]
  ]
  alternates = html.scan(%r{<link rel="alternate" hreflang="([^"]+)" href="([^"]+)"\s*/?>})
  errors << "#{locale}: hreflang set is wrong" unless alternates == expected_alternates
  errors << "#{locale}: page must contain exactly one H1" unless html.scan(/<h1\b/i).size == 1
  errors << "#{locale}: model name is missing" unless html.include?("ZEEHO EZ4")
  errors << "#{locale}: confirmed 2,890 AZN price is missing" unless html.include?("2,890 AZN")
  errors << "#{locale}: cache-versioned EZ4 stylesheet is missing" unless html.include?("/assets/zeeho-ez4-model-v1.css?v=#{IMAGE_CACHE_VERSION}")
  errors << "#{locale}: standalone finance calculator is missing" unless html.include?('id="odenis"') && html.include?('data-ez4-finance') && html.include?('data-price="2890"')
  errors << "#{locale}: internal finance must start at 40%" unless html.include?('data-down type="range" min="40"')
  errors << "#{locale}: bank finance must allow 10% down and 36 months" unless html.include?('data-bank-term type="range" min="3" max="36"')
  errors << "#{locale}: EZ4 finance script is missing" unless html.match?(%r{/assets/ez4-finance-v1(?:-sales-[a-f0-9]{12})?\.js})
  accessory_link = '/aksesuar-konfiquratoru/?model=zeeho-ez4&amp;bike=0&amp;lock=1'
  errors << "#{locale}: accessory enquiry deep link is missing" unless html.scan(accessory_link).size >= 2
  errors << "#{locale}: accessory enquiry CTA is missing" unless html.include?('accessory-model-cta') && html.include?('/assets/accessory-entry-v1.css')
  VERSIONED_MODEL_IMAGES.each do |image_url|
    errors << "#{locale}: cache-versioned EZ4 image is missing: #{image_url}" unless html.include?(image_url)
  end
  errors << "#{locale}: a remote ZEEHO image is hotlinked" if html.match?(%r{<img[^>]+src="https?://[^"]*zeehoev\.com}i)
  errors << "#{locale}: a Pro/Max-only hero or dashboard asset is present" if html.match?(/ez4-(?:hero|dashboard)/i)

  begin
    products = product_nodes(html)
    errors << "#{locale}: expected exactly one Product schema" unless products.size == 1
    products.each do |product|
      offer = product["offers"]
      errors << "#{locale}: Product brand must be ZEEHO" unless product.dig("brand", "name") == "ZEEHO"
      errors << "#{locale}: Product model must be EZ4" unless product["model"] == "EZ4"
      errors << "#{locale}: Product SKU must be ZH1300DT-3" unless product["sku"] == "ZH1300DT-3"
      errors << "#{locale}: Product offer price must be 2890 AZN" unless offer.is_a?(Hash) && offer["price"].to_s == "2890" && offer["priceCurrency"] == "AZN"
      errors << "#{locale}: stock availability must not be invented" if offer.is_a?(Hash) && offer.key?("availability")
    end
  rescue JSON::ParserError => error
    errors << "#{locale}: invalid structured data (#{error.message})"
  end
end

az_page = pages.dig("AZ", 0)
if File.file?(az_page)
  az = read(az_page)
  {
    "nominal power" => "1,3 kW",
    "peak power" => "2,4 kW",
    "battery" => "72 V · 23 Ah",
    "maximum speed" => "≥ 53 km/saat",
    "range" => "≥ 63 km",
    "base-model LCD" => "6,2 düym LCD",
    "ABS/CBS caution" => "Standart EZ4 üçün ABS və ya CBS istehsalçı spesifikasiyasında göstərilmir."
  }.each do |label, text|
    errors << "AZ: #{label} is missing" unless az.include?(text)
  end
  errors << "AZ: base EZ4 must not be marketed with a TFT display" if az.match?(/EZ4.{0,80}TFT|TFT.{0,80}EZ4/i)
end

required_images = %w[
  models/zeeho-ez4.webp
  models/cards/zeeho-ez4.webp
  gallery/zeeho-ez4-ergonomics.webp
  gallery/zeeho-ez4-practicality.webp
  gallery/zeeho-ez4-storage.webp
]
required_images.each do |relative|
  path = File.join(ROOT, relative)
  errors << "Missing EZ4 image: #{relative}" unless File.file?(path) && File.size(path) > 10_000
end

{
  "AZ home" => File.join(ROOT, "index.html"),
  "RU home" => File.join(ROOT, "ru", "index.html")
}.each do |label, path|
  next errors << "#{label}: page is missing" unless File.file?(path)

  html = read(path)
  errors << "#{label}: expected 50 model cards" unless html.scan('class="model-card"').size == 50
  errors << "#{label}: EZ4 home card must appear exactly once" unless html.scan(%r{<article class="model-card">(?:(?!</article>).)*href="/(?:ru/)?model/zeeho-ez4/"(?:(?!</article>).)*</article>}m).size == 1
  errors << "#{label}: EZ4 mega-menu link must appear exactly once" unless html.scan(%r{<a href="/(?:ru/)?model/zeeho-ez4/" class="mega-model"}).size == 1
  errors << "#{label}: cache-versioned EZ4 card image is missing" unless html.include?("/models/cards/zeeho-ez4.webp?v=#{IMAGE_CACHE_VERSION}")
end

{
  "AZ motorcycle category" => File.join(ROOT, "motosiklet", "index.html"),
  "RU motorcycle category" => File.join(ROOT, "ru", "motocikly", "index.html")
}.each do |label, path|
  next errors << "#{label}: page is missing" unless File.file?(path)

  html = read(path)
  errors << "#{label}: EZ4 category card must appear exactly once" unless html.scan(%r{<article class="category-model-card">(?:(?!</article>).)*href="/(?:ru/)?model/zeeho-ez4/"(?:(?!</article>).)*</article>}m).size == 1
  errors << "#{label}: cache-versioned EZ4 category image is missing" unless html.include?("/models/cards/zeeho-ez4.webp?v=#{IMAGE_CACHE_VERSION}")
end

{
  "AZ comparison" => File.join(ROOT, "model-muqayisesi", "index.html"),
  "RU comparison" => File.join(ROOT, "ru", "sravnenie-modeley", "index.html")
}.each do |label, path|
  next errors << "#{label}: page is missing" unless File.file?(path)

  html = read(path)
  row = html[%r{<tr>(?:(?!</tr>).)*href="/(?:ru/)?model/zeeho-ez4/"(?:(?!</tr>).)*</tr>}m]
  errors << "#{label}: EZ4 comparison row is missing" unless row
  if row
    errors << "#{label}: EZ4 must use 40% internal down payment" unless row.include?("40%")
    expected_term = label.start_with?("AZ") ? "18 ayadək" : "до 18 мес."
    errors << "#{label}: EZ4 must allow internal finance up to 18 months" unless row.include?(expected_term)
  end
end

menu_bundles = Dir.glob(File.join(ROOT, "assets", "ProductMegaMenu-*.js"))
az_menu = menu_bundles.reject { |path| File.basename(path).include?("Russian") }
ru_menu = menu_bundles.select { |path| File.basename(path).include?("Russian") }
{
  "AZ catalogue bundle" => az_menu,
  "RU catalogue bundle" => ru_menu
}.each do |label, paths|
  matching = paths.select { |path| read(path).include?('slug:`zeeho-ez4`') }
  errors << "#{label}: EZ4 data record is missing" if matching.empty?
  matching.each do |path|
    source = read(path)
    record = source[%r{\{slug:`zeeho-ez4`,[^{}]+\}}]
    errors << "#{label}: malformed EZ4 record in #{File.basename(path)}" unless record
    next unless record
    errors << "#{label}: EZ4 price/finance state is wrong in #{File.basename(path)}" unless record.include?("price:2890") && record.include?("financeEligible:true")
    errors << "#{label}: EZ4 image is not cache-versioned in #{File.basename(path)}" unless record.include?("image:`/models/zeeho-ez4.webp?v=#{IMAGE_CACHE_VERSION}`")
  end
end

style_path = File.join(ROOT, "assets", "zeeho-ez4-model-v1.css")
if File.file?(style_path)
  style = read(style_path)
  errors << "EZ4 banner image is not cache-versioned" unless style.include?("/gallery/zeeho-ez4-ergonomics.webp?v=#{IMAGE_CACHE_VERSION}")
else
  errors << "EZ4 stylesheet is missing"
end

finance_bundles = Dir.glob(File.join(ROOT, "assets", "page-*.js"))
finance_filtered = finance_bundles.select { |path| read(path).include?("e.financeEligible!==false") }
errors << "Homepage finance eligibility filter is missing" if finance_filtered.empty?

redirects_path = File.join(ROOT, "_redirects")
if File.file?(redirects_path)
  redirects = read(redirects_path)
  errors << "Legacy /ez4 redirect is missing" unless redirects.lines.any? { |line| line.strip == "/ez4 /model/zeeho-ez4/ 301" }
  errors << "Canonical alias /zeeho-ez4 redirect is missing" unless redirects.lines.any? { |line| line.strip == "/zeeho-ez4 /model/zeeho-ez4/ 301" }
else
  errors << "Redirect file is missing"
end

sitemap_path = File.join(ROOT, "sitemap.xml")
if File.file?(sitemap_path)
  sitemap = read(sitemap_path)
  [AZ_URL, RU_URL].each do |url|
    entry = sitemap[%r{<url><loc>#{Regexp.escape(url)}</loc>.*?</url>}m]
    errors << "Sitemap entry is missing for #{url}" unless entry
    next unless entry
    errors << "Sitemap lastmod is wrong for #{url}" unless entry.include?("<lastmod>2026-10-27</lastmod>")
    errors << "Sitemap alternates are incomplete for #{url}" unless entry.include?(%(hreflang="az" href="#{AZ_URL}")) && entry.include?(%(hreflang="ru" href="#{RU_URL}")) && entry.include?(%(hreflang="x-default" href="#{AZ_URL}"))
  end
else
  errors << "Sitemap is missing"
end

if errors.empty?
  puts "ZEEHO EZ4 audit passed: AZ/RU pages, 2,890 AZN price, official base-model specs and images, catalogue/category placement, SEO, 40% finance and accessory enquiry"
else
  warn errors.map { |error| "- #{error}" }.join("\n")
  exit 1
end
