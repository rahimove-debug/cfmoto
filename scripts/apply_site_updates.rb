#!/usr/bin/env ruby
require "fileutils"

ROOT = File.expand_path("..", __dir__)
ASSETS = File.join(ROOT, "assets")

OLD_RUNTIME = "index-WBfaOMAt.js"
PREVIOUS_RUNTIME = "index-CfmotoAug24.js"
NEW_RUNTIME = "index-CfmotoAug24Fix.js"
OLD_HOME_BUNDLE = "page-DZgbTvch.js"
PREVIOUS_HOME_BUNDLE = "page-CfmotoAug24.js"
NEW_HOME_BUNDLE = "page-CfmotoAug24Fix.js"
OLD_MENU_BUNDLE = "ProductMegaMenu-Cpx-ytn3.js"
PREVIOUS_MENU_BUNDLE = "ProductMegaMenu-CfmotoAug24.js"
NEW_MENU_BUNDLE = "ProductMegaMenu-CfmotoAug24Fix.js"

SERVICE_BASE_COPY = "CFMOTO standartlarına uyğun diaqnostika, texniki qulluq və təmir."
SERVICE_HOURS_COPY = "Bazar ertəsi xaric hər gün 10:00–19:00."

SUPPORT_ASSET_SOURCES = {
  ["rolldown-runtime-S-ySWqyJ.js", "rolldown-runtime-CfmotoAug24.js"] => "rolldown-runtime-CfmotoAug24Fix.js",
  ["framework-CXnKph_e.js", "framework-CfmotoAug24.js"] => "framework-CfmotoAug24Fix.js",
  ["layout-segment-context-BqNUFdFf.js", "layout-segment-context-CfmotoAug24.js"] => "layout-segment-context-CfmotoAug24Fix.js",
  ["link-IATORi5E.js", "link-CfmotoAug24.js"] => "link-CfmotoAug24Fix.js",
  ["router-CzKeCzcA.js", "router-CfmotoAug24.js"] => "router-CfmotoAug24Fix.js",
  ["ModelFinance-QyWdpaDg.js", "ModelFinance-CfmotoAug24.js"] => "ModelFinance-CfmotoAug24Fix.js",
  ["ModelGallery-BT140N7z.js", "ModelGallery-CfmotoAug24.js"] => "ModelGallery-CfmotoAug24Fix.js",
  ["ModelSpecs-BJB4gaLM.js", "ModelSpecs-CfmotoAug24.js"] => "ModelSpecs-CfmotoAug24Fix.js",
  ["ModelColorSelector-DIxmErfw.js", "ModelColorSelector-CfmotoAug24.js"] => "ModelColorSelector-CfmotoAug24Fix.js"
}.freeze

PRIMARY_ASSET_SOURCES = {
  [OLD_RUNTIME, PREVIOUS_RUNTIME] => NEW_RUNTIME,
  [OLD_HOME_BUNDLE, PREVIOUS_HOME_BUNDLE] => NEW_HOME_BUNDLE,
  [OLD_MENU_BUNDLE, PREVIOUS_MENU_BUNDLE] => NEW_MENU_BUNDLE
}.freeze

ASSET_SOURCE_GROUPS = SUPPORT_ASSET_SOURCES.merge(PRIMARY_ASSET_SOURCES).freeze
ASSET_RENAMES = ASSET_SOURCE_GROUPS.each_with_object({}) do |(sources, target), renames|
  sources.each { |source| renames[source] = target }
end.freeze

def read_utf8(path)
  File.read(path, encoding: "UTF-8")
end

def write_utf8(path, content)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content, encoding: "UTF-8")
end

def update_asset(source_names, new_name)
  source_names = Array(source_names)
  new_path = File.join(ASSETS, new_name)
  source = (source_names + [new_name])
    .map { |name| File.join(ASSETS, name) }
    .find { |path| File.file?(path) }
  abort "Missing required asset: #{(source_names + [new_name]).join(', ')}" unless source

  content = read_utf8(source)
  yield content
  write_utf8(new_path, content)
  source_names.each do |name|
    path = File.join(ASSETS, name)
    FileUtils.rm_f(path) unless path == new_path
  end
end

def normalize_service_schedule!(content)
  base = Regexp.escape(SERVICE_BASE_COPY)
  hours = Regexp.escape(SERVICE_HOURS_COPY)
  content.gsub!(/#{base}(?: #{hours})*/, "#{SERVICE_BASE_COPY} #{SERVICE_HOURS_COPY}")
end

def build_c5_page
  template_path = File.join(ROOT, "model", "cforce-c4", "index.html")
  abort "Missing CFORCE C4 template" unless File.file?(template_path)

  html = read_utf8(template_path)
  html.gsub!("cforce-c4", "cforce-c5")
  html.gsub!("CFORCE%20C4", "CFORCE%20C5")
  html.gsub!("CFORCE C4", "CFORCE C5")
  html.gsub!("12,400", "13,900")
  html.gsub!("12400", "13900")
  html.gsub!("Nağd satış qiyməti", "Nağd satış qiyməti · ƏDV daxil")
  html.gsub!("Hər relyef üçün hazır.", "Gündəlik işdən həftəsonu macərasına.")
  html.gsub!(
    "CFORCE C5 iş, istirahət və çətin relyefdə etibarlı hərəkət üçün yaradılmış çoxməqsədli kvadrosikldir.",
    "CFORCE C5 yeni nəsil 500 cc sinifli ATV-dir; gündəlik iş, yedəkləmə və həftəsonu macəraları üçün hazırlanıb."
  )
  html.gsub!("408,8", "498,6")
  html.gsub!("33 a.g.", "39 a.g.")
  html.gsub!("34,5 Nm", "43,5 Nm")
  html.gsub!("Cypress Green", "Zephyr Blue")
  html.gsub!("Gedanite Grey", "Magma Red")
  html.gsub!("#596c57", "#87a8b2")
  html.gsub!("#777a78", "#e1251b")
  html.gsub!(
    "https://www.cfmoto.com/content/dam/cfmoto/site/global/product/atv/atv/c4/2026/model1.png",
    "/models/cforce-c5.webp"
  )
  html.gsub!(
    "https://www.cfmoto.com/content/dam/cfmoto/site/global/product/atv/atv/c4/2026/model2.png",
    "/models/cforce-c5-red.webp"
  )
  html.gsub!(
    "Yığcam ölçülər, ifadəli işıqlandırma və funksional kuzov C4-ü gündəlik istifadə üçün əlçatan edir.",
    "GEN⁴ kuzov, LED işıqlandırma və arxa hərəkət işığı C5-i işdə və çətin relyefdə daha funksional edir."
  )
  html.gsub!(
    "Yük platformaları və yedəkləmə yönümlü quruluş təsərrüfatla istirahəti bir texnikada birləşdirir.",
    "40/80 kq yük rəfləri, 612 kq yedəkləmə və 2500 lb bucurqad işi və istirahəti bir texnikada birləşdirir."
  )
  html.gsub!(
    %q({\"title\":\"Şassi\",\"specs\":[{\"label\":\"Ötürücü sistemi\",\"value\":\"2WD / 4WD / ön diferensial kilidi\"}]}),
    %q({\"title\":\"Şassi və yük\",\"specs\":[{\"label\":\"Ötürücü sistemi\",\"value\":\"2WD / 4WD / ön diferensial kilidi\"},{\"label\":\"Yedəkləmə qabiliyyəti\",\"value\":\"612 kq\"},{\"label\":\"Ön / arxa yük rəfi\",\"value\":\"40 / 80 kq\"},{\"label\":\"Bucurqad\",\"value\":\"2500 lb\"}]})
  )

  target = File.join(ROOT, "model", "cforce-c5", "index.html")
  write_utf8(target, html)
end

build_c5_page

update_asset([OLD_MENU_BUNDLE, PREVIOUS_MENU_BUNDLE], NEW_MENU_BUNDLE) do |javascript|
  unless javascript.include?('slug:`cforce-c5`')
    anchor = '{slug:`cforce-c4`,name:`CFORCE C4`,type:`Kvadrosikl`,segment:`Utility ATV`,engineClass:`400 cc`,price:12400,image:`/models/cforce-c4.webp`,officialPage:`https://cfmoto.az/cforce-c4`},'
    addition = '{slug:`cforce-c5`,name:`CFORCE C5`,type:`Kvadrosikl`,segment:`Utility ATV`,engineClass:`500 cc`,price:13900,image:`/models/cforce-c5.webp`,officialPage:`https://www.cfmoto.com/global/atv/atv/c5.html`,badge:`Yeni`,vatIncluded:!0},'
    abort "CFORCE C4 model anchor not found" unless javascript.include?(anchor)
    javascript.sub!(anchor, "#{anchor}#{addition}")
  end

  javascript.gsub!(
    'e.price===null?`Qiyməti dəqiqləşdirin`:`${l(e.price)} AZN`',
    'e.price===null?`Qiyməti dəqiqləşdirin`:`${l(e.price)} AZN${e.vatIncluded?` · ƏDV daxil`:``}`'
  )
  [OLD_RUNTIME, PREVIOUS_RUNTIME].each { |name| javascript.gsub!(name, NEW_RUNTIME) }
  [OLD_HOME_BUNDLE, PREVIOUS_HOME_BUNDLE].each { |name| javascript.gsub!(name, NEW_HOME_BUNDLE) }
  [OLD_MENU_BUNDLE, PREVIOUS_MENU_BUNDLE].each { |name| javascript.gsub!(name, NEW_MENU_BUNDLE) }
end

update_asset([OLD_HOME_BUNDLE, PREVIOUS_HOME_BUNDLE], NEW_HOME_BUNDLE) do |javascript|
  [OLD_MENU_BUNDLE, PREVIOUS_MENU_BUNDLE].each { |name| javascript.gsub!(name, NEW_MENU_BUNDLE) }
  javascript.gsub!(
    "Babək pr. 188 · Hər gün 10:00–19:00 · Bazar ertəsi bağlıdır",
    "Babək pr. 188 · Salon hər gün 10:00–19:00"
  )
  normalize_service_schedule!(javascript)
  javascript.gsub!('children:`Şəhərdaxili`', 'children:`Şəhərdaxili çatdırılma`')
  javascript.gsub!('children:`35 AZN`', 'children:`45 AZN`')
  javascript.gsub!(
    'children:[`10:00–19:00`,(0,c.jsx)(`br`,{}),`Bazar ertəsi bağlıdır`]',
    'children:[`Hər gün 10:00–19:00`,(0,c.jsx)(`br`,{}),`Salon hər gün açıqdır`]'
  )
  javascript.gsub!(
    'e.price===null?`Dəqiqləşdirin`:`${o(e.price)} AZN`',
    'e.price===null?`Dəqiqləşdirin`:`${o(e.price)} AZN${e.vatIncluded?` · ƏDV daxil`:``}`'
  )
end

update_asset([OLD_RUNTIME, PREVIOUS_RUNTIME], NEW_RUNTIME) do |javascript|
  [OLD_MENU_BUNDLE, PREVIOUS_MENU_BUNDLE].each { |name| javascript.gsub!(name, NEW_MENU_BUNDLE) }
  [OLD_HOME_BUNDLE, PREVIOUS_HOME_BUNDLE].each { |name| javascript.gsub!(name, NEW_HOME_BUNDLE) }
end

SUPPORT_ASSET_SOURCES.each do |source_names, new_name|
  update_asset(source_names, new_name) { |_javascript| }
end

Dir.glob(File.join(ASSETS, "*.js")).each do |path|
  javascript = read_utf8(path)
  ASSET_RENAMES.each { |old_name, new_name| javascript.gsub!(old_name, new_name) }
  write_utf8(path, javascript)
end

html_paths = [
  File.join(ROOT, "index.html"),
  *Dir.glob(File.join(ROOT, "model", "*", "index.html")).sort
]

html_paths.each do |path|
  html = read_utf8(path)
  ASSET_RENAMES.each { |old_name, new_name| html.gsub!(old_name, new_name) }
  html.gsub!(
    "Babək pr. 188 · Hər gün 10:00–19:00 · Bazar ertəsi bağlıdır",
    "Babək pr. 188 · Salon hər gün 10:00–19:00"
  )
  normalize_service_schedule!(html)
  html.gsub!(
    '<span>Kvadrosikl</span><small>8<!-- --> model</small>',
    '<span>Kvadrosikl</span><small>9<!-- --> model</small>'
  )
  write_utf8(path, html)
end

home_path = File.join(ROOT, "index.html")
home = read_utf8(home_path)
normalize_service_schedule!(home)
home.gsub!('<span>Şəhərdaxili</span><h3>35 AZN</h3>', '<span>Şəhərdaxili çatdırılma</span><h3>45 AZN</h3>')
home.gsub!(
  '<small>İş saatları</small><strong>10:00–19:00<br/>Bazar ertəsi bağlıdır</strong>',
  '<small>İş saatları</small><strong>Hər gün 10:00–19:00<br/>Salon hər gün açıqdır</strong>'
)

unless home.include?('href="/model/cforce-c5"')
  card_pattern = %r{<article class="model-card"><a href="/model/cforce-c4".*?</article>}m
  c4_card = home[card_pattern]
  abort "CFORCE C4 home card not found" unless c4_card
  c5_card = c4_card.dup
  c5_card.gsub!("cforce-c4", "cforce-c5")
  c5_card.gsub!("CFORCE C4", "CFORCE C5")
  c5_card.gsub!("12,400 AZN", "13,900 AZN · ƏDV daxil")
  c5_card.sub!('loading="lazy"/>', 'loading="lazy"/><span class="badge">Yeni</span>')
  home.sub!(c4_card, "#{c4_card}#{c5_card}")
end
home.gsub!("46 aktual model", "47 aktual model")
write_utf8(home_path, home)

u10_path = File.join(ROOT, "model", "u10-pro", "index.html")
u10 = read_utf8(u10_path)

required_images = %w[
  models/cforce-c5.webp
  models/cforce-c5-red.webp
  gallery/cforce-c5-1.webp
  gallery/cforce-c5-2.webp
  gallery/cforce-c5-3.webp
]
missing_images = required_images.reject { |relative| File.file?(File.join(ROOT, relative)) }
abort "Missing required product images: #{missing_images.join(', ')}" unless missing_images.empty?

c5 = read_utf8(File.join(ROOT, "model", "cforce-c5", "index.html"))
checks = {
  "home delivery price" => home.include?("45 AZN"),
  "home showroom hours" => home.include?("Salon hər gün açıqdır"),
  "home service hours" => home.include?("Bazar ertəsi xaric hər gün 10:00–19:00"),
  "home service hours appear once" => home.scan(SERVICE_HOURS_COPY).size == 1,
  "home C5 card" => home.include?('href="/model/cforce-c5"'),
  "C5 VAT price" => c5.include?("13,900 AZN"),
  "C5 blue color image" => c5.include?("/models/cforce-c5.webp"),
  "C5 red color image" => c5.include?("/models/cforce-c5-red.webp"),
  "C5 has no C4 color images" => !c5.include?("/atv/atv/c4/2026/model"),
  "U10 PRO name" => u10.include?('<h1 class="product-title">U10 PRO</h1>') && !u10.include?("U10 PRO HIGHLAND"),
  "U10 PRO model image" => u10.include?("/models/u10-pro.webp"),
  "U10 PRO gallery" => u10.include?("/gallery/u10-pro-1.webp"),
  "U10 PRO color images" => u10.include?("/sxs/utility/u10-pro/2026/model1.png"),
  "new runtime" => File.file?(File.join(ASSETS, NEW_RUNTIME)),
  "new home bundle" => File.file?(File.join(ASSETS, NEW_HOME_BUNDLE)),
  "new menu bundle" => File.file?(File.join(ASSETS, NEW_MENU_BUNDLE)),
  "all versioned assets" => ASSET_RENAMES.values.all? { |name| File.file?(File.join(ASSETS, name)) },
  "no stale asset references" => Dir.glob(File.join(ROOT, "{index.html,model/*/index.html,assets/*.js}"))
    .none? { |path| ASSET_RENAMES.keys.any? { |old_name| read_utf8(path).include?(old_name) } }
}
failures = checks.reject { |_label, passed| passed }.keys
abort "Site update checks failed: #{failures.join(', ')}" unless failures.empty?

puts "Site updates applied: CFORCE C5 colors, U10 PRO preserved, delivery price and operating hours"
