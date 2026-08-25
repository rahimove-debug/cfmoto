#!/usr/bin/env ruby
require "json"
require_relative "domain_config"

ROOT = File.expand_path("..", __dir__)
SITE_ORIGIN = DomainConfig::SITE_ORIGIN

errors = []
html_paths = [
  File.join(ROOT, "index.html"),
  *Dir.glob(File.join(ROOT, "model", "*", "index.html")).sort
]
titles = []
descriptions = []
canonicals = []

errors << "Expected 48 HTML pages, found #{html_paths.size}" unless html_paths.size == 48

html_paths.each do |path|
  relative = path.delete_prefix("#{ROOT}/")
  html = File.read(path, encoding: "UTF-8")

  title = html[/<title>(.*?)<\/title>/m, 1]
  description = html[/<meta name="description" content="([^"]+)"\s*\/>/, 1]
  canonical = html[/<link rel="canonical" href="([^"]+)"\s*\/>/, 1]
  og_url = html[/<meta property="og:url" content="([^"]+)"\s*\/>/, 1]
  og_image = html[/<meta property="og:image" content="([^"]+)"\s*\/>/, 1]
  twitter_image = html[/<meta name="twitter:image" content="([^"]+)"\s*\/>/, 1]
  expected_canonical = if relative == "index.html"
    "#{SITE_ORIGIN}/"
  else
    "#{SITE_ORIGIN}/model/#{File.basename(File.dirname(path))}"
  end

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

  schemas = html.scan(%r{<script type="application/ld\+json">(.*?)</script>}m).flatten
  errors << "#{relative}: missing JSON-LD" if schemas.empty?
  schemas.each do |schema|
    JSON.parse(schema)
  rescue JSON::ParserError => error
    errors << "#{relative}: invalid JSON-LD (#{error.message})"
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
  errors << "Sitemap URL count does not match canonicals" unless sitemap_urls.size == canonicals.size
  errors << "Sitemap and canonical URLs differ" unless sitemap_urls == canonicals
else
  errors << "Missing sitemap.xml"
end

robots_path = File.join(ROOT, "robots.txt")
if !File.exist?(robots_path)
  errors << "Missing robots.txt"
elsif File.read(robots_path, encoding: "UTF-8") != "User-agent: *\nAllow: /\nSitemap: #{SITE_ORIGIN}/sitemap.xml\n"
  errors << "robots.txt does not contain the canonical sitemap directive"
end

errors << "Missing social preview image" unless File.exist?(File.join(ROOT, "official-800mtx-hero.webp"))

home_path = File.join(ROOT, "index.html")
home = File.read(home_path, encoding: "UTF-8")
{
  "delivery price" => "45 AZN",
  "delivery label" => "Şəhərdaxili çatdırılma",
  "showroom schedule" => "Salon hər gün açıqdır",
  "service schedule" => "Bazar ertəsi xaric hər gün 10:00–19:00",
  "CFORCE C5 card" => 'href="/model/cforce-c5"',
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
  errors << "U10 PRO must use its original color imagery" unless u10.include?("/sxs/utility/u10-pro/2026/model1.png")
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

redirects_path = File.join(ROOT, "_redirects")
redirects = {}
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
    expected_redirects["/#{slug}"] ||= "/model/#{slug}"
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
end

if errors.empty?
  puts "SEO audit passed: #{html_paths.size} pages, #{canonicals.size} canonicals, valid JSON-LD, sitemap and #{redirects.size} redirects"
else
  warn errors.map { |error| "- #{error}" }.join("\n")
  exit 1
end
