#!/usr/bin/env ruby

require "digest"

ROOT = File.expand_path("..", __dir__)
STYLESHEET = "/assets/model-image-layout-CfmotoImageFixV1.css"
BOBBER_STYLESHEET = "/assets/450cl-c-bobber-images-v1.css"

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

# Pin both Global color mappings and their original image bytes. Different URLs
# alone would not catch accidentally copying the same photo under two names.
aura_colors = {
  "Ivory White" => ["/models/aura-150-ivory-white-official-v1.png", "fd04791915f2c43c94c1c9954b54b6cdbf38ba944fbd04f0b766e2695cd5320f"],
  "Vintage White" => ["/models/aura-150-vintage-white-official-v1.png", "7f08e3a008b01c6aa24f21f38e47b15d3c18596a9aee0f4d3bb7c7c68912dcdd"]
}.freeze

aura_colors.each do |name, (reference, sha256)|
  image_path = File.join(ROOT, reference.delete_prefix("/"))
  abort "Missing official AURA #{name} image" unless File.file?(image_path)
  abort "AURA #{name} image differs from the verified Global source" unless Digest::SHA256.file(image_path).hexdigest == sha256
end

%w[model/aura-150/index.html ru/model/aura-150/index.html].each do |relative_path|
  source = File.binread(File.join(ROOT, relative_path)).force_encoding(Encoding::UTF_8)
  decoded = source.gsub('\\"', '"')
  aura_colors.each do |name, (reference, _sha256)|
    mapping = /"name":"#{Regexp.escape(name)}","value":"[^"]+","image":"#{Regexp.escape(reference)}"/
    abort "#{relative_path}: incorrect AURA #{name} color mapping" unless decoded.match?(mapping)
  end
  ivory = aura_colors.fetch("Ivory White").first
  abort "#{relative_path}: incorrect initial AURA image" unless source.include?(%(class="model-color-image" src="#{ivory}"))
  abort "#{relative_path}: incorrect AURA fallback image" unless decoded.include?(%("fallbackImage":"#{ivory}"))
  abort "#{relative_path}: misleading imported AURA image remains" if source.include?("/models/aura-150.webp")
end

# Pin the official BOBBER image derivatives and verify color/locale hydration
# data. Different local URLs alone would not catch a mislabeled or duplicated
# color export.
bobber_colors = {
  "Ivory White" => ["/models/450cl-c-bobber-ivory-white-official-v1.webp", "66daa6b07d645c917f0bb4969b1757a05ebda9e5874d8e3b3345027f5f349486"],
  "Nebula Black" => ["/models/450cl-c-bobber-nebula-black-official-v1.webp", "483c51688617fb5d1004c696ecda425fac432335af358c6a67c0550c1ce297e6"]
}.freeze

bobber_gallery = {
  "/gallery/450cl-c-bobber-silhouette-official-v1.webp" => "eb32efcb69a6e9b46ffded1e2d5a490da2f811c7e5a340267674a2e82b7afdd9",
  "/gallery/450cl-c-bobber-riding-position-official-v1.webp" => "68d2fb9b4981231ba33a5fd6372b680a065cf0c5cbec8a2251ef4c5995dc2fc4",
  "/gallery/450cl-c-bobber-detail-official-v1.webp" => "af6009e6efbab354aad73805f916c0e7d0c4ad2448e3c2c38de48a0848c9c72d"
}.freeze

(bobber_colors.values.to_h { |reference, sha256| [reference, sha256] }.merge(bobber_gallery)).each do |reference, sha256|
  image_path = File.join(ROOT, reference.delete_prefix("/"))
  abort "Missing official BOBBER image: #{reference}" unless File.file?(image_path)
  abort "BOBBER image differs from the verified official derivative: #{reference}" unless Digest::SHA256.file(image_path).hexdigest == sha256
end

bobber_stylesheet_path = File.join(ROOT, BOBBER_STYLESHEET.delete_prefix("/"))
abort "Missing BOBBER image stylesheet" unless File.file?(bobber_stylesheet_path)
bobber_stylesheet = File.binread(bobber_stylesheet_path)
unless bobber_stylesheet.include?("aspect-ratio: 3 / 2") && bobber_stylesheet.include?("min-height: 0 !important")
  abort "BOBBER stylesheet does not preserve the official 3:2 gallery framing"
end

%w[model/450cl-c-bobber/index.html ru/model/450cl-c-bobber/index.html].each do |relative_path|
  source = File.binread(File.join(ROOT, relative_path)).force_encoding(Encoding::UTF_8)
  decoded = source.gsub('\\"', '"')

  bobber_colors.each do |name, (reference, _sha256)|
    mapping = /"name":"#{Regexp.escape(name)}","value":"[^"]+","image":"#{Regexp.escape(reference)}"/
    abort "#{relative_path}: incorrect BOBBER #{name} color mapping" unless decoded.match?(mapping)
  end

  ivory = bobber_colors.fetch("Ivory White").first
  abort "#{relative_path}: incorrect initial BOBBER image" unless source.include?(%(class="model-color-image" src="#{ivory}"))
  abort "#{relative_path}: incorrect BOBBER fallback image" unless decoded.include?(%("fallbackImage":"#{ivory}"))
  abort "#{relative_path}: missing BOBBER framing stylesheet" unless source.include?(%(<link rel="stylesheet" href="#{BOBBER_STYLESHEET}"/>))

  bobber_gallery.each_key do |reference|
    abort "#{relative_path}: missing official BOBBER gallery image #{reference}" unless source.include?(reference)
  end

  deprecated = [
    "/models/450cl-c-bobber.webp",
    "/gallery/450cl-c-bobber-1.webp",
    "/gallery/450cl-c-bobber-2.webp",
    "/gallery/450cl-c-bobber-3.webp",
    "https://www.cfmoto.com/content/dam/cfmoto/site/global/product/motorcycle/cl-x----classic/450cl-c-bobber/2024/model/model_2.png"
  ]
  hits = deprecated.select { |reference| source.include?(reference) }
  abort "#{relative_path}: stale or corrupt BOBBER image references remain: #{hits.join(', ')}" unless hits.empty?
end

puts "Model image audit passed: #{page_paths.size} pages and #{local_image_refs.size} local references checked, including BOBBER color/gallery quality"
