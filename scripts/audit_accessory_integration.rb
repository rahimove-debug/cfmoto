#!/usr/bin/env ruby

ROOT = File.expand_path("..", __dir__)
PAGE = File.join(ROOT, "aksesuar-konfiquratoru", "index.html")
CANONICAL = "https://cfmoto.az/aksesuar-konfiquratoru/"
errors = []

def read(path)
  File.read(path, encoding: "UTF-8")
end

errors << "Missing configurator page" unless File.file?(PAGE)
errors << "Missing accessory image directory" unless Dir.exist?(File.join(ROOT, "accessories"))

if File.file?(PAGE)
  page = read(PAGE)
  errors << "Configurator canonical is missing" unless page.include?(%(<link rel="canonical" href="#{CANONICAL}"/>))
  errors << "Configurator az-AZ hreflang is missing" unless page.include?(%(hrefLang="az-AZ" href="#{CANONICAL}"))
  errors << "Configurator x-default hreflang is missing" unless page.include?(%(hrefLang="x-default" href="#{CANONICAL}"))
  errors << "Configurator title is missing" unless page.include?("CFMOTO Aksesuar Konfiquratoru | CFMOTO Azerbaijan")
  errors << "GTM is missing from configurator" unless page.include?("GTM-W9877TBG")
  errors << "Meta Pixel is missing from configurator" unless page.include?("1395135232664282")
  errors << "Model preselection script is missing from configurator" unless page.include?("/assets/accessory-model-preselect-v1.js")
  errors << "Legacy ChatGPT site origin leaked" if page.include?("cfmoto-azerbaycan-aksesuar.dvhqpbbkmw.chatgpt.site")

  page.scan(%r{(?:src|href)="(/aksesuar-konfiquratoru/_next/[^"?#]+)"}).flatten.uniq.each do |url|
    local = File.join(ROOT, url.delete_prefix("/"))
    errors << "Missing configurator bundle: #{url}" unless File.file?(local)
  end
end

accessory_images = Dir.glob(File.join(ROOT, "accessories", "**", "*")).count { |path| File.file?(path) }
errors << "Expected at least 300 accessory images, found #{accessory_images}" if accessory_images < 300

home = read(File.join(ROOT, "index.html"))
errors << "AZ homepage promo is missing" unless home.include?('class="accessory-promo section"')
errors << "AZ homepage sales hero CTA is missing" unless home.include?('class="button accessory-hero-button"')
errors << "AZ homepage configurator link is missing" unless home.scan('href="/aksesuar-konfiquratoru/"').size >= 3
errors << "AZ homepage accessory stylesheet is missing" unless home.include?('/assets/accessory-entry-v1.css')

ru_home = read(File.join(ROOT, "ru", "index.html"))
errors << "RU homepage configurator link is missing" unless ru_home.scan('href="/aksesuar-konfiquratoru/"').size >= 2

home_bundle = read(File.join(ROOT, "assets", "page-CfmotoFinanceFixV11.js"))
errors << "AZ hydrated promo is missing" unless home_bundle.include?('className:`accessory-promo section`')
errors << "AZ hydrated sales hero CTA is missing" unless home_bundle.include?('button accessory-hero-button')
errors << "AZ hydrated navigation link is missing" unless home_bundle.include?('[`Aksesuarlar`,`/aksesuar-konfiquratoru/`]')

ru_bundle_path = Dir.glob(File.join(ROOT, "assets", "page-CfmotoRussianV*.js")).max
errors << "Russian home bundle is missing" unless ru_bundle_path
if ru_bundle_path
  ru_bundle = read(ru_bundle_path)
  errors << "RU hydrated navigation link is missing" unless ru_bundle.include?('[`Аксессуары`,`/aksesuar-konfiquratoru/`]')
end

sitemap = read(File.join(ROOT, "sitemap.xml"))
errors << "Configurator sitemap URL must appear once" unless sitemap.scan("<loc>#{CANONICAL}</loc>").size == 1

errors << "Missing configurator entry stylesheet" unless File.file?(File.join(ROOT, "assets", "accessory-entry-v1.css"))
errors << "Missing model preselection script" unless File.file?(File.join(ROOT, "assets", "accessory-model-preselect-v1.js"))

motorcycle_pages = Dir.glob(File.join(ROOT, "model", "*", "index.html")).select do |path|
  read(path).include?('"category":"Motosiklet')
end
errors << "Expected 29 motorcycle model pages, found #{motorcycle_pages.size}" unless motorcycle_pages.size == 29
motorcycle_pages.each do |path|
  slug = File.basename(File.dirname(path))
  html = read(path)
  deep_link = "/aksesuar-konfiquratoru/?model=#{slug}#models"
  errors << "#{slug}: desktop accessory CTA is missing" unless html.include?(%(class="button accessory-model-cta" href="#{deep_link}"))
  errors << "#{slug}: mobile accessory CTA is missing" unless html.include?(%(<div class="model-mobile-cta"><a href="#{deep_link}">Aksesuar seç</a>))
  errors << "#{slug}: accessory stylesheet is missing" unless html.include?('/assets/accessory-entry-v1.css')
end
errors << "Broken legacy 450SR gallery reference remains" if Dir.glob(File.join(ROOT, "aksesuar-konfiquratoru", "_next", "**", "*.js")).any? { |path| read(path).include?("/gallery/450sr-s.webp") }

headers = read(File.join(ROOT, "_headers"))
errors << "Configurator bundles are missing immutable cache policy" unless headers.include?("/aksesuar-konfiquratoru/_next/*")
errors << "Accessory images are missing cache policy" unless headers.include?("/accessories/*")

abort "Accessory integration audit failed:\n- #{errors.join("\n- ")}" unless errors.empty?

puts "Accessory integration audit passed: #{accessory_images} images, sales hero, #{motorcycle_pages.size} model deep links, SEO and analytics"
