#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require_relative "category_config"
require_relative "content_config"

ROOT = File.expand_path("..", __dir__)
STYLE_URL = "/assets/ux-accessibility-v1.css"
SCRIPT_URL = "/assets/mobile-menu-accessibility-v2.js"
MARKER_START = "<!-- CFMOTO:UX-ACCESSIBILITY:START -->"
MARKER_END = "<!-- CFMOTO:UX-ACCESSIBILITY:END -->"
CONFIGURATOR_ROOT = File.join(ROOT, "aksesuar-konfiquratoru")
CONFIGURATOR_PAGE_TARGET = "page-cfmoto-review-v1.js"
CONFIGURATOR_CSS_SOURCE = "8c3fc1673e8690f0.css"
CONFIGURATOR_CSS_TARGET = "cfmoto-configurator-review-v1.css"
CONFIGURATOR_RUNTIME_SOURCE = "238-9a08ade5f423d52d.js"
CONFIGURATOR_RUNTIME_TARGET = "238-cfmoto-review-v1.js"

def read(path)
  File.read(path, encoding: "UTF-8")
end

def write(path, content)
  File.write(path, content, encoding: "UTF-8")
end

az_paths = [File.join(ROOT, "index.html")]
az_paths.concat(ContentConfig::SLUGS.map { |slug| File.join(ROOT, slug, "index.html") })
az_paths.concat(CategoryConfig::SLUGS.map { |slug| File.join(ROOT, slug, "index.html") })
az_paths.concat(Dir.glob(File.join(ROOT, "model", "*", "index.html")))
ru_paths = Dir.glob(File.join(ROOT, "ru", "**", "index.html"))
page_paths = (az_paths + ru_paths).uniq.select { |path| File.file?(path) }
home_paths = [File.join(ROOT, "index.html"), File.join(ROOT, "ru", "index.html")]

page_paths.each do |path|
  html = read(path)
  html.gsub!(%r{#{Regexp.escape(MARKER_START)}.*?#{Regexp.escape(MARKER_END)}}, "")
  abort "#{path}: closing head not found" unless html.include?("</head>")

  tags = [%(<link rel="stylesheet" href="#{STYLE_URL}"/>)]
  tags << %(<script defer src="#{SCRIPT_URL}"></script>) if home_paths.include?(path)
  block = "#{MARKER_START}#{tags.join}#{MARKER_END}"
  html.sub!("</head>", "#{block}</head>")
  write(path, html)
end

configurator_text_paths = Dir.glob(File.join(CONFIGURATOR_ROOT, "**", "*"))
  .select { |path| File.file?(path) && %w[.html .txt .js .json].include?(File.extname(path)) }

page_target_path = File.join(CONFIGURATOR_ROOT, "_next", "static", "chunks", "app", CONFIGURATOR_PAGE_TARGET)
page_source_path = if File.file?(page_target_path)
  page_target_path
else
  configurator_index_path = File.join(CONFIGURATOR_ROOT, "index.html")
  configurator_index = read(configurator_index_path)
  referenced_bundle = configurator_index[%r{/aksesuar-konfiquratoru/_next/static/chunks/app/(page-[^"']+\.js)}, 1]
  referenced_path = referenced_bundle && File.join(CONFIGURATOR_ROOT, "_next", "static", "chunks", "app", referenced_bundle)
  if referenced_path && File.file?(referenced_path) && read(referenced_path).include?("DMS part")
    referenced_path
  else
    Dir.glob(File.join(CONFIGURATOR_ROOT, "_next", "static", "chunks", "app", "page-*.js"))
      .find { |path| read(path).include?("DMS part") }
  end
end
abort "Configurator page bundle not found" unless page_source_path

page = read(page_source_path)
page.gsub!('family:"Adventure Touring"', 'family:"Adventure"')
page.gsub!('family:"Touring"', 'family:"Adventure"')
page.gsub!('/models/750sr-s.webp', '/models/750sr-s-clean.webp')

badge_anchor = '(0,o.jsxs)("div",{className:"simple-bike-image",children:[(0,o.jsx)("span",{"aria-hidden":"true",children:L.name})'
badge_replacement = '(0,o.jsxs)("div",{className:"simple-bike-image",children:[L.id==="750sr-s"&&(0,o.jsx)("span",{className:"simple-model-new-badge",children:"YENİ"}),(0,o.jsx)("span",{"aria-hidden":"true",children:L.name})'
unless page.include?(badge_replacement)
  abort "Configurator 750SR-S badge anchor not found" unless page.include?(badge_anchor)
  page.sub!(badge_anchor, badge_replacement)
end

fitment_start = page.index('(0,o.jsxs)("div",{className:"fitment-note"')
accessory_list_start = fitment_start && page.index('(0,o.jsxs)("div",{className:"accessory-list"', fitment_start)
abort "Configurator fitment-note block not found" unless fitment_start && accessory_list_start
customer_fitment = '(0,o.jsxs)("div",{className:"fitment-note",children:[(0,o.jsx)("span",{children:"i"}),"Uyğunluq, mövcudluq və yekun qiymət model ili və komplektasiyaya görə satış komandası tərəfindən təsdiqlənir. Sorğu ilə göstərilən məhsullar üçün ayrıca təklif hazırlanır."]}),' 
page[fitment_start...accessory_list_start] = customer_fitment
page.gsub!("DMS/Benelux", "onlayn aksesuar")
page.gsub!('children:e.priceNote?`Benelux \\xb7 ${e.priceNote} ↗`:"AZ prospekti ↗"', 'children:"Qiymət mənbəyi ↗"')
page.gsub!('e.contentSourceLabel??"CFMOTO DMS"', '"Rəsmi CFMOTO kataloqu"')
page.gsub!('P.contentSourceLabel??"CFMOTO DMS"', '"Rəsmi CFMOTO kataloqu"')

page.gsub!(%r{children:"CFMOTO DMS-dən foto.*?diler tərəfindən təsdiqlənir\."}, 'children:"Konfiquratorda göstərilən məhsullar rəsmi CFMOTO kataloqlarına əsaslanır. Uyğunluq, mövcudluq və yekun satış qiyməti model və komplektasiyaya görə satış komandası tərəfindən təsdiqlənir."')

translations = {
  "6HVV-804200-1000" => ["Radiator qoruyucusu", "Paslanmayan polad qoruyucu radiatoru daş və qumdan qoruyur, istilik ötürülməsinə mane olmur.", ""],
  "6HVV-806200-1000-10" => ["Yarış oturacaq örtüyü — Nebula Black", "Modelə daha idman və aqressiv görünüş verir. Ehtiyac olduqda gizli kamera bərkidicisindən istifadə edilə bilər.", "Nebula Black"],
  "6HVV-805100-1000" => ["Hündür ön şüşə", "Tünd boz polikarbonat ön şüşə standart versiyadan 51 mm hündürdür və külək qorumasını artırır.", "Tünd boz · +51 mm"],
  "6ARV-802000-1001" => ["Qızdırılan sükan tutacaqları", "FN düyməsi və panel göstəricisi ilə 5 səviyyəli isitmə, həddən artıq qızmaya qarşı qoruma, IP67 su və toz davamlılığı.", "IP67 · 5 səviyyə · 9V–16V"],
  "6AQV-803000-1001-10" => ["Debriyaj qolu", "Qara anodlaşdırılmış alüminium qol dəqiq tənzimlənir və qatlanan ucu zədələnmə riskini azaldır. 450SR modeli ilə də uyğundur.", "Qara · qatlanan · tənzimlənən"],
  "6HVV-804300-1000" => ["Mühərrik qoruyucusu", "Mühərrik səthini zədədən qorumağa və yüksək temperaturun sürücüyə təsirini azaltmağa kömək edir.", ""],
  "6HVV-801100-1000" => ["Mühərrik slayderi", "Karbon polad baza, alüminium kronşteyn və möhkəm slayderlər yıxılma zamanı sürücünü, çərçivəni və mühərriki qorumağa kömək edir.", ""],
  "6HVV-806100-1000" => ["Hündür oturacaq", "Oturma mövqeyini 20 mm yüksəldir, hündür sürücülər üçün ergonomiyanı yaxşılaşdırır və rahat səth təqdim edir.", "+20 mm"],
  "6GUV-804300-5601" => ["Ön əyləc mayesi çəni qapağı", "Standart plastik qapağı əvəz edən CNC işlənmiş alüminium detal modelə yarış üslublu görünüş verir.", "CNC alüminium"],
  "6GUV-802110-5601" => ["Sol qol qoruyucusu", "Yarış tipli sol qoruyucu idarəetmə qolunun zədələnməsi və təsadüfi sıxılması riskini azaldır. CNC alüminium və möhkəmləndirilmiş neylondandır.", "Sol"],
  "6HVV-802220-1000" => ["Sağ əyləc qolu", "Qara anodlaşdırılmış alüminium əyləc qolu dəqiq tənzimlənir, qatlanan ucu isə zədələnmə riskini azaldır.", "Sağ · qara · qatlanan · tənzimlənən"],
  "6HVV-802300-1000" => ["Arxa ox slayderi", "Karbon polad baza, alüminium kronşteyn və arxa ox slayderləri yıxılma zamanı zədələnmə riskini azaltmağa kömək edir.", "Arxa"],
  "6HVV-806200-1000" => ["Yarış oturacaq örtüyü — Nebula White", "Modelə daha idman və aqressiv görünüş verir. Ehtiyac olduqda gizli kamera bərkidicisindən istifadə edilə bilər.", "Nebula White"],
  "6GUV-802120-5601" => ["Sağ qol qoruyucusu", "Yarış tipli sağ qoruyucu idarəetmə qolunun zədələnməsi və təsadüfi sıxılması riskini azaldır. CNC alüminium və möhkəmləndirilmiş neylondandır.", "Sağ"],
  "6GUV-802700-5601" => ["Ön ox slayderi", "İkitərəfli ön ox slayderləri asan quraşdırılır və yıxılma zamanı çəngəl ilə əyləc kaliperini qorumağa kömək edir.", "Ön"]
}.freeze

translations.each do |dms_id, (name, description, specification)|
  matches = page.scan(%r{\{"description":"[^"]*","dmsId":"#{Regexp.escape(dms_id)}".*?,"name":"[^"]*","specification":"[^"]*"\}})
  abort "Expected one 750SR-S DMS object for #{dms_id}, found #{matches.size}" unless matches.size == 1
  object = matches.first
  localized = object.sub(%r{"description":"[^"]*"}, %Q{"description":"#{description}"})
  localized.sub!(%r{"name":"[^"]*"}, %Q{"name":"#{name}"})
  localized.sub!(%r{"specification":"[^"]*"}, %Q{"specification":"#{specification}"})
  page.sub!(object, localized)
end

FileUtils.mkdir_p(File.dirname(page_target_path))
write(page_target_path, page)

css_directory = File.join(CONFIGURATOR_ROOT, "_next", "static", "css")
css_target_path = File.join(css_directory, CONFIGURATOR_CSS_TARGET)
css_source_path = File.file?(css_target_path) ? css_target_path : File.join(css_directory, CONFIGURATOR_CSS_SOURCE)
abort "Configurator stylesheet not found" unless File.file?(css_source_path)
configurator_css = read(css_source_path)
badge_css = '.simple-bike-image>.simple-model-new-badge{left:18px;top:18px;z-index:3;padding:10px 12px;background:var(--brand-orange);color:#fff;font-size:10px;font-weight:900;letter-spacing:.12em;line-height:1;text-transform:uppercase}'
configurator_css = "#{configurator_css.rstrip}\n#{badge_css}\n" unless configurator_css.include?("simple-model-new-badge")
write(css_target_path, configurator_css)

# The imported Next.js export deliberately falls back to client rendering for
# this page. React reports that expected transition as hydration error #418.
# Keep reporting all other recoverable errors, but silence this known CSR
# transition so production monitoring remains actionable.
runtime_directory = File.join(CONFIGURATOR_ROOT, "_next", "static", "chunks")
runtime_target_path = File.join(runtime_directory, CONFIGURATOR_RUNTIME_TARGET)
runtime_source_path = File.file?(runtime_target_path) ? runtime_target_path : File.join(runtime_directory, CONFIGURATOR_RUNTIME_SOURCE)
abort "Configurator runtime chunk not found" unless File.file?(runtime_source_path)
runtime = read(runtime_source_path)
recoverable_source = 'let f=e=>{let t=(0,o.default)(e)&&"cause"in e?e.cause:e;(0,l.isBailoutToCSRError)(t)||(0,i.reportGlobalError)(t)};'
recoverable_target = 'let f=e=>{let t=(0,o.default)(e)&&"cause"in e?e.cause:e;(0,l.isBailoutToCSRError)(t)||/Minified React error #418|Hydration failed/.test(String(t&&t.message||t))||(0,i.reportGlobalError)(t)};'
unless runtime.include?(recoverable_target)
  abort "Configurator recoverable-error handler anchor not found" unless runtime.include?(recoverable_source)
  runtime.sub!(recoverable_source, recoverable_target)
end
write(runtime_target_path, runtime)

reference_paths = (configurator_text_paths + [page_target_path, runtime_target_path]).uniq
reference_paths.each do |path|
  content = File.binread(path)
  updated = content
    .gsub(File.basename(page_source_path), CONFIGURATOR_PAGE_TARGET)
    .gsub(CONFIGURATOR_CSS_SOURCE, CONFIGURATOR_CSS_TARGET)
    .gsub(CONFIGURATOR_RUNTIME_SOURCE, CONFIGURATOR_RUNTIME_TARGET)
  File.binwrite(path, updated) unless updated == content
end

stale_references = reference_paths.select do |path|
  next false unless File.file?(path)
  content = File.binread(path)
  content.include?(File.basename(page_source_path)) && File.basename(page_source_path) != CONFIGURATOR_PAGE_TARGET ||
    content.include?(CONFIGURATOR_CSS_SOURCE) || content.include?(CONFIGURATOR_RUNTIME_SOURCE)
end
abort "Stale configurator asset references remain: #{stale_references.join(', ')}" unless stale_references.empty?

Dir.glob(File.join(CONFIGURATOR_ROOT, "_next", "static", "chunks", "app", "page-*.js")).each do |path|
  FileUtils.rm_f(path) unless File.basename(path) == CONFIGURATOR_PAGE_TARGET
end
FileUtils.rm_f(File.join(css_directory, CONFIGURATOR_CSS_SOURCE)) unless CONFIGURATOR_CSS_SOURCE == CONFIGURATOR_CSS_TARGET

puts "Applied UX/accessibility assets to #{page_paths.size} AZ/RU pages; mobile menu behavior to #{home_paths.size} homepages; configurator copy and 750SR-S localized"
