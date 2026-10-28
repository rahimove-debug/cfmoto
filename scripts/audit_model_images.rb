#!/usr/bin/env ruby

require "digest"
require "json"

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

def standard_color_data(source)
  decoded = source.force_encoding(Encoding::UTF_8).gsub('\\"', '"')
  match = decoded.match(/"colors":(\[.*?\]),"fallbackImage":"([^"]+)"/m)
  return [nil, nil] unless match

  [JSON.parse(match[1]), match[2]]
end

# Audit every standard color selector, not only the models with known fixes.
# AZ/RU must expose the same named assets; each color needs a distinct source;
# and the server-rendered hero/fallback must match the first selector option.
az_model_pages = Dir.glob(File.join(ROOT, "model", "*", "index.html")).to_h do |path|
  [File.basename(File.dirname(path)), path]
end
ru_model_pages = Dir.glob(File.join(ROOT, "ru", "model", "*", "index.html")).to_h do |path|
  [File.basename(File.dirname(path)), path]
end

selector_count = 0
az_model_pages.each do |slug, az_path|
  ru_path = ru_model_pages.fetch(slug) { abort "Missing RU model page for #{slug}" }
  az_source = File.binread(az_path)
  ru_source = File.binread(ru_path)
  az_colors, az_fallback = standard_color_data(az_source)
  ru_colors, ru_fallback = standard_color_data(ru_source)

  if az_colors.nil? || ru_colors.nil?
    abort "#{slug}: standard color selector exists in only one locale" unless az_colors.nil? && ru_colors.nil?
    next
  end

  selector_count += 1
  abort "#{slug}: AZ/RU color mappings differ" unless az_colors == ru_colors
  abort "#{slug}: AZ/RU fallback images differ" unless az_fallback == ru_fallback

  images = az_colors.map { |color| color.fetch("image") }
  abort "#{slug}: two color options reuse the same image reference" unless images.uniq.size == images.size

  first_image = images.first
  abort "#{slug}: fallback does not match the first color" unless az_fallback == first_image
  [az_source, ru_source].each do |source|
    unless source.include?(%(class="model-color-image" src="#{first_image}"))
      abort "#{slug}: initial hero does not match the first color"
    end
  end
end

abort "Expected 47 standard color selectors, found #{selector_count}" unless selector_count == 47

# These exact official derivatives repair every clear first-color mismatch found
# by the full 49-model AZ/RU visual audit. Pinning bytes prevents a later card
# export from silently reintroducing a different paint option under the label.
verified_primary_colors = {
  "125nk" => ["Gem Black", "/models/125nk-gem-black-official-v1.webp", "126232f2d5a09cac1a8f13688d2a0e536e87e26665529687f6a8bddfe15dabf6"],
  "150sc" => ["Space Silver", "/models/150sc-space-silver-official-v1.webp", "1637e9e5279871f413ee75bb5ef69dd2c1df9d946927da9326b6726b570f0f0d"],
  "250cl-c" => ["Nebula Black", "/models/250cl-c-nebula-black-official-v1.webp", "b5e54a53e9e630c6dd755daae916dca16e26e529acd2e47bc4a089d868fecf4c"],
  "250dual" => ["Lime Green", "/models/250dual-lime-green-official-v1.webp", "e1fd4adf321774434eb16f06727ac5a906af738ff97ef7e99c775143d40d628c"],
  "300sr" => ["Nebula Black", "/models/300sr-nebula-black-official-v1.webp", "f1981b64cbdcdcf077d36606d5c0132257a6132ec97b06df992b8484f31f387a"],
  "450sr-s" => ["Gem Black", "/models/450sr-s-gem-black-official-v1.webp", "687d4e683514d325b22caca3639f23bb51f44c0790388704c93a2ca5e8f75f4b"],
  "500sr-voom" => ["Zephyr Blue", "/models/500sr-voom-zephyr-blue-official-v1.webp", "c2bc4d493f341de4520397f23a7ef4b408680291f30410f04388da0406e4b21e"],
  "675nk" => ["Glacier White", "/models/675nk-glacier-white-official-v1.webp", "b8ab2018fb838a427ac398964d08c9a47e7c7a330934b2c8c2ab3aab7e505a39"],
  "675sr-r" => ["Nebula White", "/models/675sr-r-nebula-white-official-v1.webp", "10007b17baea9652042286d947e2e9009016167700143a5d8d76291f3e6f1451"],
  "700mt" => ["Nebula White", "/models/700mt-nebula-white-official-v1.webp", "4413940505236da284010e7260934b5c66d88c3f74bd9f1cc065c9f0b08c45e8"],
  "800mt-x" => ["Zephyr Blue", "/models/800mt-x-zephyr-blue-official-v1.webp", "9b52d4e357e5fb667eab974b30e8c84df38477b3fa1cee9b7a75c966a7a896ae"],
  "cflite-230-dual" => ["Zephyr Blue", "/models/cflite-230-dual-zephyr-blue-official-v1.webp", "75b4fa022166b04cfd567a444949f526ace1cfc44f99089a4870d58f9a441abf"],
  "cforce-520-l" => ["Magma Red", "/models/cforce-520-l-magma-red-official-v1.webp", "f8e145a2fb45f8c4a289b15b3457f9a9660c93592476e1ec041094f712b6a6d8"],
  "u10-xl-pro" => ["Bordeaux Red", "/models/u10-xl-pro-bordeaux-red-official-v1.webp", "c72d98a0bf314e2dd65f74f15f316f207ed3ca823635af4027b8a6c48948108f"],
  "uforce-600" => ["Desert Tan", "/models/uforce-600-desert-tan-official-v1.webp", "c1825dae54e1c6c7b902b511b6438bc8c643e456c67cc30cbabbc12f179a394e"],
  "zforce-1000-sport-r" => ["Desert Tan", "/models/zforce-1000-sport-r-desert-tan-official-v1.webp", "44018b1caa2091d6fc9fb4ab00e7f5e900949dff91b0d79620b1e8c8ec61cfc4"],
  "zforce-950-sport-4" => ["Nebula Black", "/models/zforce-950-sport-4-nebula-black-official-v1.webp", "ea83adb0af842294d3a73b8cc484e6c1cbb9a1a4b1395bae20f58fcb53fde753"]
}.freeze

verified_alternate_colors = {
  "800mt-x" => ["Nebula Black", "/models/800mt-x-nebula-black-official-v1.webp", "6f12e49800e8fca47f8c3f4f03eaff4a29fdd96421fc345548e15da7c614943e"]
}.freeze

(verified_primary_colors.merge(verified_alternate_colors) { |_slug, primary, alternate| [primary, alternate] }).each do |slug, specs|
  specs = [specs] if specs.first.is_a?(String)
  az_source = File.binread(az_model_pages.fetch(slug)).force_encoding(Encoding::UTF_8).gsub('\\"', '"')
  ru_source = File.binread(ru_model_pages.fetch(slug)).force_encoding(Encoding::UTF_8).gsub('\\"', '"')

  specs.each do |name, reference, sha256|
    image_path = File.join(ROOT, reference.delete_prefix("/"))
    abort "#{slug}: missing verified #{name} image" unless File.file?(image_path)
    unless Digest::SHA256.file(image_path).hexdigest == sha256
      abort "#{slug}: verified #{name} image bytes changed"
    end
    mapping = /"name":"#{Regexp.escape(name)}","value":"[^"]+","image":"#{Regexp.escape(reference)}"/
    abort "#{slug}: incorrect AZ #{name} mapping" unless az_source.match?(mapping)
    abort "#{slug}: incorrect RU #{name} mapping" unless ru_source.match?(mapping)
  end
end

verified_primary_colors.each do |slug, (_name, reference, _sha256)|
  [az_model_pages.fetch(slug), ru_model_pages.fetch(slug)].each do |page_path|
    source = File.binread(page_path).force_encoding(Encoding::UTF_8)
    decoded = source.gsub('\\"', '"')
    abort "#{slug}: incorrect initial verified color image" unless source.include?(%(class="model-color-image" src="#{reference}"))
    abort "#{slug}: incorrect verified fallback image" unless decoded.include?(%("fallbackImage":"#{reference}"))
    abort "#{slug}: stale generic primary remains" if source.include?(%(/models/#{slug}.webp))
  end
end

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
