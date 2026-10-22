#!/usr/bin/env ruby
# frozen_string_literal: true

require "date"
require "json"
require "uri"

module SitemapLastmod
  ROOT = File.expand_path("..", __dir__)
  SITE_ORIGIN = "https://cfmoto.az"
  MANIFEST_PATH = File.join(__dir__, "sitemap_lastmod.json")
  SITEMAP_PATH = File.join(ROOT, "sitemap.xml")

  module_function

  def load_manifest(path = MANIFEST_PATH, today: Date.today)
    data = JSON.parse(File.read(path, encoding: "UTF-8"))
    raise "Unsupported sitemap lastmod manifest version" unless data["version"] == 1
    pages = data.fetch("pages")
    raise "Sitemap lastmod pages must be an array" unless pages.is_a?(Array)

    dates = {}
    pages.each_with_index do |entry, index|
      route = entry.fetch("path")
      value = entry.fetch("lastmod")
      raise "Manifest entry #{index + 1}: duplicate path #{route}" if dates.key?(route)
      valid_route = route.start_with?("/") && route.end_with?("/") && !route.include?("?") && !route.include?("#")
      raise "Manifest entry #{index + 1}: invalid canonical path #{route.inspect}" unless valid_route
      raise "Manifest entry #{index + 1}: invalid date #{value.inspect}" unless value.match?(/\A\d{4}-\d{2}-\d{2}\z/)

      parsed = Date.iso8601(value)
      raise "Manifest entry #{index + 1}: future date #{value}" if parsed > today
      dates[route] = value
    rescue Date::Error
      raise "Manifest entry #{index + 1}: invalid date #{value.inspect}"
    end
    dates
  end

  def apply(xml, dates)
    seen = []
    updated = xml.gsub(%r{<url>(.*?)</url>}m) do
      node = Regexp.last_match(1)
      locations = node.scan(%r{<loc>(.*?)</loc>}m).flatten
      raise "Sitemap URL node must contain exactly one loc" unless locations.size == 1

      uri = URI.parse(locations.first)
      raise "Unexpected sitemap origin: #{uri}" unless "#{uri.scheme}://#{uri.host}" == SITE_ORIGIN && uri.port == 443
      raise "Sitemap URL must not contain query or fragment: #{uri}" if uri.query || uri.fragment
      route = uri.path
      raise "Duplicate sitemap route: #{route}" if seen.include?(route)
      seen << route

      value = dates[route]
      raise "Missing lastmod manifest entry for #{route}" unless value
      lastmods = node.scan(%r{<lastmod>(.*?)</lastmod>}m).flatten
      raise "Multiple lastmod values for #{route}" if lastmods.size > 1
      if lastmods.empty?
        node = node.sub(%r{</loc>}, "</loc><lastmod>#{value}</lastmod>")
      else
        node = node.sub(%r{<lastmod>.*?</lastmod>}m, "<lastmod>#{value}</lastmod>")
      end
      "<url>#{node}</url>"
    end

    missing = dates.keys - seen
    unexpected = seen - dates.keys
    raise "Lastmod manifest contains URL(s) absent from sitemap: #{missing.join(', ')}" unless missing.empty?
    raise "Sitemap contains URL(s) absent from lastmod manifest: #{unexpected.join(', ')}" unless unexpected.empty?
    updated
  end

  def apply_file!(sitemap_path = SITEMAP_PATH, manifest_path = MANIFEST_PATH)
    xml = File.read(sitemap_path, encoding: "UTF-8")
    dates = load_manifest(manifest_path)
    updated = apply(xml, dates)
    File.write(sitemap_path, updated, encoding: "UTF-8") if updated != xml
    [dates.size, updated]
  end
end

if $PROGRAM_NAME == __FILE__
  count, = SitemapLastmod.apply_file!
  puts "Sitemap lastmod applied to #{count} canonical URLs"
end
