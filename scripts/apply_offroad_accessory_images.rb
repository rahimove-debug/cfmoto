#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"

ROOT = File.expand_path("..", __dir__)
CONFIGURATOR_ROOT = File.join(ROOT, "aksesuar-konfiquratoru")
BUNDLE = File.join(CONFIGURATOR_ROOT, "_next", "static", "chunks", "app", "page-cfmoto-offroad-partsazn-v4.js")
SOURCE_ROOT = ENV.fetch("CFMOTO_DMS_OFFROAD_SOURCE", File.expand_path("../cfmoto-dms-accessories/final", ROOT))
PUBLIC_DIRECTORY = "dms-offroad"
IMAGE_MAP_VARIABLE = "offroadDmsImages"

# Key-specific mapping is deliberate: several catalog entries share a part
# family, but the DMS photo must still match the selected vehicle and variant.
IMAGE_SOURCES = {
  "c45-a-arm" => "atv/cforce-c4-c5/24-aluminum-a-arm-protectors.jpg",
  "c45-canvas-bag" => "atv/cforce-c4-c5/15-canvas-storage-bag.jpg",
  "c45-winch-guard" => "atv/cforce-c4-c5/20-steel-winch-guard.jpg",
  "c45-heated-2up" => "atv/cforce-c4-c5/28-heated-seat-assembly-2up.jpg",
  "c45-heated-1up" => "atv/cforce-c4-c5/27-heated-seat-assembly-1up.jpg",
  "c45-rear-box-110" => "atv/cforce-c4-c5/13-110l-rear-cargo-box-assembly-lock-latch.jpg",
  "c45-front-bumper" => "atv/cforce-c4-c5/03-front-bumper-assembly.jpg",
  "c45-rear-bumper" => "atv/cforce-c4-c5/04-rear-bumper-assembly.jpg",
  "c45-rack-extender" => "atv/cforce-c4-c5/10-rack-extender-assembly.jpg",
  "c45-cargo-55" => "atv/cforce-c4-c5/11-55l-cargo-box-assembly-lock-latch.jpg",
  "c45-basket" => "atv/cforce-c4-c5/14-front-basket-assembly.jpg",
  "c500-front-bumper" => "atv/cforce-520-l/12-front-bumper-assembly.jpg",
  "c500-rear-bumper" => "atv/cforce-520-l/13-rear-bumper-assembly.jpg",
  "c500-front-basket" => "atv/cforce-520-l/31-front-basket-assembly.jpg",
  "c500-rack-extender" => "atv/cforce-520-l/29-rack-extender-assembly.jpg",
  "c500-front-box" => "atv/cforce-520-l/18-front-cargo-box-assembly-new-lock-latch.jpg",
  "c500-rear-box" => "atv/cforce-520-l/16-rear-cargo-box-assembly-new-lock-latch.jpg",
  "c600-windshield" => "atv/cforce-625-touring-legacy/16-front-windshield-assembly.jpg",
  "c600-front-bumper" => "atv/cforce-625-touring-legacy/18-front-bumper-assembly.jpg",
  "c600-rear-bumper" => "atv/cforce-625-touring-legacy/17-rear-bumper-assy.jpg",
  "c600-front-basket" => "atv/cforce-625-touring-legacy/05-front-cargo-basket-assembly.jpg",
  "c600-front-rack" => "atv/cforce-625-touring-legacy/30-front-rack-extender-assembly-1-piece.jpg",
  "c600-rear-rack" => "atv/cforce-625-touring-legacy/21-rear-rack-extender-assembly-1-piece.jpg",
  "c600-cargo-box" => "atv/cforce-625-touring-legacy/12-x6-x6-touring-rear-cargo-box-lock.jpg",
  "c600-infill-rack" => "atv/cforce-625-touring-legacy/09-infill-passenger-rack.jpg",
  "ct-windshield" => "atv/cforce-850-touring/09-front-windshield-assembly-new-x8x10.jpg",
  "ct-front-bumper" => "atv/cforce-850-touring/10-front-bumper-assembly-newx8x10.jpg",
  "ct-rear-bumper" => "atv/cforce-850-touring/11-rear-bumper-assembly-new-x8x10.jpg",
  "ct-rack-extender" => "atv/cforce-850-touring/12-f-r-rack-extender-new-x8-x10.jpg",
  "ct-front-box" => "atv/cforce-850-touring/04-front-cargo-box-assembly-new-lock-latch.jpg",
  "ct-front-basket" => "atv/cforce-850-touring/05-front-basket-assembly.jpg",
  "ct-rear-box" => "atv/cforce-850-touring/03-rear-cargo-box-assembly-new-lock-latch.jpg",
  "ct-soft-bag" => "atv/cforce-850-touring/26-canvas-storage-bag.jpg",
  "ct-cooler" => "atv/cforce-850-touring/01-rear-atv-cooler-cooler-box-assembly.jpg",
  "ct-infill-rack" => "atv/cforce-850-touring/49-infill-box-assembly.jpg",
  "z10-front-bumper" => "buggy/z10-4/27-front-bumper-assembly.jpg",
  "z10-rear-bumper" => "buggy/z10-4/26-rear-bumper-assembly.jpg",
  "z10-intrusion-bar" => "buggy/z10-4/12-front-intrusion-bar-assembly.jpg",
  "z10-a-arm" => "buggy/z10-4/29-a-arm-protector-assembly.jpg",
  "z10-spare-carrier" => "buggy/z10-4/13-spare-tire-carrier-assembly.jpg",
  "z10-aluminum-mirrors" => "buggy/z10-4/34-side-mirrors-assembly.jpg",
  "z10-sport-mirrors" => "buggy/z10-4/34-side-mirrors-assembly.jpg",
  "z10-center-mirror" => "buggy/z10-4/25-center-mirror-assembly.jpg",
  "z10-front-camera" => "buggy/z10-4/28-front-camera-assembly.jpg",
  "z10-alternator" => "buggy/z10-4/19-alternator-assembly.jpg",
  "z10-screen-protector" => "buggy/z10-4/35-12-3-screen-protector-0-2mm.jpg",
  "z10-removable-box" => "buggy/z10-4/02-seat-box-assembly.jpg",
  "z104-rock-sliders" => "buggy/z10-4/24-nerf-bars-assembly-4-seater.jpg",
  "z10-harness" => "buggy/z10-4/08-4-point-seat-harness-kit.jpg",
  "z104-harness" => "buggy/z10-4/08-4-point-seat-harness-kit.jpg",
  "z10-door-bag" => "buggy/z10-4/03-front-door-storage-bag-kit.jpg",
  "z104-door-bag" => "buggy/z10-4/03-front-door-storage-bag-kit.jpg",
  "z104-skid" => "buggy/z10-4/23-hdpe-skid-plate-assembly-4-seater.jpg",
  "z104-full-front-system" => "buggy/z10-4/32-front-windshield-assembly.jpg",
  "z104-half-front-system" => "buggy/z10-4/38-front-half-windshield-assembly.jpg",
  "z104-rear-system" => "buggy/z10-4/10-rear-panel-assembly.jpg",
  "zf-full-front" => "buggy/zforce-950-sport-4/22-front-windshield-assembly.jpg",
  "zf-half-front" => "buggy/zforce-950-sport-4/26-front-half-windshield-assembly.jpg",
  "zf-full-rear" => "buggy/zforce-950-sport-4/20-rear-panel-assembly.jpg",
  "zf-side-mirrors" => "buggy/zforce-950-sport-4/30-side-mirrors-assembly.jpg",
  "zf-front-bumper" => "buggy/zforce-950-sport-4/19-front-bumper-assembly.jpg",
  "zf-rear-bumper" => "buggy/zforce-950-sport-4/13-rear-bumper-assembly.jpg",
  "zf-audio-1" => "buggy/zforce-950-sport-4/17-stage-1-door-speaker-kit.jpg",
  "zf-audio-2" => "buggy/zforce-950-sport-4/23-audio-system-assembly.jpg",
  "zf-trail-a-arm" => "buggy/zforce-950-sport-4/12-a-arm-protector-assembly.jpg",
  "zf-2-seat-nerf" => "buggy/zforce-950-sport-4/23-nerf-bars-assembly-2-seater.jpg",
  "zf-4-seat-nerf" => "buggy/zforce-950-sport-4/33-nerf-bumper-assembly.jpg",
  "zf-sport-a-arm" => "buggy/zforce-950-sport-4/28-a-arm-protector-assembly.jpg",
  "u10-full-poly" => "buggy/u10-pro/08-pc-full-windshield.jpg",
  "u10-poly-rear" => "buggy/u10-pro/07-pc-rear-panel.jpg",
  "u10-front-bumper" => "buggy/u10-pro/51-hd-front-bumper-assembly.jpg",
  "u10-rear-bumper" => "buggy/u10-pro/14-rear-bumper-assembly-eur.jpg",
  "u10-a-arm" => "buggy/u10-pro/05-hdpe-a-arm-protectors-kit-8mm.jpg",
  "u10-microphone" => "buggy/u10-pro/31-microphone-assembly.jpg",
  "u10-screen-protector" => "buggy/u10-pro/54-8-screen-protector-0-2mm.jpg",
  "u10-small-cargo" => "buggy/u10-pro/12-small-cargo-box.jpg",
  "u10-large-cargo" => "buggy/u10-pro/13-rear-cargo-box-assembly.jpg",
  "u10-rear-rack" => "buggy/u10-pro/18-cargo-bed-rack-assembly.jpg",
  "u10-overbed-rack" => "buggy/u10-pro/18-cargo-bed-rack-assembly.jpg",
  "u10-pro-roof-liner" => "buggy/u10-pro/48-roof-liner-assembly.jpg",
  "u10-pro-heater" => "buggy/u10-pro/19-u10-pro-heater-system.jpg",
  "u10-pro-wiper" => "buggy/u10-pro/02-wiper-wash.jpg",
  "u10-pro-nerf" => "buggy/u10-pro/09-nerf-bars-assembly.jpg",
  "u10-pro-skid" => "buggy/u10-pro/04-hdpe-skid-plate-assembly.jpg",
  "u10-pro-power-doors" => "buggy/u10-pro/16-power-window-door-assembly.jpg",
  "u10-pro-half-doors" => "buggy/u10-pro/11-half-doors.jpg",
  "u10-xl-roof-liner" => "buggy/u10-xl-pro/03-roof-liner-assembly.jpg",
  "u10-xl-heater" => "buggy/u10-xl-pro/10-u10-xl-pro-heater-system.jpg",
  "u10-xl-wiper" => "buggy/u10-xl-pro/43-wiper-wash.jpg",
  "u10-xl-nerf" => "buggy/u10-xl-pro/37-nerf-bars-assembly.jpg",
  "u10-xl-skid" => "buggy/u10-xl-pro/26-hdpe-skid-plate-assembly.jpg",
  "u10-xl-power-doors" => "buggy/u10-xl-pro/44-power-window-door-assembly.jpg",
  "u10-xl-front-half-doors" => "buggy/u10-xl-pro/14-half-door-front.jpg",
  "u10-xl-rear-half-doors" => "buggy/u10-xl-pro/45-half-door-rear.jpg",
  "u1000-fixed-glass" => "buggy/uforce-1000-xl/32-front-windshield-assembly.jpg",
  "u1000-infotainment" => "buggy/uforce-1000-xl/31-u10-infotainment-display-with-stage-1.jpg",
  "u1000-front-half-doors" => "buggy/uforce-1000-xl/53-half-doors-assembly-front.jpg",
  "u1000-rear-half-doors" => "buggy/uforce-1000-xl/52-half-doors-assembly-rear.jpg",
  "u1000-tipout" => "buggy/uforce-1000-xl/28-front-tip-out-windshield-assembly-glass.jpg",
  "u1000-full-poly" => "buggy/uforce-1000-xl/32-front-windshield-assembly.jpg",
  "u1000-tipout-wiper" => "buggy/uforce-1000-xl/22-40w-wiper-and-washer-system-wind-shield-apron.jpg",
  "u1000-fixed-wiper" => "buggy/uforce-1000-xl/03-wiper-assy.jpg",
  "u1000-glass-rear" => "buggy/uforce-1000-xl/11-rear-windshield-assembly.jpg",
  "u1000-poly-rear" => "buggy/uforce-1000-xl/11-rear-windshield-assembly.jpg",
  "u1000-front-bumper" => "buggy/uforce-1000-xl/57-front-bumper-assy.jpg",
  "u1000-rear-bumper" => "buggy/uforce-1000-xl/47-rear-bumper-assy.jpg",
  "u1000-nerf" => "buggy/uforce-1000-xl/40-nerf-bars-assembly-u10xl.jpg",
  "u1000-rear-rack" => "buggy/uforce-1000-xl/41-cargo-bed-rack-assembly.jpg",
  "u1000-large-cargo" => "buggy/uforce-1000-xl/42-rear-cargo-box-assembly.jpg",
  "u1000-stage1-audio" => "buggy/uforce-1000-xl/12-u10-audio-stage1-radio-and-2-sp.jpg",
  "u600-full-poly" => "buggy/uforce-600/48-front-windshield-assembly.jpg",
  "u600-tipout" => "buggy/uforce-600/24-front-tip-out-windshield-glass.jpg",
  "u600-roof-liner" => "buggy/uforce-600/31-roof-liner-assembly.jpg",
  "u600-glass-rear" => "buggy/uforce-600/21-rear-windshield-assembly.jpg",
  "u600-poly-rear" => "buggy/uforce-600/21-rear-windshield-assembly.jpg",
  "u600-full-door-left" => "buggy/uforce-600/49-lh-side-door-assembly.jpg",
  "u600-full-door-right" => "buggy/uforce-600/51-rh-side-door-assembly.jpg",
  "u600-fixed-glass" => "buggy/uforce-600/48-front-windshield-assembly.jpg",
  "u600-rear-bumper" => "buggy/uforce-600/28-rear-bumper-assy.jpg",
  "u600-nerf" => "buggy/uforce-600/45-nerf-bar-assy.jpg",
  "u600-front-bumper" => "buggy/uforce-600/15-front-bumper-assy.jpg",
  "u600-rear-rack" => "buggy/uforce-600/50-cargo-bed-rack.jpg",
  "u600-large-cargo" => "buggy/uforce-600/47-rear-cargo-box-assembly.jpg",
  "u600-half-doors" => "buggy/uforce-600/03-half-doors-assembly.jpg",
  "u600-audio" => "buggy/uforce-600/52-u6-audio-system.jpg",
  "u600-heated-driver" => "buggy/uforce-600/58-driver-heating-seat-assembly.jpg",
  "u600-heated-passenger" => "buggy/uforce-600/30-passenger-heating-seat-assembly.jpg",
  "u600-mirrors" => "buggy/uforce-600/38-side-mirrors-assembly.jpg"
}.freeze

def public_filename(catalog_key)
  "#{catalog_key}.jpg"
end

if $PROGRAM_NAME == __FILE__
  target_roots = [File.join(ROOT, "accessories", PUBLIC_DIRECTORY)]
  source_available = Dir.exist?(SOURCE_ROOT)
  expected_filenames = IMAGE_SOURCES.keys.map { |catalog_key| public_filename(catalog_key) }
  target_roots.each do |target_root|
    FileUtils.mkdir_p(target_root)
    Dir.glob(File.join(target_root, "*.jpg")).each do |path|
      FileUtils.rm_f(path) unless expected_filenames.include?(File.basename(path))
    end
  end

  IMAGE_SOURCES.each do |catalog_key, relative_source|
    source = File.join(SOURCE_ROOT, relative_source)
    filename = public_filename(catalog_key)
    if source_available
      abort "Missing DMS source image: #{relative_source}" unless File.file?(source)
      target_roots.each { |target_root| FileUtils.cp(source, File.join(target_root, filename)) }
    else
      target_roots.each do |target_root|
        target = File.join(target_root, filename)
        abort "Missing committed DMS image: #{target.delete_prefix("#{ROOT}/")}" unless File.file?(target)
      end
    end
  end

  abort "Configurator bundle not found: #{BUNDLE}" unless File.file?(BUNDLE)
  bundle = File.read(BUNDLE, encoding: "UTF-8")

  IMAGE_SOURCES.each_key do |catalog_key|
    abort "Catalog key not found: #{catalog_key}" unless bundle.include?(%Q{["#{catalog_key}",})
  end

  image_urls = IMAGE_SOURCES.to_h do |catalog_key, _relative_source|
    [catalog_key, "/accessories/#{PUBLIC_DIRECTORY}/#{public_filename(catalog_key)}"]
  end
  bundle.sub!(/,(?:E|#{IMAGE_MAP_VARIABLE})=\{[^}]*\},G=/, ",G=")
  image_map_anchor = /L=(\{[^}]+\}),G=/
  abort "Off-road image-map anchor not found" unless bundle.match?(image_map_anchor)
  bundle.sub!(image_map_anchor, "L=\\1,#{IMAGE_MAP_VARIABLE}=#{JSON.generate(image_urls)},G=")

  factory_source = "image:L[o.category],imageIsPlaceholder:!0"
  factory_target = "image:#{IMAGE_MAP_VARIABLE}[r]??L[o.category],imageIsPlaceholder:!#{IMAGE_MAP_VARIABLE}[r]"
  bundle.gsub!("image:E[r]??L[o.category],imageIsPlaceholder:!E[r]", factory_target)
  unless bundle.include?(factory_target)
    abort "Off-road image factory not found" unless bundle.include?(factory_source)
    bundle.sub!(factory_source, factory_target)
  end

  File.write(BUNDLE, bundle, encoding: "UTF-8")
  puts "Applied #{IMAGE_SOURCES.size} matched CFMOTO DMS photos to the ATV and Buggy accessory catalog"
end
