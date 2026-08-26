#!/usr/bin/env ruby

ROOT = File.expand_path("..", __dir__)
STYLESHEET = "/assets/mobile-model-names-v1.css"
TAG = %(<link rel="stylesheet" href="#{STYLESHEET}"/>)

css_path = File.join(ROOT, STYLESHEET.delete_prefix("/"))
abort "Mobile model-name stylesheet missing" unless File.file?(css_path)

css = File.read(css_path, encoding: "UTF-8")
%w[.mega-model .mega-categories .model-info .category-model-copy .model-choice .model-title].each do |selector|
  abort "Mobile model-name CSS missing #{selector}" unless css.include?(selector)
end

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

paths.each do |path|
  html = File.read(path, encoding: "UTF-8")
  abort "#{path}: mobile model-name stylesheet not linked once" unless html.scan(TAG).size == 1
end

puts "Mobile model-name audit passed for #{paths.size} catalog pages"
