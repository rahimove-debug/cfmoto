#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "domain_config"
require_relative "news_config"

ROOT = File.expand_path("..", __dir__)
SITEMAP_PATH = File.join(ROOT, "sitemap.xml")
HOME_PATH = File.join(ROOT, "index.html")
HOME_STYLESHEET = "/assets/home-news-v1.css"
HOME_PAGE_SOURCE = "/assets/page-CfmotoAccessoryV15.js"
HOME_PAGE_PUBLIC = "/assets/page-CfmotoHomeNewsV4.js"
HOME_LOADER_SOURCE = "/assets/index-CfmotoAccessoryV15.js"
HOME_LOADER_PUBLIC = "/assets/index-CfmotoHomeNewsV4.js"
HOME_LAYOUT_SOURCE = "/assets/layout-segment-context-CfmotoAccessoryV15.js"
HOME_LAYOUT_PUBLIC = "/assets/layout-segment-context-CfmotoHomeNewsV4.js"
HOME_LINK_SOURCE = "/assets/link-CfmotoAccessoryV15.js"
HOME_LINK_PUBLIC = "/assets/link-CfmotoHomeNewsV4.js"
HOME_ROUTER_SOURCE = "/assets/router-CfmotoAccessoryV15.js"
HOME_ROUTER_PUBLIC = "/assets/router-CfmotoHomeNewsV4.js"
HOME_MEGA_SOURCE = "/assets/ProductMegaMenu-CfmotoAccessoryV15.js"
HOME_MEGA_PUBLIC = "/assets/ProductMegaMenu-CfmotoHomeNewsV4.js"
ARTICLE_PATH = NewsConfig::FEATURED_ARTICLE.fetch(:path)
NEWS_INDEX_PATH = NewsConfig::INDEX_PAGE.fetch(:path)

HOME_NEWS_HTML = <<~HTML.strip
  <section class="home-news section" id="xeberler"><div class="home-news-head"><div><p class="eyebrow"><span></span> CFMOTO XƏBƏRLƏRİ</p><h2>Yeniliklər və yeni modellər</h2></div><a class="home-news-all" href="#{NEWS_INDEX_PATH}">Bütün xəbərlər <span>↗︎</span></a></div><article class="home-news-card"><a class="home-news-media" href="#{ARTICLE_PATH}" aria-label="Romaniacs 2026 xəbərini oxu"><img src="/gallery/romaniacs-2026-450mt-hero.webp" alt="Red Bull Romaniacs 2026-da Karpat meşə cığırında CFMOTO 450MT" width="896" height="600" loading="lazy" decoding="async" fetchpriority="low"/><span>Adventure</span></a><div class="home-news-copy"><time datetime="2026-08-29">29 avqust 2026</time><h3><a href="#{ARTICLE_PATH}">CFMOTO Romaniacs 2026-da üç Adventure sinfində qalib gəldi</a></h3><p>Mario Románın 450MT ilə Ultimate qələbəsi və CFMOTO-nun hər üç Adventure sinfində birinciliyi.</p><a class="button primary" href="#{ARTICLE_PATH}">Ətraflı oxu <span>↗︎</span></a></div></article></section>
HTML

HOME_NEWS_JSX = <<~JS.strip
  (0,c.jsxs)(`section`,{className:`home-news section`,id:`xeberler`,children:[(0,c.jsxs)(`div`,{className:`home-news-head`,children:[(0,c.jsxs)(`div`,{children:[(0,c.jsxs)(`p`,{className:`eyebrow`,children:[(0,c.jsx)(`span`,{}),` CFMOTO XƏBƏRLƏRİ`]}),(0,c.jsx)(`h2`,{children:`Yeniliklər və yeni modellər`})]}),(0,c.jsxs)(`a`,{className:`home-news-all`,href:`#{NEWS_INDEX_PATH}`,children:[`Bütün xəbərlər `,(0,c.jsx)(`span`,{children:`↗︎`})]})]}),(0,c.jsxs)(`article`,{className:`home-news-card`,children:[(0,c.jsxs)(`a`,{className:`home-news-media`,href:`#{ARTICLE_PATH}`,"aria-label":`Romaniacs 2026 xəbərini oxu`,children:[(0,c.jsx)(`img`,{src:`/gallery/romaniacs-2026-450mt-hero.webp`,alt:`Red Bull Romaniacs 2026-da Karpat meşə cığırında CFMOTO 450MT`,width:896,height:600,loading:`lazy`,decoding:`async`,fetchPriority:`low`}),(0,c.jsx)(`span`,{children:`Adventure`})]}),(0,c.jsxs)(`div`,{className:`home-news-copy`,children:[(0,c.jsx)(`time`,{dateTime:`2026-08-29`,children:`29 avqust 2026`}),(0,c.jsx)(`h3`,{children:(0,c.jsx)(`a`,{href:`#{ARTICLE_PATH}`,children:`CFMOTO Romaniacs 2026-da üç Adventure sinfində qalib gəldi`})}),(0,c.jsx)(`p`,{children:`Mario Románın 450MT ilə Ultimate qələbəsi və CFMOTO-nun hər üç Adventure sinfində birinciliyi.`}),(0,c.jsxs)(`a`,{className:`button primary`,href:`#{ARTICLE_PATH}`,children:[`Ətraflı oxu `,(0,c.jsx)(`span`,{children:`↗︎`})]})]})]})]})
JS

def read(path)
  File.read(path, encoding: "UTF-8")
end

def write(path, content)
  File.write(path, content, encoding: "UTF-8")
end

def require_replace!(content, source, replacement, label)
  return content if content.include?(replacement)

  abort "#{label}: anchor not found" unless content.include?(source)
  content.sub(source, replacement)
end

def add_home_stylesheet!(html)
  tag = %(<link rel="stylesheet" href="#{HOME_STYLESHEET}"/>)
  return html if html.include?(tag)

  abort "Homepage news stylesheet: closing head not found" unless html.include?("</head>")
  html.sub("</head>", "#{tag}</head>")
end

def create_cache_variant!(source_url, public_url, replacements, label)
  source_path = File.join(ROOT, source_url.delete_prefix("/"))
  public_path = File.join(ROOT, public_url.delete_prefix("/"))
  abort "#{label}: source asset not found" unless File.file?(source_path)

  content = read(source_path)
  replacements.each do |source_name, public_name|
    abort "#{label}: dependency #{source_name} not found" unless content.include?(source_name)
    content.gsub!(source_name, public_name)
  end
  write(public_path, content)
end

home_page_source_path = File.join(ROOT, HOME_PAGE_SOURCE.delete_prefix("/"))
home_page_public_path = File.join(ROOT, HOME_PAGE_PUBLIC.delete_prefix("/"))
abort "Missing generated accessory homepage bundle" unless File.file?(home_page_source_path)

home_page = read(home_page_source_path)
home_page = require_replace!(
  home_page,
  'l=[[`Aksesuarlar`,`/aksesuar-konfiquratoru/`],[`Kredit`,`#kredit-kalkulyator`],[`Servis`,`#servis`],[`Satış mərkəzi`,`#showroom`]]',
  'l=[[`Xəbərlər`,`/xeberler/`],[`Aksesuarlar`,`/aksesuar-konfiquratoru/`],[`Kredit`,`#kredit-kalkulyator`],[`Servis`,`#servis`],[`Satış mərkəzi`,`#showroom`]]',
  "Homepage news navigation"
)
home_page = require_replace!(
  home_page,
  '(0,c.jsx)(`a`,{href:`/aksesuar-konfiquratoru/`,children:`Aksesuarlar`}),(0,c.jsx)(`a`,{href:`/ehtiyat-hisseleri/`,children:`Ehtiyat hissələri`})',
  '(0,c.jsx)(`a`,{href:`/xeberler/`,children:`Xəbərlər`}),(0,c.jsx)(`a`,{href:`/aksesuar-konfiquratoru/`,children:`Aksesuarlar`}),(0,c.jsx)(`a`,{href:`/ehtiyat-hisseleri/`,children:`Ehtiyat hissələri`})',
  "Homepage news footer"
)
unless home_page.include?('className:`home-news section`')
  service_anchor = '(0,c.jsxs)(`section`,{className:`service section`,id:`servis`'
  abort "Homepage news section: hydrated service anchor not found" unless home_page.include?(service_anchor)
  home_page.sub!(service_anchor, "#{HOME_NEWS_JSX},#{service_anchor}")
end
{
  File.basename(HOME_LINK_SOURCE) => File.basename(HOME_LINK_PUBLIC),
  File.basename(HOME_MEGA_SOURCE) => File.basename(HOME_MEGA_PUBLIC),
}.each do |source_name, public_name|
  abort "Homepage news page: dependency #{source_name} not found" unless home_page.include?(source_name)
  home_page.gsub!(source_name, public_name)
end
write(home_page_public_path, home_page)

create_cache_variant!(
  HOME_LOADER_SOURCE,
  HOME_LOADER_PUBLIC,
  {
    File.basename(HOME_PAGE_SOURCE) => File.basename(HOME_PAGE_PUBLIC),
    File.basename(HOME_LAYOUT_SOURCE) => File.basename(HOME_LAYOUT_PUBLIC),
    File.basename(HOME_LINK_SOURCE) => File.basename(HOME_LINK_PUBLIC),
    File.basename(HOME_MEGA_SOURCE) => File.basename(HOME_MEGA_PUBLIC),
  },
  "Homepage news loader"
)
create_cache_variant!(
  HOME_LAYOUT_SOURCE,
  HOME_LAYOUT_PUBLIC,
  { File.basename(HOME_LOADER_SOURCE) => File.basename(HOME_LOADER_PUBLIC) },
  "Homepage news layout context"
)
create_cache_variant!(
  HOME_LINK_SOURCE,
  HOME_LINK_PUBLIC,
  {
    File.basename(HOME_LOADER_SOURCE) => File.basename(HOME_LOADER_PUBLIC),
    File.basename(HOME_ROUTER_SOURCE) => File.basename(HOME_ROUTER_PUBLIC),
  },
  "Homepage news link"
)
create_cache_variant!(
  HOME_ROUTER_SOURCE,
  HOME_ROUTER_PUBLIC,
  {
    File.basename(HOME_LOADER_SOURCE) => File.basename(HOME_LOADER_PUBLIC),
    File.basename(HOME_LINK_SOURCE) => File.basename(HOME_LINK_PUBLIC),
  },
  "Homepage news router"
)
create_cache_variant!(
  HOME_MEGA_SOURCE,
  HOME_MEGA_PUBLIC,
  { File.basename(HOME_LINK_SOURCE) => File.basename(HOME_LINK_PUBLIC) },
  "Homepage news product menu"
)

abort "Missing homepage index.html" unless File.file?(HOME_PATH)
home = add_home_stylesheet!(read(HOME_PATH))
home = require_replace!(
  home,
  %(<link rel="modulepreload" href="#{HOME_PAGE_SOURCE}" crossorigin=""/>),
  %(<link rel="modulepreload" href="#{HOME_PAGE_PUBLIC}" crossorigin=""/>),
  "Homepage news cache-busted page bundle"
)
unless home.include?(HOME_LOADER_PUBLIC)
  abort "Homepage news loader: source URL not found" unless home.include?(HOME_LOADER_SOURCE)
  home.gsub!(HOME_LOADER_SOURCE, HOME_LOADER_PUBLIC)
end
{
  HOME_LAYOUT_SOURCE => HOME_LAYOUT_PUBLIC,
  HOME_LINK_SOURCE => HOME_LINK_PUBLIC,
  HOME_MEGA_SOURCE => HOME_MEGA_PUBLIC,
}.each do |source_url, public_url|
  next if home.include?(public_url)

  abort "Homepage news cache graph: source URL #{source_url} not found" unless home.include?(source_url)
  home.gsub!(source_url, public_url)
end
home = require_replace!(
  home,
  '<a href="/aksesuar-konfiquratoru/">Aksesuarlar</a><a href="#kredit-kalkulyator">Kredit</a>',
  '<a href="/xeberler/">Xəbərlər</a><a href="/aksesuar-konfiquratoru/">Aksesuarlar</a><a href="#kredit-kalkulyator">Kredit</a>',
  "Homepage prerendered news navigation"
)
home = require_replace!(
  home,
  '<a href="/aksesuar-konfiquratoru/">Aksesuarlar</a><a href="/ehtiyat-hisseleri/">Ehtiyat hissələri</a>',
  '<a href="/xeberler/">Xəbərlər</a><a href="/aksesuar-konfiquratoru/">Aksesuarlar</a><a href="/ehtiyat-hisseleri/">Ehtiyat hissələri</a>',
  "Homepage prerendered news footer"
)
unless home.include?('class="home-news section"')
  service_anchor = '<section class="service section" id="servis">'
  abort "Homepage news section: prerendered service anchor not found" unless home.include?(service_anchor)
  home.sub!(service_anchor, "#{HOME_NEWS_HTML}#{service_anchor}")
end
write(HOME_PATH, home)

abort "Missing sitemap.xml" unless File.file?(SITEMAP_PATH)

sitemap = File.read(SITEMAP_PATH, encoding: "UTF-8")
abort "Sitemap closing tag not found" unless sitemap.include?("</urlset>")

NewsConfig.urls(DomainConfig::SITE_ORIGIN).each do |url|
  next if sitemap.include?("<loc>#{url}</loc>")

  alternates = [
    %(<xhtml:link rel="alternate" hreflang="az" href="#{url}"/>),
    %(<xhtml:link rel="alternate" hreflang="x-default" href="#{url}"/>),
  ].join
  entry = %(  <url><loc>#{url}</loc>#{alternates}</url>\n)
  sitemap.sub!("</urlset>", "#{entry}</urlset>")
end

File.write(SITEMAP_PATH, sitemap, encoding: "UTF-8")
puts "News integration added #{NewsConfig::PAGES.size} Azerbaijani URLs and linked the homepage to news"
