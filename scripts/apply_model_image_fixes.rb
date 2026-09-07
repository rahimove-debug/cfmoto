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

# The imported AURA hero is the two-tone Vintage White, not Ivory White.
# Match the live swatches on the official Global 150AURA page:
# https://www.cfmoto.com/global/motorcycles/scooter/150aura.html
# Ivory White -> model1.png; Vintage White -> model5.png.
# Keep versioned local copies so the selector does not depend on hotlinking.
AURA_IMAGE_REPLACEMENTS = {
  "/models/aura-150.webp" => "/models/aura-150-ivory-white-official-v1.png",
  "https://www.cfmoto.com/content/dam/cfmoto/site/global/product/motorcycle/sc---scooter/150aura/model/model1.png" => "/models/aura-150-ivory-white-official-v1.png",
  "https://www.cfmoto.com/content/dam/cfmoto/site/global/product/motorcycle/sc---scooter/150aura/model/model5.png" => "/models/aura-150-vintage-white-official-v1.png"
}.freeze

page_paths = Dir.glob(File.join(ROOT, "model", "*", "index.html")) +
             Dir.glob(File.join(ROOT, "ru", "model", "*", "index.html"))

abort "No model pages found" if page_paths.empty?

updated = 0
page_paths.each do |page_path|
  source = File.binread(page_path)
  original = source.dup

  IMAGE_REPLACEMENTS.each { |old_reference, new_reference| source.gsub!(old_reference, new_reference) }

  if File.basename(File.dirname(page_path)) == "aura-150"
    # Covers the initial HTML, metadata and serialized React color/fallback props.
    AURA_IMAGE_REPLACEMENTS.each { |old_reference, new_reference| source.gsub!(old_reference, new_reference) }
  end

  unless source.include?(STYLESHEET_LINK)
    abort "Missing </head> in #{page_path}" unless source.include?("</head>")
    source.sub!("</head>", "#{STYLESHEET_LINK}</head>")
  end

  next if source == original

  File.binwrite(page_path, source)
  updated += 1
end

puts "Applied model image fixes to #{page_paths.size} pages (#{updated} updated)"
