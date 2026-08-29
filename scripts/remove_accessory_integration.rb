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
%w[V2 V1].each do |version|
  home.gsub!("/assets/page-CfmotoHomeNews#{version}.js", "/assets/page-CfmotoAccessoryV15.js")
  home.gsub!("/assets/index-CfmotoHomeNews#{version}.js", "/assets/index-CfmotoAccessoryV15.js")
  home.gsub!("/assets/layout-segment-context-CfmotoHomeNews#{version}.js", "/assets/layout-segment-context-CfmotoAccessoryV15.js")
  home.gsub!("/assets/link-CfmotoHomeNews#{version}.js", "/assets/link-CfmotoAccessoryV15.js")
  home.gsub!("/assets/router-CfmotoHomeNews#{version}.js", "/assets/router-CfmotoAccessoryV15.js")
  home.gsub!("/assets/ProductMegaMenu-CfmotoHomeNews#{version}.js", "/assets/ProductMegaMenu-CfmotoAccessoryV15.js")
end
home.gsub!(%(<link rel="stylesheet" href="/assets/home-news-v1.css"/>), "")
home.gsub!(%(<a href="/xeberler/">Xəbərlər</a>), "")
home.sub!(
  %r{<section class="home-news section".*?</section><section class="service section"}m,
  '<section class="service section"'
)
home.gsub!("/assets/page-CfmotoAccessoryV15.js", "/assets/page-CfmotoFinanceFixV12.js")
home.gsub!("/assets/page-CfmotoAccessoryV14.js", "/assets/page-CfmotoFinanceFixV11.js")
%w[V15 V14].each do |version|
  home.gsub!("/assets/index-CfmotoAccessory#{version}.js", "/assets/index-CfmotoPolicyFixV10.js")
  home.gsub!("/assets/layout-segment-context-CfmotoAccessory#{version}.js", "/assets/layout-segment-context-CfmotoPolicyFixV10.js")
  home.gsub!("/assets/link-CfmotoAccessory#{version}.js", "/assets/link-CfmotoPolicyFixV10.js")
  home.gsub!("/assets/ProductMegaMenu-CfmotoAccessory#{version}.js", "/assets/ProductMegaMenu-CfmotoPolicyFixV10.js")
end
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

bundle_name = %w[page-CfmotoFinanceFixV12.js page-CfmotoFinanceFixV11.js].find do |name|
  File.file?(File.join(ROOT, "assets", name))
end
abort "Finance home bundle not found while removing accessory integration" unless bundle_name
bundle_path = File.join(ROOT, "assets", bundle_name)
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
%w[CfmotoAccessoryV15 CfmotoAccessoryV14].each do |version|
  %w[page index layout-segment-context link router ProductMegaMenu].each do |asset|
    FileUtils.rm_f(File.join(ROOT, "assets", "#{asset}-#{version}.js"))
  end
end
%w[V2 V1].each do |version|
  %w[page index layout-segment-context link router ProductMegaMenu].each do |asset|
    FileUtils.rm_f(File.join(ROOT, "assets", "#{asset}-CfmotoHomeNews#{version}.js"))
  end
end

configurator_path = File.join(ROOT, "aksesuar-konfiquratoru", "index.html")
configurator = read(configurator_path)
configurator.gsub!(%r{<script defer src="/assets/accessory-model-preselect-v\d+\.js"></script>}, "")
write(configurator_path, configurator)

Dir.glob(File.join(ROOT, "model", "*", "index.html")).each do |path|
  slug = File.basename(File.dirname(path))
  configurator_urls = [
    "/aksesuar-konfiquratoru/?model=#{slug}#models",
    "/aksesuar-konfiquratoru/?model=#{slug}&bike=0&lock=1"
  ]
  html = read(path)
  %w[V15 V14].each do |version|
    html.gsub!("/assets/index-CfmotoAccessory#{version}.js", "/assets/index-CfmotoPolicyFixV10.js")
    html.gsub!("/assets/layout-segment-context-CfmotoAccessory#{version}.js", "/assets/layout-segment-context-CfmotoPolicyFixV10.js")
    html.gsub!("/assets/link-CfmotoAccessory#{version}.js", "/assets/link-CfmotoPolicyFixV10.js")
    html.gsub!("/assets/ProductMegaMenu-CfmotoAccessory#{version}.js", "/assets/ProductMegaMenu-CfmotoPolicyFixV10.js")
  end
  html.gsub!(%(<link rel="stylesheet" href="/assets/accessory-entry-v1.css"/>), "")
  configurator_urls.each do |configurator_url|
    html.gsub!(%r{<a class="button accessory-model-cta" href="#{Regexp.escape(configurator_url)}">.*?</a>}m, "")
    html.gsub!(
      %(<div class="model-mobile-cta"><a href="#{configurator_url}">Aksesuar seç</a>),
      '<div class="model-mobile-cta"><a href="#odenis">Aylıq ödəniş</a>'
    )
  end

  configurator_url = configurator_urls.last
  original_rsc = '[\\"$\\",\\"a\\",null,{\\"className\\":\\"button ghost\\",\\"href\\":\\"#odenis\\",\\"children\\":\\"Ödənişi hesabla\\"}]]}]]}'
  accessory_rsc_element = %r{,\[\\"\$\\",\\"a\\",null,\{\\"className\\":\\"button accessory-model-cta\\".*?\\"children\\":\\"↗︎\\"\}\]\]\}\]}m
  html.gsub!(accessory_rsc_element, "")
  malformed_rsc = %Q![\\"$\\",\\"a\\",null,{\\"className\\":\\"button ghost\\",\\"href\\":\\"#odenis\\",\\"children\\":\\"Ödənişi hesabla\\"},[\\"$\\",\\"a\\",null,{\\"className\\":\\"button accessory-model-cta\\",\\"href\\":\\"#{configurator_url}\\",\\"children\\":[\\"Aksesuar paketini qur \",[\\"$\\",\\"span\\",null,{\\"children\\":\\"↗︎\\"}]]}]]}]]}!
  valid_rsc = '[\\"$\\",\\"a\\",null,{\\"className\\":\\"button ghost\\",\\"href\\":\\"#odenis\\",\\"children\\":\\"Ödənişi hesabla\\"}],[\\"$\\",\\"a\\",null,{\\"className\\":\\"button accessory-model-cta\\",\\"href\\":\\"' + configurator_url + '\\",\\"children\\":[\\"Aksesuar paketini qur \\", [\\"$\\",\\"span\\",null,{\\"children\\":\\"↗︎\\"}]]}]]}]]}'
  html.gsub!(malformed_rsc, original_rsc)
  html.gsub!(valid_rsc, original_rsc)

  mobile_rsc_original = '\\"className\\":\\"model-mobile-cta\\",\\"children\\":[[\\"$\\",\\"a\\",null,{\\"href\\":\\"#odenis\\",\\"children\\":\\"Aylıq ödəniş\\"}]'
  configurator_urls.each do |url|
    mobile_rsc = %!\\"className\\":\\"model-mobile-cta\\",\\"children\\":[[\\"$\\",\\"a\\",null,{\\"href\\":\\"#{url}\\",\\"children\\":\\"Aksesuar seç\\"}]!
    html.gsub!(mobile_rsc, mobile_rsc_original)
  end
  write(path, html)
end

%w[kvadrosikl buggy].each do |category|
  path = File.join(ROOT, category, "index.html")
  next unless File.file?(path)

  html = read(path)
  html.gsub!(%r{<a class="button primary accessory-category-cta" href="[^"]+">.*?</a>}m, "")
  write(path, html)
end

puts "Removed generated accessory links before rebuild"
