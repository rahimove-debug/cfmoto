#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "json"

ROOT = File.expand_path(ARGV.fetch(0, ".."), __dir__)
errors = []

pages = {
  "AZ" => File.join(ROOT, "model", "250nk", "index.html"),
  "RU" => File.join(ROOT, "ru", "model", "250nk", "index.html")
}

pages.each do |locale, path|
  html = File.read(path, encoding: "UTF-8")
  errors << "#{locale}: product name missing" unless html.include?("CFLITE 250NK")
  errors << "#{locale}: EFI + ABS variant missing" unless html.include?("EFI + ABS") && html.include?("5,390 AZN")
  errors << "#{locale}: Carb variant missing" unless html.include?("Carb") && html.include?("4,790 AZN")
  errors << "#{locale}: legacy standalone name remains" if html.match?(/(?<!CFLITE )(?<!CFLITE%20)250NK/)
  errors << "#{locale}: official Zephyr Blue colour missing" unless html.include?("Zephyr Blue")
  errors << "#{locale}: official Zephyr Blue image missing" unless html.include?("/models/cflite-250nk-zephyr-blue-v1.webp")
  errors << "#{locale}: official Bordeaux Red colour missing" unless html.include?("Bordeaux Red") && html.include?("/models/cflite-250nk-bordeaux-red-v1.webp")
  errors << "#{locale}: legacy colour remains" if html.include?("Athens Blue") || html.include?("Nebula Black") || html.include?("Ruby Red")
  errors << "#{locale}: variant stylesheet missing" unless html.include?("/assets/cflite-250nk-v1.css")

  schema_source = html[%r{<script type="application/ld\+json">(.*?)</script>}m, 1]
  begin
    schema = JSON.parse(schema_source)
    errors << "#{locale}: Product name is wrong" unless schema["name"] == "CFLITE 250NK"
    errors << "#{locale}: entry Offer price is wrong" unless schema.dig("offers", "price").to_i == 4_790
    properties = schema.fetch("additionalProperty", []).to_h { |entry| [entry["name"], entry["value"]] }
    errors << "#{locale}: structured EFI price missing" unless properties["EFI + ABS"] == "5,390 AZN"
    errors << "#{locale}: structured Carb price missing" unless properties.values.include?("4,790 AZN")
  rescue JSON::ParserError, TypeError => error
    errors << "#{locale}: Product schema invalid (#{error.message})"
  end
end

required_images = {
  "models/cflite-250nk-zephyr-blue-v1.webp" => "9aeb763ebfd82739689593413e86e26f29ec10f123b2e1a34ada3743ef5c45aa",
  "models/cflite-250nk-bordeaux-red-v1.webp" => "9929123d18dcddb9b24b2339acc81a80423ff605080a937aacfb95750cb049cf",
  "models/cards/cflite-250nk-v1.webp" => "f2cdb42642a7eac5260c6224b42d35c516282e27f352d52db1b29d3c0e565381",
  "gallery/cflite-250nk-1-v1.webp" => "ac6d82b36f5ec5eea9919949df474456e0e2ed585c9dd4630b4eecd4b3cebf38",
  "gallery/cflite-250nk-2-v1.webp" => "7767eba57a968a63992d362f529f75cef203db17a793261a5402709ddfe2fa10",
  "gallery/cflite-250nk-3-v1.webp" => "d2076b2513c78c192e4e071639373feeedaa5f808796fa60c6be995a8dbeedaf"
}
required_images.each do |relative, expected_sha256|
  path = File.join(ROOT, relative)
  errors << "Missing official CFLITE image: #{relative}" unless File.file?(path) && File.size(path) > 10_000
  errors << "Incorrect CFLITE model image: #{relative}" if File.file?(path) && Digest::SHA256.file(path).hexdigest != expected_sha256
end

catalogues = Dir.glob(File.join(ROOT, "assets", "ProductMegaMenu-*.js"))
record_pattern = /slug:`250nk`,name:`CFLITE 250NK`,type:`[^`]+`,segment:`Naked`,engineClass:`[^`]+`,price:4790,image:`\/models\/cflite-250nk-zephyr-blue-v1\.webp`/
errors << "CFLITE 250NK entry price is missing from the public catalogue" unless catalogues.any? { |path| File.read(path, encoding: "UTF-8").match?(record_pattern) }

configurator = Dir.glob(File.join(ROOT, "aksesuar-konfiquratoru", "**", "page-*.js"))
errors << "CFLITE 250NK entry price is missing from the configurator" unless configurator.any? do |path|
  File.read(path, encoding: "UTF-8").match?(/id:"250nk",name:"CFLITE 250NK"[^{}]*basePriceAzn:4790/)
end

if errors.empty?
  puts "CFLITE 250NK audit passed: localized detail pages, 2 variants, exact prices, structured data, catalogue and official images"
else
  warn errors.map { |error| "- #{error}" }.join("\n")
  exit 1
end
