#!/usr/bin/env ruby
require "fileutils"

ROOT = File.expand_path("..", __dir__)

def read(path)
  File.read(path, encoding: "UTF-8")
end

def write(path, content)
  File.write(path, content, encoding: "UTF-8")
end

home_path = File.join(ROOT, "index.html")
home = read(home_path)
home.gsub!("/assets/index-CfmotoAccessoryV14.js", "/assets/index-CfmotoPolicyFixV10.js")
home.gsub!("/assets/page-CfmotoAccessoryV14.js", "/assets/page-CfmotoFinanceFixV11.js")
home.gsub!("/assets/layout-segment-context-CfmotoAccessoryV14.js", "/assets/layout-segment-context-CfmotoPolicyFixV10.js")
home.gsub!("/assets/link-CfmotoAccessoryV14.js", "/assets/link-CfmotoPolicyFixV10.js")
home.gsub!("/assets/ProductMegaMenu-CfmotoAccessoryV14.js", "/assets/ProductMegaMenu-CfmotoPolicyFixV10.js")
home.gsub!(%(<link rel="stylesheet" href="/assets/accessory-entry-v1.css"/>), "")
home.gsub!(%(<a href="/aksesuar-konfiquratoru/">Aksesuarlar</a>), "")
home.gsub!(%r{<a class="accessory-hero-link" href="/aksesuar-konfiquratoru/">.*?</a>}m, "")
home.gsub!(
  '<a class="button accessory-hero-button" href="/aksesuar-konfiquratoru/" tabindex="0">Aksesuar seç →</a>',
  '<a class="button ghost" href="#kredit-kalkulyator" tabindex="0">Kredit hesabla</a>'
)
home.sub!(
  %r{<section class="accessory-promo section".*?</section><section class="service section"}m,
  '<section class="service section"'
)
write(home_path, home)

bundle_path = File.join(ROOT, "assets", "page-CfmotoFinanceFixV11.js")
bundle = read(bundle_path)
bundle.gsub!('[`Aksesuarlar`,`/aksesuar-konfiquratoru/`],', "")
bundle.gsub!(
  '(0,c.jsx)(`a`,{href:`/aksesuar-konfiquratoru/`,children:`Aksesuarlar`}),',
  ""
)
home_hero_jsx = 'e.key===`moto`&&(0,c.jsxs)(`a`,{className:`accessory-hero-link`,href:`/aksesuar-konfiquratoru/`,children:[(0,c.jsx)(`span`,{children:`YENİ`}),(0,c.jsx)(`strong`,{children:`Motosikletinə aksesuar seç`}),(0,c.jsx)(`b`,{children:`Paketi qur →`})]})'
bundle.gsub!(",#{home_hero_jsx}", "")
bundle.gsub!(
  '(0,c.jsx)(`a`,{className:e.key===`moto`?`button accessory-hero-button`:`button ghost`,href:e.key===`moto`?`/aksesuar-konfiquratoru/`:`#kredit-kalkulyator`,tabIndex:t?0:-1,children:e.key===`moto`?`Aksesuar seç →`:`Kredit hesabla`})',
  '(0,c.jsx)(`a`,{className:`button ghost`,href:`#kredit-kalkulyator`,tabIndex:t?0:-1,children:`Kredit hesabla`})'
)
bundle.sub!(
  %r{\(0,c\.jsxs\)\(`section`,\{className:`accessory-promo section`.*?\}\),\(0,c\.jsxs\)\(`section`,\{className:`service section`}m,
  '(0,c.jsxs)(`section`,{className:`service section`'
)
write(bundle_path, bundle)
FileUtils.rm_f(File.join(ROOT, "assets", "page-CfmotoAccessoryV14.js"))
FileUtils.rm_f(File.join(ROOT, "assets", "index-CfmotoAccessoryV14.js"))
FileUtils.rm_f(File.join(ROOT, "assets", "layout-segment-context-CfmotoAccessoryV14.js"))
FileUtils.rm_f(File.join(ROOT, "assets", "link-CfmotoAccessoryV14.js"))
FileUtils.rm_f(File.join(ROOT, "assets", "router-CfmotoAccessoryV14.js"))
FileUtils.rm_f(File.join(ROOT, "assets", "ProductMegaMenu-CfmotoAccessoryV14.js"))

configurator_path = File.join(ROOT, "aksesuar-konfiquratoru", "index.html")
configurator = read(configurator_path)
configurator.gsub!(%(<script defer src="/assets/accessory-model-preselect-v1.js"></script>), "")
write(configurator_path, configurator)

Dir.glob(File.join(ROOT, "model", "*", "index.html")).each do |path|
  slug = File.basename(File.dirname(path))
  configurator_url = "/aksesuar-konfiquratoru/?model=#{slug}#models"
  html = read(path)
  html.gsub!(%(<link rel="stylesheet" href="/assets/accessory-entry-v1.css"/>), "")
  html.gsub!(%r{<a class="button accessory-model-cta" href="#{Regexp.escape(configurator_url)}">.*?</a>}m, "")
  html.gsub!(
    %(<div class="model-mobile-cta"><a href="#{configurator_url}">Aksesuar seç</a>),
    '<div class="model-mobile-cta"><a href="#odenis">Aylıq ödəniş</a>'
  )

  original_rsc = '[\\"$\\",\\"a\\",null,{\\"className\\":\\"button ghost\\",\\"href\\":\\"#odenis\\",\\"children\\":\\"Ödənişi hesabla\\"}]]}]]}'
  accessory_rsc_element = %r{,\[\\"\$\\",\\"a\\",null,\{\\"className\\":\\"button accessory-model-cta\\".*?\\"children\\":\\"↗︎\\"\}\]\]\}\]}m
  html.gsub!(accessory_rsc_element, "")
  malformed_rsc = %Q![\\"$\\",\\"a\\",null,{\\"className\\":\\"button ghost\\",\\"href\\":\\"#odenis\\",\\"children\\":\\"Ödənişi hesabla\\"},[\\"$\\",\\"a\\",null,{\\"className\\":\\"button accessory-model-cta\\",\\"href\\":\\"#{configurator_url}\\",\\"children\\":[\\"Aksesuar paketini qur \",[\\"$\\",\\"span\\",null,{\\"children\\":\\"↗︎\\"}]]}]]}]]}!
  valid_rsc = '[\\"$\\",\\"a\\",null,{\\"className\\":\\"button ghost\\",\\"href\\":\\"#odenis\\",\\"children\\":\\"Ödənişi hesabla\\"}],[\\"$\\",\\"a\\",null,{\\"className\\":\\"button accessory-model-cta\\",\\"href\\":\\"' + configurator_url + '\\",\\"children\\":[\\"Aksesuar paketini qur \\", [\\"$\\",\\"span\\",null,{\\"children\\":\\"↗︎\\"}]]}]]}]]}'
  html.gsub!(malformed_rsc, original_rsc)
  html.gsub!(valid_rsc, original_rsc)

  mobile_rsc = %!\\"className\\":\\"model-mobile-cta\\",\\"children\\":[[\\"$\\",\\"a\\",null,{\\"href\\":\\"#{configurator_url}\\",\\"children\\":\\"Aksesuar seç\\"}]!
  mobile_rsc_original = '\\"className\\":\\"model-mobile-cta\\",\\"children\\":[[\\"$\\",\\"a\\",null,{\\"href\\":\\"#odenis\\",\\"children\\":\\"Aylıq ödəniş\\"}]'
  html.gsub!(mobile_rsc, mobile_rsc_original)
  write(path, html)
end

puts "Removed generated accessory links before rebuild"
