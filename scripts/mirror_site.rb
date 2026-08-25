#!/usr/bin/env ruby
require "fileutils"
require "net/http"
require "rbconfig"
require "set"
require "uri"

ORIGIN = URI("https://cfmoto-azerbaijan.dvhqpbbkmw.chatgpt.site/")
DEST = File.expand_path("..", __dir__)
queue = [ORIGIN]
seen = Set.new

def local_path(uri)
  target = URI.decode_www_form_component(uri.path)
  target = "/index.html" if target == "/"
  target = "#{target}/index.html" if File.extname(target).empty?
  File.join(DEST, target.sub(%r{\A/}, ""))
end

def downloadable?(uri)
  return false unless uri.host == ORIGIN.host
  return false unless uri.query.nil?
  target = uri.path
  return true if target == "/" || target.start_with?("/model/")
  %w[.html .css .js .mjs .json .png .jpg .jpeg .webp .svg .gif .ico .woff .woff2 .ttf .mp4 .webm].include?(File.extname(target).downcase)
end

def candidates(body, base_uri)
  raw = []
  raw.concat(body.scan(/(?:href|src)=["']([^"']+)["']/i).flatten)
  raw.concat(body.scan(/url\(\s*["']?([^\)"']+)/i).flatten)
  raw.concat(body.scan(/(?:from\s*|import\s*\(\s*)["'`]([^"'`]+)["'`]/).flatten)
  raw.concat(body.scan(/["'](\/[^"'\s]+\.(?:css|js|mjs|json|png|jpe?g|webp|svg|gif|ico|woff2?|ttf|mp4|webm))["']/i).flatten)
  raw.map do |value|
    next if value.empty? || value.start_with?("#", "data:", "mailto:", "tel:", "javascript:")
    begin
      URI.join(base_uri.to_s, value)
    rescue URI::InvalidURIError
      nil
    end
  end.compact
end

until queue.empty?
  uri = queue.shift
  next if seen.include?(uri.to_s)
  seen << uri.to_s
  next unless downloadable?(uri)

  response = Net::HTTP.get_response(uri)
  next unless response.is_a?(Net::HTTPSuccess)

  target = local_path(uri)
  FileUtils.mkdir_p(File.dirname(target))
  File.binwrite(target, response.body)
  puts "GET #{uri.path}"

  content_type = response["content-type"].to_s
  if content_type.include?("text/") || content_type.include?("javascript") || File.extname(uri.path).empty?
    candidates(response.body, uri).each do |candidate|
      candidate.fragment = nil
      queue << candidate if downloadable?(candidate) && !seen.include?(candidate.to_s)
    end
  end
end

FileUtils.touch(File.join(DEST, ".nojekyll"))
puts "Imported #{seen.size} discovered URLs"

updates_script = File.join(__dir__, "apply_site_updates.rb")
abort "Site updates failed" unless system(RbConfig.ruby, updates_script)

seo_script = File.join(__dir__, "apply_seo.rb")
abort "SEO processing failed" unless system(RbConfig.ruby, seo_script)

analytics_script = File.join(__dir__, "apply_analytics.rb")
abort "Analytics processing failed" unless system(RbConfig.ruby, analytics_script)
