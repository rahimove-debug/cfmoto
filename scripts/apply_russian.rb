#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "fileutils"
require "json"
require_relative "category_config"
require_relative "content_config"
require_relative "domain_config"
require_relative "russian_config"

ROOT = File.expand_path("..", __dir__)
RU_ROOT = File.join(ROOT, "ru")
ASSETS = File.join(ROOT, "assets")
SITE_ORIGIN = DomainConfig::SITE_ORIGIN
LANGUAGE_START = "<!-- CFMOTO:LANGUAGE:START -->"
LANGUAGE_END = "<!-- CFMOTO:LANGUAGE:END -->"
RSC_CANONICAL_LINK = %r{\[\\"\$\\",\\"link\\",\\"[^\\"]+\\",\{\\"rel\\":\\"canonical\\",\\"href\\":\\"[^\\"]+\\"\}\]}
RSC_LOCALIZED_ALTERNATE = %r{,\[\\"\$\\",\\"link\\",\\"cfmoto-hreflang-(?:az|ru|x-default)\\",\{\\"rel\\":\\"alternate\\",\\"hrefLang\\":\\"(?:az|ru|x-default)\\",\\"href\\":\\"[^\\"]+\\"\}\]}

RU_CONTENT_META = {
  "kredit" => {
    title: "Кредит и рассрочка CFMOTO | Азербайджан",
    description: "Условия кредита и рассрочки на мотоциклы, квадроциклы и багги CFMOTO: первоначальный взнос, сроки и предварительный расчёт.",
    heading: "Кредит и рассрочка CFMOTO"
  },
  "servis" => {
    title: "Официальный сервис CFMOTO в Баку | Обслуживание и ремонт",
    description: "Диагностика, техническое обслуживание и ремонт CFMOTO в Баку. Телефон сервиса: +994 10 241 42 99; ежедневно, кроме понедельника, 10:00–19:00.",
    heading: "Сервис, техническое обслуживание и ремонт CFMOTO"
  },
  "garantiya" => {
    title: "Условия гарантии CFMOTO | Азербайджан",
    description: "Информация о гарантии CFMOTO: для мотоциклов — 2 года или 24 000 км; условия для ATV и багги уточняются по модели и режиму эксплуатации.",
    heading: "Условия гарантии CFMOTO"
  },
  "zapchasti" => {
    title: "Запчасти и аксессуары CFMOTO | Баку",
    description: "Оригинальные запчасти, масла и аксессуары для моделей CFMOTO. Уточните совместимость по телефону +994 10 241 42 99.",
    heading: "Запчасти и аксессуары CFMOTO"
  },
  "sravnenie-modeley" => {
    title: "Сравнение моделей CFMOTO | Цены и категории",
    description: "Сравните 47 моделей CFMOTO по категории, объёму двигателя, цене, первоначальному взносу и максимальному сроку рассрочки.",
    heading: "Сравните модели CFMOTO"
  }
}.freeze

RU_CATEGORY_META = {
  "motocikly" => {
    title: "Продажа и цены на мотоциклы | CFMOTO Азербайджан",
    description: "Мотоциклы CFMOTO и актуальные цены в Азербайджане. Сравните нейкеды, спортивные, туристические модели, эндуро, круизеры и скутеры.",
    heading: "Мотоциклы CFMOTO: модели и цены"
  },
  "kvadrocikly" => {
    title: "Продажа и цены на квадроциклы (ATV) | CFMOTO Азербайджан",
    description: "Квадроциклы и ATV CFMOTO, характеристики и актуальные цены в Азербайджане. Утилитарные, туристические, премиальные и детские модели ATV.",
    heading: "Квадроциклы и ATV CFMOTO: модели и цены"
  },
  "buggy" => {
    title: "Модели багги и UTV | CFMOTO Азербайджан",
    description: "Багги, SSV и UTV CFMOTO и актуальные цены в Азербайджане. Сравните серии ZFORCE, UFORCE и U10.",
    heading: "Багги, SSV и UTV CFMOTO"
  }
}.freeze

def read_utf8(path)
  File.read(path, encoding: "UTF-8")
end

def write_utf8(path, content)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content, encoding: "UTF-8")
end

def entries
  result = [
    {
      kind: :home,
      source: File.join(ROOT, "index.html"),
      target: File.join(RU_ROOT, "index.html"),
      az_path: "/",
      ru_path: "/ru/"
    }
  ]

  Dir.glob(File.join(ROOT, "model", "*", "index.html")).sort.each do |source|
    slug = File.basename(File.dirname(source))
    result << {
      kind: :model,
      slug: slug,
      source: source,
      target: File.join(RU_ROOT, "model", slug, "index.html"),
      az_path: "/model/#{slug}/",
      ru_path: "/ru/model/#{slug}/"
    }
  end

  ContentConfig::SLUGS.each do |az_slug|
    ru_slug = RussianConfig.ru_content_slug(az_slug)
    result << {
      kind: :content,
      az_slug: az_slug,
      ru_slug: ru_slug,
      source: File.join(ROOT, az_slug, "index.html"),
      target: File.join(RU_ROOT, ru_slug, "index.html"),
      az_path: "/#{az_slug}/",
      ru_path: "/ru/#{ru_slug}/"
    }
  end


  CategoryConfig::SLUGS.each do |az_slug|
    ru_slug = RussianConfig.ru_category_slug(az_slug)
    result << {
      kind: :category,
      az_slug: az_slug,
      ru_slug: ru_slug,
      source: File.join(ROOT, az_slug, "index.html"),
      target: File.join(RU_ROOT, ru_slug, "index.html"),
      az_path: "/#{az_slug}/",
      ru_path: "/ru/#{ru_slug}/"
    }
  end

  result
end

def absolute_url(path)
  "#{SITE_ORIGIN}#{path}"
end

def remove_localization!(html)
  html.gsub!(%r{#{Regexp.escape(LANGUAGE_START)}.*?#{Regexp.escape(LANGUAGE_END)}\s*}m, "")
  html.gsub!(%r{<link rel="stylesheet" href="/assets/language(?:-v[23])?\.css"\s*/>}, "")
  html.gsub!(%r{<script\b[^>]*src="/assets/language-switcher-v(?:1|2|3)\.js"[^>]*></script>}, "")
  html.gsub!(%r{<link rel="alternate" hreflang="(?:az|ru|x-default)" href="[^"]+"\s*/>}, "")
  html.gsub!(%r{<meta property="og:locale:alternate" content="[^"]+"\s*/>}, "")
  html.gsub!(RSC_LOCALIZED_ALTERNATE, "")
end

def rsc_alternate_link(key, hreflang, href)
  %([\\"$\\",\\"link\\",\\"cfmoto-hreflang-#{key}\\",{\\"rel\\":\\"alternate\\",\\"hrefLang\\":\\"#{hreflang}\\",\\"href\\":\\"#{href}\\"}])
end

def inject_rsc_localization!(html, own_url:, az_url:, ru_url:)
  # Content/category pages are plain HTML. Vinext home/model pages, however,
  # reconcile <head> from this embedded RSC metadata during hydration.
  return unless html.include?("__VINEXT_RSC_")

  canonical_links = html.scan(RSC_CANONICAL_LINK)
  abort "Expected one embedded RSC canonical, found #{canonical_links.size}" unless canonical_links.size == 1

  current = canonical_links.first
  canonical = current.sub(%r{\\"href\\":\\"[^\\"]+\\"}, %(\\"href\\":\\"#{own_url}\\"))
  alternates = [
    rsc_alternate_link("az", "az", az_url),
    rsc_alternate_link("ru", "ru", ru_url),
    rsc_alternate_link("x-default", "x-default", az_url)
  ]
  html.sub!(current, ([canonical] + alternates).join(","))
end

def inject_localization!(html, language:, az_url:, ru_url:, counterpart_path:)
  remove_localization!(html)
  own_url = language == "ru" ? ru_url : az_url

  alternates = [
    %(<link rel="alternate" hreflang="az" href="#{az_url}"/>),
    %(<link rel="alternate" hreflang="ru" href="#{ru_url}"/>),
    %(<link rel="alternate" hreflang="x-default" href="#{az_url}"/>)
  ].join
  canonical = html[%r{<link rel="canonical" href="[^"]+"\s*/>}]
  abort "Missing canonical while adding language alternates" unless canonical
  html.sub!(canonical, "#{canonical}#{alternates}")

  locale = language == "ru" ? "ru_RU" : "az_AZ"
  alternate_locale = language == "ru" ? "az_AZ" : "ru_RU"
  html.gsub!(%r{<meta property="og:locale" content="[^"]+"\s*/>}, %(<meta property="og:locale" content="#{locale}"/><meta property="og:locale:alternate" content="#{alternate_locale}"/>))
  inject_rsc_localization!(html, own_url: own_url, az_url: az_url, ru_url: ru_url)
  runtime = <<~HTML.delete("\n")
    #{LANGUAGE_START}
    <script defer src="/assets/language-switcher-v4.js" data-language="#{language}" data-counterpart="#{CGI.escapeHTML(counterpart_path)}" data-canonical="#{CGI.escapeHTML(own_url)}" data-az="#{CGI.escapeHTML(az_url)}" data-ru="#{CGI.escapeHTML(ru_url)}" data-default="#{CGI.escapeHTML(az_url)}"></script>
    #{LANGUAGE_END}
  HTML
  html.sub!("</head>", %(<link rel="stylesheet" href="/assets/language-v3.css"/>#{runtime}</head>))
end

def set_tag!(html, pattern, replacement, label)
  abort "Missing #{label}" unless html.match?(pattern)
  html.sub!(pattern, replacement)
end

def set_russian_metadata!(html, entry, source_html)
  title, description = case entry[:kind]
  when :home
    [
      "CFMOTO Азербайджан | Мотоциклы, квадроциклы и багги",
      "Официальный представитель CFMOTO в Азербайджане. Мотоциклы, квадроциклы, багги, кредит, официальный сервис и запчасти."
    ]
  when :model
    model = source_html[%r{<h1 class="[^"]*\bproduct-title\b[^"]*">(.*?)</h1>}m, 1]
    abort "#{entry[:slug]}: missing product title" unless model
    [
      "#{model} | CFMOTO Азербайджан",
      "#{model}: официальная модель CFMOTO в Азербайджане. Характеристики, цена, условия оплаты, фотографии и консультация."
    ]
  when :content
    meta = RU_CONTENT_META.fetch(entry[:ru_slug])
    [meta.fetch(:title), meta.fetch(:description)]
  when :category
    meta = RU_CATEGORY_META.fetch(entry[:ru_slug])
    [meta.fetch(:title), meta.fetch(:description)]
  end

  canonical = absolute_url(entry[:ru_path])
  previous_title = html[%r{<title>(.*?)</title>}m, 1]
  previous_description = html[%r{<meta name="description" content="([^"]*)"\s*/>}, 1]
  abort "Missing translated title before Russian metadata normalization" unless previous_title
  abort "Missing translated description before Russian metadata normalization" unless previous_description
  html.gsub!(previous_title, title) unless previous_title == title
  html.gsub!(previous_description, description) unless previous_description == description
  set_tag!(html, %r{<title>.*?</title>}m, "<title>#{title}</title>", "title")
  set_tag!(html, %r{<meta name="description" content="[^"]*"\s*/>}, %(<meta name="description" content="#{description}"/>), "description")
  set_tag!(html, %r{<link rel="canonical" href="[^"]*"\s*/>}, %(<link rel="canonical" href="#{canonical}"/>), "canonical")
  set_tag!(html, %r{<meta property="og:title" content="[^"]*"\s*/>}, %(<meta property="og:title" content="#{title}"/>), "og:title")
  set_tag!(html, %r{<meta property="og:description" content="[^"]*"\s*/>}, %(<meta property="og:description" content="#{description}"/>), "og:description")
  set_tag!(html, %r{<meta property="og:url" content="[^"]*"\s*/>}, %(<meta property="og:url" content="#{canonical}"/>), "og:url")
  set_tag!(html, %r{<meta name="twitter:title" content="[^"]*"\s*/>}, %(<meta name="twitter:title" content="#{title}"/>), "twitter:title")
  set_tag!(html, %r{<meta name="twitter:description" content="[^"]*"\s*/>}, %(<meta name="twitter:description" content="#{description}"/>), "twitter:description")
  if entry[:kind] == :content
    html.sub!(%r{<h1>(.*?)</h1>}m, "<h1>#{RU_CONTENT_META.fetch(entry[:ru_slug]).fetch(:heading)}</h1>")
  elsif entry[:kind] == :category
    html.sub!(%r{<h1>(.*?)</h1>}m, "<h1>#{RU_CATEGORY_META.fetch(entry[:ru_slug]).fetch(:heading)}</h1>")
  end
end

def localize_internal_paths!(content)
  localized = content.dup
  RussianConfig::ASSET_SOURCE_VERSIONS.each do |version|
    localized.gsub!(version, RussianConfig::ASSET_RUSSIAN_VERSION)
  end
  localized.gsub!(%r{(?<=["'`])/model/}, "/ru/model/")
  localized.gsub!("#{SITE_ORIGIN}/model/", "#{SITE_ORIGIN}/ru/model/")
  localized.gsub!("route:/model/", "route:/ru/model/")
  localized.gsub!("page:/model/", "page:/ru/model/")
  RussianConfig::CONTENT_ROUTES.each do |az_slug, ru_slug|
    boundary = %r{(?=[/\\`"'#?]|\z)}
    localized.gsub!(%r{(?<=["'`])/#{Regexp.escape(az_slug)}#{boundary}}, "/ru/#{ru_slug}")
    localized.gsub!(%r{#{Regexp.escape(SITE_ORIGIN)}/#{Regexp.escape(az_slug)}#{boundary}}, "#{SITE_ORIGIN}/ru/#{ru_slug}")
  end
  RussianConfig::CATEGORY_ROUTES.each do |az_slug, ru_slug|
    boundary = %r{(?=[/\\`"'#?]|\z)}
    localized.gsub!(%r{(?<=["'`])/#{Regexp.escape(az_slug)}#{boundary}}, "/ru/#{ru_slug}")
    localized.gsub!(%r{#{Regexp.escape(SITE_ORIGIN)}/#{Regexp.escape(az_slug)}#{boundary}}, "#{SITE_ORIGIN}/ru/#{ru_slug}")
  end

  localized.gsub!('href="/#', 'href="/ru/#')
  localized.gsub!('href:`/#', 'href:`/ru/#')
  localized.gsub!('href:\"/#', 'href:\"/ru/#')
  localized.gsub!(%q{\"href\":\"/#}, %q{\"href\":\"/ru/#})
  localized.gsub!('href="/"', 'href="/ru/"')
  localized.gsub!('href:`/`', 'href:`/ru/`')
  localized.gsub!('href:\"/\"', 'href:\"/ru/\"')
  localized.gsub!(%q{\"href\":\"/\"}, %q{\"href\":\"/ru/\"})
  localized.gsub!('"pathname":"/"', '"pathname":"/ru/"')
  localized.gsub!('\\"pathname\\":\\"/\\"', '\\"pathname\\":\\"/ru/\\"')
  localized.gsub!('<!-- --> model', '<!-- --> моделей')
  localized.gsub!('<!-- --> ay', '<!-- --> мес.')
  localized.gsub!('children:`model`', 'children:`моделей`')
  localized.gsub!('children:`ay`', 'children:`мес.`')
  localized.gsub!(%r{(<strong>\d+(?:[.,]\d+)?) L(</strong>)}, '\\1 л\\2')
  localized.gsub!(%r{(\\"value\\":\\"\d+(?:[.,]\d+)?) L(\\")}, '\\1 л\\2')
  localized.gsub!(%r{(\\"children\\":\\"\d+(?:[.,]\d+)?) L(\\")}, '\\1 л\\2')
  localized.gsub!(%r{(\d+(?:[.,]\d+)?) cc\b}, '\\1 см³')
  localized.gsub!(%r{(\d+(?:[.,]\d+)?) mm\b}, '\\1 мм')
  localized.gsub!(%r{(\d+(?:[.,]\d+)?) kW\b}, '\\1 кВт')
  localized.gsub!(%r{(\d+(?:[.,]\d+)?) Nm\b}, '\\1 Н·м')
  localized.gsub!(%r{(\d+(?:[.,]\d+)?) lb\b}, '\\1 фунтов')
  localized
end

def normalize_schema!(html, language:, home:)
  html.gsub!(%r{<script type="application/ld\+json">(.*?)</script>}m) do
    raw = Regexp.last_match(1)
    begin
      schema = JSON.parse(raw)
    rescue JSON::ParserError
      next Regexp.last_match(0)
    end

    visit = lambda do |value|
      case value
      when Hash
        type = value["@type"]
        value["inLanguage"] = ["az", "ru"] if type == "WebSite"
        value["inLanguage"] = language if type == "WebPage"
        value["availableLanguage"] = ["az", "ru"] if value.key?("availableLanguage")
        if language == "ru" && Array(type).include?("BreadcrumbList")
          Array(value["itemListElement"]).each do |item|
            next unless item.is_a?(Hash) && item["position"] == 1 && item["item"] == "#{SITE_ORIGIN}/"

            item["item"] = "#{SITE_ORIGIN}/ru/"
          end
        end
        value.each_value { |nested| visit.call(nested) }
      when Array
        value.each { |nested| visit.call(nested) }
      end
    end
    visit.call(schema)
    %(<script type="application/ld+json">#{JSON.generate(schema)}</script>)
  end

  return unless home
  expected = language == "ru" ? '"inLanguage":["az","ru"]' : '"inLanguage":["az","ru"]'
  abort "Home schema is missing bilingual language data" unless html.include?(expected)
end

def translate_whatsapp_links!(content)
  generic = CGI.escape("Здравствуйте! Хочу получить информацию о CFMOTO.")
  content.gsub(%r{https://wa\.me/994512332484\?text=[^"`<\\]+}, "https://wa.me/994512332484?text=#{generic}")
end

def build_sitemap!(page_entries)
  url_nodes = page_entries.flat_map do |entry|
    az_url = absolute_url(entry[:az_path])
    ru_url = absolute_url(entry[:ru_path])
    alternates = [
      %(<xhtml:link rel="alternate" hreflang="az" href="#{az_url}"/>),
      %(<xhtml:link rel="alternate" hreflang="ru" href="#{ru_url}"/>),
      %(<xhtml:link rel="alternate" hreflang="x-default" href="#{az_url}"/>)
    ].join
    [
      "  <url><loc>#{az_url}</loc>#{alternates}</url>",
      "  <url><loc>#{ru_url}</loc>#{alternates}</url>"
    ]
  end

  sitemap = [
    %(<?xml version="1.0" encoding="UTF-8"?>),
    %(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">),
    *url_nodes,
    %(</urlset>),
    ""
  ].join("\n")
  write_utf8(File.join(ROOT, "sitemap.xml"), sitemap)
end

page_entries = entries
abort "Expected 56 Azerbaijani source pages, found #{page_entries.size}" unless page_entries.size == 56

FileUtils.rm_rf(RU_ROOT)
([RussianConfig::ASSET_RUSSIAN_VERSION] + RussianConfig::LEGACY_RUSSIAN_ASSET_VERSIONS).each do |version|
  Dir.glob(File.join(ASSETS, "*#{version}*")).each { |path| FileUtils.rm_f(path) }
end

source_assets = RussianConfig::ASSET_SOURCE_VERSIONS.flat_map do |version|
  Dir.glob(File.join(ASSETS, "*#{version}*"))
end.uniq
abort "Expected 13 versioned source assets, found #{source_assets.size}" unless source_assets.size == 13
source_assets.each do |source|
  source_version = RussianConfig::ASSET_SOURCE_VERSIONS.find { |version| source.include?(version) }
  abort "Unknown source asset version: #{source}" unless source_version
  target = source.sub(source_version, RussianConfig::ASSET_RUSSIAN_VERSION)
  content = read_utf8(source)
  content = RussianConfig.translate(content) if File.extname(source) == ".js"
  content = localize_internal_paths!(content)
  content.gsub!("az-AZ", "ru-RU") if File.extname(source) == ".js"
  content = translate_whatsapp_links!(content) if File.extname(source) == ".js"
  write_utf8(target, content)
end

page_entries.each do |entry|
  source_html = read_utf8(entry[:source])
  remove_localization!(source_html)
  normalize_schema!(source_html, language: "az", home: entry[:kind] == :home)
  inject_localization!(
    source_html,
    language: "az",
    az_url: absolute_url(entry[:az_path]),
    ru_url: absolute_url(entry[:ru_path]),
    counterpart_path: entry[:ru_path]
  )
  write_utf8(entry[:source], source_html)

  russian = RussianConfig.translate(source_html)
  russian = localize_internal_paths!(russian)
  russian.gsub!(%r{<html lang="az">}, '<html lang="ru">')
  russian.gsub!('\\"lang\\":\\"az\\"', '\\"lang\\":\\"ru\\"')
  russian.gsub!("az-AZ", "ru-RU")
  russian = translate_whatsapp_links!(russian)
  remove_localization!(russian)
  set_russian_metadata!(russian, entry, source_html)
  normalize_schema!(russian, language: "ru", home: entry[:kind] == :home)
  inject_localization!(
    russian,
    language: "ru",
    az_url: absolute_url(entry[:az_path]),
    ru_url: absolute_url(entry[:ru_path]),
    counterpart_path: entry[:az_path]
  )
  write_utf8(entry[:target], russian)
end

build_sitemap!(page_entries)

ru_pages = Dir.glob(File.join(RU_ROOT, "**", "index.html"))
abort "Expected 56 Russian pages, found #{ru_pages.size}" unless ru_pages.size == 56
puts "Russian site generated: #{ru_pages.size} pages, 13 locale assets and #{page_entries.size * 2} sitemap URLs"
