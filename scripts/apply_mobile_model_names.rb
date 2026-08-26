#!/usr/bin/env ruby

ROOT = File.expand_path("..", __dir__)
STYLESHEET = "/assets/mobile-model-names-v1.css"
TAG = %(<link rel="stylesheet" href="#{STYLESHEET}"/>)

paths = [
  File.join(ROOT, "index.html"),
  File.join(ROOT, "ru", "index.html"),
  File.join(ROOT, "motosiklet", "index.html"),
  File.join(ROOT, "kvadrosikl", "index.html"),
  File.join(ROOT, "buggy", "index.html"),
  File.join(ROOT, "ru", "motocikly", "index.html"),
  File.join(ROOT, "ru", "kvadrocikly", "index.html"),
  File.join(ROOT, "ru", "buggy", "index.html"),
  File.join(ROOT, "aksesuar-konfiquratoru", "index.html")
]

missing = paths.reject { |path| File.file?(path) }
abort "Mobile model-name pages missing: #{missing.join(', ')}" unless missing.empty?

paths.each do |path|
  html = File.read(path, encoding: "UTF-8")
  next if html.include?(TAG)
  abort "#{path}: closing head not found" unless html.include?("</head>")

  html.sub!("</head>", "#{TAG}</head>")
  File.write(path, html, encoding: "UTF-8")
end

puts "Mobile model-name stylesheet linked from #{paths.size} catalog pages"
