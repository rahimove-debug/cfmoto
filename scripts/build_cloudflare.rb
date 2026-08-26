#!/usr/bin/env ruby
require "fileutils"
require "rbconfig"
require_relative "content_config"
require_relative "category_config"

ROOT = File.expand_path("..", __dir__)
DIST = File.join(ROOT, "dist")

directories = %w[assets gallery model models ru accessories aksesuar-konfiquratoru] + ContentConfig::SLUGS + CategoryConfig::SLUGS
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

accessory_cleanup = File.join(__dir__, "remove_accessory_integration.rb")
abort "Accessory integration cleanup failed" unless system(RbConfig.ruby, accessory_cleanup)

updates = File.join(__dir__, "apply_site_updates.rb")
abort "Site updates failed" unless system(RbConfig.ruby, updates)

content = File.join(__dir__, "apply_content_pages.rb")
abort "SEO content generation failed" unless system(RbConfig.ruby, content)

categories = File.join(__dir__, "apply_category_pages.rb")
abort "Category page generation failed" unless system(RbConfig.ruby, categories)

seo = File.join(__dir__, "apply_seo.rb")
abort "SEO processing failed" unless system(RbConfig.ruby, seo)

analytics = File.join(__dir__, "apply_analytics.rb")
abort "Analytics processing failed" unless system(RbConfig.ruby, analytics)

russian = File.join(__dir__, "apply_russian.rb")
abort "Russian localization failed" unless system(RbConfig.ruby, russian)

typography = File.join(__dir__, "apply_typography.rb")
abort "Corporate typography processing failed" unless system(RbConfig.ruby, typography)

audit = File.join(__dir__, "audit_seo.rb")
abort "SEO audit failed" unless system(RbConfig.ruby, audit)

russian_audit = File.join(__dir__, "audit_russian.rb")
abort "Russian localization audit failed" unless system(RbConfig.ruby, russian_audit)

accessory_integration = File.join(__dir__, "apply_accessory_integration.rb")
abort "Accessory integration failed" unless system(RbConfig.ruby, accessory_integration)

accessory_audit = File.join(__dir__, "audit_accessory_integration.rb")
abort "Accessory integration audit failed" unless system(RbConfig.ruby, accessory_audit)

mobile_model_names = File.join(__dir__, "apply_mobile_model_names.rb")
abort "Mobile model-name processing failed" unless system(RbConfig.ruby, mobile_model_names)

mobile_model_names_audit = File.join(__dir__, "audit_mobile_model_names.rb")
abort "Mobile model-name audit failed" unless system(RbConfig.ruby, mobile_model_names_audit)

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
expected_html_count = 3 + Dir.glob(File.join(ROOT, "model", "*", "index.html")).size + ContentConfig::SLUGS.size + CategoryConfig::SLUGS.size + Dir.glob(File.join(ROOT, "ru", "**", "index.html")).size
abort "Expected #{expected_html_count} HTML files in dist, found #{html_count}" unless html_count == expected_html_count

forbidden = %w[README.md .github cloudflare scripts]
leaked = forbidden.select { |path| File.exist?(File.join(DIST, path)) }
abort "Non-public files copied to dist: #{leaked.join(', ')}" unless leaked.empty?

puts "Cloudflare bundle ready: #{html_count} HTML files in dist/"
