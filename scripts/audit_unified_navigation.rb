#!/usr/bin/env ruby
# frozen_string_literal: true

ROOT = File.expand_path("..", __dir__)
STYLE_URL = "/assets/unified-navigation-v1.css"
SCRIPT_URL = "/assets/unified-navigation-v1.js"
errors = []

def read(path)
  File.read(path, encoding: "UTF-8")
end

paths = Dir.glob(File.join(ROOT, "**", "index.html"))
paths << File.join(ROOT, "404.html") if File.file?(File.join(ROOT, "404.html"))
paths.reject! { |path| path.include?("/dist/") }

paths.uniq.each do |path|
  html = read(path)
  next unless html.include?("</head>")
  relative = path.delete_prefix("#{ROOT}/")
  errors << "#{relative}: unified navigation stylesheet must appear once" unless html.scan(STYLE_URL).size == 1
  errors << "#{relative}: unified navigation script must appear once" unless html.scan(SCRIPT_URL).size == 1
end

%w[
  motosiklet/index.html
  kvadrosikl/index.html
  buggy/index.html
  servis/index.html
  xeberler/index.html
  aksesuar-konfiquratoru/index.html
  ru/motocikly/index.html
  ru/servis/index.html
].each do |relative|
  path = File.join(ROOT, relative)
  next unless File.file?(path)
  html = read(path)
  errors << "#{relative}: unified static header is missing" unless html.scan('class="site-header unified-site-header"').size == 1
  errors << "#{relative}: duplicate old content/news header remains" if html.include?('class="content-header"') || html.include?('class="news-site-nav"')
  category_paths = html.match?(/<html[^>]+lang=["']ru/i) ? %w[/ru/motocikly/ /ru/kvadrocikly/ /ru/buggy/] : %w[/motosiklet/ /kvadrosikl/ /buggy/]
  errors << "#{relative}: category navigation is incomplete" unless html.include?("unified-products-menu") && category_paths.all? { |category_path| html.include?(category_path) }
  header = html[%r{<header class="site-header unified-site-header">.*?</header>}m].to_s
  language_control = header.include?('class="language-switcher"') || header.include?("/assets/language-switcher-v4.js")
  errors << "#{relative}: language selector loader must be inside the header" unless language_control
end

%w[index.html ru/index.html model/450mt/index.html ru/model/450mt/index.html].each do |relative|
  path = File.join(ROOT, relative)
  next unless File.file?(path)
  html = read(path)
  errors << "#{relative}: established site header is missing" unless html.include?('class="site-header')
end

style_path = File.join(ROOT, STYLE_URL.delete_prefix("/"))
script_path = File.join(ROOT, SCRIPT_URL.delete_prefix("/"))
if File.file?(style_path)
  css = read(style_path)
  errors << "Mobile home header must participate in layout" unless css.include?(".site-header.home-header") && css.include?("position: relative !important")
  errors << "Mobile active ATV layout must retain the motorcycle row" unless css.include?(".category-hero-grid.active-atv") && css.include?("72px minmax(576px, 1fr) 72px")
  errors << "Mobile active Buggy layout must retain both earlier category rows" unless css.include?(".category-hero-grid.active-buggy") && css.include?("72px 72px minmax(576px, 1fr)")
  errors << "Mobile category grid must disable scroll anchoring" unless css.include?("overflow-anchor: none")
else
  errors << "Unified navigation stylesheet is missing"
end

if File.file?(script_path)
  javascript = read(script_path)
  errors << "Detail headers must receive a mobile menu button" unless javascript.include?("ensureDetailMenuButton")
  errors << "Unified mobile menu Escape support is missing" unless javascript.include?('event.key !== "Escape"')
  errors << "Language switcher must move into existing headers" unless javascript.include?("moveLanguageSwitcher")
else
  errors << "Unified navigation script is missing"
end

abort "Unified navigation audit failed:\n- #{errors.join("\n- ")}" unless errors.empty?

puts "Unified navigation audit passed: #{paths.uniq.size} pages, shared desktop/mobile header and stable 01/02/03 category access"
