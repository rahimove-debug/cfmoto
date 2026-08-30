#!/usr/bin/env ruby
require "fileutils"
require "rbconfig"
require_relative "content_config"
require_relative "category_config"
require_relative "news_config"

ROOT = File.expand_path("..", __dir__)
DIST = File.join(ROOT, "dist")

directories = %w[assets gallery model models ru accessories aksesuar-konfiquratoru] + ContentConfig::SLUGS + CategoryConfig::SLUGS + [NewsConfig::ROOT_SLUG]
files = %w[
  index.html
  404.html
  _headers
  _redirects
  robots.txt
  llms.txt
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

ux_accessibility = File.join(__dir__, "apply_ux_accessibility.rb")
abort "UX/accessibility processing failed" unless system(RbConfig.ruby, ux_accessibility)

offroad_accessory_images = File.join(__dir__, "apply_offroad_accessory_images.rb")
abort "Off-road accessory image processing failed" unless system(RbConfig.ruby, offroad_accessory_images)

audit = File.join(__dir__, "audit_seo.rb")
abort "SEO audit failed" unless system(RbConfig.ruby, audit)

russian_audit = File.join(__dir__, "audit_russian.rb")
abort "Russian localization audit failed" unless system(RbConfig.ruby, russian_audit)

accessory_integration = File.join(__dir__, "apply_accessory_integration.rb")
abort "Accessory integration failed" unless system(RbConfig.ruby, accessory_integration)

accessory_audit = File.join(__dir__, "audit_accessory_integration.rb")
abort "Accessory integration audit failed" unless system(RbConfig.ruby, accessory_audit)

offroad_accessory_image_audit = File.join(__dir__, "audit_offroad_accessory_images.rb")
abort "Off-road accessory image audit failed" unless system(RbConfig.ruby, offroad_accessory_image_audit)

news_integration = File.join(__dir__, "apply_news_integration.rb")
abort "News integration failed" unless system(RbConfig.ruby, news_integration)

semrush_seo_fixes = File.join(__dir__, "apply_semrush_seo_fixes.rb")
abort "Semrush structured-data fixes failed" unless system(RbConfig.ruby, semrush_seo_fixes)

news_audit = File.join(__dir__, "audit_news_integration.rb")
abort "News integration audit failed" unless system(RbConfig.ruby, news_audit)

mobile_model_names = File.join(__dir__, "apply_mobile_model_names.rb")
abort "Mobile model-name processing failed" unless system(RbConfig.ruby, mobile_model_names)

mobile_model_names_audit = File.join(__dir__, "audit_mobile_model_names.rb")
abort "Mobile model-name audit failed" unless system(RbConfig.ruby, mobile_model_names_audit)

unified_navigation = File.join(__dir__, "apply_unified_navigation.rb")
abort "Unified navigation processing failed" unless system(RbConfig.ruby, unified_navigation)

unified_navigation_audit = File.join(__dir__, "audit_unified_navigation.rb")
abort "Unified navigation audit failed" unless system(RbConfig.ruby, unified_navigation_audit)

ux_accessibility_audit = File.join(__dir__, "audit_ux_accessibility.rb")
abort "UX/accessibility audit failed" unless system(RbConfig.ruby, ux_accessibility_audit)

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
accessory_html_count = Dir.glob(File.join(ROOT, "aksesuar-konfiquratoru", "**", "*.html")).size
expected_html_count = 2 + accessory_html_count + Dir.glob(File.join(ROOT, "model", "*", "index.html")).size + ContentConfig::SLUGS.size + CategoryConfig::SLUGS.size + Dir.glob(File.join(ROOT, "ru", "**", "index.html")).size
expected_html_count += NewsConfig.html_paths(ROOT).size
abort "Expected #{expected_html_count} HTML files in dist, found #{html_count}" unless html_count == expected_html_count

forbidden = %w[README.md .github cloudflare scripts]
leaked = forbidden.select { |path| File.exist?(File.join(DIST, path)) }
abort "Non-public files copied to dist: #{leaked.join(', ')}" unless leaked.empty?

puts "Cloudflare bundle ready: #{html_count} HTML files in dist/"
