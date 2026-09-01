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

  %w[price priceCurrency availability url priceValidUntil itemCondition].each do |property|
    errors << "#{label} Offer is missing #{property}" if offer[property].nil? || offer[property] == ""
  end
  errors << "#{label} Offer has the wrong price-validity date" unless offer["priceValidUntil"] == PRICE_VALID_UNTIL
  errors << "#{label} Offer is not marked as new" unless offer["itemCondition"] == NEW_CONDITION
  errors << "#{label} Offer seller is missing its name" if offer.dig("seller", "name").to_s.empty?
  errors << "#{label} Offer seller is missing its URL" unless offer.dig("seller", "url") == SELLER_URL
end

errors << "Expected Product structured data for both Azerbaijani and Russian model pages" if products.size < 94

if errors.empty?
  puts "Product structured-data audit passed: #{products.size} complete Product offers"
else
  warn errors.map { |error| "- #{error}" }.join("\n")
  exit 1
end
