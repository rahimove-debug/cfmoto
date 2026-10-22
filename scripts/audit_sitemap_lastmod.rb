#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "apply_sitemap_lastmod"

errors = []

begin
  xml = File.read(SitemapLastmod::SITEMAP_PATH, encoding: "UTF-8")
  dates = SitemapLastmod.load_manifest
  reapplied = SitemapLastmod.apply(xml, dates)
  errors << "Sitemap lastmod applicator is not idempotent" unless reapplied == xml

  nodes = xml.scan(%r{<url>(.*?)</url>}m).flatten
  errors << "Sitemap node count differs from manifest" unless nodes.size == dates.size
  nodes.each_with_index do |node, index|
    location = node[%r{<loc>(.*?)</loc>}m, 1]
    route = URI.parse(location).path if location
    values = node.scan(%r{<lastmod>(.*?)</lastmod>}m).flatten
    errors << "Sitemap node #{index + 1} must contain one lastmod" unless values.size == 1
    errors << "#{route || "node #{index + 1}"}: lastmod differs from manifest" unless route && values == [dates[route]]
  end
rescue StandardError => error
  errors << error.message
end

if errors.empty?
  puts "Sitemap lastmod audit passed: #{SitemapLastmod.load_manifest.size} canonical URLs"
else
  warn errors.map { |error| "- #{error}" }.join("\n")
  abort "Sitemap lastmod audit failed with #{errors.size} error(s)"
end
