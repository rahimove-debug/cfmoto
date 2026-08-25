#!/usr/bin/env ruby
# frozen_string_literal: true

ROOT = File.expand_path("..", __dir__)
DIST = File.join(ROOT, "dist")
STYLESHEET = "/assets/cfmoto-typography-v1.css"
LINK = %(<link rel="stylesheet" href="#{STYLESHEET}"/>).freeze
FONT_FILES = %w[
  supreme-ll-light.ttf
  supreme-ll-light-italic.ttf
  supreme-ll-regular.ttf
  supreme-ll-italic.ttf
  supreme-ll-medium.ttf
  supreme-ll-bold.ttf
  supreme-ll-bold-flat.ttf
  supreme-ll-bold-flat-italic.ttf
  supreme-ll-black.ttf
  supreme-ll-black-italic.ttf
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
  html.gsub!(%r{<link\s+rel="stylesheet"\s+href="#{Regexp.escape(STYLESHEET)}"\s*/?>}, "")
  abort "Missing </head> in #{path.delete_prefix("#{ROOT}/")}" unless html.include?("</head>")

  html.sub!("</head>", "#{LINK}</head>")
  abort "Typography link was not applied exactly once" unless html.scan(STYLESHEET).size == 1
  File.write(path, html, encoding: "UTF-8")
end

puts "Applied CFMOTO corporate typography to #{html_paths.size} pages"
