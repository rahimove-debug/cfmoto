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

# The generic optimized `/models/<slug>.webp` files were created from card or
# catalogue artwork. For the models below that artwork belongs to a different
# paint option than the first color exposed by the selector. Keep verified,
# versioned derivatives of the exact official first-color sources so the hero,
# metadata, fallback and hydrated selector all describe the same motorcycle.
VERIFIED_PRIMARY_COLOR_IMAGES = {
  "125nk" => {
    name: "Gem Black",
    reference: "/models/125nk-gem-black-official-v1.webp",
    sources: ["https://www.cfmoto.com/content/dam/cfmoto/site/global/product/motorcycle/nk---naked/125nk/model/color1.png"]
  },
  "150sc" => {
    name: "Space Silver",
    reference: "/models/150sc-space-silver-official-v1.webp",
    sources: ["https://www.cfmoto.com/content/dam/cfmoto/site/global/product/motorcycle/sc---scooter/150sc/150SC_Space-Silver_ToClient.png"]
  },
  "250cl-c" => {
    name: "Nebula Black",
    reference: "/models/250cl-c-nebula-black-official-v1.webp",
    sources: ["https://www.cfmoto.com/content/dam/cfmoto/site/global/product/motorcycle/cl-x----classic/250cl-c/2026/model1.png"]
  },
  "250dual" => {
    name: "Lime Green",
    reference: "/models/250dual-lime-green-official-v1.webp",
    sources: ["https://www.cfmotomalaysia.com.my/image/CFMOTO-250%20DUAL/Colors/Lime%20Green.png"]
  },
  "300sr" => {
    name: "Nebula Black",
    reference: "/models/300sr-nebula-black-official-v1.webp",
    sources: ["https://www.cfmoto.com/content/dam/cfmoto/site/global/product/motorcycle/sr---sport-racing/300sr_2023%E6%96%B0%E7%89%88/product-image/%E7%BC%96%E7%BB%84%203%E5%A4%87%E4%BB%BD%204.png"]
  },
  "450sr-s" => {
    name: "Gem Black",
    reference: "/models/450sr-s-gem-black-official-v1.webp",
    sources: ["https://www.cfmoto.com/content/dam/cfmoto/site/global/product/motorcycle/sr---sport-racing/450sr-s/2025/model2.png"]
  },
  "500sr-voom" => {
    name: "Zephyr Blue",
    reference: "/models/500sr-voom-zephyr-blue-official-v1.webp",
    sources: ["https://www.cfmoto.com/content/dam/cfmoto/site/global/product/motorcycle/sr---sport-racing/500sr-voom/2024/model/model1.png"]
  },
  "675nk" => {
    name: "Glacier White",
    reference: "/models/675nk-glacier-white-official-v1.webp",
    sources: ["https://www.cfmoto.com/content/dam/cfmoto/site/global/product/motorcycle/nk---naked/675nk/2025/model/color1.png"]
  },
  "675sr-r" => {
    name: "Nebula White",
    reference: "/models/675sr-r-nebula-white-official-v1.webp",
    sources: ["https://www.cfmoto.com/content/dam/cfmoto/site/global/product/motorcycle/sr---sport-racing/675sr-r/model/model1.png"]
  },
  "700mt" => {
    name: "Nebula White",
    reference: "/models/700mt-nebula-white-official-v1.webp",
    sources: ["https://www.cfmoto.com/content/dam/cfmoto/site/global/product/motorcycle/mt----mult-touring/700mt/2025/model/color2.png"]
  },
  "800mt-x" => {
    name: "Zephyr Blue",
    reference: "/models/800mt-x-zephyr-blue-official-v1.webp",
    sources: [
      "https://www.cfmoto.com/content/dam/cfmoto/site/global/product/motorcycle/mt----mult-touring/800mt-x/model/model7.png",
      "https://cfimages.cfmoto.com/cfmoto/20240827_800_MT_X_2_e5dd79a39a.jpg"
    ]
  },
  "cflite-230-dual" => {
    name: "Zephyr Blue",
    reference: "/models/cflite-230-dual-zephyr-blue-official-v1.webp",
    sources: ["https://static.wixstatic.com/media/dab146_bc8d10762a584e79b0f476bcf74733fd~mv2.png"]
  },
  "cforce-520-l" => {
    name: "Magma Red",
    reference: "/models/cforce-520-l-magma-red-official-v1.webp",
    sources: ["https://cfmoto.com.ua/uploads/2024/11/CFORCE-520-L_Magma-Red.png"]
  },
  "u10-xl-pro" => {
    name: "Bordeaux Red",
    reference: "/models/u10-xl-pro-bordeaux-red-official-v1.webp",
    sources: ["https://www.cfmoto.com/content/dam/cfmoto/site/global/product/sxs/utility/u10-xl-pro/2026/model1.png"]
  },
  "uforce-600" => {
    name: "Desert Tan",
    reference: "/models/uforce-600-desert-tan-official-v1.webp",
    sources: ["https://www.cfmoto.com/content/dam/cfmoto/site/global/product/sxs/utility/uforce-600/2026/model1.png"]
  },
  "zforce-1000-sport-r" => {
    name: "Desert Tan",
    reference: "/models/zforce-1000-sport-r-desert-tan-official-v1.webp",
    sources: ["https://cfmoto.com.ua/uploads/2020/10/2024-ZFORCE1000-SPORT-R-Side-Desert-Tan-760x578.png"]
  },
  "zforce-950-sport-4" => {
    name: "Nebula Black",
    reference: "/models/zforce-950-sport-4-nebula-black-official-v1.webp",
    sources: ["https://www.cfmoto.com/content/dam/cfmoto/site/global/product/sxs/sports/zforce-950-sport-4/2026/model1.png"]
  }
}.freeze

VERIFIED_ALTERNATE_COLOR_IMAGES = {
  "800mt-x" => {
    name: "Nebula Black",
    reference: "/models/800mt-x-nebula-black-official-v1.webp",
    sources: [
      "https://www.cfmoto.com/content/dam/cfmoto/site/global/product/motorcycle/mt----mult-touring/800mt-x/model/model8.png",
      "https://cfimages.cfmoto.com/cfmoto/20240827_800_MT_X_2_386ef05b10.jpg"
    ]
  }
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

  if (primary = VERIFIED_PRIMARY_COLOR_IMAGES[slug])
    source.gsub!("/models/#{slug}.webp", primary.fetch(:reference))
    primary.fetch(:sources).each { |old_reference| source.gsub!(old_reference, primary.fetch(:reference)) }
  end

  if (alternate = VERIFIED_ALTERNATE_COLOR_IMAGES[slug])
    alternate.fetch(:sources).each { |old_reference| source.gsub!(old_reference, alternate.fetch(:reference)) }
  end

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
