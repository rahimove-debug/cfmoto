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
  errors << "#{locale}: old colour remains" if html.include?("Athens Blue") || html.include?("Nebula Black")
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

required_images = %w[
  models/250nk.webp
  models/cards/250nk.webp
  gallery/250nk-1.webp
  gallery/250nk-2.webp
  gallery/250nk-3.webp
]
required_images.each do |relative|
  path = File.join(ROOT, relative)
  errors << "Missing official CFLITE image: #{relative}" unless File.file?(path) && File.size(path) > 10_000
end

catalogues = Dir.glob(File.join(ROOT, "assets", "ProductMegaMenu-*.js"))
record_pattern = /slug:`250nk`,name:`CFLITE 250NK`,type:`[^`]+`,segment:`Naked`,engineClass:`[^`]+`,price:4790,image:`\/models\/250nk\.webp`/
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
