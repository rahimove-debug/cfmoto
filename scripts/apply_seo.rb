#!/usr/bin/env ruby
require "json"

ROOT = File.expand_path("..", __dir__)
SITE_ORIGIN = "https://cfmoto.az"
SOURCE_ORIGIN = "https://cfmoto-azerbaijan.dvhqpbbkmw.chatgpt.site"

HOME_TITLE = "CFMOTO Azerbaijan | Motosiklet, ATV və Buggy"
HOME_DESCRIPTION = "CFMOTO-nun Azərbaycanda rəsmi nümayəndəsi. Motosiklet, kvadrosikl, buggy, kredit, rəsmi servis və ehtiyat hissələri."
HOME_IMAGE = "#{SITE_ORIGIN}/official-800mtx-hero.webp"

organization_schema = {
  "@context" => "https://schema.org",
  "@graph" => [
    {
      "@type" => "LocalBusiness",
      "@id" => "#{SITE_ORIGIN}/#organization",
      "name" => "CFMOTO Azerbaijan",
      "legalName" => "SAZMOTO MMC",
      "url" => "#{SITE_ORIGIN}/",
      "logo" => "#{SITE_ORIGIN}/cfmoto-logo-black.png",
      "image" => HOME_IMAGE,
      "telephone" => "+994125709766",
      "priceRange" => "₼₼₼",
      "address" => {
        "@type" => "PostalAddress",
        "streetAddress" => "Babək prospekti 188",
        "addressLocality" => "Bakı",
        "addressCountry" => "AZ"
      },
      "sameAs" => ["https://www.instagram.com/cfmoto.az/"],
      "openingHoursSpecification" => [
        {
          "@type" => "OpeningHoursSpecification",
          "dayOfWeek" => %w[Tuesday Wednesday Thursday Friday Saturday Sunday],
          "opens" => "10:00",
          "closes" => "19:00"
        }
      ]
    },
    {
      "@type" => "WebSite",
      "@id" => "#{SITE_ORIGIN}/#website",
      "url" => "#{SITE_ORIGIN}/",
      "name" => "CFMOTO Azerbaijan",
      "inLanguage" => "az",
      "publisher" => { "@id" => "#{SITE_ORIGIN}/#organization" }
    }
  ]
}

home_seo = <<~HTML.delete("\n")
  <!-- SEO:START -->
  <link rel="canonical" href="#{SITE_ORIGIN}/"/>
  <meta property="og:title" content="#{HOME_TITLE}"/>
  <meta property="og:description" content="#{HOME_DESCRIPTION}"/>
  <meta property="og:url" content="#{SITE_ORIGIN}/"/>
  <meta property="og:type" content="website"/>
  <meta property="og:image" content="#{HOME_IMAGE}"/>
  <meta property="og:image:alt" content="CFMOTO Azerbaijan motosiklet modeli"/>
  <meta property="og:locale" content="az_AZ"/>
  <meta property="og:site_name" content="CFMOTO Azerbaijan"/>
  <meta name="twitter:card" content="summary_large_image"/>
  <meta name="twitter:title" content="#{HOME_TITLE}"/>
  <meta name="twitter:description" content="#{HOME_DESCRIPTION}"/>
  <meta name="twitter:image" content="#{HOME_IMAGE}"/>
  <meta name="twitter:image:alt" content="CFMOTO Azerbaijan motosiklet modeli"/>
  <script type="application/ld+json">#{JSON.generate(organization_schema)}</script>
  <!-- SEO:END -->
HTML

challenge_script = %r{<script>\(function\(\)\{function c\(\)\{.*?/cdn-cgi/challenge-platform/scripts/jsd/main\.js.*?</script>}m

html_paths = Dir.glob(File.join(ROOT, "**", "*.html")).sort
html_paths.each do |path|
  html = File.read(path, encoding: "UTF-8")
  html.gsub!(SOURCE_ORIGIN, SITE_ORIGIN)
  html.gsub!(%r{<!-- SEO:START -->.*?<!-- SEO:END -->}m, "")
  html.gsub!(%r{<meta name="codex-preview" content="development"\s*/>}, "")
  html.gsub!(%r{,\[\\"\$\\",\\"meta\\",\\"\d+\\",\{\\"name\\":\\"codex-preview\\",\\"content\\":\\"development\\"\}\]}, "")
  html.gsub!(challenge_script, "")

  if path == File.join(ROOT, "index.html")
    description_tag = %(<meta name="description" content="#{HOME_DESCRIPTION}"/>)
    abort "Home description meta tag not found" unless html.include?(description_tag)
    html.sub!(description_tag, "#{description_tag}#{home_seo}")

    html.gsub!(%(href=".showroom"), %(href="#showroom"))
    html.gsub!(%(<section class="showroom section">), %(<section class="showroom section" id="showroom">))

    title = "YOLU ÖZÜN SEÇ."
    heading = "<h1>#{title}</h1>"
    unless html.include?(%(class="category-hero-title"))
      abort "Home hero headings not found" unless html.include?(heading)
      html.sub!(heading, %(<h1 class="category-hero-title">#{title}</h1>))
      html.gsub!(heading, %(<p class="category-hero-title">#{title}</p>))
    end
  else
    unless html.include?(%(property="og:locale"))
      html.sub!(%(property="og:type" content="website"/>), %(property="og:type" content="website"/><meta property="og:locale" content="az_AZ"/><meta property="og:site_name" content="CFMOTO Azerbaijan"/>))
    end
  end

  File.write(path, html, encoding: "UTF-8")
end

Dir.glob(File.join(ROOT, "assets", "*.js")).each do |page_bundle|
  javascript = File.read(page_bundle, encoding: "UTF-8")
  javascript.gsub!('`Satış mərkəzi`,`.showroom`', '`Satış mərkəzi`,`#showroom`')
  javascript.gsub!('className:`showroom section`', 'className:`showroom section`,id:`showroom`')
  javascript.gsub!(
    '(0,c.jsx)(`h1`,{children:`YOLU ÖZÜN SEÇ.`})',
    '(0,c.jsx)(t?`h1`:`p`,{className:`category-hero-title`,children:`YOLU ÖZÜN SEÇ.`})'
  )
  File.write(page_bundle, javascript, encoding: "UTF-8")
end

Dir.glob(File.join(ROOT, "assets", "*.css")).each do |path|
  css = File.read(path, encoding: "UTF-8")
  css.gsub!(".category-hero-content h1", ".category-hero-content .category-hero-title")
  File.write(path, css, encoding: "UTF-8")
end

model_urls = Dir.glob(File.join(ROOT, "model", "*", "index.html")).sort.map do |path|
  slug = File.basename(File.dirname(path))
  "#{SITE_ORIGIN}/model/#{slug}"
end

sitemap_urls = ["#{SITE_ORIGIN}/", *model_urls]
sitemap = [
  %(<?xml version="1.0" encoding="UTF-8"?>),
  %(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">),
  *sitemap_urls.map { |url| "  <url><loc>#{url}</loc></url>" },
  %(</urlset>),
  ""
].join("\n")

File.write(File.join(ROOT, "sitemap.xml"), sitemap)
File.write(File.join(ROOT, "robots.txt"), "User-agent: *\nAllow: /\nSitemap: #{SITE_ORIGIN}/sitemap.xml\n")

puts "SEO applied to #{html_paths.size} HTML pages; sitemap contains #{sitemap_urls.size} URLs"
