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

configurator_bundle_path = File.join(ROOT, "aksesuar-konfiquratoru", "_next", "static", "chunks", "app", "page-cfmoto-review-v1.js")
configurator_css_path = File.join(ROOT, "aksesuar-konfiquratoru", "_next", "static", "css", "cfmoto-configurator-review-v1.css")
configurator_runtime_path = File.join(ROOT, "aksesuar-konfiquratoru", "_next", "static", "chunks", "238-cfmoto-review-v1.js")
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
  errors << "Commercial fitment copy is missing" unless bundle.include?("Uyğunluq, mövcudluq və yekun qiymət")
  errors << "750SR-S clean image is missing" unless bundle.include?("/models/750sr-s-clean.webp")
  errors << "750SR-S orange badge markup is missing" unless bundle.include?("simple-model-new-badge")
  errors << "Adventure families were not merged" if bundle.include?('family:"Adventure Touring"') || bundle.include?('family:"Touring"')
  errors << "750SR-S Azerbaijani accessory copy is missing" unless bundle.include?("Radiator qoruyucusu") && bundle.include?("Qızdırılan sükan tutacaqları")
else
  errors << "Cache-busted configurator page bundle is missing"
end
errors << "Cache-busted configurator stylesheet is missing" unless File.file?(configurator_css_path)
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
