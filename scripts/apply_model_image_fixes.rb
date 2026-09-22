#!/usr/bin/env ruby

ROOT = File.expand_path("..", __dir__)
STYLESHEET = "/assets/model-image-layout-CfmotoImageFixV1.css"
STYLESHEET_LINK = %(<link rel="stylesheet" href="#{STYLESHEET}"/>).freeze
BOBBER_STYLESHEET = "/assets/450cl-c-bobber-images-v1.css"
BOBBER_STYLESHEET_LINK = %(<link rel="stylesheet" href="#{BOBBER_STYLESHEET}"/>).freeze

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

# The imported BOBBER page labelled a 720x541 black motorcycle as Ivory White,
# hotlinked the alternate black color and used two locally corrupted gallery
# exports. Keep verified, versioned local derivatives from the current official
# CFMOTO product page so color selection, gallery quality and CDN caching stay
# deterministic.
#
# Ivory White source:
# https://cfimages.cfmoto.com/cfmoto/240325_450_CLC_da9d242090.jpg
# Nebula Black source:
# https://cfimages.cfmoto.com/cfmoto/240325_450_CLC_3f7f53c927.jpg
# Gallery sources:
# https://cfimages.cfmoto.com/cfmoto/450clcbapperance1_c844f99c37.jpg
# https://cfimages.cfmoto.com/cfmoto/450clcbhualang2_a4db9ea696.jpg
# https://cfimages.cfmoto.com/cfmoto/450clcbapperance4_572d98d1e1.jpg
BOBBER_IMAGE_REPLACEMENTS = {
  "/models/450cl-c-bobber.webp" => "/models/450cl-c-bobber-ivory-white-official-v1.webp",
  "https://www.cfmoto.com/content/dam/cfmoto/site/global/product/motorcycle/cl-x----classic/450cl-c-bobber/2024/model/model_2.png" => "/models/450cl-c-bobber-nebula-black-official-v1.webp",
  "/gallery/450cl-c-bobber-1.webp" => "/gallery/450cl-c-bobber-silhouette-official-v1.webp",
  "/gallery/450cl-c-bobber-2.webp" => "/gallery/450cl-c-bobber-riding-position-official-v1.webp",
  "/gallery/450cl-c-bobber-3.webp" => "/gallery/450cl-c-bobber-detail-official-v1.webp"
}.freeze

page_paths = Dir.glob(File.join(ROOT, "model", "*", "index.html")) +
             Dir.glob(File.join(ROOT, "ru", "model", "*", "index.html"))

abort "No model pages found" if page_paths.empty?

updated = 0
page_paths.each do |page_path|
  source = File.binread(page_path)
  original = source.dup

  IMAGE_REPLACEMENTS.each { |old_reference, new_reference| source.gsub!(old_reference, new_reference) }

  slug = File.basename(File.dirname(page_path))

  if slug == "aura-150"
    # Covers the initial HTML, metadata and serialized React color/fallback props.
    AURA_IMAGE_REPLACEMENTS.each { |old_reference, new_reference| source.gsub!(old_reference, new_reference) }
  end

  if slug == "450cl-c-bobber"
    # Covers initial HTML, social metadata, JSON-LD and serialized React props in
    # both languages. The gallery remains a consistent Ivory White story, while
    # the hero selector accurately switches between the two official colors.
    BOBBER_IMAGE_REPLACEMENTS.each { |old_reference, new_reference| source.gsub!(old_reference, new_reference) }

    unless source.include?(BOBBER_STYLESHEET_LINK)
      abort "Missing </head> in #{page_path}" unless source.include?("</head>")
      source.sub!("</head>", "#{BOBBER_STYLESHEET_LINK}</head>")
    end
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
