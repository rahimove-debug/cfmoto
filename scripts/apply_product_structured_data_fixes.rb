#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "uri"

ROOT = File.expand_path("..", __dir__)
PRICE_VALID_UNTIL = "2027-09-01"
SELLER_URL = "https://cfmoto.az/"
NEW_CONDITION = "https://schema.org/NewCondition"

PRODUCT_PATHS = [
  *Dir.glob(File.join(ROOT, "model", "*", "index.html")),
  *Dir.glob(File.join(ROOT, "ru", "model", "*", "index.html")),
  *Dir.glob(File.join(ROOT, "xeberler", "*", "index.html"))
].sort.freeze

def walk_json(value, &block)
  yield value
  case value
  when Hash
    value.each_value { |child| walk_json(child, &block) }
  when Array
    value.each { |child| walk_json(child, &block) }
  end
end

def model_slug(product)
  url = product["url"] || product.dig("offers", "url")
  return unless url

  segments = URI.parse(url).path.split("/").reject(&:empty?)
  model_index = segments.index("model")
  segments[model_index + 1] if model_index && segments[model_index + 1]
rescue URI::InvalidURIError
  nil
end

def product_schemas(path)
  html = File.read(path, encoding: "UTF-8")
  schemas = []
  html.scan(%r{<script type="application/ld\+json">(.*?)</script>}m).flatten.each do |source|
    schema = JSON.parse(source)
    walk_json(schema) do |node|
      schemas << node if node.is_a?(Hash) && node["@type"] == "Product"
    end
  end
  schemas
end

def apply_product_structured_data_fixes!
  model_reference = {}
  Dir.glob(File.join(ROOT, "model", "*", "index.html")).sort.each do |path|
    product_schemas(path).each do |product|
      slug = model_slug(product)
      model_reference[slug] = product if slug
    end
  end

  updated_products = 0

  PRODUCT_PATHS.each do |path|
    html = File.read(path, encoding: "UTF-8")
    updated = html.gsub(%r{<script type="application/ld\+json">(.*?)</script>}m) do
      schema = JSON.parse(Regexp.last_match(1))
      walk_json(schema) do |node|
        next unless node.is_a?(Hash) && node["@type"] == "Product"

        offer = node["offers"]
        next unless offer.is_a?(Hash) && offer["@type"] == "Offer"

        slug = model_slug(node)
        reference = model_reference[slug]
        node["url"] ||= offer["url"]
        node["image"] ||= reference&.fetch("image", nil)
        node["description"] ||= reference&.fetch("description", nil)
        node["brand"] ||= reference&.fetch("brand", nil)
        node["category"] ||= reference&.fetch("category", nil)
        node["sku"] = slug if slug
        node["model"] ||= node["name"].to_s.sub(/\ACFMOTO\s+/i, "")

        offer["priceValidUntil"] = PRICE_VALID_UNTIL
        offer["itemCondition"] = NEW_CONDITION
        seller = offer["seller"]
        seller["url"] ||= SELLER_URL if seller.is_a?(Hash)
        updated_products += 1
      end
      %(<script type="application/ld+json">#{JSON.generate(schema)}</script>)
    rescue JSON::ParserError => error
      abort "#{path.delete_prefix("#{ROOT}/")}: invalid JSON-LD: #{error.message}"
    end
    File.write(path, updated, encoding: "UTF-8")
  end

  abort "No CFMOTO Product offers were updated" if updated_products.zero?

  puts "Product structured-data fixes applied to #{updated_products} Product offers"
end

apply_product_structured_data_fixes! if __FILE__ == $PROGRAM_NAME
