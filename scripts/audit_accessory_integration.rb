#!/usr/bin/env ruby

require_relative "domain_config"

ROOT = File.expand_path("..", __dir__)
PAGE = File.join(ROOT, "aksesuar-konfiquratoru", "index.html")
CANONICAL = "https://cfmoto.az/aksesuar-konfiquratoru/"
GA4_MEASUREMENT_ID = DomainConfig::GA4_MEASUREMENT_ID
ANALYTICS_START = "<!-- CFMOTO:ANALYTICS:START -->"
ANALYTICS_END = "<!-- CFMOTO:ANALYTICS:END -->"
errors = []

def read(path)
  File.read(path, encoding: "UTF-8")
end

errors << "Missing configurator page" unless File.file?(PAGE)
errors << "Missing accessory image directory" unless Dir.exist?(File.join(ROOT, "accessories"))

if File.file?(PAGE)
  page = read(PAGE)
  errors << "Configurator canonical is missing" unless page.include?(%(<link rel="canonical" href="#{CANONICAL}"/>))
  errors << "Configurator must not publish hreflang without an equivalent locale page" if page.match?(%r{<link rel="alternate"\b}i) || page.include?('\\"hrefLang\\"')
  errors << "Configurator must expose exactly one H1" unless page.scan(/<h1\b/i).size == 1
  errors << "Configurator loading-shell H1 is missing" unless page.include?('<main class="loading-shell"><h1>CFMOTO Aksesuar Konfiquratoru</h1>')
  errors << "Configurator persistent SEO heading must remain H2" unless page.include?('<h2 id="configurator-seo-title">') && page.include?('[\\"$\\",\\"h2\\",null,{\\"id\\":\\"configurator-seo-title\\"')
  errors << "Configurator title is missing" unless page.include?("CFMOTO Aksesuar Konfiquratoru: Moto, ATV və Buggy | CFMOTO Azerbaijan")
  errors << "Configurator must contain one GA4 analytics block" unless page.scan(ANALYTICS_START).size == 1 && page.scan(ANALYTICS_END).size == 1
  ga4_loader_ids = page.scan(%r{googletagmanager\.com/gtag/js\?id=(G-[A-Z0-9]+)}).flatten
  ga4_config_ids = page.scan(/gtag\('config','(G-[A-Z0-9]+)'\)/).flatten
  errors << "Configurator GA4 loader must use only #{GA4_MEASUREMENT_ID}" unless ga4_loader_ids == [GA4_MEASUREMENT_ID]
  errors << "Configurator GA4 configuration must use only #{GA4_MEASUREMENT_ID}" unless ga4_config_ids == [GA4_MEASUREMENT_ID]
  errors << "GTM is missing from configurator" unless page.include?("GTM-W9877TBG")
  errors << "Configurator still contains a duplicate direct Meta Pixel loader" if page.include?("connect.facebook.net/en_US/fbevents.js")
  errors << "Configurator still contains a duplicate direct Meta Pixel init" if page.include?("fbq('init','1395135232664282')")
  errors << "Configurator still contains a duplicate direct Meta Pixel PageView" if page.include?("fbq('track','PageView')")
  errors << "Configurator still contains a duplicate Meta Pixel noscript request" if page.include?("facebook.com/tr?id=1395135232664282")
  errors << "Model preselection script is missing from configurator" unless page.include?("/assets/accessory-model-preselect-v2.js")
  errors << "Stale model preselection script remains in configurator" if page.include?("/assets/accessory-model-preselect-v1.js")
  errors << "Legacy ChatGPT site origin leaked" if page.include?("cfmoto-azerbaycan-aksesuar.dvhqpbbkmw.chatgpt.site")

  page.scan(%r{(?:src|href)="(/aksesuar-konfiquratoru/_next/[^"?#]+)"}).flatten.uniq.each do |url|
    local = File.join(ROOT, url.delete_prefix("/"))
    errors << "Missing configurator bundle: #{url}" unless File.file?(local)
  end

  app_bundle_paths = Dir.glob(File.join(ROOT, "aksesuar-konfiquratoru", "_next", "static", "chunks", "app", "page-*.js"))
  app_has_h1 = app_bundle_paths.any? do |path|
    bundle = read(path)
    bundle.include?(')("h1",{children:[') && bundle.include?("CFMOTO-nu")
  end
  errors << "Configurator client bundle is missing its hydrated H1" unless app_has_h1
end

Dir.glob(File.join(ROOT, "aksesuar-konfiquratoru", "**", "*.{html,txt}"), File::FNM_EXTGLOB).each do |path|
  content = read(path)
  errors << "#{path.delete_prefix("#{ROOT}/")}: direct Meta Pixel source remains outside GTM" if content.match?(/connect\.facebook\.net\/en_US\/fbevents\.js|fbq\('(?:init|track)'|facebook\.com\/tr\?id=1395135232664282/)
end

accessory_images = Dir.glob(File.join(ROOT, "accessories", "**", "*")).count { |path| File.file?(path) }
errors << "Expected at least 300 accessory images, found #{accessory_images}" if accessory_images < 300

home = read(File.join(ROOT, "index.html"))
errors << "AZ homepage promo is missing" unless home.include?('class="accessory-promo section"')
errors << "AZ homepage sales hero CTA is missing" unless home.include?('class="button accessory-hero-button"')
errors << "AZ homepage configurator link is missing" unless home.scan('href="/aksesuar-konfiquratoru/"').size >= 3
errors << "AZ homepage accessory stylesheet is missing" unless home.include?('/assets/accessory-entry-v1.css')
errors << "AZ homepage cache-busted bundle is missing" unless home.include?('/assets/page-CfmotoAccessoryV15.js')
errors << "AZ homepage cache-busted app loader is missing" unless home.scan('/assets/index-CfmotoAccessoryV15.js').size >= 2

ru_home = read(File.join(ROOT, "ru", "index.html"))
errors << "RU homepage configurator link is missing" unless ru_home.scan('href="/aksesuar-konfiquratoru/"').size >= 2

home_bundle = read(File.join(ROOT, "assets", "page-CfmotoAccessoryV15.js"))
app_loader = read(File.join(ROOT, "assets", "index-CfmotoAccessoryV15.js"))
errors << "AZ hydrated promo is missing" unless home_bundle.include?('className:`accessory-promo section`')
errors << "AZ hydrated sales hero CTA is missing" unless home_bundle.include?('button accessory-hero-button')
errors << "AZ hydrated navigation link is missing" unless home_bundle.include?('[`Aksesuarlar`,`/aksesuar-konfiquratoru/`]')
errors << "AZ app loader does not load cache-busted home bundle" unless app_loader.include?('assets/page-CfmotoAccessoryV15.js')
errors << "AZ app loader still references stale home bundle" if app_loader.include?('page-CfmotoFinanceFixV12.js')
%w[
  layout-segment-context-CfmotoAccessoryV15.js
  link-CfmotoAccessoryV15.js
  router-CfmotoAccessoryV15.js
  ProductMegaMenu-CfmotoAccessoryV15.js
].each do |asset|
  errors << "Missing cache-busted dependency: #{asset}" unless File.file?(File.join(ROOT, "assets", asset))
end
errors << "AZ app loader still references stale layout" if app_loader.include?('layout-segment-context-CfmotoPolicyFixV10.js')
errors << "AZ app loader still references stale link" if app_loader.include?('link-CfmotoPolicyFixV10.js')
errors << "AZ app loader still references stale mega menu" if app_loader.include?('ProductMegaMenu-CfmotoPolicyFixV10.js')

ru_bundle_path = Dir.glob(File.join(ROOT, "assets", "page-CfmotoRussianV*.js")).max
errors << "Russian home bundle is missing" unless ru_bundle_path
if ru_bundle_path
  ru_bundle = read(ru_bundle_path)
  errors << "RU hydrated navigation link is missing" unless ru_bundle.include?('[`Аксессуары`,`/aksesuar-konfiquratoru/`]')
end

sitemap = read(File.join(ROOT, "sitemap.xml"))
errors << "Configurator sitemap URL must appear once" unless sitemap.scan("<loc>#{CANONICAL}</loc>").size == 1
configurator_sitemap_entry = sitemap[%r{<url><loc>#{Regexp.escape(CANONICAL)}</loc>.*?</url>}m]
errors << "Configurator sitemap entry must not publish hreflang" if configurator_sitemap_entry&.include?("xhtml:link")

errors << "Missing configurator entry stylesheet" unless File.file?(File.join(ROOT, "assets", "accessory-entry-v1.css"))
errors << "Missing model preselection script" unless File.file?(File.join(ROOT, "assets", "accessory-model-preselect-v2.js"))

offroad_slugs = %w[
  cforce-c4
  cforce-c5
  cforce1000-mv
  cforce1000-touring
  cforce-850-touring
  cforce625eps-touring
  cforce-520-l
  goes-terrox-400l
  cforce-110-high
  z10-4
  z10
  u10-xl-pro
  uforce-1000-xl
  zforce-950-sport-4
  zforce-1000-sport-r
  zforce-800-trail
  uforce-600
  u10-pro
].freeze

model_pages = Dir.glob(File.join(ROOT, "model", "*", "index.html"))
errors << "Expected 48 model pages, found #{model_pages.size}" unless model_pages.size == 48
missing_offroad_pages = offroad_slugs.reject { |slug| File.file?(File.join(ROOT, "model", slug, "index.html")) }
errors << "Missing off-road model pages: #{missing_offroad_pages.join(', ')}" unless missing_offroad_pages.empty?

model_pages.each do |path|
  slug = File.basename(File.dirname(path))
  html = read(path)
  if slug == "500sr"
    errors << "500sr: enquiry-only page must not expose an unverified accessory deep link" if html.include?('/aksesuar-konfiquratoru/?model=500sr')
    errors << "500sr: accessory stylesheet is missing" unless html.include?('/assets/accessory-entry-v1.css')
    next
  end
  deep_link = "/aksesuar-konfiquratoru/?model=#{slug}&bike=0&lock=1"
  errors << "#{slug}: desktop accessory CTA is missing" unless html.include?(%(class="button accessory-model-cta" href="#{deep_link}"))
  errors << "#{slug}: mobile accessory CTA is missing" unless html.include?(%(<div class="model-mobile-cta"><a href="#{deep_link}">Aksesuar seç</a>))
  errors << "#{slug}: accessory stylesheet is missing" unless html.include?('/assets/accessory-entry-v1.css')
  errors << "#{slug}: cache-busted app loader is missing" unless html.scan('/assets/index-CfmotoAccessoryV15.js').size >= 2
  errors << "#{slug}: stale immutable app loader remains" if html.include?('/assets/index-CfmotoPolicyFixV10.js')
  errors << "#{slug}: cache-busted layout is missing" unless html.include?('/assets/layout-segment-context-CfmotoAccessoryV15.js')
  errors << "#{slug}: cache-busted link module is missing" unless html.include?('/assets/link-CfmotoAccessoryV15.js')
  errors << "#{slug}: cache-busted mega menu is missing" unless html.include?('/assets/ProductMegaMenu-CfmotoAccessoryV15.js')
end

{
  "kvadrosikl" => ["cforce-c4", "ATV aksesuarlarını seç"],
  "buggy" => ["z10", "Buggy / UTV aksesuarlarını seç"]
}.each do |category, (model, label)|
  path = File.join(ROOT, category, "index.html")
  unless File.file?(path)
    errors << "#{category}: category page is missing"
    next
  end
  html = read(path)
  deep_link = "/aksesuar-konfiquratoru/?model=#{model}&bike=0#models"
  cta = %(<a class="button primary accessory-category-cta" href="#{deep_link}">#{label}</a>)
  errors << "#{category}: configurator category CTA is missing" unless html.include?(cta)
end

preselect = File.join(ROOT, "assets", "accessory-model-preselect-v2.js")
if File.file?(preselect)
  preselect_source = read(preselect)
  errors << "Model preselection must prefer data-model-id" unless preselect_source.include?('button[data-model-id]') && preselect_source.include?('candidate.dataset.modelId === slug')
end
errors << "Broken legacy 450SR gallery reference remains" if Dir.glob(File.join(ROOT, "aksesuar-konfiquratoru", "_next", "**", "*.js")).any? { |path| read(path).include?("/gallery/450sr-s.webp") }

headers = read(File.join(ROOT, "_headers"))
errors << "Configurator bundles are missing immutable cache policy" unless headers.include?("/aksesuar-konfiquratoru/_next/*")
errors << "Accessory images are missing cache policy" unless headers.include?("/accessories/*")

abort "Accessory integration audit failed:\n- #{errors.join("\n- ")}" unless errors.empty?

puts "Accessory integration audit passed: #{accessory_images} images, sales hero, #{model_pages.size - 1} verified model deep links (#{offroad_slugs.size} off-road), 1 enquiry-only model, 2 category entry points, SEO and analytics"
