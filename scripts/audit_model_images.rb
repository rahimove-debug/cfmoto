#!/usr/bin/env ruby

ROOT = File.expand_path("..", __dir__)
STYLESHEET = "/assets/model-image-layout-CfmotoImageFixV1.css"

page_paths = Dir.glob(File.join(ROOT, "model", "*", "index.html")) +
             Dir.glob(File.join(ROOT, "ru", "model", "*", "index.html"))

abort "No model pages found" if page_paths.empty?

stylesheet_path = File.join(ROOT, STYLESHEET.delete_prefix("/"))
abort "Missing model image stylesheet: #{stylesheet_path}" unless File.file?(stylesheet_path)

stylesheet = File.binread(stylesheet_path)
unless stylesheet.include?(".model-feature-image > img") &&
       stylesheet.include?("position: absolute") &&
       stylesheet.include?("object-fit: cover")
  abort "Model image stylesheet does not enforce full card coverage"
end

missing_stylesheet_links = page_paths.reject do |page_path|
  File.binread(page_path).include?(%(<link rel="stylesheet" href="#{STYLESHEET}"/>))
end

unless missing_stylesheet_links.empty?
  abort "Model pages missing image layout stylesheet:\n#{missing_stylesheet_links.join("\n")}" 
end

local_image_refs = page_paths.flat_map do |page_path|
  File.binread(page_path).scan(%r{/(?:models|gallery)/[A-Za-z0-9._/-]+\.(?:avif|jpe?g|png|webp)}i)
end.uniq

missing = local_image_refs.reject do |reference|
  File.file?(File.join(ROOT, reference.delete_prefix("/")))
end

abort "Missing model image files:\n#{missing.sort.join("\n")}" unless missing.empty?

required_replacements = {
  "800nk-advanced" => %w[
    /gallery/800nk-advanced-2-official-v2.webp
  ],
  "800mt-explore" => %w[
    /gallery/800mt-explore-1-official-v2.webp
    /gallery/800mt-explore-2-official-v2.webp
    /gallery/800mt-explore-3-official-v2.webp
  ]
}.freeze

required_replacements.each do |slug, references|
  [
    File.join(ROOT, "model", slug, "index.html"),
    File.join(ROOT, "ru", "model", slug, "index.html")
  ].each do |page_path|
    source = File.binread(page_path)
    references.each do |reference|
      abort "#{page_path} does not reference #{reference}" unless source.include?(reference)
    end
  end
end

deprecated_references = %w[
  /gallery/800nk-advanced-2.webp
  /gallery/800mt-explore-1.webp
  /gallery/800mt-explore-2.webp
  /gallery/800mt-explore-3.webp
].freeze

deprecated_hits = page_paths.flat_map do |page_path|
  source = File.binread(page_path)
  deprecated_references.map do |reference|
    "#{page_path}: #{reference}" if source.include?(reference)
  end.compact
end

unless deprecated_hits.empty?
  abort "Deprecated low-resolution model images are still referenced:\n#{deprecated_hits.join("\n")}" 
end

puts "Model image audit passed: #{page_paths.size} pages and #{local_image_refs.size} local references checked"
