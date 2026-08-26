#!/usr/bin/env ruby
require "fileutils"
require_relative "domain_config"

ROOT = File.expand_path("..", __dir__)
ASSETS = File.join(ROOT, "assets")

OLD_RUNTIME = "index-WBfaOMAt.js"
PREVIOUS_RUNTIME = "index-CfmotoAug24.js"
CURRENT_RUNTIME = "index-CfmotoAug24Fix.js"
LAST_RUNTIME = "index-CfmotoMobileFix.js"
CURRENT_V2_RUNTIME = "index-CfmotoMobileFixV2.js"
CURRENT_V3_RUNTIME = "index-CfmotoMobileFixV3.js"
CURRENT_V4_RUNTIME = "index-CfmotoMobilePerfV4.js"
CURRENT_V5_RUNTIME = "index-CfmotoPolicyFixV5.js"
CURRENT_V6_RUNTIME = "index-CfmotoPolicyFixV6.js"
CURRENT_V7_RUNTIME = "index-CfmotoPolicyFixV7.js"
CURRENT_V8_RUNTIME = "index-CfmotoPolicyFixV8.js"
CURRENT_V9_RUNTIME = "index-CfmotoPolicyFixV9.js"
NEW_RUNTIME = "index-CfmotoPolicyFixV10.js"
OLD_HOME_BUNDLE = "page-DZgbTvch.js"
PREVIOUS_HOME_BUNDLE = "page-CfmotoAug24.js"
CURRENT_HOME_BUNDLE = "page-CfmotoAug24Fix.js"
LAST_HOME_BUNDLE = "page-CfmotoMobileFix.js"
CURRENT_V2_HOME_BUNDLE = "page-CfmotoMobileFixV2.js"
CURRENT_V3_HOME_BUNDLE = "page-CfmotoMobileFixV3.js"
CURRENT_V4_HOME_BUNDLE = "page-CfmotoMobilePerfV4.js"
CURRENT_V5_HOME_BUNDLE = "page-CfmotoPolicyFixV5.js"
CURRENT_V6_HOME_BUNDLE = "page-CfmotoPolicyFixV6.js"
CURRENT_V7_HOME_BUNDLE = "page-CfmotoPolicyFixV7.js"
CURRENT_V8_HOME_BUNDLE = "page-CfmotoPolicyFixV8.js"
CURRENT_V9_HOME_BUNDLE = "page-CfmotoPolicyFixV9.js"
CURRENT_V10_HOME_BUNDLE = "page-CfmotoPolicyFixV10.js"
NEW_HOME_BUNDLE = "page-CfmotoFinanceFixV11.js"
OLD_MENU_BUNDLE = "ProductMegaMenu-Cpx-ytn3.js"
PREVIOUS_MENU_BUNDLE = "ProductMegaMenu-CfmotoAug24.js"
CURRENT_MENU_BUNDLE = "ProductMegaMenu-CfmotoAug24Fix.js"
CURRENT_V3_MENU_BUNDLE = "ProductMegaMenu-CfmotoMobileFixV3.js"
CURRENT_V4_MENU_BUNDLE = "ProductMegaMenu-CfmotoMobilePerfV4.js"
CURRENT_V5_MENU_BUNDLE = "ProductMegaMenu-CfmotoPolicyFixV5.js"
CURRENT_V6_MENU_BUNDLE = "ProductMegaMenu-CfmotoPolicyFixV6.js"
CURRENT_V7_MENU_BUNDLE = "ProductMegaMenu-CfmotoPolicyFixV7.js"
CURRENT_V8_MENU_BUNDLE = "ProductMegaMenu-CfmotoPolicyFixV8.js"
CURRENT_V9_MENU_BUNDLE = "ProductMegaMenu-CfmotoPolicyFixV9.js"
NEW_MENU_BUNDLE = "ProductMegaMenu-CfmotoPolicyFixV10.js"
CURRENT_STYLESHEET = "index-DiLMqMiY.css"
LAST_STYLESHEET = "index-CfmotoMobileFix.css"
CURRENT_V2_STYLESHEET = "index-CfmotoMobileFixV2.css"
CURRENT_V3_STYLESHEET = "index-CfmotoMobileFixV3.css"
CURRENT_V4_STYLESHEET = "index-CfmotoMobilePerfV4.css"
CURRENT_V5_STYLESHEET = "index-CfmotoPolicyFixV5.css"
CURRENT_V6_STYLESHEET = "index-CfmotoPolicyFixV6.css"
CURRENT_V7_STYLESHEET = "index-CfmotoPolicyFixV7.css"
CURRENT_V8_STYLESHEET = "index-CfmotoPolicyFixV8.css"
CURRENT_V9_STYLESHEET = "index-CfmotoPolicyFixV9.css"
NEW_STYLESHEET = "index-CfmotoPolicyFixV10.css"
NEW_LINK_BUNDLE = "link-CfmotoPolicyFixV10.js"
NEW_MODEL_COLOR_BUNDLE = "ModelColorSelector-CfmotoPolicyFixV10.js"
CURRENT_V10_MODEL_FINANCE_BUNDLE = "ModelFinance-CfmotoPolicyFixV10.js"
NEW_MODEL_FINANCE_BUNDLE = "ModelFinance-CfmotoFinanceFixV11.js"

RUNTIME_SOURCES = [OLD_RUNTIME, PREVIOUS_RUNTIME, CURRENT_RUNTIME, LAST_RUNTIME, CURRENT_V2_RUNTIME, CURRENT_V3_RUNTIME, CURRENT_V4_RUNTIME, CURRENT_V5_RUNTIME, CURRENT_V6_RUNTIME, CURRENT_V7_RUNTIME, CURRENT_V8_RUNTIME, CURRENT_V9_RUNTIME].freeze
HOME_BUNDLE_SOURCES = [OLD_HOME_BUNDLE, PREVIOUS_HOME_BUNDLE, CURRENT_HOME_BUNDLE, LAST_HOME_BUNDLE, CURRENT_V2_HOME_BUNDLE, CURRENT_V3_HOME_BUNDLE, CURRENT_V4_HOME_BUNDLE, CURRENT_V5_HOME_BUNDLE, CURRENT_V6_HOME_BUNDLE, CURRENT_V7_HOME_BUNDLE, CURRENT_V8_HOME_BUNDLE, CURRENT_V9_HOME_BUNDLE, CURRENT_V10_HOME_BUNDLE].freeze
MENU_BUNDLE_SOURCES = [OLD_MENU_BUNDLE, PREVIOUS_MENU_BUNDLE, CURRENT_MENU_BUNDLE, CURRENT_V3_MENU_BUNDLE, CURRENT_V4_MENU_BUNDLE, CURRENT_V5_MENU_BUNDLE, CURRENT_V6_MENU_BUNDLE, CURRENT_V7_MENU_BUNDLE, CURRENT_V8_MENU_BUNDLE, CURRENT_V9_MENU_BUNDLE].freeze

CLEAN_IMAGE_SLUGS = %w[1000mt-x 750sr-s cforce-c4 cforce1000-touring].freeze
PRODUCT_BADGE_HTML = '<span class="product-badge">Yeni</span>'
PRODUCT_BADGE_RSC_UNSET = %q{\"className\":\"product-image-wrap\",\"children\":[\"$undefined\",[}
PRODUCT_BADGE_RSC_NEW = %q{\"className\":\"product-image-wrap\",\"children\":[[\"$\",\"span\",null,{\"className\":\"product-badge\",\"children\":\"Yeni\"}],[}
DIRECTORY_CONTENT_PATHS = %w[kredit servis zemanet ehtiyat-hisseleri model-muqayisesi].freeze

INTERNAL_20_SLUGS = %w[
  125nk 150sc 250cl-c 250dual 250nk 250sr-fun 300nk 300sr aura-150
  cflite-230-dual papio-xo 450sr
].freeze
INTERNAL_20_MODEL_NAMES = [
  "125NK", "150SC", "250CL-C", "CFMOTO 250DUAL", "250NK", "250SR FUN",
  "300NK", "300SR", "AURA 150", "CFLITE 230 DUAL", "PAPIO XO", "450SR"
].freeze
INTERNAL_40_MOTORCYCLE_SLUGS = %w[
  1000mt-x 800mt-explore 800mt-sport 800mt-x 800nk-advanced 750sr-s
  700cl-x-sport 700mt 675sr-r 675nk 500sr-voom 450cl-c-bobber 450cl-c
  450cl-c-amt 450sr-s 450mt 450nk
].freeze

INSTALLMENT_INTEREST_RATES = {
  6 => 0.08,
  12 => 0.15,
  18 => 0.23
}.freeze
HOME_CALCULATOR_NOTE = "Daxili ödəniş faizləri: 6 ay 8%, 12 ay 15%, 18 ay 23%. Bank şərtləri ayrıca hesablanır."
OLD_HOME_CALCULATOR_NOTE = "Hesablama məlumat xarakterlidir; bank faizi və komissiyalar daxil deyil. Yekun şərtlər fərqlənə bilər."
MODEL_CALCULATOR_NOTE = "Daxili ödəniş faizi: 6 ay 8%, 12 ay 15%, 18 ay 23%. Yekun şərtlər satış mütəxəssisi tərəfindən təsdiqlənir."
OLD_MODEL_CALCULATOR_NOTE = "Yekun şərtlər satış mütəxəssisi tərəfindən təsdiqlənir."

ORIGINAL_FINANCE_POLICY_COPY = "Motosikletlər üçün daxili hissəli ödəniş 20% ilkin ödənişlə 18 ayadək, ATV və buggy üçün 50% ilkin ödənişlə 12 ayadək. Bank krediti 10%-dən başlayır və 35 ayadək mümkündür."
PREVIOUS_FINANCE_POLICY_COPY = "Mühərrik həcmi 300 cc-dək olan motosikletlər və 450SR üçün daxili hissəli ödəniş 20% ilkin ödənişlə, digər motosikletlər üçün 50% ilkin ödənişlə 18 ayadək. ATV və buggy üçün 50% ilkin ödənişlə 12 ayadək. Bank krediti 10%-dən başlayır və 35 ayadək mümkündür."
NEW_FINANCE_POLICY_COPY = "Mühərrik həcmi 300 cc-dək olan motosikletlər və 450SR üçün daxili hissəli ödəniş 20% ilkin ödənişlə, digər motosikletlər üçün 40% ilkin ödənişlə 18 ayadək. ATV və buggy üçün 50% ilkin ödənişlə 12 ayadək. Bank krediti 10%-dən başlayır və 35 ayadək mümkündür."
FINANCE_POLICY_COPIES = [
  ORIGINAL_FINANCE_POLICY_COPY,
  PREVIOUS_FINANCE_POLICY_COPY,
  NEW_FINANCE_POLICY_COPY
].freeze

SERVICE_BASE_COPY = "CFMOTO standartlarına uyğun diaqnostika, texniki qulluq və təmir."
SERVICE_HOURS_COPY = "Bazar ertəsi xaric hər gün 10:00–19:00."
SERVICE_PHONE = "+994102414299"
SERVICE_PHONE_DISPLAY = "+994 10 241 42 99"
SHOWROOM_MAP_URL = "https://maps.app.goo.gl/onFPjWTaXRN92rDfA"
INSTAGRAM_URL = DomainConfig::INSTAGRAM_URL
LOGO_WIDTH = 159
LOGO_HEIGHT = 34
MOBILE_CREDIT_ID = "kredit-kalkulyator"
MOBILE_CREDIT_CSS_MARKER = "/* CFMOTO:MOBILE-CREDIT */"
MOBILE_CREDIT_CSS = <<~CSS.strip
  #{MOBILE_CREDIT_CSS_MARKER}
  .calc-top-link{display:none}
  @media (width<=860px){html{scroll-behavior:auto}##{MOBILE_CREDIT_ID}{scroll-margin-top:18px}}
  @media (width<=580px){.finance{gap:24px}.finance>.calculator{order:-1}.calculator{padding:20px 16px}.calc-title{margin-bottom:14px}.calc-title span{font-size:20px}.mode-switch{margin-bottom:14px}.mode-switch button{min-height:36px;font-size:12px}.calculator>label{margin-bottom:12px}.calculator select{padding:10px 12px}.range-line{margin:11px 0 4px}.calc-result{margin:14px 0 10px;padding:15px}.calc-result strong{font-size:32px}.calc-top-link{border:1px solid var(--line);min-height:40px;color:var(--copy);justify-content:center;align-items:center;margin-top:12px;font-size:12px;display:flex}}
CSS
MOBILE_PERFORMANCE_CSS_MARKER = "/* CFMOTO:MOBILE-PERFORMANCE */"
MOBILE_PERFORMANCE_CSS = <<~CSS.strip
  #{MOBILE_PERFORMANCE_CSS_MARKER}
  @media (width<=860px){.category-hero-panel:not(.active){background-image:none!important}}
CSS
MOBILE_DOM_CSS_MARKER = "/* CFMOTO:MOBILE-DOM-PERFORMANCE */"
MOBILE_DOM_CSS = <<~CSS.strip
  #{MOBILE_DOM_CSS_MARKER}
  .mega-menu:not(.open){display:none}.mega-menu.open{display:block}
  @media (width<=580px){.site-header,.category-hero-featured{-webkit-backdrop-filter:none;backdrop-filter:none}.model-card{content-visibility:auto;contain-intrinsic-size:auto 430px}}
CSS
MOBILE_CATEGORY_CSS_MARKER = "/* CFMOTO:MOBILE-CATEGORY-BACKGROUNDS */"
MOBILE_CATEGORY_CSS = <<~CSS.strip
  #{MOBILE_CATEGORY_CSS_MARKER}
  @media (width<=860px){.category-panel.motorcycles{background-image:url(/official-800mtx-hero-mobile.jpg)}.category-panel.offroad{background-image:url(/models/z10-4-mobile.jpg)}}
CSS
MOBILE_CATEGORY_IMAGES = %w[
  official-800mtx-hero-mobile.jpg
  models/z10-4-mobile.jpg
].freeze

SUPPORT_ASSET_SOURCES = {
  ["rolldown-runtime-S-ySWqyJ.js", "rolldown-runtime-CfmotoAug24.js", "rolldown-runtime-CfmotoAug24Fix.js", "rolldown-runtime-CfmotoMobileFixV3.js", "rolldown-runtime-CfmotoMobilePerfV4.js", "rolldown-runtime-CfmotoPolicyFixV5.js", "rolldown-runtime-CfmotoPolicyFixV6.js", "rolldown-runtime-CfmotoPolicyFixV7.js", "rolldown-runtime-CfmotoPolicyFixV8.js", "rolldown-runtime-CfmotoPolicyFixV9.js"] => "rolldown-runtime-CfmotoPolicyFixV10.js",
  ["framework-CXnKph_e.js", "framework-CfmotoAug24.js", "framework-CfmotoAug24Fix.js", "framework-CfmotoMobileFixV3.js", "framework-CfmotoMobilePerfV4.js", "framework-CfmotoPolicyFixV5.js", "framework-CfmotoPolicyFixV6.js", "framework-CfmotoPolicyFixV7.js", "framework-CfmotoPolicyFixV8.js", "framework-CfmotoPolicyFixV9.js"] => "framework-CfmotoPolicyFixV10.js",
  ["layout-segment-context-BqNUFdFf.js", "layout-segment-context-CfmotoAug24.js", "layout-segment-context-CfmotoAug24Fix.js", "layout-segment-context-CfmotoMobileFixV3.js", "layout-segment-context-CfmotoMobilePerfV4.js", "layout-segment-context-CfmotoPolicyFixV5.js", "layout-segment-context-CfmotoPolicyFixV6.js", "layout-segment-context-CfmotoPolicyFixV7.js", "layout-segment-context-CfmotoPolicyFixV8.js", "layout-segment-context-CfmotoPolicyFixV9.js"] => "layout-segment-context-CfmotoPolicyFixV10.js",
  ["link-IATORi5E.js", "link-CfmotoAug24.js", "link-CfmotoAug24Fix.js", "link-CfmotoMobileFixV3.js", "link-CfmotoMobilePerfV4.js", "link-CfmotoPolicyFixV5.js", "link-CfmotoPolicyFixV6.js", "link-CfmotoPolicyFixV7.js", "link-CfmotoPolicyFixV8.js", "link-CfmotoPolicyFixV9.js"] => NEW_LINK_BUNDLE,
  ["router-CzKeCzcA.js", "router-CfmotoAug24.js", "router-CfmotoAug24Fix.js", "router-CfmotoMobileFixV3.js", "router-CfmotoMobilePerfV4.js", "router-CfmotoPolicyFixV5.js", "router-CfmotoPolicyFixV6.js", "router-CfmotoPolicyFixV7.js", "router-CfmotoPolicyFixV8.js", "router-CfmotoPolicyFixV9.js"] => "router-CfmotoPolicyFixV10.js",
  ["ModelFinance-QyWdpaDg.js", "ModelFinance-CfmotoAug24.js", "ModelFinance-CfmotoAug24Fix.js", "ModelFinance-CfmotoMobileFixV3.js", "ModelFinance-CfmotoMobilePerfV4.js", "ModelFinance-CfmotoPolicyFixV5.js", "ModelFinance-CfmotoPolicyFixV6.js", "ModelFinance-CfmotoPolicyFixV7.js", "ModelFinance-CfmotoPolicyFixV8.js", "ModelFinance-CfmotoPolicyFixV9.js", CURRENT_V10_MODEL_FINANCE_BUNDLE] => NEW_MODEL_FINANCE_BUNDLE,
  ["ModelGallery-BT140N7z.js", "ModelGallery-CfmotoAug24.js", "ModelGallery-CfmotoAug24Fix.js", "ModelGallery-CfmotoMobileFixV3.js", "ModelGallery-CfmotoMobilePerfV4.js", "ModelGallery-CfmotoPolicyFixV5.js", "ModelGallery-CfmotoPolicyFixV6.js", "ModelGallery-CfmotoPolicyFixV7.js", "ModelGallery-CfmotoPolicyFixV8.js", "ModelGallery-CfmotoPolicyFixV9.js"] => "ModelGallery-CfmotoPolicyFixV10.js",
  ["ModelSpecs-BJB4gaLM.js", "ModelSpecs-CfmotoAug24.js", "ModelSpecs-CfmotoAug24Fix.js", "ModelSpecs-CfmotoMobileFixV3.js", "ModelSpecs-CfmotoMobilePerfV4.js", "ModelSpecs-CfmotoPolicyFixV5.js", "ModelSpecs-CfmotoPolicyFixV6.js", "ModelSpecs-CfmotoPolicyFixV7.js", "ModelSpecs-CfmotoPolicyFixV8.js", "ModelSpecs-CfmotoPolicyFixV9.js"] => "ModelSpecs-CfmotoPolicyFixV10.js",
  ["ModelColorSelector-DIxmErfw.js", "ModelColorSelector-CfmotoAug24.js", "ModelColorSelector-CfmotoAug24Fix.js", "ModelColorSelector-CfmotoMobileFixV3.js", "ModelColorSelector-CfmotoMobilePerfV4.js", "ModelColorSelector-CfmotoPolicyFixV5.js", "ModelColorSelector-CfmotoPolicyFixV6.js", "ModelColorSelector-CfmotoPolicyFixV7.js", "ModelColorSelector-CfmotoPolicyFixV8.js", "ModelColorSelector-CfmotoPolicyFixV9.js"] => NEW_MODEL_COLOR_BUNDLE
}.freeze

PRIMARY_ASSET_SOURCES = {
  RUNTIME_SOURCES => NEW_RUNTIME,
  HOME_BUNDLE_SOURCES => NEW_HOME_BUNDLE,
  MENU_BUNDLE_SOURCES => NEW_MENU_BUNDLE
}.freeze

ASSET_SOURCE_GROUPS = SUPPORT_ASSET_SOURCES.merge(PRIMARY_ASSET_SOURCES).freeze
ASSET_RENAMES = ASSET_SOURCE_GROUPS.each_with_object({}) do |(sources, target), renames|
  sources.each { |source| renames[source] = target }
end
ASSET_RENAMES[CURRENT_STYLESHEET] = NEW_STYLESHEET
ASSET_RENAMES[LAST_STYLESHEET] = NEW_STYLESHEET
ASSET_RENAMES[CURRENT_V2_STYLESHEET] = NEW_STYLESHEET
ASSET_RENAMES[CURRENT_V3_STYLESHEET] = NEW_STYLESHEET
ASSET_RENAMES[CURRENT_V4_STYLESHEET] = NEW_STYLESHEET
ASSET_RENAMES[CURRENT_V5_STYLESHEET] = NEW_STYLESHEET
ASSET_RENAMES[CURRENT_V6_STYLESHEET] = NEW_STYLESHEET
ASSET_RENAMES[CURRENT_V7_STYLESHEET] = NEW_STYLESHEET
ASSET_RENAMES[CURRENT_V8_STYLESHEET] = NEW_STYLESHEET
ASSET_RENAMES[CURRENT_V9_STYLESHEET] = NEW_STYLESHEET
ASSET_RENAMES.freeze

def read_utf8(path)
  File.read(path, encoding: "UTF-8")
end

def write_utf8(path, content)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content, encoding: "UTF-8")
end

def update_asset(source_names, new_name)
  source_names = Array(source_names)
  new_path = File.join(ASSETS, new_name)
  source = (source_names + [new_name])
    .map { |name| File.join(ASSETS, name) }
    .find { |path| File.file?(path) }
  abort "Missing required asset: #{(source_names + [new_name]).join(', ')}" unless source

  content = read_utf8(source)
  yield content
  write_utf8(new_path, content)
  source_names.each do |name|
    path = File.join(ASSETS, name)
    FileUtils.rm_f(path) unless path == new_path
  end
end

def normalize_service_schedule!(content)
  base = Regexp.escape(SERVICE_BASE_COPY)
  hours = Regexp.escape(SERVICE_HOURS_COPY)
  content.gsub!(/#{base}(?: #{hours})*/, "#{SERVICE_BASE_COPY} #{SERVICE_HOURS_COPY}")
end

def remove_unused_font_preloads!(content)
  content.gsub!(%r{<link\s+rel="preload"\s+href="/assets/_vinext_fonts/[^"]+"\s+as="font"\s+type="font/woff2"\s+crossorigin\s*/>\s*}i, "")
end

def remove_unused_vinext_font_css!(content)
  content.gsub!(%r{<style\s+data-vinext-fonts>.*?</style>}m, "")
end

def primary_model_image_source(slug)
  suffix = CLEAN_IMAGE_SLUGS.include?(slug) ? "-clean" : ""
  "/models/#{slug}#{suffix}.webp"
end

def card_model_image_source(slug)
  primary_model_image_source(slug).sub("/models/", "/models/cards/")
end

def use_clean_model_data_images!(content)
  CLEAN_IMAGE_SLUGS.each do |slug|
    original = "image:`/models/#{slug}.webp`"
    cleaned = "image:`#{primary_model_image_source(slug)}`"
    unless content.include?(cleaned)
      abort "#{slug}: model data image anchor not found" unless content.include?(original)
      content.gsub!(original, cleaned)
    end

    entry_pattern = %r!\{slug:`#{Regexp.escape(slug)}`,[^{}]+\}!
    entries = content.scan(entry_pattern)
    abort "#{slug}: model data badge anchor not found" if entries.empty?
    content.gsub!(entry_pattern) do |entry|
      entry.include?('badge:`Yeni`') ? entry : entry.sub(/\}\z/, ',badge:`Yeni`}')
    end
  end
end

def use_clean_model_image_paths!(content)
  CLEAN_IMAGE_SLUGS.each do |slug|
    content.gsub!("/models/#{slug}.webp", primary_model_image_source(slug))
  end
end

def normalize_internal_directory_links!(content)
  content.gsub!(%r{href="/model/([^"/?#]+)/?"}) do
    %(href="/model/#{Regexp.last_match(1)}/")
  end
  content.gsub!('href:`/model/${e.slug}`', 'href:`/model/${e.slug}/`')

  DIRECTORY_CONTENT_PATHS.each do |path|
    content.gsub!(%(href="/#{path}"), %(href="/#{path}/"))
    content.gsub!(%(href:`/#{path}`), %(href:`/#{path}/`))
    content.gsub!(%Q{\\"href\\":\\"/#{path}\\"}, %Q{\\"href\\":\\"/#{path}/\\"})
  end
end

def localize_primary_model_image!(content, slug)
  source = content[/<img\s+class="model-color-image"\s+src="([^"]+)"/, 1]
  return unless source

  local_source = primary_model_image_source(slug)
  return if source == local_source

  abort "#{slug}: missing local primary model image" unless File.file?(File.join(ROOT, local_source.delete_prefix("/")))
  occurrences = content.scan(source).size
  if CLEAN_IMAGE_SLUGS.include?(slug)
    abort "#{slug}: expected at least 3 primary/model-data image references, found #{occurrences}" unless occurrences >= 3
  else
    abort "#{slug}: expected 3 primary image references, found #{occurrences}" unless occurrences == 3
  end

  content.gsub!(source, local_source)
end

def ensure_clean_model_product_badge!(content, slug)
  return unless CLEAN_IMAGE_SLUGS.include?(slug)

  product_wrap = '<div class="product-image-wrap">'
  unless content.include?("#{product_wrap}#{PRODUCT_BADGE_HTML}")
    abort "#{slug}: product image wrapper not found for Yeni badge" unless content.include?(product_wrap)
    content.sub!(product_wrap, "#{product_wrap}#{PRODUCT_BADGE_HTML}")
  end

  unless content.include?(PRODUCT_BADGE_RSC_NEW)
    abort "#{slug}: embedded product badge anchor not found" unless content.include?(PRODUCT_BADGE_RSC_UNSET)
    content.sub!(PRODUCT_BADGE_RSC_UNSET, PRODUCT_BADGE_RSC_NEW)
  end
end

def use_home_card_images!(content)
  content.gsub!(%r{<article class="model-card">.*?</article>}m) do |card|
    slug = card[%r{href="/model/([^"/]+)/?"}, 1]
    abort "Homepage model card is missing a slug" unless slug
    card_source = card_model_image_source(slug)
    abort "#{slug}: missing optimized card image" unless File.file?(File.join(ROOT, card_source.delete_prefix("/")))

    optimized = card.sub(%r{src="/models/[^"]+\.webp"}, %(src="#{card_source}"))
    optimized.gsub!(%r{\s+(?:decoding="async"|fetchpriority="low")}, "")
    optimized.sub!('loading="lazy"', 'loading="lazy" decoding="async" fetchpriority="low"')
    if CLEAN_IMAGE_SLUGS.include?(slug) && !optimized.include?('<span class="badge">Yeni</span>')
      optimized.sub!(%r{(<img\b[^>]+/>)}, '\1<span class="badge">Yeni</span>')
    end
    optimized
  end
end

def use_optimized_mega_menu_images!(content)
  content.gsub!(%r{<img src="/models/(?:cards/)?([^"/]+)\.webp" alt="([^"]+ rəsmi foto)" loading="lazy"(?: decoding="async" fetchpriority="low")?/>}) do
    slug = Regexp.last_match(1).delete_suffix("-clean")
    alt = Regexp.last_match(2)
    card_source = card_model_image_source(slug)
    abort "#{slug}: missing optimized mega-menu image" unless File.file?(File.join(ROOT, card_source.delete_prefix("/")))

    %(<img src="#{card_source}" alt="#{alt}" loading="lazy" decoding="async" fetchpriority="low"/>)
  end

  content.gsub!(%r{<a\b[^>]*href="/model/([^"/]+)/?"[^>]*class="mega-model"[^>]*>.*?</a>}m) do |item|
    slug = Regexp.last_match(1)
    next item unless CLEAN_IMAGE_SLUGS.include?(slug)
    next item if item.include?("<em>Yeni</em>")

    item.sub(%r{(<img\b[^>]+/>)}, '\1<em>Yeni</em>')
  end
end

def normalize_footer_links!(content)
  footer = content[%r{<footer>.*?</footer>}m]
  return unless footer

  links = footer[%r{<div>.*?</div>}m]
  abort "Footer link group not found" unless links
  replacement = %(<div><a href="/motosiklet/">Motosikletlər</a><a href="/kvadrosikl/">Kvadrosikllər</a><a href="/buggy/">Buggy və UTV</a><a href="/kredit/">Kredit</a><a href="/servis/">Servis</a><a href="/zemanet/">Zəmanət</a><a href="/ehtiyat-hisseleri/">Ehtiyat hissələri</a><a href="/model-muqayisesi/">Müqayisə</a><a href="#{INSTAGRAM_URL}" target="_blank" rel="noreferrer">Instagram</a></div>)
  return if links == replacement

  content.sub!(footer, footer.sub(links, replacement))
end

def normalize_embedded_footer_links!(content)
  source = %q{[\"$\",\"div\",null,{\"children\":[[\"$\",\"$L6\",null,{\"href\":\"/#modeller\",\"children\":\"Modellər\"}],[\"$\",\"$L6\",null,{\"href\":\"/#kredit\",\"children\":\"Kredit\"}],[\"$\",\"$L6\",null,{\"href\":\"/#servis\",\"children\":\"Servis\"}]]}]}
  previous = %q{[\"$\",\"div\",null,{\"children\":[[\"$\",\"$L6\",null,{\"href\":\"/motosiklet/\",\"children\":\"Motosikletlər\"}],[\"$\",\"$L6\",null,{\"href\":\"/kvadrosikl/\",\"children\":\"Kvadrosikllər\"}],[\"$\",\"$L6\",null,{\"href\":\"/buggy/\",\"children\":\"Buggy və UTV\"}],[\"$\",\"$L6\",null,{\"href\":\"/kredit\",\"children\":\"Kredit\"}],[\"$\",\"$L6\",null,{\"href\":\"/servis\",\"children\":\"Servis\"}],[\"$\",\"$L6\",null,{\"href\":\"/zemanet\",\"children\":\"Zəmanət\"}],[\"$\",\"$L6\",null,{\"href\":\"/ehtiyat-hisseleri\",\"children\":\"Ehtiyat hissələri\"}],[\"$\",\"$L6\",null,{\"href\":\"/model-muqayisesi\",\"children\":\"Müqayisə\"}]]}]}
  replacement = %q{[\"$\",\"div\",null,{\"children\":[[\"$\",\"$L6\",null,{\"href\":\"/motosiklet/\",\"children\":\"Motosikletlər\"}],[\"$\",\"$L6\",null,{\"href\":\"/kvadrosikl/\",\"children\":\"Kvadrosikllər\"}],[\"$\",\"$L6\",null,{\"href\":\"/buggy/\",\"children\":\"Buggy və UTV\"}],[\"$\",\"$L6\",null,{\"href\":\"/kredit/\",\"children\":\"Kredit\"}],[\"$\",\"$L6\",null,{\"href\":\"/servis/\",\"children\":\"Servis\"}],[\"$\",\"$L6\",null,{\"href\":\"/zemanet/\",\"children\":\"Zəmanət\"}],[\"$\",\"$L6\",null,{\"href\":\"/ehtiyat-hisseleri/\",\"children\":\"Ehtiyat hissələri\"}],[\"$\",\"$L6\",null,{\"href\":\"/model-muqayisesi/\",\"children\":\"Müqayisə\"}],[\"$\",\"a\",null,{\"href\":\"__INSTAGRAM_URL__\",\"target\":\"_blank\",\"rel\":\"noreferrer\",\"children\":\"Instagram\"}]]}]}.sub("__INSTAGRAM_URL__", INSTAGRAM_URL)
  return if content.include?(replacement)
  anchor = [previous, source].find { |candidate| content.include?(candidate) }
  return unless anchor

  content.gsub!(anchor, replacement)
end

def replace_required_once!(content, source, replacement, label)
  return if content.include?(replacement)

  abort "#{label} anchor not found" unless content.include?(source)
  content.sub!(source, replacement)
end

def replace_required_variant!(content, sources, replacement, label)
  return if content.include?(replacement)

  source = Array(sources).find { |candidate| content.include?(candidate) }
  abort "#{label} anchor not found" unless source
  content.sub!(source, replacement)
end

def rounded_amount(value)
  (value + 0.5).floor
end

def format_amount(value)
  value.to_i.to_s.reverse.scan(/.{1,3}/).join(",").reverse
end

def installment_total(principal, months)
  rate = INSTALLMENT_INTEREST_RATES.fetch(months)
  principal * (1 + rate)
end

def remove_home_finance_policy_copy!(content)
  FINANCE_POLICY_COPIES.each do |copy|
    content.gsub!(%(<p>#{copy}</p>), "")
    content.gsub!(%((0,c.jsx)(`p`,{children:`#{copy}`}),), "")
    abort "Home finance policy copy wrapper not found" if content.include?(copy)
  end
end

def apply_home_finance_policy!(home)
  calculator_pattern = %r{<div class="calculator"[^>]*>.*?<small class="calc-note">.*?</small><a class="calc-top-link".*?</a></div>}m
  original_calculator = home[calculator_pattern]
  abort "Home calculator fragment not found" unless original_calculator
  calculator = original_calculator.dup
  price = 11_990
  percent = 40
  down = format_amount(rounded_amount(price * percent / 100.0))
  principal = price * (100 - percent) / 100.0
  financed = format_amount(rounded_amount(installment_total(principal, 18)))
  monthly = format_amount(rounded_amount(installment_total(principal, 18) / 18))
  calculator.gsub!("Maliyyələşdirilən məbləğ", "Faiz daxil borc")
  calculator.gsub!(OLD_HOME_CALCULATOR_NOTE, HOME_CALCULATOR_NOTE)
  patterns = {
    "down-payment heading" => %r{(<div class="range-line"><label for="down">İlkin ödəniş</label><strong>)\d+(<!-- -->% · <!-- -->)[\d,]+(<!-- --> AZN</strong></div>)},
    "down-payment range" => %r{<input id="down" type="range" min="\d+" max="80" step="5" value="\d+"/>},
    "term range" => %r{<input id="term" type="range" min="\d+" max="18" step="\d+" value="18"/>},
    "monthly result" => %r{(<div class="calc-result"><span>Təxmini aylıq ödəniş</span><strong>)[\d,]+(<!-- --> <small>AZN / ay</small></strong>)},
    "financed result" => %r{(<p>Faiz daxil borc: <!-- -->)[\d,]+(<!-- --> AZN</p>)}
  }
  patterns.each do |label, pattern|
    abort "Home #{label} normalization anchor not found" unless calculator.match?(pattern)
  end
  calculator.sub!(patterns.fetch("down-payment heading")) do
    "#{Regexp.last_match(1)}#{percent}#{Regexp.last_match(2)}#{down}#{Regexp.last_match(3)}"
  end
  calculator.sub!(
    patterns.fetch("down-payment range"),
    %(<input id="down" type="range" min="#{percent}" max="80" step="5" value="#{percent}"/>))
  calculator.sub!(patterns.fetch("term range"), '<input id="term" type="range" min="6" max="18" step="6" value="18"/>')
  calculator.sub!(patterns.fetch("monthly result")) do
    "#{Regexp.last_match(1)}#{monthly}#{Regexp.last_match(2)}"
  end
  calculator.sub!(patterns.fetch("financed result")) do
    "#{Regexp.last_match(1)}#{financed}#{Regexp.last_match(2)}"
  end
  home.sub!(original_calculator, calculator)
end

def apply_model_finance_policy!(html, slug)
  return unless INTERNAL_40_MOTORCYCLE_SLUGS.include?(slug)

  [20, 50].each do |percent|
    html.gsub!(
      "Daxili ödəniş: #{percent}%-dən başlayan ilkin ödəniş",
      "Daxili ödəniş: 40%-dən başlayan ilkin ödəniş"
    )
  end
end

def normalize_model_finance_calculator!(html, slug)
  calculator_pattern = %r{<div class="model-calculator">.*?<small class="model-finance-note">.*?</small></div>}m
  original_calculator = html[calculator_pattern]
  abort "#{slug}: model calculator fragment not found for normalization" unless original_calculator
  calculator = original_calculator.dup

  price_match = calculator.match(%r{<small>Nağd alış qiyməti</small><strong>([\d,]+)<!-- --> AZN</strong>})
  abort "#{slug}: model cash price not found for normalization" unless price_match
  price = price_match[1].delete(",").to_i
  percent = if INTERNAL_20_SLUGS.include?(slug)
    20
  elsif INTERNAL_40_MOTORCYCLE_SLUGS.include?(slug)
    40
  else
    50
  end
  down = format_amount(rounded_amount(price * percent / 100.0))
  principal = price * (100 - percent) / 100.0
  financed = format_amount(rounded_amount(installment_total(principal, 12)))
  monthly = format_amount(rounded_amount(installment_total(principal, 12) / 12))
  calculator.gsub!('<button type="button" class="">3<!-- --> ay</button>', "")
  calculator.gsub!("Maliyyələşən məbləğ", "Faiz daxil borc")
  calculator.gsub!(OLD_MODEL_CALCULATOR_NOTE, MODEL_CALCULATOR_NOTE)

  patterns = {
    "down-payment heading" => %r{(<div class="model-calc-label"><span>İlkin ödəniş</span><strong>)\d+(<!-- -->% · <!-- -->)[\d,]+(<!-- --> AZN</strong></div>)},
    "down-payment range" => %r{<input aria-label="İlkin ödəniş faizi" type="range" min="\d+" max="80" step="5" value="\d+"/>},
    "down-payment scale" => %r{<span>minimum <!-- -->\d+<!-- -->%</span>},
    "monthly result" => %r{(<div class="model-calc-result"><span>Aylıq ödəniş</span><strong>)[\d,]+(<!-- --> <small>AZN / ay</small></strong>)},
    "down-payment summary" => %r{(<div><small>İlkin ödəniş</small><strong>)[\d,]+(<!-- --> AZN</strong></div>)},
    "financed summary" => %r{(<div><small>Faiz daxil borc</small><strong>)[\d,]+(<!-- --> AZN</strong></div>)},
    "offer link" => %r{%C4%B0lkin%20%C3%B6d%C9%99ni%C5%9F%3A%20(?:\d|%2C)+%20AZN%20\(\d+%25\)}
  }
  patterns.each do |label, pattern|
    abort "#{slug}: #{label} normalization anchor not found" unless calculator.match?(pattern)
  end

  calculator.sub!(patterns.fetch("down-payment heading")) do
    "#{Regexp.last_match(1)}#{percent}#{Regexp.last_match(2)}#{down}#{Regexp.last_match(3)}"
  end
  calculator.sub!(
    patterns.fetch("down-payment range"),
    %(<input aria-label="İlkin ödəniş faizi" type="range" min="#{percent}" max="80" step="5" value="#{percent}"/>))
  calculator.sub!(patterns.fetch("down-payment scale"), %(<span>minimum <!-- -->#{percent}<!-- -->%</span>))
  calculator.sub!(patterns.fetch("monthly result")) do
    "#{Regexp.last_match(1)}#{monthly}#{Regexp.last_match(2)}"
  end
  calculator.sub!(patterns.fetch("down-payment summary")) do
    "#{Regexp.last_match(1)}#{down}#{Regexp.last_match(2)}"
  end
  calculator.sub!(patterns.fetch("financed summary")) do
    "#{Regexp.last_match(1)}#{financed}#{Regexp.last_match(2)}"
  end
  calculator.sub!(
    patterns.fetch("offer link"),
    "%C4%B0lkin%20%C3%B6d%C9%99ni%C5%9F%3A%20#{down.gsub(',', '%2C')}%20AZN%20(#{percent}%25)"
  )
  html.sub!(original_calculator, calculator)
end

def build_c5_page
  template_path = File.join(ROOT, "model", "cforce-c4", "index.html")
  abort "Missing CFORCE C4 template" unless File.file?(template_path)

  html = read_utf8(template_path)
  html.gsub!(PRODUCT_BADGE_HTML, "")
  html.gsub!(PRODUCT_BADGE_RSC_NEW, PRODUCT_BADGE_RSC_UNSET)
  html.gsub!("cforce-c4", "cforce-c5")
  html.gsub!("/models/cforce-c5-clean.webp", "/models/cforce-c5.webp")
  html.gsub!("CFORCE%20C4", "CFORCE%20C5")
  html.gsub!("CFORCE C4", "CFORCE C5")
  html.gsub!("12,400", "13,900")
  html.gsub!("12400", "13900")
  html.gsub!("Nağd satış qiyməti", "Nağd satış qiyməti · ƏDV daxil")
  html.gsub!("Hər relyef üçün hazır.", "Gündəlik işdən həftəsonu macərasına.")
  html.gsub!(
    "CFORCE C5 iş, istirahət və çətin relyefdə etibarlı hərəkət üçün yaradılmış çoxməqsədli kvadrosikldir.",
    "CFORCE C5 yeni nəsil 500 cc sinifli ATV-dir; gündəlik iş, yedəkləmə və həftəsonu macəraları üçün hazırlanıb."
  )
  html.gsub!("408,8", "498,6")
  html.gsub!("33 a.g.", "39 a.g.")
  html.gsub!("34,5 Nm", "43,5 Nm")
  html.gsub!("Cypress Green", "Zephyr Blue")
  html.gsub!("Gedanite Grey", "Magma Red")
  html.gsub!("#596c57", "#87a8b2")
  html.gsub!("#777a78", "#e1251b")
  html.gsub!(
    "https://www.cfmoto.com/content/dam/cfmoto/site/global/product/atv/atv/c4/2026/model1.png",
    "/models/cforce-c5.webp"
  )
  html.gsub!(
    "https://www.cfmoto.com/content/dam/cfmoto/site/global/product/atv/atv/c4/2026/model2.png",
    "/models/cforce-c5-red.webp"
  )
  html.gsub!(
    "Yığcam ölçülər, ifadəli işıqlandırma və funksional kuzov C4-ü gündəlik istifadə üçün əlçatan edir.",
    "GEN⁴ kuzov, LED işıqlandırma və arxa hərəkət işığı C5-i işdə və çətin relyefdə daha funksional edir."
  )
  html.gsub!(
    "Yük platformaları və yedəkləmə yönümlü quruluş təsərrüfatla istirahəti bir texnikada birləşdirir.",
    "40/80 kq yük rəfləri, 612 kq yedəkləmə və 2500 lb bucurqad işi və istirahəti bir texnikada birləşdirir."
  )
  html.gsub!(
    %q({\"title\":\"Şassi\",\"specs\":[{\"label\":\"Ötürücü sistemi\",\"value\":\"2WD / 4WD / ön diferensial kilidi\"}]}),
    %q({\"title\":\"Şassi və yük\",\"specs\":[{\"label\":\"Ötürücü sistemi\",\"value\":\"2WD / 4WD / ön diferensial kilidi\"},{\"label\":\"Yedəkləmə qabiliyyəti\",\"value\":\"612 kq\"},{\"label\":\"Ön / arxa yük rəfi\",\"value\":\"40 / 80 kq\"},{\"label\":\"Bucurqad\",\"value\":\"2500 lb\"}]})
  )
  html.gsub!(">Şassi</button>", ">Şassi və yük</button>")

  target = File.join(ROOT, "model", "cforce-c5", "index.html")
  write_utf8(target, html)
end

build_c5_page

update_asset(MENU_BUNDLE_SOURCES, NEW_MENU_BUNDLE) do |javascript|
  unless javascript.include?('slug:`cforce-c5`')
    anchor = '{slug:`cforce-c4`,name:`CFORCE C4`,type:`Kvadrosikl`,segment:`Utility ATV`,engineClass:`400 cc`,price:12400,image:`/models/cforce-c4.webp`,officialPage:`https://cfmoto.az/cforce-c4`},'
    addition = '{slug:`cforce-c5`,name:`CFORCE C5`,type:`Kvadrosikl`,segment:`Utility ATV`,engineClass:`500 cc`,price:13900,image:`/models/cforce-c5.webp`,officialPage:`https://www.cfmoto.com/global/atv/atv/c5.html`,badge:`Yeni`,vatIncluded:!0},'
    abort "CFORCE C4 model anchor not found" unless javascript.include?(anchor)
    javascript.sub!(anchor, "#{anchor}#{addition}")
  end
  use_clean_model_data_images!(javascript)

  javascript.gsub!(
    'e.price===null?`Qiyməti dəqiqləşdirin`:`${l(e.price)} AZN`',
    'e.price===null?`Qiyməti dəqiqləşdirin`:`${l(e.price)} AZN${e.vatIncluded?` · ƏDV daxil`:``}`'
  )
  javascript.gsub!('new Intl.NumberFormat(`az-AZ`,{maximumFractionDigits:0})', 'new Intl.NumberFormat(`en-US`,{maximumFractionDigits:0})')
  menu_image_sources = [
    '(0,u.jsx)(`img`,{src:e.image,alt:`${e.name} rəsmi foto`,loading:`lazy`})',
    '(0,u.jsx)(`img`,{src:`/models/cards/${e.slug}.webp`,alt:`${e.name} rəsmi foto`,loading:`lazy`,decoding:`async`,fetchPriority:`low`})'
  ]
  menu_image_replacement = '(0,u.jsx)(`img`,{src:e.image.replace(`/models/`,`/models/cards/`),alt:`${e.name} rəsmi foto`,loading:`lazy`,decoding:`async`,fetchPriority:`low`})'
  unless javascript.include?(menu_image_replacement)
    menu_image_source = menu_image_sources.find { |source| javascript.include?(source) }
    abort "Mega-menu image anchor not found" unless menu_image_source
    javascript.sub!(menu_image_source, menu_image_replacement)
  end
  menu_click_only = 'className:`products-menu`,children'
  unless javascript.include?(menu_click_only)
    menu_hover_source = [
      'className:`products-menu`,onMouseEnter:()=>n(!0),onMouseLeave:()=>n(!1),children',
      'className:`products-menu`,onPointerEnter:e=>e.pointerType===`mouse`&&n(!0),onPointerLeave:e=>e.pointerType===`mouse`&&n(!1),children'
    ].find { |source| javascript.include?(source) }
    abort "Click-only product menu anchor not found" unless menu_hover_source
    javascript.sub!(menu_hover_source, menu_click_only)
  end
  RUNTIME_SOURCES.each { |name| javascript.gsub!(name, NEW_RUNTIME) }
  HOME_BUNDLE_SOURCES.each { |name| javascript.gsub!(name, NEW_HOME_BUNDLE) }
  [OLD_MENU_BUNDLE, PREVIOUS_MENU_BUNDLE].each { |name| javascript.gsub!(name, NEW_MENU_BUNDLE) }
end

update_asset(HOME_BUNDLE_SOURCES, NEW_HOME_BUNDLE) do |javascript|
  [OLD_MENU_BUNDLE, PREVIOUS_MENU_BUNDLE].each { |name| javascript.gsub!(name, NEW_MENU_BUNDLE) }
  replace_required_variant!(
    javascript,
    [
      '];function f(){',
      '];const q=e=>e?.type===`Motosiklet`&&(e.slug===`450sr`||parseInt(e.engineClass,10)<=300);function f(){'
    ],
    '];const q=e=>e?.type===`Motosiklet`&&(e.slug===`450sr`||parseInt(e.engineClass,10)<=300),INTEREST_RATES={6:.08,12:.15,18:.23};function f(){',
    "Home finance eligibility and interest rates"
  )
  replace_required_variant!(
    javascript,
    ['[y,b]=(0,s.useState)(20)', '[y,b]=(0,s.useState)(50)'],
    '[y,b]=(0,s.useState)(40)',
    "Home default down payment"
  )
  replace_required_variant!(
    javascript,
    [
      'E=T.price??0,D=T.type!==`Motosiklet`,O=_===`Bank krediti`?10:D?50:20,k=_===`Bank krediti`?35:D?12:18',
      'E=T.price??0,D=T.type!==`Motosiklet`,R=q(T),O=_===`Bank krediti`?10:R?20:50,k=_===`Bank krediti`?35:D?12:18'
    ],
    'E=T.price??0,D=T.type!==`Motosiklet`,R=q(T),O=_===`Bank krediti`?10:R?20:D?50:40,k=_===`Bank krediti`?35:D?12:18',
    "Home selected-model finance rule"
  )
  replace_required_variant!(
    javascript,
    [
      'function F(e){v(e),b(e===`Bank krediti`?10:D?50:20),S(e===`Bank krediti`?35:D?12:18)}',
      'function F(e){v(e),b(e===`Bank krediti`?10:R?20:50),S(e===`Bank krediti`?35:D?12:18)}'
    ],
    'function F(e){v(e),b(e===`Bank krediti`?10:R?20:D?50:40),S(e===`Bank krediti`?35:D?12:18)}',
    "Home payment-mode finance rule"
  )
  replace_required_variant!(
    javascript,
    [
      'function I(e){let t=a.find(t=>t.name===e);if(g(e),_===`Daxili hissəli`){let e=t?.type!==`Motosiklet`;b(e?50:20),S(e?12:18)}}',
      'function I(e){let t=a.find(t=>t.name===e);if(g(e),_===`Daxili hissəli`){let e=t?.type!==`Motosiklet`;b(q(t)?20:50),S(e?12:18)}}'
    ],
    'function I(e){let t=a.find(t=>t.name===e);if(g(e),_===`Daxili hissəli`){let e=t?.type!==`Motosiklet`;b(q(t)?20:e?50:40),S(e?12:18)}}',
    "Home model-change finance rule"
  )
  replace_required_once!(
    javascript,
    'M=E*A/100,N=E-M,P=N/j;',
    'M=E*A/100,N=E-M,interestRate=_===`Daxili hissəli`?INTEREST_RATES[j]??0:0,financedWithInterest=N*(1+interestRate),P=financedWithInterest/j;',
    "Home installment interest calculation"
  )
  replace_required_once!(
    javascript,
    '(0,c.jsx)(`input`,{id:`term`,type:`range`,min:`3`,max:k,step:`1`,value:j,onChange:e=>S(Number(e.target.value))})',
    '(0,c.jsx)(`input`,{id:`term`,type:`range`,min:_===`Bank krediti`?3:6,max:k,step:_===`Bank krediti`?1:6,value:j,onChange:e=>S(Number(e.target.value))})',
    "Home installment term steps"
  )
  javascript.gsub!('`Maliyyələşdirilən məbləğ: `,o(N)', '`Faiz daxil borc: `,o(financedWithInterest)')
  javascript.gsub!(OLD_HOME_CALCULATOR_NOTE, HOME_CALCULATOR_NOTE)
  remove_home_finance_policy_copy!(javascript)
  card_image_sources = [
    '(0,c.jsx)(`img`,{src:e.image,alt:`${e.name} rəsmi model fotosu`,loading:`lazy`})',
    '(0,c.jsx)(`img`,{src:`/models/cards/${e.slug}.webp`,alt:`${e.name} rəsmi model fotosu`,loading:`lazy`,decoding:`async`,fetchPriority:`low`})'
  ]
  card_image_replacement = '(0,c.jsx)(`img`,{src:e.image.replace(`/models/`,`/models/cards/`),alt:`${e.name} rəsmi model fotosu`,loading:`lazy`,decoding:`async`,fetchPriority:`low`})'
  unless javascript.include?(card_image_replacement)
    card_image_source = card_image_sources.find { |source| javascript.include?(source) }
    abort "Homepage card image anchor not found" unless card_image_source
    javascript.sub!(card_image_source, card_image_replacement)
  end

  footer_links_source = '(0,c.jsx)(`a`,{href:`#modeller`,children:`Modellər`}),(0,c.jsx)(`a`,{href:`#kredit-kalkulyator`,children:`Kredit`}),(0,c.jsx)(`a`,{href:`#servis`,children:`Servis`}),(0,c.jsx)(`a`,{href:`https://www.instagram.com/cfmoto_azerbaijan?igsi=MWR6ZnNhM2ltcHRtNQ%3D%3D&utm_source=qr`,target:`_blank`,rel:`noreferrer`,children:`Instagram`})'
  footer_links_previous = '(0,c.jsx)(`a`,{href:`/#modeller`,children:`Modellər`}),(0,c.jsx)(`a`,{href:`/kredit`,children:`Kredit`}),(0,c.jsx)(`a`,{href:`/servis`,children:`Servis`}),(0,c.jsx)(`a`,{href:`/zemanet`,children:`Zəmanət`}),(0,c.jsx)(`a`,{href:`/ehtiyat-hisseleri`,children:`Ehtiyat hissələri`}),(0,c.jsx)(`a`,{href:`/model-muqayisesi`,children:`Müqayisə`}),(0,c.jsx)(`a`,{href:`https://www.instagram.com/cfmoto_azerbaijan?igsi=MWR6ZnNhM2ltcHRtNQ%3D%3D&utm_source=qr`,target:`_blank`,rel:`noreferrer`,children:`Instagram`})'
  footer_links_current = '(0,c.jsx)(`a`,{href:`/motosiklet/`,children:`Motosikletlər`}),(0,c.jsx)(`a`,{href:`/kvadrosikl/`,children:`Kvadrosikllər`}),(0,c.jsx)(`a`,{href:`/buggy/`,children:`Buggy və UTV`}),(0,c.jsx)(`a`,{href:`/kredit`,children:`Kredit`}),(0,c.jsx)(`a`,{href:`/servis`,children:`Servis`}),(0,c.jsx)(`a`,{href:`/zemanet`,children:`Zəmanət`}),(0,c.jsx)(`a`,{href:`/ehtiyat-hisseleri`,children:`Ehtiyat hissələri`}),(0,c.jsx)(`a`,{href:`/model-muqayisesi`,children:`Müqayisə`}),(0,c.jsx)(`a`,{href:`https://www.instagram.com/cfmoto_azerbaijan?igsi=MWR6ZnNhM2ltcHRtNQ%3D%3D&utm_source=qr`,target:`_blank`,rel:`noreferrer`,children:`Instagram`})'
  footer_links_replacement = '(0,c.jsx)(`a`,{href:`/motosiklet/`,children:`Motosikletlər`}),(0,c.jsx)(`a`,{href:`/kvadrosikl/`,children:`Kvadrosikllər`}),(0,c.jsx)(`a`,{href:`/buggy/`,children:`Buggy və UTV`}),(0,c.jsx)(`a`,{href:`/kredit/`,children:`Kredit`}),(0,c.jsx)(`a`,{href:`/servis/`,children:`Servis`}),(0,c.jsx)(`a`,{href:`/zemanet/`,children:`Zəmanət`}),(0,c.jsx)(`a`,{href:`/ehtiyat-hisseleri/`,children:`Ehtiyat hissələri`}),(0,c.jsx)(`a`,{href:`/model-muqayisesi/`,children:`Müqayisə`}),(0,c.jsx)(`a`,{href:`https://www.instagram.com/cfmoto_azerbaijan?igsi=MWR6ZnNhM2ltcHRtNQ%3D%3D&utm_source=qr`,target:`_blank`,rel:`noreferrer`,children:`Instagram`})'
  footer_links_accessory = footer_links_replacement.sub(
    '(0,c.jsx)(`a`,{href:`/ehtiyat-hisseleri/`,children:`Ehtiyat hissələri`})',
    '(0,c.jsx)(`a`,{href:`/aksesuar-konfiquratoru/`,children:`Aksesuarlar`}),(0,c.jsx)(`a`,{href:`/ehtiyat-hisseleri/`,children:`Ehtiyat hissələri`})'
  )
  replace_required_variant!(javascript, [footer_links_accessory, footer_links_current, footer_links_previous, footer_links_source], footer_links_replacement, "Homepage footer links")
  javascript.gsub!("https://maps.google.com/?q=Babek+Avenue+188+Baku", SHOWROOM_MAP_URL)
  javascript.gsub!('`Kredit`,`#kredit`', "`Kredit`,`##{MOBILE_CREDIT_ID}`")
  javascript.gsub!('href:`#kredit`', "href:`##{MOBILE_CREDIT_ID}`")
  javascript.gsub!(
    'className:`calculator`,"aria-label":`Kredit kalkulyatoru`',
    "className:`calculator`,id:`#{MOBILE_CREDIT_ID}`,\"aria-label\":`Kredit kalkulyatoru`"
  )
  calculator_note = '(0,c.jsx)(`small`,{className:`calc-note`,children:`Hesablama məlumat xarakterlidir; bank faizi və komissiyalar daxil deyil. Yekun şərtlər fərqlənə bilər.`})'
  unless javascript.include?('className:`calc-top-link`')
    abort "Home calculator note anchor not found" unless javascript.include?(calculator_note)
    javascript.sub!(
      calculator_note,
      "#{calculator_note},(0,c.jsx)(`a`,{className:`calc-top-link`,href:`#top`,children:`↑ Yuxarı qayıt`})"
    )
  end
  javascript.gsub!(
    '(0,c.jsx)(`a`,{href:`${u}?text=Salam%2C%20servis%20qəbulu%20üçün%20yazılıram`,target:`_blank`,rel:`noreferrer`,children:`Servisə yazıl →`})',
    "(0,c.jsx)(`a`,{href:`tel:#{SERVICE_PHONE}`,children:`#{SERVICE_PHONE_DISPLAY} · Servisə zəng et →`})"
  )
  javascript.gsub!(
    '(0,c.jsx)(`a`,{href:`${u}?text=Salam%2C%20ehtiyat%20hissəsi%20axtarıram`,target:`_blank`,rel:`noreferrer`,children:`Sorğu göndər →`})',
    "(0,c.jsx)(`a`,{href:`tel:#{SERVICE_PHONE}`,children:`#{SERVICE_PHONE_DISPLAY} · Ehtiyat hissələri üçün zəng et →`})"
  )
  javascript.gsub!(
    '(0,c.jsx)(`a`,{href:`${u}?text=Salam%2C%20servis%20daşınması%20xidmətini%20sifariş%20etmək%20istəyirəm`,target:`_blank`,rel:`noreferrer`,children:`Sifariş et →`})',
    "(0,c.jsx)(`a`,{href:`tel:#{SERVICE_PHONE}`,children:`#{SERVICE_PHONE_DISPLAY} · Çatdırılma üçün zəng et →`})"
  )
  javascript.gsub!(
    "Babək pr. 188 · Hər gün 10:00–19:00 · Bazar ertəsi bağlıdır",
    "Babək pr. 188 · Salon hər gün 10:00–19:00"
  )
  normalize_service_schedule!(javascript)
  javascript.gsub!('children:`Şəhərdaxili`', 'children:`Şəhərdaxili çatdırılma`')
  javascript.gsub!('children:`35 AZN`', 'children:`45 AZN`')
  javascript.gsub!(
    'children:[`10:00–19:00`,(0,c.jsx)(`br`,{}),`Bazar ertəsi bağlıdır`]',
    'children:[`Hər gün 10:00–19:00`,(0,c.jsx)(`br`,{}),`Salon hər gün açıqdır`]'
  )
  javascript.gsub!(
    'e.price===null?`Dəqiqləşdirin`:`${o(e.price)} AZN`',
    'e.price===null?`Dəqiqləşdirin`:`${o(e.price)} AZN${e.vatIncluded?` · ƏDV daxil`:``}`'
  )
  javascript.gsub!('"aria-label":`Menyunu aç`,"aria-expanded":e', '"aria-label":e?`Menyunu bağla`:`Menyunu aç`,"aria-expanded":e')
end

update_asset(RUNTIME_SOURCES, NEW_RUNTIME) do |javascript|
  [OLD_MENU_BUNDLE, PREVIOUS_MENU_BUNDLE].each { |name| javascript.gsub!(name, NEW_MENU_BUNDLE) }
  HOME_BUNDLE_SOURCES.each { |name| javascript.gsub!(name, NEW_HOME_BUNDLE) }
  scroll_source = 'history.scrollRestoration=`manual`'
  scroll_replacement = 'history.scrollRestoration=`auto`'
  unless javascript.include?(scroll_replacement)
    abort "Static scroll restoration anchor not found" unless javascript.include?(scroll_source)
    javascript.sub!(scroll_source, scroll_replacement)
  end

  popstate_source = 'window.addEventListener(`popstate`,e=>{M(window.location.href,`traverse`);let t=window.__VINEXT_RSC_NAVIGATE__?.(window.location.href,0,`traverse`)??Promise.resolve();window.__VINEXT_RSC_PENDING__=t,t.finally(()=>{$i(e.state),window.__VINEXT_RSC_PENDING__===t&&(window.__VINEXT_RSC_PENDING__=null)})})'
  popstate_replacement = '/* CFMOTO:STATIC-HISTORY */void 0'
  unless javascript.include?(popstate_replacement)
    abort "Static popstate anchor not found" unless javascript.include?(popstate_source)
    javascript.sub!(popstate_source, popstate_replacement)
  end
end

SUPPORT_ASSET_SOURCES.each do |source_names, new_name|
  update_asset(source_names, new_name) do |javascript|
    if new_name == NEW_MODEL_COLOR_BUNDLE
      preload_source = '(0,r.useEffect)(()=>{e.forEach(e=>{if(!e.image)return;let t=new Image;t.src=e.image})},[e]),l?'
      preload_replacement = ' l?'
      javascript.sub!('returnl?', 'return l?')
      if javascript.include?(preload_source)
        javascript.sub!(preload_source, preload_replacement)
      elsif !javascript.include?('return l?(0,i.jsxs)')
        abort "Color image preload anchor not found"
      end
    end

    if new_name == NEW_MODEL_FINANCE_BUNDLE
      javascript.gsub!('new Intl.NumberFormat(`az-AZ`,{maximumFractionDigits:0})', 'new Intl.NumberFormat(`en-US`,{maximumFractionDigits:0})')
      eligible_models = INTERNAL_20_MODEL_NAMES.map { |model| "`#{model}`" }.join(",")
      replace_required_variant!(
        javascript,
        [
          'var r=e(t(),1),i=n(),a=e=>new Intl.NumberFormat(`en-US`,{maximumFractionDigits:0}).format(Math.round(e));function o',
          "var r=e(t(),1),i=n(),a=e=>new Intl.NumberFormat(`en-US`,{maximumFractionDigits:0}).format(Math.round(e)),q=new Set([#{eligible_models}]);function o"
        ],
        "var r=e(t(),1),i=n(),a=e=>new Intl.NumberFormat(`en-US`,{maximumFractionDigits:0}).format(Math.round(e)),q=new Set([#{eligible_models}]),INTEREST_RATES={6:.08,12:.15,18:.23};function o",
        "Model finance eligibility and interest rates"
      )
      replace_required_once!(
        javascript,
        'let s=n===`Motosiklet`,',
        'let s=n===`Motosiklet`,x=s&&q.has(e),',
        "Model finance eligibility predicate"
      )
      replace_required_variant!(
        javascript,
        ['[f,p]=(0,r.useState)(s?20:50)', '[f,p]=(0,r.useState)(x?20:50)'],
        '[f,p]=(0,r.useState)(x?20:s?40:50)',
        "Model finance default down payment"
      )
      replace_required_variant!(
        javascript,
        ['_=c===`internal`?s?20:50:10', '_=c===`internal`?x?20:50:10'],
        '_=c===`internal`?x?20:s?40:50:10',
        "Model finance minimum down payment"
      )
      replace_required_variant!(
        javascript,
        ['n=e===`internal`?s?20:50:10', 'n=e===`internal`?x?20:50:10'],
        'n=e===`internal`?x?20:s?40:50:10',
        "Model finance payment-mode rule"
      )
      replace_required_once!(
        javascript,
        'm=s?[3,6,12,18]:[3,6,12]',
        'm=s?[6,12,18]:[6,12]',
        "Model installment term options"
      )
      replace_required_once!(
        javascript,
        'y=(0,r.useMemo)(()=>{let e=f/100*t,n=Math.max(0,t-e);return{downPayment:e,financed:n,monthly:n/u}},[f,u,t])',
        'y=(0,r.useMemo)(()=>{let e=f/100*t,n=Math.max(0,t-e),interestRate=c===`internal`?INTEREST_RATES[u]??0:0,financed=n*(1+interestRate);return{downPayment:e,financed,monthly:financed/u,interestRate}},[f,u,t,c])',
        "Model installment interest calculation"
      )
      javascript.gsub!(
        'c===`bank`?`Bank faizi və komissiyası daxil edilməyib.`:`Yekun şərtlər satış mütəxəssisi tərəfindən təsdiqlənir.`',
        'c===`bank`?`Bank faizi və komissiyası daxil edilməyib.`:`Daxili ödəniş faizi: ${Math.round(y.interestRate*100)}%. Yekun şərtlər satış mütəxəssisi tərəfindən təsdiqlənir.`'
      )
      javascript.gsub!('children:`Maliyyələşən məbləğ`', 'children:`Faiz daxil borc`')
    end

    next unless new_name == NEW_LINK_BUNDLE

    prefetch_source = 'function re(e){return e.nodeEnv===`production`&&e.prefetch!==!1&&!e.isDangerous}'
    prefetch_replacement = 'function re(e){return!1}'
    javascript.sub!('function re(){return!1}', prefetch_replacement)
    unless javascript.include?(prefetch_replacement)
      abort "Link prefetch anchor not found" unless javascript.include?(prefetch_source)
      javascript.sub!(prefetch_source, prefetch_replacement)
    end

    navigation_source = 'P=async e=>{if(c&&c(e),e.defaultPrevented'
    navigation_replacement = 'P=async e=>{c&&c(e);return;if(e.defaultPrevented'
    javascript.sub!(navigation_replacement, navigation_source)

    rendered_link_source = 'ref:A,href:C,onClick:e=>{P(e)},onMouseEnter:M,onTouchStart:N,...I,children:a'
    rendered_link_replacement = 'ref:A,href:C,onClick:c,onMouseEnter:l,onTouchStart:u,...I,children:a'
    unless javascript.include?(rendered_link_replacement)
      abort "Rendered Link navigation anchor not found" unless javascript.include?(rendered_link_source)
      javascript.sub!(rendered_link_source, rendered_link_replacement)
    end
  end
end

Dir.glob(File.join(ASSETS, "*.js")).each do |path|
  javascript = read_utf8(path)
  ASSET_RENAMES.each { |old_name, new_name| javascript.gsub!(old_name, new_name) }
  DomainConfig::LEGACY_INSTAGRAM_URLS.each { |url| javascript.gsub!(url, INSTAGRAM_URL) }
  javascript.gsub!(
    %r{src:`/cfmoto-logo-black\.png`,alt:`CFMOTO`(?:,width:\d+,height:\d+)*},
    "src:`/cfmoto-logo-black.png`,alt:`CFMOTO`,width:#{LOGO_WIDTH},height:#{LOGO_HEIGHT}"
  )
  use_clean_model_image_paths!(javascript)
  normalize_internal_directory_links!(javascript)
  write_utf8(path, javascript)
end

html_paths = [
  File.join(ROOT, "index.html"),
  *Dir.glob(File.join(ROOT, "model", "*", "index.html")).sort
]

html_paths.each do |path|
  html = read_utf8(path)
  ASSET_RENAMES.each { |old_name, new_name| html.gsub!(old_name, new_name) }
  DomainConfig::LEGACY_INSTAGRAM_URLS.each { |url| html.gsub!(url, INSTAGRAM_URL) }
  html.gsub!(
    '<img src="/cfmoto-logo-black.png" alt="CFMOTO"/>',
    %(<img src="/cfmoto-logo-black.png" alt="CFMOTO" width="#{LOGO_WIDTH}" height="#{LOGO_HEIGHT}"/>))
  html.gsub!(%(<link rel="modulepreload" href="/assets/#{NEW_RUNTIME}" />\n), "")
  remove_unused_font_preloads!(html)
  remove_unused_vinext_font_css!(html)
  use_optimized_mega_menu_images!(html)
  html.gsub!(
    "Babək pr. 188 · Hər gün 10:00–19:00 · Bazar ertəsi bağlıdır",
    "Babək pr. 188 · Salon hər gün 10:00–19:00"
  )
  normalize_service_schedule!(html)
  html.gsub!(
    '<span>Kvadrosikl</span><small>8<!-- --> model</small>',
    '<span>Kvadrosikl</span><small>9<!-- --> model</small>'
  )
  unless path == File.join(ROOT, "index.html")
    slug = File.basename(File.dirname(path))
    localize_primary_model_image!(html, slug)
    ensure_clean_model_product_badge!(html, slug)
    apply_model_finance_policy!(html, slug)
    normalize_model_finance_calculator!(html, slug)
  end
  normalize_footer_links!(html)
  normalize_embedded_footer_links!(html)
  use_clean_model_image_paths!(html)
  normalize_internal_directory_links!(html)
  write_utf8(path, html)
end

home_path = File.join(ROOT, "index.html")
home = read_utf8(home_path)
use_home_card_images!(home)
hero_preload = '<link rel="preload" as="image" href="/gallery/800mt-x-1.webp" fetchpriority="high"/>'
unless home.include?(hero_preload)
  logo_preload = '<link rel="preload" as="image" href="/cfmoto-logo-black.png"/>'
  abort "Home logo preload anchor not found" unless home.include?(logo_preload)
  home.sub!(logo_preload, "#{logo_preload}#{hero_preload}")
end
normalize_service_schedule!(home)
remove_home_finance_policy_copy!(home)
home.gsub!("https://maps.google.com/?q=Babek+Avenue+188+Baku", SHOWROOM_MAP_URL)
home.gsub!('href="#kredit"', %(href="##{MOBILE_CREDIT_ID}"))
home.gsub!(
  '<div class="calculator" aria-label="Kredit kalkulyatoru">',
  %(<div class="calculator" id="#{MOBILE_CREDIT_ID}" aria-label="Kredit kalkulyatoru">)
)
calculator_note_html = '<small class="calc-note">Hesablama məlumat xarakterlidir; bank faizi və komissiyalar daxil deyil. Yekun şərtlər fərqlənə bilər.</small>'
unless home.include?('class="calc-top-link"')
  abort "Prerendered calculator note anchor not found" unless home.include?(calculator_note_html)
  home.sub!(
    calculator_note_html,
    %(#{calculator_note_html}<a class="calc-top-link" href="#top">↑ Yuxarı qayıt</a>)
  )
end
home.gsub!(
  '<a href="https://wa.me/994512332484?text=Salam%2C%20servis%20qəbulu%20üçün%20yazılıram" target="_blank" rel="noreferrer">Servisə yazıl →</a>',
  %(<a href="tel:#{SERVICE_PHONE}">#{SERVICE_PHONE_DISPLAY} · Servisə zəng et →</a>)
)
home.gsub!(
  '<a href="https://wa.me/994512332484?text=Salam%2C%20ehtiyat%20hissəsi%20axtarıram" target="_blank" rel="noreferrer">Sorğu göndər →</a>',
  %(<a href="tel:#{SERVICE_PHONE}">#{SERVICE_PHONE_DISPLAY} · Ehtiyat hissələri üçün zəng et →</a>)
)
home.gsub!(
  '<a href="https://wa.me/994512332484?text=Salam%2C%20servis%20daşınması%20xidmətini%20sifariş%20etmək%20istəyirəm" target="_blank" rel="noreferrer">Sifariş et →</a>',
  %(<a href="tel:#{SERVICE_PHONE}">#{SERVICE_PHONE_DISPLAY} · Çatdırılma üçün zəng et →</a>)
)
home.gsub!('<span>Şəhərdaxili</span><h3>35 AZN</h3>', '<span>Şəhərdaxili çatdırılma</span><h3>45 AZN</h3>')
home.gsub!(
  '<small>İş saatları</small><strong>10:00–19:00<br/>Bazar ertəsi bağlıdır</strong>',
  '<small>İş saatları</small><strong>Hər gün 10:00–19:00<br/>Salon hər gün açıqdır</strong>'
)

unless home.include?('href="/model/cforce-c5/"')
  card_pattern = %r{<article class="model-card"><a href="/model/cforce-c4/?".*?</article>}m
  c4_card = home[card_pattern]
  abort "CFORCE C4 home card not found" unless c4_card
  c5_card = c4_card.dup
  c5_card.gsub!("cforce-c4", "cforce-c5")
  c5_card.gsub!("CFORCE C4", "CFORCE C5")
  c5_card.gsub!("400 cc", "500 cc")
  c5_card.gsub!("12,400 AZN", "13,900 AZN · ƏDV daxil")
  c5_card.sub!('loading="lazy"/>', 'loading="lazy"/><span class="badge">Yeni</span>')
  home.sub!(c4_card, "#{c4_card}#{c5_card}")
end
home.gsub!(
  'CFORCE C5</h3><p>Kvadrosikl<!-- --> · <!-- -->400 cc</p>',
  'CFORCE C5</h3><p>Kvadrosikl<!-- --> · <!-- -->500 cc</p>'
)

unless home.include?('value="CFORCE C5"')
  c4_option = '<option value="CFORCE C4">CFORCE C4<!-- --> — <!-- -->12,400<!-- --> AZN</option>'
  c5_option = '<option value="CFORCE C5">CFORCE C5<!-- --> — <!-- -->13,900<!-- --> AZN</option>'
  abort "CFORCE C4 calculator option not found" unless home.include?(c4_option)
  home.sub!(c4_option, "#{c4_option}#{c5_option}")
end

home.gsub!("46<!-- --> aktual model", "47<!-- --> aktual model")
home.gsub!("46 aktual model", "47 aktual model")
apply_home_finance_policy!(home)
write_utf8(home_path, home)

stylesheet_source = [CURRENT_STYLESHEET, LAST_STYLESHEET, CURRENT_V2_STYLESHEET, CURRENT_V3_STYLESHEET, CURRENT_V4_STYLESHEET, CURRENT_V5_STYLESHEET, CURRENT_V6_STYLESHEET, CURRENT_V7_STYLESHEET, CURRENT_V8_STYLESHEET, CURRENT_V9_STYLESHEET, NEW_STYLESHEET]
  .map { |name| File.join(ASSETS, name) }
  .find { |path| File.file?(path) }
abort "Missing required stylesheet: #{CURRENT_STYLESHEET}" unless stylesheet_source

stylesheet = read_utf8(stylesheet_source)
stylesheet = "#{stylesheet.rstrip}\n#{MOBILE_CREDIT_CSS}\n" unless stylesheet.include?(MOBILE_CREDIT_CSS_MARKER)
stylesheet = "#{stylesheet.rstrip}\n#{MOBILE_PERFORMANCE_CSS}\n" unless stylesheet.include?(MOBILE_PERFORMANCE_CSS_MARKER)
stylesheet = "#{stylesheet.rstrip}\n#{MOBILE_DOM_CSS}\n" unless stylesheet.include?(MOBILE_DOM_CSS_MARKER)
mobile_category_images_available = MOBILE_CATEGORY_IMAGES.all? { |relative| File.file?(File.join(ROOT, relative)) }
if mobile_category_images_available
  stylesheet = "#{stylesheet.rstrip}\n#{MOBILE_CATEGORY_CSS}\n" unless stylesheet.include?(MOBILE_CATEGORY_CSS_MARKER)
else
  stylesheet.gsub!(%r{\n?#{Regexp.escape(MOBILE_CATEGORY_CSS_MARKER)}\n@media \(width<=860px\)\{\.category-panel\.motorcycles\{background-image:url\(/official-800mtx-hero-mobile\.jpg\)\}\.category-panel\.offroad\{background-image:url\(/models/z10-4-mobile\.jpg\)\}\}\n?}, "\n")
end
new_stylesheet_path = File.join(ASSETS, NEW_STYLESHEET)
write_utf8(new_stylesheet_path, stylesheet)
FileUtils.rm_f(File.join(ASSETS, CURRENT_STYLESHEET)) unless CURRENT_STYLESHEET == NEW_STYLESHEET
FileUtils.rm_f(File.join(ASSETS, LAST_STYLESHEET)) unless LAST_STYLESHEET == NEW_STYLESHEET
FileUtils.rm_f(File.join(ASSETS, CURRENT_V2_STYLESHEET)) unless CURRENT_V2_STYLESHEET == NEW_STYLESHEET
FileUtils.rm_f(File.join(ASSETS, CURRENT_V3_STYLESHEET)) unless CURRENT_V3_STYLESHEET == NEW_STYLESHEET
FileUtils.rm_f(File.join(ASSETS, CURRENT_V4_STYLESHEET)) unless CURRENT_V4_STYLESHEET == NEW_STYLESHEET
FileUtils.rm_f(File.join(ASSETS, CURRENT_V5_STYLESHEET)) unless CURRENT_V5_STYLESHEET == NEW_STYLESHEET
FileUtils.rm_f(File.join(ASSETS, CURRENT_V6_STYLESHEET)) unless CURRENT_V6_STYLESHEET == NEW_STYLESHEET
FileUtils.rm_f(File.join(ASSETS, CURRENT_V7_STYLESHEET)) unless CURRENT_V7_STYLESHEET == NEW_STYLESHEET
FileUtils.rm_f(File.join(ASSETS, CURRENT_V8_STYLESHEET)) unless CURRENT_V8_STYLESHEET == NEW_STYLESHEET
FileUtils.rm_f(File.join(ASSETS, CURRENT_V9_STYLESHEET)) unless CURRENT_V9_STYLESHEET == NEW_STYLESHEET

u10_path = File.join(ROOT, "model", "u10-pro", "index.html")
u10 = read_utf8(u10_path)

required_images = %w[
  models/cforce-c5.webp
  models/cforce-c5-red.webp
  gallery/cforce-c5-1.webp
  gallery/cforce-c5-2.webp
  gallery/cforce-c5-3.webp
]
missing_images = required_images.reject { |relative| File.file?(File.join(ROOT, relative)) }
abort "Missing required product images: #{missing_images.join(', ')}" unless missing_images.empty?

c5 = read_utf8(File.join(ROOT, "model", "cforce-c5", "index.html"))
home_bundle = read_utf8(File.join(ASSETS, NEW_HOME_BUNDLE))
model_finance_bundle = read_utf8(File.join(ASSETS, NEW_MODEL_FINANCE_BUNDLE))
eligible_finance_pages = INTERNAL_20_SLUGS.to_h do |slug|
  [slug, read_utf8(File.join(ROOT, "model", slug, "index.html"))]
end
ineligible_finance_pages = INTERNAL_40_MOTORCYCLE_SLUGS.to_h do |slug|
  [slug, read_utf8(File.join(ROOT, "model", slug, "index.html"))]
end
offroad_slugs = Dir.glob(File.join(ROOT, "model", "*", "index.html")).map do |path|
  File.basename(File.dirname(path))
end - INTERNAL_20_SLUGS - INTERNAL_40_MOTORCYCLE_SLUGS
offroad_finance_pages = offroad_slugs.to_h do |slug|
  [slug, read_utf8(File.join(ROOT, "model", slug, "index.html"))]
end
versioned_targets = (ASSET_SOURCE_GROUPS.values + [NEW_STYLESHEET]).uniq
old_spare_contact = "ehtiyat%20hissəsi%20axtarıram"
old_delivery_contact = "servis%20daşınması%20xidmətini%20sifariş"
checks = {
  "home delivery price" => home.include?("45 AZN"),
  "home showroom hours" => home.include?("Salon hər gün açıqdır"),
  "home service hours" => home.include?("Bazar ertəsi xaric hər gün 10:00–19:00"),
  "home service hours appear once" => home.scan(SERVICE_HOURS_COPY).size == 1,
  "home service contacts share phone" => home.scan(%(href="tel:#{SERVICE_PHONE}")).size == 3 && home.scan(SERVICE_PHONE_DISPLAY).size == 3,
  "home spare-parts phone label" => [home, home_bundle].all? { |content| content.include?("#{SERVICE_PHONE_DISPLAY} · Ehtiyat hissələri üçün zəng et →") },
  "home delivery phone label" => [home, home_bundle].all? { |content| content.include?("#{SERVICE_PHONE_DISPLAY} · Çatdırılma üçün zəng et →") },
  "home service contacts no longer use sales WhatsApp" => !home.include?(old_spare_contact) && !home.include?(old_delivery_contact) && !home_bundle.include?(old_spare_contact) && !home_bundle.include?(old_delivery_contact),
  "home map link" => home.include?(SHOWROOM_MAP_URL),
  "home mobile calculator target" => home.include?(%(id="#{MOBILE_CREDIT_ID}")) && home.include?(%(href="##{MOBILE_CREDIT_ID}")),
  "home calculator top link" => home.include?('class="calc-top-link"'),
  "home finance policy copy removed" => FINANCE_POLICY_COPIES.none? { |copy| home.include?(copy) || home_bundle.include?(copy) },
  "home finance policy predicate" => home_bundle.include?('const q=e=>e?.type===`Motosiklet`&&(e.slug===`450sr`||parseInt(e.engineClass,10)<=300)'),
  "home ineligible default calculator" => home.include?('<strong>40<!-- -->% · <!-- -->4,796<!-- --> AZN</strong>') && home.include?('id="down" type="range" min="40" max="80" step="5" value="40"') && home.include?('id="term" type="range" min="6" max="18" step="6" value="18"') && home.include?('<strong>492<!-- --> <small>AZN / ay</small></strong>') && home.include?('Faiz daxil borc: <!-- -->8,849<!-- --> AZN'),
  "home installment interest formula" => home_bundle.include?('INTEREST_RATES={6:.08,12:.15,18:.23}') && home_bundle.include?('financedWithInterest=N*(1+interestRate),P=financedWithInterest/j') && home_bundle.include?(HOME_CALCULATOR_NOTE),
  "model finance policy allowlist" => INTERNAL_20_MODEL_NAMES.all? { |model| model_finance_bundle.include?("`#{model}`") } && model_finance_bundle.include?('x=s&&q.has(e)') && model_finance_bundle.include?('[f,p]=(0,r.useState)(x?20:s?40:50)'),
  "motorcycle finance policy partitions all models" => INTERNAL_20_SLUGS.size == 12 && INTERNAL_40_MOTORCYCLE_SLUGS.size == 17 && (INTERNAL_20_SLUGS & INTERNAL_40_MOTORCYCLE_SLUGS).empty?,
  "eligible motorcycle calculators retain 20 percent" => eligible_finance_pages.all? { |_slug, page| page.include?('min="20" max="80" step="5" value="20"') && page.include?("Daxili ödəniş: 20%-dən başlayan ilkin ödəniş") },
  "other motorcycle calculators require 40 percent" => ineligible_finance_pages.all? { |_slug, page| page.include?('min="40" max="80" step="5" value="40"') && page.include?("Daxili ödəniş: 40%-dən başlayan ilkin ödəniş") && !page.include?("Daxili ödəniş: 20%-dən başlayan ilkin ödəniş") && !page.include?("Daxili ödəniş: 50%-dən başlayan ilkin ödəniş") },
  "offroad calculators retain 50 percent" => offroad_finance_pages.size == 18 && offroad_finance_pages.all? { |_slug, page| page.include?('min="50" max="80" step="5" value="50"') && page.include?("Daxili ödəniş: 50%-dən başlayan ilkin ödəniş") },
  "450MT calculator matches interest-bearing SSR" => ineligible_finance_pages.fetch("450mt").include?('<strong>40<!-- -->% · <!-- -->4,796<!-- --> AZN</strong>') && ineligible_finance_pages.fetch("450mt").include?('<strong>689<!-- --> <small>AZN / ay</small></strong>') && ineligible_finance_pages.fetch("450mt").include?('<small>Faiz daxil borc</small><strong>8,273<!-- --> AZN</strong>') && ineligible_finance_pages.fetch("450mt").include?('4%2C796%20AZN%20(40%25)'),
  "model installment interest formula" => model_finance_bundle.include?('INTEREST_RATES={6:.08,12:.15,18:.23}') && model_finance_bundle.include?('m=s?[6,12,18]:[6,12]') && model_finance_bundle.include?('monthly:financed/u,interestRate'),
  "450SR exception retains 20 percent" => eligible_finance_pages.fetch("450sr").include?('<strong>20<!-- -->% · <!-- -->2,098<!-- --> AZN</strong>'),
  "home active hero preload" => home.include?(hero_preload),
  "mobile calculator CSS" => File.file?(new_stylesheet_path) && read_utf8(new_stylesheet_path).include?(MOBILE_CREDIT_CSS_MARKER),
  "mobile hero image deferral CSS" => File.file?(new_stylesheet_path) && read_utf8(new_stylesheet_path).include?(MOBILE_PERFORMANCE_CSS_MARKER),
  "mobile DOM performance CSS" => File.file?(new_stylesheet_path) && read_utf8(new_stylesheet_path).include?(MOBILE_DOM_CSS_MARKER),
  "mobile category backgrounds" => !mobile_category_images_available || (File.file?(new_stylesheet_path) && read_utf8(new_stylesheet_path).include?('/official-800mtx-hero-mobile.jpg') && read_utf8(new_stylesheet_path).include?('/models/z10-4-mobile.jpg')),
  "correct Instagram profile" => [home, home_bundle].all? { |content| content.include?(INSTAGRAM_URL) } && DomainConfig::LEGACY_INSTAGRAM_URLS.none? { |url| [home, home_bundle].any? { |content| content.include?(url) } },
  "logo dimensions in prerendered HTML" => html_paths.all? do |path|
    tags = read_utf8(path).scan(%r{<img\b[^>]*src="/cfmoto-logo-black\.png"[^>]*>})
    !tags.empty? && tags.all? { |tag| tag.include?(%(width="#{LOGO_WIDTH}")) && tag.include?(%(height="#{LOGO_HEIGHT}")) }
  end,
  "logo dimensions in client bundles" => Dir.glob(File.join(ASSETS, "*.js")).all? do |path|
    content = read_utf8(path)
    !content.include?('src:`/cfmoto-logo-black.png`,alt:`CFMOTO`') ||
      content.include?("src:`/cfmoto-logo-black.png`,alt:`CFMOTO`,width:#{LOGO_WIDTH},height:#{LOGO_HEIGHT}")
  end,
  "unused font preloads removed" => html_paths.none? { |path| read_utf8(path).include?('<link rel="preload" href="/assets/_vinext_fonts/') },
  "unused inline font CSS removed" => html_paths.none? { |path| read_utf8(path).include?('<style data-vinext-fonts>') },
  "local primary model images" => html_paths.reject { |path| path == File.join(ROOT, "index.html") }.all? do |path|
    slug = File.basename(File.dirname(path))
    html = read_utf8(path)
    source = primary_model_image_source(slug)
    html.include?(%(<img class="model-color-image" src="#{source}")) &&
      html.include?(%(<link rel="preload" as="image" href="#{source}"))
  end,
  "optimized homepage and mega-menu images" => Dir.glob(File.join(ROOT, "models", "cards", "*.webp")).size == 51 && home.scan(%r{class="model-card"}).size == 47 && home.scan(%r{src="(/models/cards/[^"]+\.webp)"}).flatten.uniq.size == 47 && home.scan(%r{src="/models/cards/[^"]+\.webp"}).size == home.scan(%r{class="model-card"}).size + home.scan(%r{class="mega-model"}).size && home_bundle.include?('e.image.replace(`/models/`,`/models/cards/`)') && read_utf8(File.join(ASSETS, NEW_MENU_BUNDLE)).include?('e.image.replace(`/models/`,`/models/cards/`)'),
  "clean model images replace red-label originals" => CLEAN_IMAGE_SLUGS.all? do |slug|
    primary = primary_model_image_source(slug)
    card = card_model_image_source(slug)
    model_html = read_utf8(File.join(ROOT, "model", slug, "index.html"))
    File.file?(File.join(ROOT, primary.delete_prefix("/"))) &&
      File.file?(File.join(ROOT, card.delete_prefix("/"))) &&
      model_html.include?(primary) && home.include?(card) &&
      read_utf8(File.join(ASSETS, NEW_MENU_BUNDLE)).include?(primary)
  end,
  "SEO and category footer links" => html_paths.all? { |path| read_utf8(path).include?('href="/motosiklet/"') && read_utf8(path).include?('href="/kvadrosikl/"') && read_utf8(path).include?('href="/buggy/"') && read_utf8(path).include?('href="/model-muqayisesi/"') && read_utf8(path).include?('href="/zemanet/"') } && home_bundle.include?('href:`/motosiklet/`') && home_bundle.include?('href:`/kvadrosikl/`') && home_bundle.include?('href:`/buggy/`') && home_bundle.include?('href:`/model-muqayisesi/`'),
  "internal directory links avoid redirect hops" => html_paths.all? { |path| !read_utf8(path).match?(%r{href="/(?:model/[^"/?#]+|kredit|servis|zemanet|ehtiyat-hisseleri|model-muqayisesi)"}) } && [home_bundle, read_utf8(File.join(ASSETS, NEW_MENU_BUNDLE))].all? { |content| !content.match?(%r{href:`/(?:model/\$\{e\.slug\}|kredit|servis|zemanet|ehtiyat-hisseleri|model-muqayisesi)`}) },
  "single runtime module preload" => html_paths.all? { |path| read_utf8(path).scan(%r{<link rel="modulepreload" href="/assets/#{Regexp.escape(NEW_RUNTIME)}"[^>]*>}).size == 1 },
  "static links use native navigation" => read_utf8(File.join(ASSETS, NEW_LINK_BUNDLE)).include?('ref:A,href:C,onClick:c,onMouseEnter:l,onTouchStart:u,...I,children:a'),
  "static links skip RSC prefetch" => read_utf8(File.join(ASSETS, NEW_LINK_BUNDLE)).include?('function re(e){return!1}'),
  "alternate color images load on demand" => !read_utf8(File.join(ASSETS, NEW_MODEL_COLOR_BUNDLE)).include?('let t=new Image;t.src=e.image'),
  "number formatting matches prerendered HTML" => [NEW_MENU_BUNDLE, NEW_MODEL_FINANCE_BUNDLE].all? { |name| read_utf8(File.join(ASSETS, name)).include?('new Intl.NumberFormat(`en-US`,{maximumFractionDigits:0})') },
  "native browser scroll restoration" => read_utf8(File.join(ASSETS, NEW_RUNTIME)).include?('history.scrollRestoration=`auto`'),
  "static runtime skips RSC popstate" => read_utf8(File.join(ASSETS, NEW_RUNTIME)).include?('/* CFMOTO:STATIC-HISTORY */void 0'),
  "product menu uses consistent click interaction" => read_utf8(File.join(ASSETS, NEW_MENU_BUNDLE)).include?('className:`products-menu`,children') && !read_utf8(File.join(ASSETS, NEW_MENU_BUNDLE)).include?('onPointerEnter:e=>e.pointerType===`mouse`&&n(!0)'),
  "mobile menu has dynamic label" => read_utf8(File.join(ASSETS, NEW_HOME_BUNDLE)).include?('"aria-label":e?`Menyunu bağla`:`Menyunu aç`'),
  "home C5 card" => home.include?('href="/model/cforce-c5/"'),
  "home C5 engine class" => home.include?('CFORCE C5</h3><p>Kvadrosikl<!-- --> · <!-- -->500 cc</p>'),
  "home C5 calculator option" => home.include?('value="CFORCE C5"'),
  "home catalog count" => home.include?("47<!-- --> aktual model") || home.include?("47 aktual model"),
  "C5 VAT price" => c5.include?("13,900 AZN"),
  "C5 calculator matches VAT price" => c5.include?('<strong>50<!-- -->% · <!-- -->6,950<!-- --> AZN</strong>') && c5.include?('<strong>666<!-- --> <small>AZN / ay</small></strong>') && c5.include?('6%2C950%20AZN%20(50%25)'),
  "C5 chassis tab matches RSC data" => c5.include?(">Şassi və yük</button>") && !c5.include?(">Şassi</button>"),
  "C5 blue color image" => c5.include?("/models/cforce-c5.webp"),
  "C5 red color image" => c5.include?("/models/cforce-c5-red.webp"),
  "C5 has no C4 color images" => !c5.include?("/atv/atv/c4/2026/model"),
  "U10 PRO name" => u10.include?('<h1 class="product-title">U10 PRO</h1>') && !u10.include?("U10 PRO HIGHLAND"),
  "U10 PRO model image" => u10.include?("/models/u10-pro.webp"),
  "U10 PRO gallery" => u10.include?("/gallery/u10-pro-1.webp"),
  "U10 PRO color images" => u10.include?('/models/u10-pro.webp') && u10.include?("/sxs/utility/u10-pro/2026/model2.png") && u10.include?("/sxs/utility/u10-pro/2026/model3.png"),
  "new runtime" => File.file?(File.join(ASSETS, NEW_RUNTIME)),
  "new home bundle" => File.file?(File.join(ASSETS, NEW_HOME_BUNDLE)),
  "new menu bundle" => File.file?(File.join(ASSETS, NEW_MENU_BUNDLE)),
  "all 13 versioned assets" => versioned_targets.size == 13 && versioned_targets.all? { |name| (name.include?("CfmotoPolicyFixV10") || name.include?("CfmotoFinanceFixV11")) && File.file?(File.join(ASSETS, name)) },
  "no obsolete V4 assets" => Dir.glob(File.join(ASSETS, "*CfmotoMobilePerfV4*")).empty?,
  "no obsolete V5 assets" => Dir.glob(File.join(ASSETS, "*CfmotoPolicyFixV5*")).empty?,
  "no obsolete V6 assets" => Dir.glob(File.join(ASSETS, "*CfmotoPolicyFixV6*")).empty?,
  "no obsolete V7 assets" => Dir.glob(File.join(ASSETS, "*CfmotoPolicyFixV7*")).empty?,
  "no obsolete V8 assets" => Dir.glob(File.join(ASSETS, "*CfmotoPolicyFixV8*")).empty?,
  "no obsolete V9 assets" => Dir.glob(File.join(ASSETS, "*CfmotoPolicyFixV9*")).empty?,
  "no stale asset references" => Dir.glob(File.join(ROOT, "{index.html,model/*/index.html,assets/*.js}"))
    .none? { |path| ASSET_RENAMES.keys.any? { |old_name| read_utf8(path).include?(old_name) } }
}
failures = checks.reject { |_label, passed| passed }.keys
abort "Site update checks failed: #{failures.join(', ')}" unless failures.empty?

puts "Site updates applied: V10 unified orange Yeni badges, cache-safe clean model imagery, canonical URLs and mobile performance"
