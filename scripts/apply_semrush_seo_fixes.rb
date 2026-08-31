#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

ROOT = File.expand_path("..", __dir__)
CONFIGURATOR_CANONICAL = "https://cfmoto.az/aksesuar-konfiquratoru/"
SELLER = {
  "@type" => "Organization",
  "name" => "CFMOTO Azerbaijan — SAZMOTO MMC",
  "url" => "https://cfmoto.az/"
}.freeze
PRODUCT_OFFERS = {
  "CFMOTO 450MT" => ["11990", "https://cfmoto.az/model/450mt/"],
  "CFORCE C4" => ["12400", "https://cfmoto.az/model/cforce-c4/"],
  "CFORCE C5" => ["13900", "https://cfmoto.az/model/cforce-c5/"],
  "Z10" => ["45900", "https://cfmoto.az/model/z10/"],
  "Z10-4" => ["47900", "https://cfmoto.az/model/z10-4/"]
}.freeze
EVENT_TOPICS = {
  "Red Bull Romaniacs 2026" => {
    "description" => "Red Bull Romaniacs 2026, 28 iyul–1 avqust tarixlərində Sibiu və Cənubi Karpatlarda keçirilən hard-enduro yarışı.",
    "sameAs" => "https://www.redbullromaniacs.com/visitors/event-news-reports/details/eng-hard-adventure-racing-baptism-of-fire-2"
  },
  "2026 MotoGP Almaniya Qran Prisi" => {
    "description" => "2026 MotoGP Almaniya Qran Prisi, 10–12 iyul tarixlərində Sachsenring trasında keçirilən motosiklet yarış mərhələsi.",
    "sameAs" => "https://www.cfmoto.com/global/media-center/news/2026/quiles-opens-grand-prix-podium-champagne-again-for-cfmoto-in-ger.html"
  }
}.freeze

def fix_configurator!
  path = File.join(ROOT, "aksesuar-konfiquratoru", "index.html")
  html = File.read(path, encoding: "UTF-8")
  html.gsub!(
    %r{<link rel="alternate" hrefLang="(?:az-AZ|x-default)" href="#{Regexp.escape(CONFIGURATOR_CANONICAL)}"/>},
    ""
  )
  html.gsub!(
    %r{,\[\\"\$\\",\\"link\\",\\"\d+\\",\{\\"rel\\":\\"alternate\\",\\"hrefLang\\":\\"(?:az-AZ|x-default)\\",\\"href\\":\\"#{Regexp.escape(CONFIGURATOR_CANONICAL)}\\"\}\]},
    ""
  )
  html.gsub!('<h1 id="configurator-seo-title">', '<h2 id="configurator-seo-title">')
  html.gsub!('</h1><p>Konfiquratorda', '</h2><p>Konfiquratorda')
  html.gsub!(
    '[\\"$\\",\\"h1\\",null,{\\"id\\":\\"configurator-seo-title\\"',
    '[\\"$\\",\\"h2\\",null,{\\"id\\":\\"configurator-seo-title\\"'
  )
  loading_shell = '<main class="loading-shell">Konfiqurator hazırlanır…</main>'
  loading_shell_with_h1 = '<main class="loading-shell"><h1>CFMOTO Aksesuar Konfiquratoru</h1><p>Konfiqurator hazırlanır…</p></main>'
  html.sub!(loading_shell, loading_shell_with_h1) unless html.include?(loading_shell_with_h1)

  abort "Configurator hreflang metadata remains" if html.include?("hrefLang")
  abort "Configurator must expose exactly one static H1" unless html.scan(/<h1\b/i).size == 1
  abort "Configurator persistent SEO heading must remain H2" unless html.include?('<h2 id="configurator-seo-title">')
  File.write(path, html, encoding: "UTF-8")
end

def fix_configurator_sitemap!
  path = File.join(ROOT, "sitemap.xml")
  sitemap = File.read(path, encoding: "UTF-8")
  sitemap.gsub!(%r{\s*<url><loc>#{Regexp.escape(CONFIGURATOR_CANONICAL)}</loc>.*?</url>\n?}, "")
  abort "Sitemap closing tag not found" unless sitemap.include?("</urlset>")
  sitemap.sub!("</urlset>", %(  <url><loc>#{CONFIGURATOR_CANONICAL}</loc></url>\n</urlset>))
  File.write(path, sitemap, encoding: "UTF-8")
end

def update_schema!(value, counts)
  case value
  when Hash
    if value["@type"] == "Product" && PRODUCT_OFFERS.key?(value["name"])
      price, url = PRODUCT_OFFERS.fetch(value["name"])
      value["offers"] = {
        "@type" => "Offer",
        "priceCurrency" => "AZN",
        "price" => price,
        "availability" => "https://schema.org/InStock",
        "url" => url,
        "seller" => SELLER
      }
      counts[value["name"]] += 1
    elsif ["SportsEvent", "Thing"].include?(value["@type"]) && EVENT_TOPICS.key?(value["name"])
      name = value.fetch("name")
      value.replace({
        "@type" => "Thing",
        "name" => name
      }.merge(EVENT_TOPICS.fetch(name)))
      counts[name] += 1
    end
    value.each_value { |child| update_schema!(child, counts) }
  when Array
    value.each { |child| update_schema!(child, counts) }
  end
end

counts = Hash.new(0)
article_paths = Dir.glob(File.join(ROOT, "xeberler", "*", "index.html")).sort

fix_configurator!
fix_configurator_sitemap!

article_paths.each do |path|
  html = File.read(path, encoding: "UTF-8")
  updated = html.gsub(%r{<script type="application/ld\+json">(.*?)</script>}m) do
    schema = JSON.parse(Regexp.last_match(1))
    update_schema!(schema, counts)
    %(<script type="application/ld+json">#{JSON.generate(schema)}</script>)
  end
  File.write(path, updated, encoding: "UTF-8")
end

expected = PRODUCT_OFFERS.keys + EVENT_TOPICS.keys
missing_or_duplicated = expected.reject { |name| counts[name] == 1 }
unless missing_or_duplicated.empty?
  abort "Expected exactly one structured-data match for: #{missing_or_duplicated.join(', ')}"
end

puts "Semrush SEO fixes applied: configurator H1/hreflang, sitemap, #{PRODUCT_OFFERS.size} Product offers and #{EVENT_TOPICS.size} historical event topics"
