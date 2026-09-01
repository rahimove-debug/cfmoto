#!/usr/bin/env ruby

ROOT = File.expand_path("..", __dir__)
STYLESHEET = "/assets/model-image-layout-CfmotoImageFixV1.css"
STYLESHEET_LINK = %(<link rel="stylesheet" href="#{STYLESHEET}"/>).freeze

IMAGE_REPLACEMENTS = {
  "/gallery/800nk-advanced-2.webp" => "/gallery/800nk-advanced-2-official-v2.webp",
  "/gallery/800mt-explore-1.webp" => "/gallery/800mt-explore-1-official-v2.webp",
  "/gallery/800mt-explore-2.webp" => "/gallery/800mt-explore-2-official-v2.webp",
  "/gallery/800mt-explore-3.webp" => "/gallery/800mt-explore-3-official-v2.webp"
}.freeze

page_paths = Dir.glob(File.join(ROOT, "model", "*", "index.html")) +
             Dir.glob(File.join(ROOT, "ru", "model", "*", "index.html"))

abort "No model pages found" if page_paths.empty?

updated = 0
page_paths.each do |page_path|
  source = File.binread(page_path)
  original = source.dup

  IMAGE_REPLACEMENTS.each { |old_reference, new_reference| source.gsub!(old_reference, new_reference) }

  unless source.include?(STYLESHEET_LINK)
    abort "Missing </head> in #{page_path}" unless source.include?("</head>")
    source.sub!("</head>", "#{STYLESHEET_LINK}</head>")
  end

  next if source == original

  File.binwrite(page_path, source)
  updated += 1
end

puts "Applied model image fixes to #{page_paths.size} pages (#{updated} updated)"
