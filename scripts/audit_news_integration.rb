#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require_relative "domain_config"
require_relative "news_config"

ROOT = File.expand_path("..", __dir__)
STYLE_PATH = File.join(ROOT, "assets", "cfmoto-news-v1.css")
errors = []

unless File.file?(STYLE_PATH)
  errors << "Missing news stylesheet"
else
  style = File.read(STYLE_PATH, encoding: "UTF-8")
  errors << "News logo must render without inversion or blend artifacts" unless style.include?("filter: none") && style.include?("mix-blend-mode: normal")
  errors << "News navigation must use a clean light background behind the opaque logo" unless style.include?("background: rgba(255,255,255,.98)")
end

NewsConfig::PAGES.each do |page|
  path = File.join(ROOT, page.fetch(:file))
  relative = page.fetch(:file)
  canonical = "#{DomainConfig::SITE_ORIGIN}#{page.fetch(:path)}"

  unless File.file?(path)
    errors << "Missing news page: #{relative}"
    next
  end

  html = File.read(path, encoding: "UTF-8")
  errors << "#{relative}: missing canonical" unless html.scan(%(<link rel="canonical" href="#{canonical}">)).size == 1
  errors << "#{relative}: missing Azerbaijani hreflang" unless html.include?(%(<link rel="alternate" hreflang="az" href="#{canonical}">))
  errors << "#{relative}: missing x-default hreflang" unless html.include?(%(<link rel="alternate" hreflang="x-default" href="#{canonical}">))
  errors << "#{relative}: og:url does not match canonical" unless html.include?(%(<meta property="og:url" content="#{canonical}">))
  errors << "#{relative}: missing social preview" unless html.include?(%(<meta property="og:image" content="#{DomainConfig::SITE_ORIGIN}/gallery/cforce-c4-1.webp">))
  errors << "#{relative}: missing Twitter card" unless html.include?(%(<meta name="twitter:card" content="summary_large_image">))
  errors << "#{relative}: expected one H1" unless html.scan(/<h1\b/i).size == 1
  errors << "#{relative}: contains placeholder link" if html.include?('href="#"')
  errors << "#{relative}: contains hotlinked image" if html.match?(%r{<img\b[^>]*\bsrc="https?://}i)
  errors << "#{relative}: contains non-local stylesheet" if html.match?(%r{<link\b[^>]*rel="stylesheet"[^>]*href="https?://}i)
  errors << "#{relative}: missing intrinsic logo dimensions" unless html.match?(%r{<img\b[^>]*src="/cfmoto-logo-black\.png"[^>]*width="159"[^>]*height="34"}i)
  errors << "#{relative}: expected one GA4 block" unless html.scan("<!-- CFMOTO:ANALYTICS:START -->").size == 1 && html.scan("<!-- CFMOTO:ANALYTICS:END -->").size == 1
  errors << "#{relative}: incorrect GA4 ID" unless html.scan("googletagmanager.com/gtag/js?id=#{DomainConfig::GA4_MEASUREMENT_ID}").size == 1 && html.scan("gtag('config','#{DomainConfig::GA4_MEASUREMENT_ID}')").size == 1
  errors << "#{relative}: expected one GTM head block" unless html.scan("<!-- CFMOTO:GTM:HEAD:START -->").size == 1 && html.scan("<!-- CFMOTO:GTM:HEAD:END -->").size == 1
  errors << "#{relative}: expected one GTM noscript block" unless html.scan("<!-- CFMOTO:GTM:BODY:START -->").size == 1 && html.scan("<!-- CFMOTO:GTM:BODY:END -->").size == 1
  errors << "#{relative}: incorrect GTM ID" unless html.scan("#{DomainConfig::GOOGLE_TAG_MANAGER_ID}").size >= 2
  errors << "#{relative}: direct Meta Pixel must not be duplicated" if html.include?("connect.facebook.net/en_US/fbevents.js") || html.include?("fbq('init'")

  schemas = html.scan(%r{<script type="application/ld\+json">(.*?)</script>}m).flatten
  errors << "#{relative}: missing JSON-LD" if schemas.empty?
  schemas.each do |schema|
    JSON.parse(schema)
  rescue JSON::ParserError => error
    errors << "#{relative}: invalid JSON-LD (#{error.message})"
  end

  html.scan(%r{(?:src|href)="(/(?:gallery|assets)/[^"?#]+)"}).flatten.uniq.each do |public_path|
    asset_path = File.join(ROOT, public_path.delete_prefix("/"))
    errors << "#{relative}: missing referenced asset #{public_path}" unless File.file?(asset_path)
  end
end

article_path = File.join(ROOT, NewsConfig::ROOT_SLUG, NewsConfig::ARTICLE_SLUG, "index.html")
if File.file?(article_path)
  article = File.read(article_path, encoding: "UTF-8")
  errors << "Article is missing NewsArticle schema" unless article.include?('"@type":"NewsArticle"')
  errors << "Article is missing the Azerbaijan arrival date" unless article.include?("Avqust 2026") && article.include?("2026-cı ilin avqustunda")
  errors << "Article must use C4 and C5 model names" unless article.include?("CFORCE C4") && article.include?("CFORCE C5")
  errors << "Article is missing model links" unless article.include?('href="/model/cforce-c4/"') && article.include?('href="/model/cforce-c5/"')
  errors << "Article is missing current local prices" unless article.include?("12,400 AZN") && article.include?("13,900 AZN")
end

sitemap_path = File.join(ROOT, "sitemap.xml")
if !File.file?(sitemap_path)
  errors << "Missing sitemap.xml"
else
  sitemap = File.read(sitemap_path, encoding: "UTF-8")
  NewsConfig.urls(DomainConfig::SITE_ORIGIN).each do |url|
    errors << "Sitemap must contain #{url} exactly once" unless sitemap.scan("<loc>#{url}</loc>").size == 1
    errors << "Sitemap is missing az alternate for #{url}" unless sitemap.include?(%(hreflang="az" href="#{url}"))
    errors << "Sitemap is missing x-default alternate for #{url}" unless sitemap.include?(%(hreflang="x-default" href="#{url}"))
  end
end

if errors.any?
  warn errors.map { |error| "- #{error}" }.join("\n")
  abort "News integration audit failed with #{errors.size} error(s)"
end

puts "News integration audit passed: #{NewsConfig::PAGES.size} pages, local media, metadata, analytics, sitemap and logo transparency fix"
