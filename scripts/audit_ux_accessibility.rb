#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "category_config"
require_relative "content_config"

ROOT = File.expand_path("..", __dir__)
STYLE_URL = "/assets/ux-accessibility-v1.css"
SCRIPT_URL = "/assets/mobile-menu-accessibility-v2.js"
errors = []

def read(path)
  File.read(path, encoding: "UTF-8")
end

az_paths = [File.join(ROOT, "index.html")]
az_paths.concat(ContentConfig::SLUGS.map { |slug| File.join(ROOT, slug, "index.html") })
az_paths.concat(CategoryConfig::SLUGS.map { |slug| File.join(ROOT, slug, "index.html") })
az_paths.concat(Dir.glob(File.join(ROOT, "model", "*", "index.html")))
ru_paths = Dir.glob(File.join(ROOT, "ru", "**", "index.html"))
page_paths = (az_paths + ru_paths).uniq.select { |path| File.file?(path) }
home_paths = [File.join(ROOT, "index.html"), File.join(ROOT, "ru", "index.html")]

page_paths.each do |path|
  html = read(path)
  errors << "#{path}: UX stylesheet must appear once" unless html.scan(STYLE_URL).size == 1
end

home_paths.each do |path|
  html = read(path)
  errors << "#{path}: mobile menu script must appear once" unless html.scan(SCRIPT_URL).size == 1
end

css_path = File.join(ROOT, STYLE_URL.delete_prefix("/"))
js_path = File.join(ROOT, SCRIPT_URL.delete_prefix("/"))
errors << "Missing UX stylesheet" unless File.file?(css_path)
errors << "Missing mobile menu script" unless File.file?(js_path)

if File.file?(css_path)
  css = read(css_path)
  errors << "RU mobile hero sizing rule is missing" unless css.include?('html[lang="ru"] .category-hero-title')
  errors << "Mobile filter sizing rule is missing" unless css.include?(".filter-row button")
  errors << "Language focus ring is missing" unless css.include?(".language-switcher a:focus-visible")
  errors << "Readable 12px calculator labels are missing" unless css.include?("font-size: 12px")
end

if File.file?(js_path)
  javascript = read(js_path)
  errors << "Mobile menu Escape support is missing" unless javascript.include?('event.key !== "Escape"')
  errors << "Mobile menu focus transfer is missing" unless javascript.include?("firstItem?.focus")
  errors << "Mobile menu aria-controls wiring is missing" unless javascript.include?('setAttribute("aria-controls"')
end

configurator_path = File.join(ROOT, "aksesuar-konfiquratoru", "index.html")
if File.file?(configurator_path)
  configurator = read(configurator_path)
  forbidden = [
    "1,9-a vurulub",
    "DMS/Benelux",
    "The stainless steel material",
    "Changes the vehicle's style",
    "PC material in smoky grey",
    "5-level heating controlled",
    "Anodized black aviation-grade",
    "Protects the engine surface",
    "Carbon-steel mounting base"
  ]
  forbidden.each do |copy|
    errors << "Configurator still exposes unlocalized/internal copy: #{copy}" if configurator.include?(copy)
  end
end

configurator_bundle_path = File.join(ROOT, "aksesuar-konfiquratoru", "_next", "static", "chunks", "app", "page-cfmoto-offroad-partsazn-v5.js")
configurator_css_path = File.join(ROOT, "aksesuar-konfiquratoru", "_next", "static", "css", "cfmoto-configurator-offroad-partsazn-v4.css")
configurator_runtime_path = File.join(ROOT, "aksesuar-konfiquratoru", "_next", "static", "chunks", "238-cfmoto-offroad-partsazn-v3.js")
if File.file?(configurator_bundle_path)
  bundle = read(configurator_bundle_path)
  forbidden = [
    "1,9-a vurulub",
    "DMS/Benelux",
    "The stainless steel material",
    "Changes the vehicle's style",
    "PC material in smoky grey",
    "5-level heating controlled",
    "Anodized black aviation-grade",
    "Protects the engine surface",
    "Carbon-steel mounting base"
  ]
  forbidden.each do |copy|
    errors << "Configurator bundle still exposes unlocalized/internal copy: #{copy}" if bundle.include?(copy)
  end
  fitment_copy_present = bundle.include?("Uyğunluq, mövcudluq və yekun qiymət") ||
    bundle.include?('Uyğunluq, m\\xf6vcudluq və yekun qiymət')
  errors << "Commercial fitment copy is missing" unless fitment_copy_present
  errors << "750SR-S clean image is missing" unless bundle.include?("/models/750sr-s-clean.webp")
  errors << "750SR-S orange badge markup is missing" unless bundle.include?("simple-model-new-badge")
  errors << "Adventure/Touring UI grouping is missing" unless bundle.include?("Adventure / Touring")
  errors << "750SR-S Azerbaijani accessory copy is missing" unless bundle.include?("Radiator qoruyucusu") && bundle.include?("Qızdırılan sükan tutacaqları")
  errors << "CFMOTO USA off-road source label is missing" unless bundle.include?("CFMOTO USA 2027 Off-Road Accessories")
  errors << "CFMoto USA Parts price source is missing" unless bundle.include?("CFMoto USA Parts")
  errors << "Official USD/AZN conversion disclosure is missing" unless bundle.include?("1 USD = 1.7000 AZN")
  errors << "USD/AZN conversion rate data is missing" unless bundle.include?('"D7":1.7')
  errors << "ZFORCE 950 Sport-4 shop price/source is missing" unless bundle.include?("5BYV-804300-6000") &&
    bundle.include?("159.99") &&
    bundle.include?("cfmotousaparts.com/product/sport-a-arm-guard-cfmoto-oem-5byv-804300-6000")
  errors << "Query-only fallback is missing" unless bundle.include?("5BYV-809100-8000") &&
    bundle.include?("cfmotousaparts.com/?s=5BYV-809100-8000&post_type=product") &&
    (bundle.include?("Sorğu ilə") || bundle.include?('Sor\u011fu il\u0259'))
  errors << "Legacy 1:1 MSRP pricing remains" if bundle.include?("valyuta çevrilmədən 1:1 AZN") ||
    bundle.include?('valyuta \\xe7evrilmədən 1:1 AZN')
  errors << "Third-party price source link remains in accessory cards" if bundle.include?('children:"Qiymət mənbəyi ↗"')
  errors << "Third-party source link remains in the accessory detail dialog" if bundle.include?('className:"accessory-detail-source"')
  errors << "Verbose accessory price note is still rendered" if bundle.include?('P.priceNote&&(0,o.jsx)("em",{children:P.priceNote})')
  errors << "Missing-price shop message remains in the configurator" if bundle.include?("mağazasında bu SKU")
  {
    "5DYV-809600-1001" => "lighted-whip mounting bracket",
    "5HYV-800100-1000" => "Work Orb Light",
    "Work Orb Light" => "work light",
    "VISION X" => "Vision X lighting",
    "DURA MINI" => "Dura Mini lighting"
  }.each do |forbidden_light, label|
    errors << "Off-road lighting product leaked into configurator: #{label}" if bundle.include?(forbidden_light)
  end
else
  errors << "Cache-busted configurator page bundle is missing"
end
if File.file?(configurator_css_path)
  configurator_css = read(configurator_css_path)
  errors << "Mobile accessory names still truncate" unless configurator_css.include?("cfmoto-mobile-accessory-name-v2") &&
    configurator_css.include?("white-space:normal!important") &&
    configurator_css.include?("text-overflow:clip!important")
  errors << "DMS source prices are not hidden from product photos" unless configurator_css.include?("cfmoto-dms-price-redaction-v1") &&
    configurator_css.include?('img[src*="dms-offroad"]{clip-path:inset(10% 0 0 0)}')
else
  errors << "Cache-busted configurator stylesheet is missing"
end
if File.file?(configurator_runtime_path)
  runtime = read(configurator_runtime_path)
  errors << "Configurator CSR hydration filter is missing" unless runtime.include?("Minified React error #418|Hydration failed")
else
  errors << "Cache-busted configurator runtime is missing"
end

Dir.glob(File.join(ROOT, "aksesuar-konfiquratoru", "**", "*.html")).each do |path|
  errors << "#{path}: stale configurator runtime reference" if read(path).include?("238-9a08ade5f423d52d.js")
end

abort "UX/accessibility audit failed:\n- #{errors.join("\n- ")}" unless errors.empty?

puts "UX/accessibility audit passed: #{page_paths.size} localized pages, mobile menu, filter, focus, readable labels and configurator copy"
