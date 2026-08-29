#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "apply_offroad_accessory_images"
require_relative "offroad_official_hq_sources"

errors = []
bundle = File.read(BUNDLE, encoding: "UTF-8")

errors << "Key-aware DMS image selection is missing" unless bundle.include?("image:#{IMAGE_MAP_VARIABLE}[r]??L[o.category],imageIsPlaceholder:!#{IMAGE_MAP_VARIABLE}[r]")
errors << "Off-road image state is still hard-coded as placeholder" if bundle.include?("image:L[o.category],imageIsPlaceholder:!0")

IMAGE_SOURCES.each_key do |catalog_key|
  filename = public_filename(catalog_key)
  directory = OFFICIAL_OFFROAD_HQ_SOURCES.key?(catalog_key) ? HQ_PUBLIC_DIRECTORY : PUBLIC_DIRECTORY
  image_url = "/accessories/#{directory}/#{filename}"
  errors << "#{catalog_key}: catalog key is missing" unless bundle.include?(%Q{["#{catalog_key}",})
  errors << "#{catalog_key}: mapped URL is missing" unless bundle.include?(JSON.generate(catalog_key => image_url)[1..-2])

  [File.join(ROOT, "accessories", directory, filename)].each do |path|
    unless File.file?(path)
      errors << "#{catalog_key}: missing #{path.delete_prefix("#{ROOT}/")}"
      next
    end
    minimum_size = directory == HQ_PUBLIC_DIRECTORY ? 20_000 : 1
    errors << "#{catalog_key}: image is unexpectedly small #{path.delete_prefix("#{ROOT}/")}" if File.size(path) < minimum_size
  end
end

abort "Off-road accessory image audit failed:\n- #{errors.join("\n- ")}" unless errors.empty?

puts "Off-road accessory image audit passed: #{OFFICIAL_OFFROAD_HQ_SOURCES.size} official HQ images and #{IMAGE_SOURCES.size - OFFICIAL_OFFROAD_HQ_SOURCES.size} matched DMS photos"
