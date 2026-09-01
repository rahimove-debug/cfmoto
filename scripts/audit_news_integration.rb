#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require_relative "domain_config"
require_relative "news_config"

ROOT = File.expand_path("..", __dir__)
STYLE_PATH = File.join(ROOT, "assets", "cfmoto-news-v2.css")
HOME_STYLE_PATH = File.join(ROOT, "assets", "home-news-v1.css")
HOME_PATH = File.join(ROOT, "index.html")
HOME_PAGE_BUNDLE_PATH = File.join(ROOT, "assets", "page-CfmotoHomeNewsV5.js")
HOME_LOADER_PATH = File.join(ROOT, "assets", "index-CfmotoHomeNewsV5.js")
HOME_LAYOUT_PATH = File.join(ROOT, "assets", "layout-segment-context-CfmotoHomeNewsV5.js")
HOME_LINK_PATH = File.join(ROOT, "assets", "link-CfmotoHomeNewsV5.js")
HOME_ROUTER_PATH = File.join(ROOT, "assets", "router-CfmotoHomeNewsV5.js")
HOME_MEGA_PATH = File.join(ROOT, "assets", "ProductMegaMenu-CfmotoHomeNewsV5.js")
errors = []

EXPECTED_PRODUCT_OFFERS = {
  "CFMOTO 450MT" => ["11990", "https://cfmoto.az/model/450mt/"],
  "CFORCE C4" => ["12400", "https://cfmoto.az/model/cforce-c4/"],
  "CFORCE C5" => ["13900", "https://cfmoto.az/model/cforce-c5/"],
  "Z10" => ["45900", "https://cfmoto.az/model/z10/"],
  "Z10-4" => ["47900", "https://cfmoto.az/model/z10-4/"]
}.freeze

def collect_schema_nodes(value, nodes)
  case value
  when Hash
    nodes << value
    value.each_value { |child| collect_schema_nodes(child, nodes) }
  when Array
    value.each { |child| collect_schema_nodes(child, nodes) }
  end
end

unless File.file?(STYLE_PATH)
  errors << "Missing news stylesheet"
else
  style = File.read(STYLE_PATH, encoding: "UTF-8")
  errors << "News logo must render without inversion or blend artifacts" unless style.include?("filter: none") && style.include?("mix-blend-mode: normal")
  errors << "News navigation must use a clean light background behind the opaque logo" unless style.include?("background: rgba(255,255,255,.98)")
  errors << "News listing cards must have explicit spacing" unless style.include?(".news-card + .news-card")
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
  article_path = NewsConfig::FEATURED_ARTICLE.fetch(:path)
  news_index_path = NewsConfig::INDEX_PAGE.fetch(:path)
  accessory_position = home.index('class="accessory-promo section"')
  news_position = home.index('class="home-news section"')
  service_position = home.index('class="service section"')

  errors << "Homepage must contain one prerendered news section" unless home.scan('class="home-news section"').size == 1
  errors << "Homepage news section must sit between accessories and service" unless accessory_position && news_position && service_position && accessory_position < news_position && news_position < service_position
  errors << "Homepage must link to the news index from navigation and footer" unless home.scan('<a href="/xeberler/">Xəbərlər</a>').size == 2
  errors << "Homepage news card is missing the article URL" unless home.scan(%(href="#{article_path}")).size >= 3
  errors << "Homepage news block is missing the listing URL" unless home.include?(%(class="home-news-all" href="#{news_index_path}"))
  errors << "Homepage news image must be local, lazy and intrinsically sized" unless home.match?(%r{<img src="/gallery/romaniacs-2026-450mt-hero\.webp"[^>]*width="896"[^>]*height="600"[^>]*loading="lazy"[^>]*decoding="async"[^>]*fetchpriority="low"}i)
  errors << "Homepage must load the scoped news stylesheet once" unless home.scan(%(<link rel="stylesheet" href="/assets/home-news-v1.css"/>)).size == 1
  errors << "Homepage must not load the article stylesheet" if home.match?(%r{/assets/cfmoto-news-v\d+\.css})
  errors << "Homepage must preload the cache-busted news page bundle once" unless home.scan("/assets/page-CfmotoHomeNewsV5.js").size == 1
  errors << "Homepage must reference the cache-busted news loader twice" unless home.scan("/assets/index-CfmotoHomeNewsV5.js").size == 2
  errors << "Homepage must reference the cache-busted news layout once" unless home.scan("/assets/layout-segment-context-CfmotoHomeNewsV5.js").size == 1
  errors << "Homepage must reference the cache-busted news link once" unless home.scan("/assets/link-CfmotoHomeNewsV5.js").size == 1
  errors << "Homepage must reference the cache-busted news product menu once" unless home.scan("/assets/ProductMegaMenu-CfmotoHomeNewsV5.js").size == 1
  errors << "Homepage must not reference a stale V1, V2, V3 or V4 news graph" if home.match?(/CfmotoHomeNewsV[1234]\.js/)
  errors << "Homepage must not reference the cached accessory JavaScript graph" if home.include?("CfmotoAccessoryV16.js")
  errors << "Homepage must keep exactly one H1" unless home.scan(/<h1\b/i).size == 1
end

if !File.file?(HOME_PAGE_BUNDLE_PATH)
  errors << "Missing cache-busted homepage news page bundle"
else
  home_page_bundle = File.read(HOME_PAGE_BUNDLE_PATH, encoding: "UTF-8")
  errors << "Hydrated homepage must contain one news section" unless home_page_bundle.scan('className:`home-news section`').size == 1
  errors << "Hydrated homepage navigation is missing News" unless home_page_bundle.include?('[`Xəbərlər`,`/xeberler/`]')
  errors << "Hydrated homepage footer is missing News" unless home_page_bundle.include?('(0,c.jsx)(`a`,{href:`/xeberler/`,children:`Xəbərlər`})')
  errors << "Hydrated homepage news image is not lazy or intrinsically sized" unless home_page_bundle.include?('src:`/gallery/romaniacs-2026-450mt-hero.webp`') && home_page_bundle.include?('width:896,height:600,loading:`lazy`,decoding:`async`,fetchPriority:`low`')
  errors << "Hydrated homepage must import the cache-busted link" unless home_page_bundle.include?("link-CfmotoHomeNewsV5.js")
  errors << "Hydrated homepage must import the cache-busted product menu" unless home_page_bundle.include?("ProductMegaMenu-CfmotoHomeNewsV5.js")
  errors << "Hydrated homepage is missing the featured Romaniacs story" unless home_page_bundle.include?(NewsConfig::FEATURED_ARTICLE.fetch(:path)) && home_page_bundle.include?("CFMOTO Romaniacs 2026-da üç Adventure sinfində qalib gəldi")
  errors << "Hydrated homepage must not import a stale V1, V2, V3 or V4 news graph" if home_page_bundle.match?(/CfmotoHomeNewsV[1234]\.js/)
  errors << "Hydrated homepage page bundle must not import the cached accessory graph" if home_page_bundle.include?("CfmotoAccessoryV16.js")
end

if !File.file?(HOME_LOADER_PATH)
  errors << "Missing cache-busted homepage news loader"
else
  home_loader = File.read(HOME_LOADER_PATH, encoding: "UTF-8")
  errors << "Homepage news loader does not import the news page bundle" unless home_loader.include?("page-CfmotoHomeNewsV5.js")
  %w[layout-segment-context link ProductMegaMenu].each do |asset|
    errors << "Homepage news loader does not import #{asset} from the news graph" unless home_loader.include?("#{asset}-CfmotoHomeNewsV5.js")
  end
  errors << "Homepage news loader still imports a stale V1, V2, V3 or V4 news graph" if home_loader.match?(/CfmotoHomeNewsV[1234]\.js/)
  errors << "Homepage news loader still imports the cached accessory graph" if home_loader.include?("CfmotoAccessoryV16.js")
end

{
  HOME_LAYOUT_PATH => %w[index-CfmotoHomeNewsV5.js],
  HOME_LINK_PATH => %w[index-CfmotoHomeNewsV5.js router-CfmotoHomeNewsV5.js],
  HOME_ROUTER_PATH => %w[index-CfmotoHomeNewsV5.js link-CfmotoHomeNewsV5.js],
  HOME_MEGA_PATH => %w[link-CfmotoHomeNewsV5.js],
}.each do |path, dependencies|
  if !File.file?(path)
    errors << "Missing cache-busted homepage graph asset #{File.basename(path)}"
    next
  end

  asset = File.read(path, encoding: "UTF-8")
  dependencies.each do |dependency|
    errors << "#{File.basename(path)} does not import #{dependency}" unless asset.include?(dependency)
  end
  errors << "#{File.basename(path)} still imports a stale V1, V2, V3 or V4 news graph" if asset.match?(/CfmotoHomeNewsV[1234]\.js/)
  errors << "#{File.basename(path)} still imports the cached accessory graph" if asset.include?("CfmotoAccessoryV16.js")
end

if File.file?(HOME_MEGA_PATH)
  mega_menu = File.read(HOME_MEGA_PATH, encoding: "UTF-8")
  mega_menu_slugs = mega_menu.scan(/\{slug:`([^`]+)`/).flatten
  model_500sr_index = mega_menu_slugs.index("500sr")
  model_500sr_voom_index = mega_menu_slugs.index("500sr-voom")
  errors << "Hydrated homepage mega menu must contain 500SR exactly once" unless mega_menu_slugs.count("500sr") == 1
  errors << "Hydrated homepage mega menu must place 500SR immediately before 500SR VOOM" unless model_500sr_index && model_500sr_voom_index && model_500sr_index + 1 == model_500sr_voom_index
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
  errors << "#{relative}: missing social preview" unless html.include?(%(<meta property="og:image" content="#{DomainConfig::SITE_ORIGIN}#{page.fetch(:image)}">))
  errors << "#{relative}: missing Twitter card" unless html.include?(%(<meta name="twitter:card" content="summary_large_image">))
  errors << "#{relative}: expected one H1" unless html.scan(/<h1\b/i).size == 1
  errors << "#{relative}: contains placeholder link" if html.include?('href="#"')
  errors << "#{relative}: contains hotlinked image" if html.match?(%r{<img\b[^>]*\bsrc="https?://}i)
  errors << "#{relative}: contains non-local stylesheet" if html.match?(%r{<link\b[^>]*rel="stylesheet"[^>]*href="https?://}i)
  errors << "#{relative}: must load the V2 news stylesheet once" unless html.scan(%(<link rel="stylesheet" href="/assets/cfmoto-news-v2.css">)).size == 1
  errors << "#{relative}: must not load the stale V1 news stylesheet" if html.include?("/assets/cfmoto-news-v1.css")
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

listing_path = File.join(ROOT, NewsConfig::INDEX_PAGE.fetch(:file))
if File.file?(listing_path)
  listing = File.read(listing_path, encoding: "UTF-8")
  article_count = NewsConfig::ARTICLES.size
  article_positions = NewsConfig::ARTICLES.map { |article| listing.index(%(href="#{article.fetch(:path)}")) }
  errors << "News listing must declare #{article_count} articles" unless listing.include?(%Q{"numberOfItems":#{article_count}}) && listing.include?("#{article_count} məqalə")
  errors << "News listing must render #{article_count} story cards" unless listing.scan('class="news-card"').size == article_count
  errors << "News listing stories are missing or out of newest-first order" unless article_positions.all? && article_positions.each_cons(2).all? { |first, second| first < second }
  errors << "News listing featured image must be eager and intrinsic" unless listing.match?(%r{<img src="/gallery/romaniacs-2026-450mt-hero\.webp"[^>]*width="896"[^>]*height="600"[^>]*loading="eager"[^>]*fetchpriority="high"}i)
  NewsConfig::ARTICLES.drop(1).each do |article|
    image = Regexp.escape(article.fetch(:image))
    errors << "News listing older image #{article.fetch(:image)} must be lazy" unless listing.match?(%r{<img src="#{image}"[^>]*loading="lazy"[^>]*fetchpriority="low"}i)
  end
end

cforce_article_path = File.join(ROOT, NewsConfig::ROOT_SLUG, NewsConfig::CFORCE_ARTICLE_SLUG, "index.html")
if File.file?(cforce_article_path)
  article = File.read(cforce_article_path, encoding: "UTF-8")
  errors << "Article is missing NewsArticle schema" unless article.include?('"@type":"NewsArticle"')
  errors << "Article is missing the Azerbaijan arrival date" unless article.include?("Avqust 2026") && article.include?("2026-cı ilin avqustunda")
  errors << "Article must use C4 and C5 model names" unless article.include?("CFORCE C4") && article.include?("CFORCE C5")
  errors << "Article is missing model links" unless article.include?('href="/model/cforce-c4/"') && article.include?('href="/model/cforce-c5/"')
  errors << "Article is missing current local prices" unless article.include?("12,400 AZN") && article.include?("13,900 AZN")
end

z10_article_path = File.join(ROOT, NewsConfig::ROOT_SLUG, NewsConfig::Z10_ARTICLE_SLUG, "index.html")
if File.file?(z10_article_path)
  article = File.read(z10_article_path, encoding: "UTF-8")
  errors << "Z10 article is missing NewsArticle schema" unless article.include?('"@type":"NewsArticle"')
  errors << "Z10 article must use local model names" unless article.include?("Z10") && article.include?("Z10-4")
  errors << "Z10 article is missing model links" unless article.include?('href="/model/z10/"') && article.include?('href="/model/z10-4/"')
  errors << "Z10 article is missing current local prices" unless article.include?("45,900 AZN") && article.include?("47,900 AZN")
  errors << "Z10 article must use the local power figure" unless article.include?("154 a.g.") && article.include?("145 Nm")
  errors << "Z10 article must not publish Russian-market prices" if article.match?(/3[\s ]*(?:379|579)[\s ]*900/) || article.include?("RUB")
  errors << "Z10 article must not claim an unverified local price reduction" if article.match?(/qiymət(?:lər)?\s+(?:endir|azal)/i)
end

romaniacs_article_path = File.join(ROOT, NewsConfig::ROOT_SLUG, NewsConfig::ROMANIACS_ARTICLE_SLUG, "index.html")
if File.file?(romaniacs_article_path)
  article = File.read(romaniacs_article_path, encoding: "UTF-8")
  errors << "Romaniacs article is missing NewsArticle schema" unless article.include?('"@type":"NewsArticle"')
  errors << "Romaniacs article must identify all three Adventure classes" unless %w[Ultimate Core Lite].all? { |name| article.include?("Adventure #{name}") }
  errors << "Romaniacs article is missing the three class winners" unless ["Mario Román", "René Columna", "Guishu He"].all? { |name| article.include?(name) }
  errors << "Romaniacs article is missing the event dates and location" unless article.include?("28 iyul–1 avqust") && article.include?("Sibiu") && article.include?("Cənubi Karpat")
  errors << "Romaniacs article is missing the verified Ultimate winning margin" unless article.include?("14 dəqiqə 40 saniyə") && article.include?("14:40")
  errors << "Romaniacs article must distinguish the race-prepared bike from the production model" unless article.include?("yarış üçün hazırlanmış") && article.include?("seriya modelindən fərqlənə bilər")
  errors << "Romaniacs article is missing the local 450MT link and price" unless article.include?('href="/model/450mt/"') && article.include?("11,990 AZN")
  errors << "Romaniacs article is missing the other participating MT model links" unless article.include?('href="/model/800mt-x/"') && article.include?('href="/model/1000mt-x/"')
  errors << "Romaniacs article is missing the official CFMOTO source" unless article.include?("https://www.cfmoto.com/global/media-center/news/2026/mario-roman-serrano-and-cfmoto-complete-a-three-class-adventure-.html")
  errors << "Romaniacs article is missing the official race report" unless article.include?("https://www.redbullromaniacs.com/visitors/event-news-reports/details/eng-hard-adventure-racing-baptism-of-fire-2")
  errors << "Romaniacs headline must not claim victory in every race class" if article.match?(%r{<(?:title|h1)[^>]*>[^<]*bütün\s+(?:yarış\s+)?sinif}i)
end

quiles_article_path = File.join(ROOT, NewsConfig::ROOT_SLUG, NewsConfig::QUILES_ARTICLE_SLUG, "index.html")
if File.file?(quiles_article_path)
  article = File.read(quiles_article_path, encoding: "UTF-8")
  errors << "Quiles article is missing NewsArticle schema" unless article.include?('"@type":"NewsArticle"')
  errors << "Quiles article must identify both podium finishers" unless article.include?("Max Quiles") && article.include?("Daniel Holgado")
  errors << "Quiles article is missing the Sachsenring location" unless article.include?("Sachsenring")
  errors << "Quiles article is missing the verified winning gaps" unless article.include?("0,063 saniyə") && article.include?("0,6 saniyə")
  errors << "Quiles article is missing the Moto3 championship lead" unless article.include?("104 xallıq")
  errors << "Quiles article is missing the official CFMOTO source" unless article.include?("https://www.cfmoto.com/global/media-center/news/2026/quiles-opens-grand-prix-podium-champagne-again-for-cfmoto-in-ger.html")
  %w[hero race moto3-podium moto2-podium].each do |image|
    errors << "Quiles article is missing local #{image} media" unless article.include?("/gallery/quiles-sachsenring-2026-#{image}.jpg")
  end
end

brembo_article_path = File.join(ROOT, NewsConfig::ROOT_SLUG, NewsConfig::BREMBO_ARTICLE_SLUG, "index.html")
if File.file?(brembo_article_path)
  article = File.read(brembo_article_path, encoding: "UTF-8")
  errors << "Brembo article is missing NewsArticle schema" unless article.include?('"@type":"NewsArticle"')
  errors << "Brembo article must describe the long-term strategic partnership" unless article.include?("uzunmüddətli strateji tərəfdaşlıq")
  errors << "Brembo article is missing the target motorcycle class" unless article.include?("orta və böyük mühərrik həcmli")
  errors << "Brembo article is missing the development workflow" unless %w[inteqrasiyasını kalibrlənməsini validasiyasını].all? { |term| article.include?(term) }
  errors << "Brembo article is missing Talent Project" unless article.include?("CFMOTO Talent Project")
  errors << "Brembo article must state that exact models and local availability are unannounced" unless article.include?("konkret model adları") && article.include?("Azərbaycan bazarı üçün satış vaxtı elan edilməyib")
  errors << "Brembo article is missing the official CFMOTO source" unless article.include?("https://www.cfmoto.com/global/media-center/news/2026/cfmoto-and-brembo-sign-long-term-strategic-partnership-to--advan.html")
  %w[hero signing performance talent].each do |image|
    errors << "Brembo article is missing local #{image} media" unless article.include?("/gallery/cfmoto-brembo-partnership-#{image}.jpg")
  end
end

schema_nodes = []
Dir.glob(File.join(ROOT, NewsConfig::ROOT_SLUG, "*", "index.html")).sort.each do |path|
  html = File.read(path, encoding: "UTF-8")
  html.scan(%r{<script type="application/ld\+json">(.*?)</script>}m).flatten.each do |source|
    collect_schema_nodes(JSON.parse(source), schema_nodes)
  rescue JSON::ParserError
    # The per-page audit above reports malformed JSON-LD with its file name.
  end
end

EXPECTED_PRODUCT_OFFERS.each do |name, (price, url)|
  products = schema_nodes.select { |node| node["@type"] == "Product" && node["name"] == name }
  if products.size != 1
    errors << "Expected exactly one Product schema for #{name}"
    next
  end

  offer = products.first["offers"]
  valid_offer = offer.is_a?(Hash) &&
    offer["@type"] == "Offer" &&
    offer["priceCurrency"] == "AZN" &&
    offer["price"].to_s == price &&
    offer["availability"] == "https://schema.org/InStock" &&
    offer["url"] == url &&
    offer.dig("seller", "name") == "CFMOTO Azerbaijan — SAZMOTO MMC"
  errors << "#{name} Product schema is missing its verified local Offer" unless valid_offer
end

historical_event_topics = {
  "Red Bull Romaniacs 2026" => "28 iyul–1 avqust",
  "2026 MotoGP Almaniya Qran Prisi" => "10–12 iyul"
}

event_nodes = schema_nodes.select { |node| node["@type"].to_s.end_with?("Event") }
errors << "Historical news articles must not expose Event rich-result schema" unless event_nodes.empty?

historical_event_topics.each do |name, date_range|
  topics = schema_nodes.select { |node| node["@type"] == "Thing" && node["name"] == name }
  if topics.size != 1
    errors << "Expected exactly one historical event topic for #{name}"
    next
  end

  topic = topics.first
  errors << "#{name} topic is missing its factual date range" unless topic["description"].to_s.include?(date_range)
  errors << "#{name} topic is missing its supporting source" unless topic["sameAs"].to_s.start_with?("https://")
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
