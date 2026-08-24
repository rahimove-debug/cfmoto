#!/usr/bin/env ruby
require "fileutils"
require "rbconfig"

ROOT = File.expand_path("..", __dir__)
DIST = File.join(ROOT, "dist")

directories = %w[assets gallery model models]
files = %w[
  index.html
  404.html
  _headers
  _redirects
  robots.txt
  sitemap.xml
  favicon.svg
  cfmoto-logo-black.png
  official-800mtx-hero.webp
  official-800mtx-hero-mobile.jpg
]

updates = File.join(__dir__, "apply_site_updates.rb")
abort "Site updates failed" unless system(RbConfig.ruby, updates)

seo = File.join(__dir__, "apply_seo.rb")
abort "SEO processing failed" unless system(RbConfig.ruby, seo)

audit = File.join(__dir__, "audit_seo.rb")
abort "SEO audit failed" unless system(RbConfig.ruby, audit)

FileUtils.rm_rf(DIST)
FileUtils.mkdir_p(DIST)

directories.each do |directory|
  source = File.join(ROOT, directory)
  abort "Missing required directory: #{directory}" unless Dir.exist?(source)
  FileUtils.cp_r(source, DIST)
end

files.each do |file|
  source = File.join(ROOT, file)
  abort "Missing required file: #{file}" unless File.file?(source)
  FileUtils.cp(source, DIST)
end

html_count = Dir.glob(File.join(DIST, "**", "*.html")).size
abort "Expected 49 HTML files in dist, found #{html_count}" unless html_count == 49

forbidden = %w[README.md .github cloudflare scripts]
leaked = forbidden.select { |path| File.exist?(File.join(DIST, path)) }
abort "Non-public files copied to dist: #{leaked.join(', ')}" unless leaked.empty?

puts "Cloudflare bundle ready: #{html_count} HTML files in dist/"
