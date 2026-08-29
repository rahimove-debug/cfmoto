#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "domain_config"
require_relative "news_config"

ROOT = File.expand_path("..", __dir__)
SITEMAP_PATH = File.join(ROOT, "sitemap.xml")

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
puts "News integration added #{NewsConfig::PAGES.size} Azerbaijani URLs to sitemap.xml"
