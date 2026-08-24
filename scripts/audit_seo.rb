#!/usr/bin/env ruby
require "json"

ROOT = File.expand_path("..", __dir__)
SITE_ORIGIN = "https://cfmoto.az"
SOURCE_ORIGIN = "https://cfmoto-azerbaijan.dvhqpbbkmw.chatgpt.site"

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

  errors << "#{relative}: missing title" unless title
  errors << "#{relative}: missing meta description" unless description
  errors << "#{relative}: missing canonical" unless canonical
  errors << "#{relative}: canonical is outside #{SITE_ORIGIN}" if canonical && !canonical.start_with?(SITE_ORIGIN)

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

  errors << "#{relative}: contains source domain" if html.include?(SOURCE_ORIGIN)
  errors << "#{relative}: contains development preview meta" if html.include?("codex-preview")
  errors << "#{relative}: contains copied Cloudflare challenge" if html.include?("cdn-cgi/challenge-platform")
  errors << "#{relative}: contains broken showroom link" if html.include?('href=".showroom"')
end

errors << "Titles are not unique" unless titles.uniq.size == html_paths.size
errors << "Descriptions are not unique" unless descriptions.uniq.size == html_paths.size
errors << "Canonicals are not unique" unless canonicals.uniq.size == html_paths.size

sitemap_path = File.join(ROOT, "sitemap.xml")
if File.exist?(sitemap_path)
  sitemap_urls = File.read(sitemap_path, encoding: "UTF-8").scan(%r{<loc>(.*?)</loc>}).flatten
  errors << "Sitemap URL count does not match canonicals" unless sitemap_urls.size == canonicals.size
  errors << "Sitemap and canonical URLs differ" unless sitemap_urls.sort == canonicals.sort
else
  errors << "Missing sitemap.xml"
end

robots_path = File.join(ROOT, "robots.txt")
if !File.exist?(robots_path)
  errors << "Missing robots.txt"
elsif !File.read(robots_path, encoding: "UTF-8").include?("Sitemap: #{SITE_ORIGIN}/sitemap.xml")
  errors << "robots.txt does not advertise the sitemap"
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
  puts "SEO audit passed: #{html_paths.size} pages, #{canonicals.size} canonicals, valid JSON-LD and sitemap"
else
  warn errors.map { |error| "- #{error}" }.join("\n")
  exit 1
end
