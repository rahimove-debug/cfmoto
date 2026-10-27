#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "fileutils"

SOURCE_ROOT = File.expand_path("..", __dir__)
TARGET_ROOT = File.expand_path(ARGV[0] || File.join(SOURCE_ROOT, "dist"))
ASSET_ROOT = File.join(TARGET_ROOT, "assets")

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

def stylesheet_tag_pattern(filename)
  %r{<link\b(?=[^>]*\brel=["']stylesheet["'])(?=[^>]*\bhref=["']/assets/#{Regexp.escape(filename)}["'])[^>]*>}i
end

def bundle_content(files)
  files.map do |filename|
    path = File.join(ASSET_ROOT, filename)
    abort "Missing homepage stylesheet: #{path}" unless File.file?(path)

    css = File.read(path, encoding: "UTF-8").sub(/\A\uFEFF/, "").rstrip
    abort "#{filename}: @import/@charset is unsafe inside the homepage bundle" if css.match?(/@(?:import|charset)\b/i)
    "/* #{filename} */\n#{css}"
  end.join("\n") + "\n"
end

FileUtils.mkdir_p(ASSET_ROOT)

PAGES.each do |locale, config|
  page_path = File.join(TARGET_ROOT, config.fetch(:path))
  abort "Missing homepage: #{page_path}" unless File.file?(page_path)

  html = File.read(page_path, encoding: "UTF-8")
  base = config.fetch(:base)
  abort "#{page_path}: base stylesheet link is missing" unless html.scan(stylesheet_tag_pattern(base)).size == 1
  abort "#{page_path}: standalone hero stylesheet remains" if html.include?("/assets/hero-performance-v1.css")

  content = bundle_content(config.fetch(:addons))
  digest = Digest::SHA256.hexdigest(content)[0, 12]
  bundle_name = "home-addons-#{locale}-#{digest}.css"
  bundle_href = "/assets/#{bundle_name}"
  bundle_tag = %(<link rel="stylesheet" href="#{bundle_href}" data-cfmoto-bundles="language-v3"/>)

  tags = config.fetch(:addons).to_h do |filename|
    matches = html.scan(stylesheet_tag_pattern(filename))
    abort "#{page_path}: expected one #{filename} link, found #{matches.size}" unless matches.size == 1
    [filename, matches.first]
  end

  first = config.fetch(:addons).first
  html.sub!(tags.fetch(first), bundle_tag)
  config.fetch(:addons).drop(1).each { |filename| html.gsub!(tags.fetch(filename), "") }

  File.write(File.join(ASSET_ROOT, bundle_name), content, encoding: "UTF-8")
  File.write(page_path, html, encoding: "UTF-8")
  puts "Homepage CSS #{locale}: #{config.fetch(:addons).size} requests combined as #{bundle_name}"
end
