#!/usr/bin/env ruby
# frozen_string_literal: true

ROOT = File.expand_path("..", __dir__)
DIST = File.join(ROOT, "dist")
STYLESHEET = "/assets/cfmoto-typography-v2.css"
LEGACY_STYLESHEETS = %w[
  /assets/cfmoto-typography-v1.css
  /assets/cfmoto-typography-v2.css
].freeze
LINK = %(<link rel="stylesheet" href="#{STYLESHEET}"/>).freeze
FONT_FILES = %w[
  supreme-ll-light.woff2
  supreme-ll-light-italic.woff2
  supreme-ll-regular.woff2
  supreme-ll-italic.woff2
  supreme-ll-medium.woff2
  supreme-ll-bold.woff2
  supreme-ll-bold-flat.woff2
  supreme-ll-bold-flat-italic.woff2
  supreme-ll-black.woff2
  supreme-ll-black-italic.woff2
].freeze

stylesheet_path = File.join(ROOT, STYLESHEET.delete_prefix("/"))
abort "Missing corporate typography stylesheet" unless File.file?(stylesheet_path)

missing_fonts = FONT_FILES.reject do |name|
  File.file?(File.join(ROOT, "assets", "fonts", name))
end
abort "Missing corporate font files: #{missing_fonts.join(', ')}" unless missing_fonts.empty?

html_paths = Dir.glob(File.join(ROOT, "**", "*.html")).reject do |path|
  path.start_with?("#{DIST}/")
end.sort
abort "No HTML pages found for typography" if html_paths.empty?

html_paths.each do |path|
  html = File.read(path, encoding: "UTF-8")
  LEGACY_STYLESHEETS.each do |stylesheet|
    html.gsub!(%r{<link\s+rel="stylesheet"\s+href="#{Regexp.escape(stylesheet)}"\s*/?>}, "")
  end
  abort "Missing </head> in #{path.delete_prefix("#{ROOT}/")}" unless html.include?("</head>")

  html.sub!("</head>", "#{LINK}</head>")
  applied_links = html.scan(%r{<link\s+rel="stylesheet"\s+href="#{Regexp.escape(STYLESHEET)}"\s*/?>}).size
  abort "Typography link was not applied exactly once" unless applied_links == 1
  File.write(path, html, encoding: "UTF-8")
end

# The statically exported configurator also records stylesheet dependencies in
# React Server Component payloads. Keep those payloads aligned with the visible
# document so hydration cannot request the immutable v1 stylesheet again.
configurator_root = File.join(ROOT, "aksesuar-konfiquratoru")
configurator_payloads = Dir.glob(File.join(configurator_root, "**", "*"))
  .select { |path| File.file?(path) && %w[.html .txt .js .json].include?(File.extname(path)) }
configurator_payloads.each do |path|
  content = File.binread(path)
  updated = content.gsub("/assets/cfmoto-typography-v1.css", STYLESHEET)
  File.binwrite(path, updated) unless updated == content
end

legacy_payloads = configurator_payloads.select do |path|
  File.binread(path).include?("/assets/cfmoto-typography-v1.css")
end
abort "Legacy configurator typography references remain: #{legacy_payloads.join(', ')}" unless legacy_payloads.empty?

puts "Applied CFMOTO corporate typography to #{html_paths.size} pages"
