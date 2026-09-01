#!/usr/bin/env ruby
require "json"
require_relative "category_config"
require_relative "content_config"
require_relative "domain_config"
require_relative "russian_config"

ROOT = File.expand_path("..", __dir__)
SITE_ORIGIN = DomainConfig::SITE_ORIGIN
CLEAN_IMAGE_SLUGS = %w[1000mt-x 750sr-s cforce-c4 cforce1000-touring].freeze
META_PIXEL_ID = DomainConfig::META_PIXEL_ID
META_PIXEL_HEAD_START = "<!-- CFMOTO:META-PIXEL:HEAD:START -->"
META_PIXEL_HEAD_END = "<!-- CFMOTO:META-PIXEL:HEAD:END -->"
META_PIXEL_BODY_START = "<!-- CFMOTO:META-PIXEL:BODY:START -->"
META_PIXEL_BODY_END = "<!-- CFMOTO:META-PIXEL:BODY:END -->"
GTM_HEAD_START = "<!-- CFMOTO:GTM:HEAD:START -->"
GTM_HEAD_END = "<!-- CFMOTO:GTM:HEAD:END -->"
GTM_BODY_START = "<!-- CFMOTO:GTM:BODY:START -->"
GTM_BODY_END = "<!-- CFMOTO:GTM:BODY:END -->"
GOOGLE_TAG_MANAGER_ID = DomainConfig::GOOGLE_TAG_MANAGER_ID
META_PIXEL_NOSCRIPT = "https://www.facebook.com/tr?id=#{META_PIXEL_ID}&ev=PageView&noscript=1"

def expected_primary_model_image(slug)
  suffix = CLEAN_IMAGE_SLUGS.include?(slug) ? "-clean" : ""
  "/models/#{slug}#{suffix}.webp"
end

def walk_json(value, &block)
  yield value
  case value
  when Hash
    value.each_value { |nested| walk_json(nested, &block) }
  when Array
    value.each { |nested| walk_json(nested, &block) }
  end
end

errors = []
html_paths = [
  File.join(ROOT, "index.html"),
  *Dir.glob(File.join(ROOT, "model", "*", "index.html")).sort,
  *ContentConfig.html_paths(ROOT),
  *CategoryConfig.html_paths(ROOT)
]
titles = []
descriptions = []
canonicals = []

expected_page_count = 1 + Dir.glob(File.join(ROOT, "model", "*", "index.html")).size + ContentConfig::SLUGS.size + CategoryConfig::SLUGS.size
errors << "Expected #{expected_page_count} HTML pages, found #{html_paths.size}" unless html_paths.size == expected_page_count

html_paths.each do |path|
  relative = path.delete_prefix("#{ROOT}/")
  html = File.read(path, encoding: "UTF-8")

  title = html[/<title>(.*?)<\/title>/m, 1]
  description = html[/<meta name="description" content="([^"]+)"\s*\/>/, 1]
  canonical = html[/<link rel="canonical" href="([^"]+)"\s*\/>/, 1]
  og_url = html[/<meta property="og:url" content="([^"]+)"\s*\/>/, 1]
  og_image = html[/<meta property="og:image" content="([^"]+)"\s*\/>/, 1]
  twitter_image = html[/<meta name="twitter:image" content="([^"]+)"\s*\/>/, 1]
  expected_canonical = relative == "index.html" ? "#{SITE_ORIGIN}/" : "#{SITE_ORIGIN}/#{relative.delete_suffix("/index.html")}/"

  errors << "#{relative}: missing title" unless title
  errors << "#{relative}: missing meta description" unless description
  errors << "#{relative}: missing canonical" unless canonical
  errors << "#{relative}: canonical must be #{expected_canonical}" unless canonical == expected_canonical
  errors << "#{relative}: og:url must match canonical" unless og_url == expected_canonical
  errors << "#{relative}: og:image must use #{SITE_ORIGIN}" unless og_image&.start_with?("#{SITE_ORIGIN}/")
  errors << "#{relative}: twitter:image must use #{SITE_ORIGIN}" unless twitter_image&.start_with?("#{SITE_ORIGIN}/")

  titles << title if title
  descriptions << description if description
  canonicals << canonical if canonical

  %w[og:title og:description og:url og:image og:locale og:site_name].each do |property|
    errors << "#{relative}: missing #{property}" unless html.include?(%(property="#{property}"))
  end

  %w[twitter:card twitter:title twitter:description twitter:image].each do |name|
    errors << "#{relative}: missing #{name}" unless html.include?(%(name="#{name}"))
  end

  headings = html.scan(/<h1\b/i).size
  errors << "#{relative}: expected one H1, found #{headings}" unless headings == 1

  if relative != "index.html"
    slashless_canonical = expected_canonical.delete_suffix("/")
    slashless_pattern = %r!#{Regexp.escape(slashless_canonical)}(?=["\\#?<\s,}\]]|\z)!
    errors << "#{relative}: contains slashless self URL #{slashless_canonical}" if html.match?(slashless_pattern)
  end

  schemas = html.scan(%r{<script type="application/ld\+json">(.*?)</script>}m).flatten
  errors << "#{relative}: missing JSON-LD" if schemas.empty?
  parsed_schemas = []
  schemas.each do |schema|
    parsed_schemas << JSON.parse(schema)
  rescue JSON::ParserError => error
    errors << "#{relative}: invalid JSON-LD (#{error.message})"
  end
  parsed_schemas.each do |schema|
    walk_json(schema) do |value|
      if value.is_a?(String) && value.start_with?("#{SITE_ORIGIN}/")
        suffix = value.delete_prefix(SITE_ORIGIN)
        slashless_route = suffix.match?(%r{\A/model/[a-z0-9-]+\z}i) || ContentConfig::SLUGS.any? { |slug| suffix == "/#{slug}" }
        errors << "#{relative}: JSON-LD route URL must end with a slash: #{value}" if slashless_route
      end
      next unless value.is_a?(Hash)

      types = Array(value["@type"])
      if types.include?("WebPage") && value["url"]
        errors << "#{relative}: WebPage URL must match canonical" unless value["url"] == expected_canonical
      end
      if relative.start_with?("model/") && types.include?("Product")
        offer_url = value.dig("offers", "url")
        errors << "#{relative}: Product offer URL must match canonical" unless offer_url == expected_canonical
      end
    end
  end

  DomainConfig::NON_CANONICAL_SITE_ORIGINS.each do |origin|
    errors << "#{relative}: contains non-canonical origin #{origin}" if html.include?(origin)
  end
  errors << "#{relative}: contains development preview meta" if html.include?("codex-preview")
  errors << "#{relative}: contains copied Cloudflare challenge" if html.include?("cdn-cgi/challenge-platform")
  errors << "#{relative}: contains broken showroom link" if html.include?('href=".showroom"')

  errors << "#{relative}: expected one GA4 analytics block" unless html.scan("<!-- CFMOTO:ANALYTICS:START -->").size == 1 && html.scan("<!-- CFMOTO:ANALYTICS:END -->").size == 1
  errors << "#{relative}: expected one GA4 loader" unless html.scan("googletagmanager.com/gtag/js?id=#{DomainConfig::GA4_MEASUREMENT_ID}").size == 1
  errors << "#{relative}: expected one GA4 configuration" unless html.scan("gtag('config','#{DomainConfig::GA4_MEASUREMENT_ID}')").size == 1
  errors << "#{relative}: expected one GTM head block" unless html.scan(GTM_HEAD_START).size == 1 && html.scan(GTM_HEAD_END).size == 1
  errors << "#{relative}: legacy GTM body block can trigger hydration mismatch" unless html.scan(GTM_BODY_START).empty? && html.scan(GTM_BODY_END).empty?
  errors << "#{relative}: expected one GTM loader" unless html.scan("googletagmanager.com/gtm.js?id='+i+dl").size == 1 && html.scan("'#{GOOGLE_TAG_MANAGER_ID}'").size == 1
  errors << "#{relative}: GTM noscript iframe must not sit outside the hydrated React tree" unless html.scan("googletagmanager.com/ns.html?id=#{GOOGLE_TAG_MANAGER_ID}").empty?
  normalized_html = html.gsub("&amp;", "&")
  errors << "#{relative}: Meta Pixel must be owned only by GTM (head marker found)" unless html.scan(META_PIXEL_HEAD_START).empty? && html.scan(META_PIXEL_HEAD_END).empty?
  errors << "#{relative}: Meta Pixel must be owned only by GTM (body marker found)" unless html.scan(META_PIXEL_BODY_START).empty? && html.scan(META_PIXEL_BODY_END).empty?
  errors << "#{relative}: duplicate direct Meta Pixel loader remains" unless html.scan("connect.facebook.net/en_US/fbevents.js").empty?
  errors << "#{relative}: duplicate direct Meta Pixel init remains" unless html.scan("fbq('init','#{META_PIXEL_ID}')").empty?
  errors << "#{relative}: duplicate direct Meta Pixel PageView remains" unless html.scan("fbq('track','PageView')").empty?
  errors << "#{relative}: duplicate direct Meta Pixel noscript remains" unless normalized_html.scan(/#{Regexp.escape(META_PIXEL_NOSCRIPT)}/).empty?
  body_open_index = html.index(%r{<body\b[^>]*>}i)
  body_close_index = html.index("</body>")
  errors << "#{relative}: missing <body> tag" unless body_open_index
  errors << "#{relative}: missing </body> tag" unless body_close_index

  if html.include?("__VINEXT_RSC_")
    rsc_canonicals = html.scan(%r{\\"rel\\":\\"canonical\\",\\"href\\":\\"([^\\"]+)\\"}).flatten
    errors << "#{relative}: hydrated canonical must be exactly #{expected_canonical}; found #{rsc_canonicals.inspect}" unless rsc_canonicals == [expected_canonical]
    rsc_alternates = html.scan(%r{\\"rel\\":\\"alternate\\",\\"hrefLang\\":\\"(az|ru|x-default)\\",\\"href\\":\\"([^\\"]+)\\"})
    expected_ru = relative == "index.html" ? "#{SITE_ORIGIN}/ru/" : "#{SITE_ORIGIN}/ru/model/#{File.basename(File.dirname(path))}/"
    expected_rsc_alternates = {
      "az" => expected_canonical,
      "ru" => expected_ru,
      "x-default" => expected_canonical
    }
    errors << "#{relative}: hydrated hreflang set must be #{expected_rsc_alternates.inspect}; found #{rsc_alternates.inspect}" unless rsc_alternates.size == 3 && rsc_alternates.to_h == expected_rsc_alternates
  end
  %w[whatsapp_click phone_click directions_click finance_lead_click].each do |event_name|
    errors << "#{relative}: missing GA4 event #{event_name}" unless html.include?("'#{event_name}'")
  end

  logo_tags = html.scan(%r{<img\b[^>]*src="/cfmoto-logo-black\.png"[^>]*>})
  errors << "#{relative}: missing CFMOTO logo" if logo_tags.empty?
  logo_tags.each do |tag|
    errors << "#{relative}: CFMOTO logo is missing intrinsic dimensions" unless tag.include?('width="159"') && tag.include?('height="34"')
  end
end

errors << "Titles are not unique" unless titles.uniq.size == html_paths.size
errors << "Descriptions are not unique" unless descriptions.uniq.size == html_paths.size
errors << "Canonicals are not unique" unless canonicals.uniq.size == html_paths.size

sitemap_path = File.join(ROOT, "sitemap.xml")
if File.exist?(sitemap_path)
  sitemap_urls = File.read(sitemap_path, encoding: "UTF-8").scan(%r{<loc>(.*?)</loc>}).flatten
  russian_canonicals = html_paths.map do |path|
    relative = path.delete_prefix("#{ROOT}/")
    if relative == "index.html"
      "#{SITE_ORIGIN}/ru/"
    elsif relative.start_with?("model/")
      "#{SITE_ORIGIN}/ru/model/#{File.basename(File.dirname(path))}/"
    elsif ContentConfig::SLUGS.include?(File.basename(File.dirname(path)))
      "#{SITE_ORIGIN}/ru/#{RussianConfig.ru_content_slug(File.basename(File.dirname(path)))}/"
    else
      "#{SITE_ORIGIN}/ru/#{RussianConfig.ru_category_slug(File.basename(File.dirname(path)))}/"
    end
  end
  expected_sitemap_urls = canonicals.zip(russian_canonicals).flat_map { |pair| pair }
  errors << "Sitemap must contain #{expected_sitemap_urls.size} Azerbaijani and Russian URLs" unless sitemap_urls.size == expected_sitemap_urls.size
  errors << "Sitemap and bilingual canonical URLs differ" unless sitemap_urls == expected_sitemap_urls
  sitemap = File.read(sitemap_path, encoding: "UTF-8")
  errors << "Sitemap is missing the XHTML namespace" unless sitemap.include?('xmlns:xhtml="http://www.w3.org/1999/xhtml"')
else
  errors << "Missing sitemap.xml"
end

robots_path = File.join(ROOT, "robots.txt")
if !File.exist?(robots_path)
  errors << "Missing robots.txt"
elsif File.read(robots_path, encoding: "UTF-8") != "User-agent: *\nDisallow:\n\nSitemap: #{SITE_ORIGIN}/sitemap.xml\n"
  errors << "robots.txt does not contain the canonical sitemap directive"
end

llms_path = File.join(ROOT, "llms.txt")
if !File.exist?(llms_path)
  errors << "Missing llms.txt"
else
  llms = File.read(llms_path, encoding: "UTF-8")
  errors << "llms.txt is missing its site heading" unless llms.start_with?("# CFMOTO Azerbaijan\n")
  errors << "llms.txt is missing the canonical site URL" unless llms.include?("https://cfmoto.az/")
end

errors << "Missing social preview image" unless File.exist?(File.join(ROOT, "official-800mtx-hero.webp"))

home_path = File.join(ROOT, "index.html")
home = File.read(home_path, encoding: "UTF-8")
{
  "delivery price" => "45 AZN",
  "delivery label" => "Şəhərdaxili çatdırılma",
  "showroom schedule" => "Salon hər gün açıqdır",
  "service schedule" => "Bazar ertəsi xaric hər gün 10:00–19:00",
  "CFORCE C5 card" => 'href="/model/cforce-c5/"',
  "CFORCE C5 VAT note" => "13,900 AZN · ƏDV daxil",
  "U10 PRO card" => "U10 PRO"
}.each do |label, text|
  errors << "Home is missing #{label}" unless home.include?(text)
end
errors << "Home repeats the service schedule" unless home.scan("Bazar ertəsi xaric hər gün 10:00–19:00.").size == 1

c5_path = File.join(ROOT, "model", "cforce-c5", "index.html")
if !File.file?(c5_path)
  errors << "Missing CFORCE C5 detail page"
else
  c5 = File.read(c5_path, encoding: "UTF-8")
  errors << "CFORCE C5 page is missing VAT-inclusive price" unless c5.include?("Nağd satış qiyməti · ƏDV daxil") && c5.include?("13,900 AZN")
  errors << "CFORCE C5 page is missing Product schema" unless c5.include?('"@type":"Product"')
  errors << "CFORCE C5 blue color is not mapped to its image" unless c5.include?('src="/models/cforce-c5.webp"') && c5.include?("Zephyr Blue")
  errors << "CFORCE C5 red color is not mapped to its image" unless c5.include?("/models/cforce-c5-red.webp") && c5.include?("Magma Red")
  errors << "CFORCE C5 page still references C4 color imagery" if c5.include?("/atv/atv/c4/2026/model")
end

u10_path = File.join(ROOT, "model", "u10-pro", "index.html")
if !File.file?(u10_path)
  errors << "Missing U10 PRO detail page"
else
  u10 = File.read(u10_path, encoding: "UTF-8")
  errors << "U10 page is missing its original model name" unless u10.include?('<h1 class="product-title">U10 PRO</h1>') && !u10.include?("U10 PRO HIGHLAND")
  errors << "U10 PRO must use its original model image" unless u10.include?("/models/u10-pro.webp")
  errors << "U10 PRO must use its original gallery" unless u10.include?("/gallery/u10-pro-1.webp")
  errors << "U10 PRO must use a local primary and retain alternate color imagery" unless u10.include?('/models/u10-pro.webp') && u10.include?("/sxs/utility/u10-pro/2026/model2.png") && u10.include?("/sxs/utility/u10-pro/2026/model3.png")
end

html_paths.each do |path|
  html = File.read(path, encoding: "UTF-8")
  errors << "#{path.delete_prefix("#{ROOT}/")}: contains obsolete Monday-closed showroom text" if html.include?("Bazar ertəsi bağlıdır")
  html.scan(%r{(?:href|src)="(/assets/[^"?#]+\.js)}) do |match|
    asset_path = File.join(ROOT, match.first.delete_prefix("/"))
    errors << "#{path.delete_prefix("#{ROOT}/")}: missing JS asset #{match.first}" unless File.file?(asset_path)
  end
end

Dir.glob(File.join(ROOT, "assets", "*.js")).each do |path|
  javascript = File.read(path, encoding: "UTF-8")
  javascript.scan(%r{(?:from|import\()[`"]\./([^`"]+\.js)}) do |match|
    dependency = File.join(File.dirname(path), match.first)
    errors << "#{File.basename(path)}: missing JS dependency #{match.first}" unless File.file?(dependency)
  end
end

public_text_paths = [
  *html_paths,
  *Dir.glob(File.join(ROOT, "assets", "*.{js,css}")),
  sitemap_path,
  robots_path,
  File.join(ROOT, "_redirects")
].select { |path| File.file?(path) }
public_text_paths.each do |path|
  content = File.read(path, encoding: "UTF-8")
  errors << "#{path.delete_prefix("#{ROOT}/")}: contains a pages.dev origin" if content.match?(DomainConfig::PAGES_SITE_ORIGIN_PATTERN)
  DomainConfig::NON_CANONICAL_SITE_ORIGINS.each do |origin|
    errors << "#{path.delete_prefix("#{ROOT}/")}: contains non-canonical origin #{origin}" if content.include?(origin)
  end
  DomainConfig::LEGACY_INSTAGRAM_URLS.each do |url|
    errors << "#{path.delete_prefix("#{ROOT}/")}: contains legacy Instagram URL #{url}" if content.include?(url)
  end
end

errors << "Home is missing the confirmed Instagram profile" unless home.include?(DomainConfig::INSTAGRAM_URL)
CategoryConfig::SLUGS.each do |slug|
  errors << "Home is missing internal category link /#{slug}/" unless home.include?(%(href="/#{slug}/"))
end

content_expectations = {
  "kredit" => ["20% · 18 ayadək", "40% · 18 ayadək", "50% · 12 ayadək", '"@type":"FAQPage"'],
  "servis" => ["Bazar ertəsi istisna olmaqla", "+994 10 241 42 99", "45 AZN", '"@type":"Service"'],
  "zemanet" => ["2 il / 24.000 km", "model və istifadə rejiminə görə", "ümumi məlumat verir"],
  "ehtiyat-hisseleri" => ["orijinal ehtiyat hissələri", "yağlar və aksesuarlar", "mövcudluq telefon sorğusu"],
  "model-muqayisesi" => ["48 aktual modeli", "Minimum ilkin ödəniş", '"numberOfItems":48']
}
content_expectations.each do |slug, expected_texts|
  path = File.join(ROOT, slug, "index.html")
  if !File.file?(path)
    errors << "Missing SEO content page /#{slug}"
    next
  end
  content = File.read(path, encoding: "UTF-8")
  expected_texts.each do |text|
    errors << "/#{slug} is missing required content: #{text}" unless content.include?(text)
  end
  ContentConfig::SLUGS.each do |linked_slug|
    errors << "/#{slug}/ is missing internal link /#{linked_slug}/" unless content.include?(%(href="/#{linked_slug}/"))
  end
end

category_expectations = {
  "motosiklet" => {
    title: "Motosiklet Satışı və Qiymətləri | CFMOTO Azerbaijan",
    count: 30,
    required: ["CFMOTO motosiklet satışı və qiymətləri", "Maliyyələşmə şərtləri", "20%", "40%"]
  },
  "kvadrosikl" => {
    title: "Kvadrosikl (ATV) Satışı və Qiymətləri | CFMOTO Azerbaijan",
    count: 9,
    required: ["CFMOTO kvadrosikl və ATV qiymətləri", "Maliyyələşmə şərtləri", "50%"]
  },
  "buggy" => {
    title: "Buggy və UTV Modelləri | CFMOTO Azerbaijan",
    count: 9,
    required: ["CFMOTO buggy, SSV və UTV modelləri", "Maliyyələşmə şərtləri", "50%"]
  }
}
category_expectations.each do |slug, expectation|
  path = File.join(ROOT, slug, "index.html")
  if !File.file?(path)
    errors << "Missing category page /#{slug}/"
    next
  end

  category = File.read(path, encoding: "UTF-8")
  errors << "/#{slug}/ has the wrong requested title" unless category.include?("<title>#{expectation.fetch(:title)}</title>")
  card_count = category.scan('class="category-model-card"').size
  errors << "/#{slug}/ expected #{expectation.fetch(:count)} product cards, found #{card_count}" unless card_count == expectation.fetch(:count)
  price_count = category.scan(%r{<strong>[\d,]+ AZN(?: · ƏDV daxil)?</strong>}).size
  pending_price_count = category.scan(%r{<strong>Dəqiqləşdirin</strong>}).size
  errors << "/#{slug}/ expected a price or enquiry label for every product" unless price_count + pending_price_count == card_count
  expectation.fetch(:required).each do |text|
    errors << "/#{slug}/ is missing required content: #{text}" unless category.include?(text)
  end
  errors << "/#{slug}/ is missing FAQ structured data" unless category.include?('"@type":"FAQPage"')
  errors << "/#{slug}/ is missing collection structured data" unless category.include?('"@type":"CollectionPage"')
  errors << "/#{slug}/ is missing visible FAQ content" unless category.scan("<details>").size >= 4
  if slug == "motosiklet"
    category_model_slugs = category.scan(%r{<article class="category-model-card">.*?</article>}m).map do |card|
      card[%r{href="/model/([^/]+)/"}, 1]
    end.compact
    model_500sr_position = category_model_slugs.index("500sr")
    model_500sr_voom_position = category_model_slugs.index("500sr-voom")
    errors << "/motosiklet/ must contain 500SR exactly once" unless category_model_slugs.count("500sr") == 1
    errors << "/motosiklet/ must place 500SR immediately before 500SR VOOM" unless model_500sr_position && model_500sr_voom_position && model_500sr_position + 1 == model_500sr_voom_position
    errors << "/motosiklet/ must identify 30 current motorcycles" unless category.include?("30 aktual motosiklet")
  end
  CategoryConfig::SLUGS.each do |linked_slug|
    errors << "/#{slug}/ is missing internal link /#{linked_slug}/" unless category.include?(%(href="/#{linked_slug}/"))
  end
end

card_images = Dir.glob(File.join(ROOT, "models", "cards", "*.webp"))
errors << "Expected 48 base and 4 clean optimized model card images, found #{card_images.size}" unless card_images.size == 52
homepage_card_sources = home.scan(%r{src="(/models/cards/[^"]+\.webp)"}).flatten
errors << "Homepage must use all 48 optimized model card images" unless homepage_card_sources.uniq.size == 48
homepage_card_sources.uniq.each do |source|
  errors << "Homepage card image is missing: #{source}" unless File.file?(File.join(ROOT, source.delete_prefix("/")))
end
CLEAN_IMAGE_SLUGS.each do |slug|
  clean_card = "/models/cards/#{slug}-clean.webp"
  errors << "Homepage must use clean card image #{clean_card}" unless homepage_card_sources.include?(clean_card)
  card = home[%r{<article class="model-card"><a href="/model/#{Regexp.escape(slug)}/".*?</article>}m]
  errors << "Homepage clean model #{slug} must use the orange Yeni badge" unless card&.include?('<span class="badge">Yeni</span>')
end

menu_bundle = Dir.glob(File.join(ROOT, "assets", "ProductMegaMenu-CfmotoPolicyFixV*.js")).max
if menu_bundle.nil?
  errors << "Missing product mega-menu bundle"
else
  menu_javascript = File.read(menu_bundle, encoding: "UTF-8")
  CLEAN_IMAGE_SLUGS.each do |slug|
    entry = menu_javascript[%r!\{slug:`#{Regexp.escape(slug)}`,[^{}]+\}!]
    errors << "Mega-menu clean model #{slug} must use the orange Yeni badge" unless entry&.include?('badge:`Yeni`')
  end
end

Dir.glob(File.join(ROOT, "model", "*", "index.html")).sort.each do |path|
  slug = File.basename(File.dirname(path))
  content = File.read(path, encoding: "UTF-8")
  primary = expected_primary_model_image(slug)
  errors << "#{slug}: primary model image is not local" unless content.match?(%r{<img class="model-color-image"[^>]*src="#{Regexp.escape(primary)}"})
  errors << "#{slug}: primary model preload is not local" unless content.include?(%(<link rel="preload" as="image" href="#{primary}"))
end

model_500sr_page = File.read(File.join(ROOT, "model", "500sr", "index.html"), encoding: "UTF-8")
errors << "500SR color selector is missing" unless model_500sr_page.include?('data-500sr-colors') && model_500sr_page.scan('data-500sr-color-button').size == 2
errors << "500SR official Galaxy Grey color is missing" unless model_500sr_page.include?('data-name="Galaxy Grey"') && model_500sr_page.include?('data-image="/models/500sr.webp"')
errors << "500SR official Nebula White color is missing" unless model_500sr_page.include?('data-name="Nebula White"') && model_500sr_page.include?('data-image="/models/500sr-nebula-white.webp"')
errors << "500SR color-selector script is missing" unless model_500sr_page.include?('/assets/500sr-colors-v1.js') && File.file?(File.join(ROOT, "assets", "500sr-colors-v1.js"))
errors << "500SR Nebula White image is missing" unless File.file?(File.join(ROOT, "models", "500sr-nebula-white.webp"))

public_code_paths = [
  *Dir.glob(File.join(ROOT, "**", "*.html")),
  *Dir.glob(File.join(ROOT, "assets", "*.js"))
].reject { |path| path.start_with?("#{ROOT}/dist/") }
CLEAN_IMAGE_SLUGS.each do |slug|
  original_sources = ["/models/#{slug}.webp", "/models/cards/#{slug}.webp"]
  original_sources.each do |source|
    referenced_by = public_code_paths.find { |path| File.read(path, encoding: "UTF-8").include?(source) }
    errors << "Red-label original remains referenced: #{source} in #{referenced_by.delete_prefix("#{ROOT}/")}" if referenced_by
  end
end

errors << "Unused Vinext font CSS remains in public HTML" if html_paths.any? { |path| File.read(path, encoding: "UTF-8").include?("<style data-vinext-fonts>") }
errors << "GA4 loader must have low fetch priority" if html_paths.any? { |path| !File.read(path, encoding: "UTF-8").include?('<script async fetchpriority="low" src="https://www.googletagmanager.com/gtag/js') }

redirects_path = File.join(ROOT, "_redirects")
redirects = {}
DomainConfig::LEGACY_PATH_REDIRECTS.each do |source, destination|
  next unless destination.start_with?("/model/")

  errors << "Legacy redirect #{source} model target must end with a slash" unless destination.end_with?("/")
end
if !File.file?(redirects_path)
  errors << "Missing _redirects"
else
  File.readlines(redirects_path, chomp: true, encoding: "UTF-8").each_with_index do |line, index|
    next if line.empty? || line.start_with?("#")

    source, destination, status, extra = line.split(/\s+/, 4)
    if !source || !destination || !status || extra
      errors << "_redirects line #{index + 1} is malformed"
      next
    end
    errors << "_redirects line #{index + 1} must be a 301" unless status == "301"
    errors << "_redirects line #{index + 1} uses unsupported domain-level matching" if source.match?(%r{\Ahttps?://})
    errors << "_redirects repeats source #{source}" if redirects.key?(source)
    redirects[source] = destination
  end

  expected_redirects = DomainConfig::LEGACY_PATH_REDIRECTS.dup
  Dir.glob(File.join(ROOT, "model", "*", "index.html")).sort.each do |path|
    slug = File.basename(File.dirname(path))
    expected_redirects["/#{slug}"] ||= "/model/#{slug}/"
  end
  missing_redirects = expected_redirects.reject { |source, destination| redirects[source] == destination }
  unexpected_redirects = redirects.reject { |source, destination| expected_redirects[source] == destination }
  errors << "_redirects is missing or misroutes: #{missing_redirects.keys.join(', ')}" unless missing_redirects.empty?
  errors << "_redirects has unexpected rules: #{unexpected_redirects.keys.join(', ')}" unless unexpected_redirects.empty?
end

host_redirects_path = File.join(ROOT, "cloudflare", "domain-redirects.json")
if !File.file?(host_redirects_path)
  errors << "Missing Cloudflare host redirect manifest"
else
  begin
    manifest = JSON.parse(File.read(host_redirects_path, encoding: "UTF-8"))
    rules = manifest.fetch("rules")
    expected_patterns = %w[
      http*://cfmoto.com.az/*
      http*://www.cfmoto.com.az/*
      http*://www.cfmoto.az/*
    ]
    actual_patterns = rules.map { |rule| rule["request_url"] }
    errors << "Cloudflare host redirect patterns are incomplete" unless actual_patterns.sort == expected_patterns.sort
    rules.each do |rule|
      errors << "Cloudflare host redirect #{rule['name']} must be a 301" unless rule["status_code"] == 301
      errors << "Cloudflare host redirect #{rule['name']} must preserve paths" unless rule["preserve_path"] == true
      errors << "Cloudflare host redirect #{rule['name']} must preserve query strings" unless rule["preserve_query_string"] == true
      errors << "Cloudflare host redirect #{rule['name']} must target #{SITE_ORIGIN}" unless rule["target_origin"] == SITE_ORIGIN
    end

    bulk_redirect = manifest.fetch("account_bulk_redirect")
    errors << "Pages bulk redirect must use the production pages.dev source" unless bulk_redirect["source_url"] == "https://cfmoto-azerbaijan.pages.dev"
    errors << "Pages bulk redirect must target #{SITE_ORIGIN}" unless bulk_redirect["target_url"] == SITE_ORIGIN
    errors << "Pages bulk redirect must be a 301" unless bulk_redirect["status_code"] == 301
    %w[preserve_query_string subpath_matching preserve_path_suffix include_subdomains].each do |setting|
      errors << "Pages bulk redirect must enable #{setting}" unless bulk_redirect[setting] == true
    end
  rescue JSON::ParserError, KeyError => error
    errors << "Invalid Cloudflare host redirect manifest: #{error.message}"
  end
end

%w[
  models/cforce-c5.webp
  models/cforce-c5-red.webp
  gallery/cforce-c5-1.webp
  gallery/cforce-c5-2.webp
  gallery/cforce-c5-3.webp
].each do |relative|
  errors << "Missing required product image: #{relative}" unless File.file?(File.join(ROOT, relative))
end

not_found_path = File.join(ROOT, "404.html")
if !File.exist?(not_found_path)
  errors << "Missing 404.html"
else
  not_found = File.read(not_found_path, encoding: "UTF-8")
  errors << "404.html must be noindex" unless not_found.include?('name="robots" content="noindex,follow"')
  errors << "404.html must link to the homepage" unless not_found.include?('href="/"')
end

headers_path = File.join(ROOT, "_headers")
if !File.exist?(headers_path)
  errors << "Missing _headers"
else
  headers = File.read(headers_path, encoding: "UTF-8")
  %w[X-Content-Type-Options X-Frame-Options Referrer-Policy Permissions-Policy].each do |header|
    errors << "_headers is missing #{header}" unless headers.include?(header)
  end
  errors << "_headers is missing the safe one-year HSTS policy" unless headers.include?("Strict-Transport-Security: max-age=31536000")
  errors << "_headers is missing the llms.txt cache policy" unless headers.match?(%r{/llms\.txt\s+Cache-Control: public, max-age=3600}m)
end

if errors.empty?
  puts "SEO audit passed: #{html_paths.size} pages, #{canonicals.size} canonicals, valid JSON-LD, sitemap and #{redirects.size} redirects"
else
  warn errors.map { |error| "- #{error}" }.join("\n")
  exit 1
end
