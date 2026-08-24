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

errors << "Expected 47 HTML pages, found #{html_paths.size}" unless html_paths.size == 47

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
