#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require_relative "apply_product_structured_data_fixes"

errors = []
products = []

PRODUCT_PATHS.each do |path|
  product_schemas(path).each do |product|
    products << [path, product]
  end
rescue JSON::ParserError => error
  errors << "#{path.delete_prefix("#{ROOT}/")}: invalid JSON-LD: #{error.message}"
end

products.each do |path, product|
  relative = path.delete_prefix("#{ROOT}/")
  label = "#{relative}: #{product['name'] || 'unnamed Product'}"
  %w[name image description brand category url sku model].each do |property|
    errors << "#{label} is missing #{property}" if product[property].nil? || product[property] == ""
  end

  offer = product["offers"]
  unless offer.is_a?(Hash) && offer["@type"] == "Offer"
    errors << "#{label} is missing its Offer"
    next
  end

  slug = model_slug(product)
  offer_properties = %w[price priceCurrency url itemCondition]
  offer_properties.concat(%w[validFrom priceValidUntil]) unless slug == "cforce-c6-pro"
  offer_properties << "availability" unless slug == "zeeho-ez4"
  offer_properties.each do |property|
    errors << "#{label} Offer is missing #{property}" if offer[property].nil? || offer[property] == ""
  end
  unless slug == "cforce-c6-pro"
    errors << "#{label} Offer has the wrong price-validity date" unless offer["priceValidUntil"] == PRICE_VALID_UNTIL
    errors << "#{label} Offer has an invalid start date" unless offer["validFrom"].to_s.match?(/\A\d{4}-\d{2}-\d{2}\z/) && offer["validFrom"] <= offer["priceValidUntil"]
  end
  errors << "#{label} Offer is not marked as new" unless offer["itemCondition"] == NEW_CONDITION
  errors << "#{label} Offer seller is missing its name" if offer.dig("seller", "name").to_s.empty?
  errors << "#{label} Offer seller is missing its URL" unless offer.dig("seller", "url") == SELLER_URL
end

errors << "Expected Product structured data for both Azerbaijani and Russian model pages" if products.size < 100

c6_products = products.select { |_path, product| model_slug(product) == "cforce-c6-pro" }
errors << "Expected Azerbaijani and Russian C6 Product schemas" unless c6_products.size == 2
c6_products.each do |path, product|
  label = path.delete_prefix("#{ROOT}/")
  offer = product["offers"] || {}
  errors << "#{label}: C6 price must be 16900 AZN" unless offer["price"].to_s == "16900" && offer["priceCurrency"] == "AZN"
  errors << "#{label}: C6 must remain a preorder" unless offer["availability"] == "https://schema.org/PreOrder"
  errors << "#{label}: C6 preorder must not invent offer dates" if offer.key?("validFrom") || offer.key?("priceValidUntil")
end

ez4_products = products.select { |_path, product| model_slug(product) == "zeeho-ez4" }
errors << "Expected Azerbaijani and Russian ZEEHO EZ4 Product schemas" unless ez4_products.size == 2
ez4_products.each do |path, product|
  label = path.delete_prefix("#{ROOT}/")
  errors << "#{label}: EZ4 brand must be ZEEHO" unless product.dig("brand", "name") == "ZEEHO"
  errors << "#{label}: EZ4 SKU must remain ZH1300DT-3" unless product["sku"] == "ZH1300DT-3"
  errors << "#{label}: EZ4 price must be 2890 AZN" unless product.dig("offers", "price").to_s == "2890" && product.dig("offers", "priceCurrency") == "AZN"
  errors << "#{label}: EZ4 stock status must not be invented" if product.dig("offers", "availability")
end

if errors.empty?
  puts "Product structured-data audit passed: #{products.size} complete Product offers"
else
  warn errors.map { |error| "- #{error}" }.join("\n")
  exit 1
end
