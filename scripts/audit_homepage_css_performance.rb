#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require_relative "domain_config"

SOURCE_ROOT = File.expand_path("..", __dir__)
TARGET_ROOT = File.expand_path(ARGV[0] || File.join(SOURCE_ROOT, "dist"))
ASSET_ROOT = File.join(TARGET_ROOT, "assets")
HERO_PRELOAD = '<link rel="preload" as="image" href="/gallery/800mt-x-1.webp" fetchpriority="high"/>'
HERO_RULE = ".category-hero-panel{background-image:var(--hero-image)}"
HERO_RULE_PATTERN = /\.category-hero-panel\s*\{\s*background-image:\s*var\(--hero-image\);\s*\}/
HERO_STYLESHEET = "hero-performance-v1.css"

COMMON_ADDONS = %w[
  mobile-model-names-v1.css
  language-v3.css
  cfmoto-typography-v2.css
  ux-accessibility-v1.css
  accessory-entry-v1.css
].freeze

TRAILING_ADDONS = %w[
  unified-navigation-v1.css
  confirmed-pricing-v2.css
  sales-improvements-v1.css
].freeze

PAGES = {
  "az" => {
    path: "index.html",
    base: "index-CfmotoPolicyFixV10.css",
    addons: [*COMMON_ADDONS, "home-news-v1.css", *TRAILING_ADDONS]
  },
  "ru" => {
    path: "ru/index.html",
    base: "index-CfmotoRussianV7.css",
    addons: [*COMMON_ADDONS, *TRAILING_ADDONS]
  }
}.freeze

def expected_bundle(files)
  files.map do |filename|
    css = File.read(File.join(ASSET_ROOT, filename), encoding: "UTF-8").sub(/\A\uFEFF/, "").rstrip
    "/* #{filename} */\n#{css}"
  end.join("\n") + "\n"
end

errors = []

PAGES.each do |locale, config|
  page_path = File.join(TARGET_ROOT, config.fetch(:path))
  unless File.file?(page_path)
    errors << "#{locale}: homepage is missing"
    next
  end

  html = File.read(page_path, encoding: "UTF-8")
  head = html[/<head>(.*?)<\/head>/m, 1].to_s
  stylesheet_hrefs = head.scan(%r{<link\b(?=[^>]*\brel=["']stylesheet["'])[^>]*\bhref=["']([^"']+)["'][^>]*>}i).flatten
  base_href = "/assets/#{config.fetch(:base)}"
  bundle_hrefs = stylesheet_hrefs.grep(%r{\A/assets/home-addons-#{locale}-[0-9a-f]{12}\.css\z})

  errors << "#{locale}: expected only base + bundle stylesheets, found #{stylesheet_hrefs.inspect}" unless stylesheet_hrefs.size == 2
  errors << "#{locale}: base stylesheet changed" unless stylesheet_hrefs.first == base_href
  errors << "#{locale}: expected one hashed bundle link" unless bundle_hrefs.size == 1 && stylesheet_hrefs.last == bundle_hrefs.first
  errors << "#{locale}: bundle capability marker is missing" unless head.include?('data-cfmoto-bundles="language-v3"')
  errors << "#{locale}: base data-rsc reference changed" unless head.include?(%(data-rsc-css-href="#{base_href}"))
  errors << "#{locale}: embedded RSC base reference changed" unless html.scan(base_href).size >= 3
  errors << "#{locale}: standalone hero stylesheet remains" if html.include?("/assets/hero-performance-v1.css")

  config.fetch(:addons).each do |filename|
    errors << "#{locale}: old #{filename} link remains" if head.include?("/assets/#{filename}")
  end

  if bundle_hrefs.size == 1
    bundle_href = bundle_hrefs.first
    bundle_path = File.join(TARGET_ROOT, bundle_href.delete_prefix("/"))
    if File.file?(bundle_path)
      actual = File.read(bundle_path, encoding: "UTF-8")
      expected = expected_bundle([HERO_STYLESHEET, *config.fetch(:addons)])
      errors << "#{locale}: bundle content/order differs from source stylesheets" unless actual == expected
      expected_digest = Digest::SHA256.hexdigest(actual)[0, 12]
      errors << "#{locale}: bundle filename hash does not match content" unless File.basename(bundle_path) == "home-addons-#{locale}-#{expected_digest}.css"
      errors << "#{locale}: cache-safe hero background rule is missing from bundle" unless actual.match?(HERO_RULE_PATTERN)
    else
      errors << "#{locale}: bundle file is missing: #{bundle_href}"
    end
  end

  base_path = File.join(ASSET_ROOT, config.fetch(:base))
  errors << "#{locale}: hero background rule is missing from base CSS" unless File.file?(base_path) && File.read(base_path, encoding: "UTF-8").include?(HERO_RULE)
  errors << "#{locale}: active hero preload must appear exactly once" unless head.scan(HERO_PRELOAD).size == 1
  preload_index = head.index(HERO_PRELOAD)
  tracking_index = head.index("googletagmanager.com/gtm.js")
  errors << "#{locale}: hero preload must be discovered before GTM" unless preload_index && tracking_index && preload_index < tracking_index
  errors << "#{locale}: direct GA4 loader remains outside GTM" if html.include?("googletagmanager.com/gtag/js?id=")
  errors << "#{locale}: direct GA4 config remains outside GTM" if html.include?("gtag('js'") || html.include?("gtag('config'")
  errors << "#{locale}: shared gtag queue is missing or duplicated" unless html.scan("window.gtag=window.gtag||function(){window.dataLayer.push(arguments)}").size == 1
  errors << "#{locale}: GTM loader is missing or duplicated" unless html.scan("googletagmanager.com/gtm.js?id='+i+dl").size == 1
  errors << "#{locale}: GTM must retain low fetch priority" unless html.include?("j.fetchPriority='low'")

  language_runtime = head[%r{<script\b[^>]*src="([^"]*language-switcher-v4[^"]*\.js)"[^>]*></script>}i, 1]
  if language_runtime
    language_runtime_path = File.join(TARGET_ROOT, language_runtime.delete_prefix("/"))
    errors << "#{locale}: language runtime is missing" unless File.file?(language_runtime_path)
    if File.file?(language_runtime_path)
      runtime = File.read(language_runtime_path, encoding: "UTF-8")
      errors << "#{locale}: language runtime can re-add bundled CSS" unless runtime.include?('data-cfmoto-bundles~="language-v3"')
    end
  else
    errors << "#{locale}: language runtime reference is missing"
  end
end

abort errors.join("\n") unless errors.empty?

puts "Homepage performance audit passed: 2 blocking CSS requests per locale, hero-first discovery and single GTM-owned analytics"
