#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "net/http"
require "uri"
require_relative "offroad_official_hq_sources"

ROOT = File.expand_path("..", __dir__)
OUTPUT = File.join(ROOT, "accessories", "official-offroad-hq")
RENDITION = "jcr:content/renditions/cq5dam.web.1280.1280.jpeg"

def rendition_url(relative_path)
  encoded_path = relative_path.split("/").map do |segment|
    URI.encode_www_form_component(segment).gsub("+", "%20")
  end.join("/")
  "#{OFFICIAL_CFMOTO_DOWNLOAD_ROOT}/#{encoded_path}/#{RENDITION}"
end

def fetch_image(url, destination, redirect_limit = 3)
  abort "Too many redirects while fetching #{url}" if redirect_limit.negative?

  uri = URI(url)
  response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = "Mozilla/5.0 CFMOTO Azerbaijan catalog updater"
    http.request(request)
  end

  if response.is_a?(Net::HTTPRedirection)
    return fetch_image(URI.join(url, response["location"]).to_s, destination, redirect_limit - 1)
  end

  abort "Download failed (#{response.code}) for #{url}" unless response.is_a?(Net::HTTPSuccess)
  abort "Unexpected content type for #{url}" unless response["content-type"]&.start_with?("image/jpeg")

  File.binwrite(destination, response.body)
end

FileUtils.mkdir_p(OUTPUT)

OFFICIAL_OFFROAD_HQ_SOURCES.each do |catalog_key, relative_path|
  destination = File.join(OUTPUT, "#{catalog_key}.jpg")
  url = rendition_url(relative_path)
  fetch_image(url, destination)
  optimized = system(
    "sips", "-Z", "960", "-s", "format", "jpeg", "-s", "formatOptions", "82", destination,
    out: File::NULL,
    err: File::NULL
  )
  abort "Image optimization failed for #{catalog_key}" unless optimized
  puts "Downloaded #{catalog_key}"
end

puts "Downloaded and optimized #{OFFICIAL_OFFROAD_HQ_SOURCES.size} official CFMOTO images to #{OUTPUT.delete_prefix("#{ROOT}/")}"
