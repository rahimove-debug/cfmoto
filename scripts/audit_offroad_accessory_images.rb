#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "apply_offroad_accessory_images"

errors = []
bundle = File.read(BUNDLE, encoding: "UTF-8")

errors << "Key-aware DMS image selection is missing" unless bundle.include?("image:#{IMAGE_MAP_VARIABLE}[r]??L[o.category],imageIsPlaceholder:!#{IMAGE_MAP_VARIABLE}[r]")
errors << "Off-road image state is still hard-coded as placeholder" if bundle.include?("image:L[o.category],imageIsPlaceholder:!0")

IMAGE_SOURCES.each_key do |catalog_key|
  filename = public_filename(catalog_key)
  image_url = "/accessories/#{PUBLIC_DIRECTORY}/#{filename}"
  errors << "#{catalog_key}: catalog key is missing" unless bundle.include?(%Q{["#{catalog_key}",})
  errors << "#{catalog_key}: mapped URL is missing" unless bundle.include?(JSON.generate(catalog_key => image_url)[1..-2])

  [File.join(ROOT, "accessories", PUBLIC_DIRECTORY, filename)].each do |path|
    unless File.file?(path)
      errors << "#{catalog_key}: missing #{path.delete_prefix("#{ROOT}/")}"
      next
    end
    errors << "#{catalog_key}: empty image #{path.delete_prefix("#{ROOT}/")}" unless File.size(path).positive?
  end
end

abort "Off-road accessory image audit failed:\n- #{errors.join("\n- ")}" unless errors.empty?

puts "Off-road accessory image audit passed: #{IMAGE_SOURCES.size} matched DMS photos in the public asset root"
