#!/usr/bin/env ruby

require "digest"

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
  source = File.read(File.join(ROOT, relative_path))
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

puts "Model image audit passed: #{page_paths.size} pages and #{local_image_refs.size} local references checked"
