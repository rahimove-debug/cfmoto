#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require_relative "domain_config"
require_relative "news_config"

ROOT = File.expand_path("..", __dir__)
STYLE_PATH = File.join(ROOT, "assets", "cfmoto-news-v1.css")
HOME_STYLE_PATH = File.join(ROOT, "assets", "home-news-v1.css")
HOME_PATH = File.join(ROOT, "index.html")
HOME_PAGE_BUNDLE_PATH = File.join(ROOT, "assets", "page-CfmotoHomeNewsV1.js")
HOME_LOADER_PATH = File.join(ROOT, "assets", "index-CfmotoHomeNewsV1.js")
HOME_LAYOUT_PATH = File.join(ROOT, "assets", "layout-segment-context-CfmotoHomeNewsV1.js")
HOME_LINK_PATH = File.join(ROOT, "assets", "link-CfmotoHomeNewsV1.js")
HOME_ROUTER_PATH = File.join(ROOT, "assets", "router-CfmotoHomeNewsV1.js")
HOME_MEGA_PATH = File.join(ROOT, "assets", "ProductMegaMenu-CfmotoHomeNewsV1.js")
errors = []

unless File.file?(STYLE_PATH)
  errors << "Missing news stylesheet"
else
  style = File.read(STYLE_PATH, encoding: "UTF-8")
  errors << "News logo must render without inversion or blend artifacts" unless style.include?("filter: none") && style.include?("mix-blend-mode: normal")
  errors << "News navigation must use a clean light background behind the opaque logo" unless style.include?("background: rgba(255,255,255,.98)")
end

unless File.file?(HOME_STYLE_PATH)
  errors << "Missing scoped homepage news stylesheet"
else
  home_style = File.read(HOME_STYLE_PATH, encoding: "UTF-8")
  errors << "Homepage news stylesheet is missing desktop card layout" unless home_style.include?(".home-news-card") && home_style.include?("grid-template-columns")
  errors << "Homepage news stylesheet is missing tablet layout" unless home_style.include?("@media (width <= 860px)")
  errors << "Homepage news stylesheet is missing mobile layout" unless home_style.include?("@media (width <= 580px)")
  errors << "Homepage news links must expose 44px tap targets" unless home_style.include?("min-height: 44px")
  errors << "Homepage news stylesheet must not contain global body, link, image or button selectors" if home_style.match?(/^\s*(?::root|html|body|a|img|\.button)\b/)
end

if !File.file?(HOME_PATH)
  errors << "Missing homepage index.html"
else
  home = File.read(HOME_PATH, encoding: "UTF-8")
  article_path = NewsConfig::PAGES.fetch(1).fetch(:path)
  news_index_path = NewsConfig::PAGES.fetch(0).fetch(:path)
  accessory_position = home.index('class="accessory-promo section"')
  news_position = home.index('class="home-news section"')
  service_position = home.index('class="service section"')

  errors << "Homepage must contain one prerendered news section" unless home.scan('class="home-news section"').size == 1
  errors << "Homepage news section must sit between accessories and service" unless accessory_position && news_position && service_position && accessory_position < news_position && news_position < service_position
  errors << "Homepage must link to the news index from navigation and footer" unless home.scan('<a href="/xeberler/">Xəbərlər</a>').size == 2
  errors << "Homepage news card is missing the article URL" unless home.scan(%(href="#{article_path}")).size >= 3
  errors << "Homepage news block is missing the listing URL" unless home.include?(%(class="home-news-all" href="#{news_index_path}"))
  errors << "Homepage news image must be local, lazy and intrinsically sized" unless home.match?(%r{<img src="/gallery/cforce-c4-1\.webp"[^>]*width="1600"[^>]*height="1067"[^>]*loading="lazy"[^>]*decoding="async"[^>]*fetchpriority="low"}i)
  errors << "Homepage must load the scoped news stylesheet once" unless home.scan(%(<link rel="stylesheet" href="/assets/home-news-v1.css"/>)).size == 1
  errors << "Homepage must not load the article stylesheet" if home.include?(%(<link rel="stylesheet" href="/assets/cfmoto-news-v1.css"/>))
  errors << "Homepage must preload the cache-busted news page bundle once" unless home.scan("/assets/page-CfmotoHomeNewsV1.js").size == 1
  errors << "Homepage must reference the cache-busted news loader twice" unless home.scan("/assets/index-CfmotoHomeNewsV1.js").size == 2
  errors << "Homepage must reference the cache-busted news layout once" unless home.scan("/assets/layout-segment-context-CfmotoHomeNewsV1.js").size == 1
  errors << "Homepage must reference the cache-busted news link once" unless home.scan("/assets/link-CfmotoHomeNewsV1.js").size == 1
  errors << "Homepage must reference the cache-busted news product menu once" unless home.scan("/assets/ProductMegaMenu-CfmotoHomeNewsV1.js").size == 1
  errors << "Homepage must not reference the cached accessory JavaScript graph" if home.include?("CfmotoAccessoryV15.js")
  errors << "Homepage must keep exactly one H1" unless home.scan(/<h1\b/i).size == 1
end

if !File.file?(HOME_PAGE_BUNDLE_PATH)
  errors << "Missing cache-busted homepage news page bundle"
else
  home_page_bundle = File.read(HOME_PAGE_BUNDLE_PATH, encoding: "UTF-8")
  errors << "Hydrated homepage must contain one news section" unless home_page_bundle.scan('className:`home-news section`').size == 1
  errors << "Hydrated homepage navigation is missing News" unless home_page_bundle.include?('[`Xəbərlər`,`/xeberler/`]')
  errors << "Hydrated homepage footer is missing News" unless home_page_bundle.include?('(0,c.jsx)(`a`,{href:`/xeberler/`,children:`Xəbərlər`})')
  errors << "Hydrated homepage news image is not lazy or intrinsically sized" unless home_page_bundle.include?('width:1600,height:1067,loading:`lazy`,decoding:`async`,fetchPriority:`low`')
  errors << "Hydrated homepage must import the cache-busted link" unless home_page_bundle.include?("link-CfmotoHomeNewsV1.js")
  errors << "Hydrated homepage must import the cache-busted product menu" unless home_page_bundle.include?("ProductMegaMenu-CfmotoHomeNewsV1.js")
  errors << "Hydrated homepage page bundle must not import the cached accessory graph" if home_page_bundle.include?("CfmotoAccessoryV15.js")
end

if !File.file?(HOME_LOADER_PATH)
  errors << "Missing cache-busted homepage news loader"
else
  home_loader = File.read(HOME_LOADER_PATH, encoding: "UTF-8")
  errors << "Homepage news loader does not import the news page bundle" unless home_loader.include?("page-CfmotoHomeNewsV1.js")
  %w[layout-segment-context link ProductMegaMenu].each do |asset|
    errors << "Homepage news loader does not import #{asset} from the news graph" unless home_loader.include?("#{asset}-CfmotoHomeNewsV1.js")
  end
  errors << "Homepage news loader still imports the cached accessory graph" if home_loader.include?("CfmotoAccessoryV15.js")
end

{
  HOME_LAYOUT_PATH => %w[index-CfmotoHomeNewsV1.js],
  HOME_LINK_PATH => %w[index-CfmotoHomeNewsV1.js router-CfmotoHomeNewsV1.js],
  HOME_ROUTER_PATH => %w[index-CfmotoHomeNewsV1.js link-CfmotoHomeNewsV1.js],
  HOME_MEGA_PATH => %w[link-CfmotoHomeNewsV1.js],
}.each do |path, dependencies|
  if !File.file?(path)
    errors << "Missing cache-busted homepage graph asset #{File.basename(path)}"
    next
  end

  asset = File.read(path, encoding: "UTF-8")
  dependencies.each do |dependency|
    errors << "#{File.basename(path)} does not import #{dependency}" unless asset.include?(dependency)
  end
  errors << "#{File.basename(path)} still imports the cached accessory graph" if asset.include?("CfmotoAccessoryV15.js")
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

puts "News integration audit passed: #{NewsConfig::PAGES.size} pages, homepage links, cache-safe hydration, local media, metadata, analytics and sitemap"
