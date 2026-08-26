#!/usr/bin/env ruby
# frozen_string_literal: true

require "cgi"
require "json"
require_relative "category_config"
require_relative "content_config"
require_relative "domain_config"
require_relative "russian_config"

module RussianSiteAudit
  ROOT = File.expand_path("..", __dir__)
  SITE_ORIGIN = DomainConfig::SITE_ORIGIN
  LANGUAGE_START = "<!-- CFMOTO:LANGUAGE:START -->"
  LANGUAGE_END = "<!-- CFMOTO:LANGUAGE:END -->"
  META_PIXEL_ID = DomainConfig::META_PIXEL_ID
META_PIXEL_HEAD_START = "<!-- CFMOTO:META-PIXEL:HEAD:START -->"
META_PIXEL_HEAD_END = "<!-- CFMOTO:META-PIXEL:HEAD:END -->"
META_PIXEL_BODY_START = "<!-- CFMOTO:META-PIXEL:BODY:START -->"
META_PIXEL_BODY_END = "<!-- CFMOTO:META-PIXEL:BODY:END -->"
GTM_HEAD_START = "<!-- CFMOTO:GTM:HEAD:START -->"
GTM_HEAD_END = "<!-- CFMOTO:GTM:HEAD:END -->"
GTM_BODY_START = "<!-- CFMOTO:GTM:BODY:START -->"
GTM_BODY_END = "<!-- CFMOTO:GTM:BODY:END -->"
GOOGLE_TAG_MANAGER_ID = DomainConfig::GOOGLE_TAG_MANAGER_ID
  META_PIXEL_NOSCRIPT = "https://www.facebook.com/tr?id=#{META_PIXEL_ID}&ev=PageView&noscript=1"
  AZERBAIJANI_SPECIAL_LETTERS = /[ƏəĞğİıÖöÜüÇçŞş]/
  AZERBAIJANI_ASCII_FRAGMENTS = [
    "Naviqasiya yolu",
    "aktual motosiklet",
    "aktual kvadrosikl",
    "Kvadrosikl &amp; Buggy",
    "Diaqnostika",
    "Texniki qulluq",
    "Orijinal",
    "Aksesuarlar",
    "2 il / 24.000 km",
    "47 aktual model",
    "<label>Model<select>",
    "<th>Model</th>",
    "children:[`Model`,",
    "PRODUCTS",
    "<!-- --> model",
    "Touring<!-- --> ·",
    "segment:`Touring`",
    "Sport · Нейкед · Эндуро · Classic",
    ">Off-road<",
    "Mufta",
    "Displey",
    "Portlar",
    "Amortizator",
    "Bucurqad",
    "Kamera",
    "CVTech avtomatik",
    "2WD / 4WD / kilid",
    "Elektrik starter",
    "rejimli EPS",
    "Simsiz CarPlay",
    "aksesuarla",
    "krank",
    "radial kaliper",
    "iki disk",
    "<strong>Elektron</strong>",
    "<strong>Mexaniki</strong>",
    "8 дюйм TFT",
    "7 дюйм TFT",
    "5 дюйм LCD",
    "12,3 дюйм MMI"
  ].freeze
  EXPECTED_MODEL_COUNT = 47
  EXPECTED_AZ_PAGE_COUNT = 56
  EXPECTED_RU_PAGE_COUNT = 56
  EXPECTED_SITEMAP_URL_COUNT = 112

  Entry = Struct.new(:kind, :slug, :az_path, :ru_path, :az_file, :ru_file, keyword_init: true)

  class Auditor
    def initialize
      @errors = []
      @entries = build_entries
    end

    def run
      audit_inventory
      audit_page_pairs
      audit_russian_assets
      audit_sitemap

      if @errors.empty?
        puts "Russian audit passed: 56 AZ + 56 RU pages, reciprocal hreflang, 13 locale assets and 112 sitemap URLs"
        return true
      end

      warn "Russian audit failed with #{@errors.size} error#{@errors.size == 1 ? "" : "s"}:"
      @errors.each { |error| warn "- #{error}" }
      false
    end

    private

    def build_entries
      entries = [
        Entry.new(
          kind: :home,
          slug: nil,
          az_path: "/",
          ru_path: "/ru/",
          az_file: File.join(ROOT, "index.html"),
          ru_file: File.join(ROOT, "ru", "index.html")
        )
      ]

      model_files = Dir.glob(File.join(ROOT, "model", "*", "index.html")).sort
      @errors << "Expected #{EXPECTED_MODEL_COUNT} Azerbaijani model pages, found #{model_files.size}" unless model_files.size == EXPECTED_MODEL_COUNT
      model_files.each do |az_file|
        slug = File.basename(File.dirname(az_file))
        entries << Entry.new(
          kind: :model,
          slug: slug,
          az_path: "/model/#{slug}/",
          ru_path: "/ru/model/#{slug}/",
          az_file: az_file,
          ru_file: File.join(ROOT, "ru", "model", slug, "index.html")
        )
      end

      ContentConfig::SLUGS.each do |az_slug|
        ru_slug = RussianConfig.ru_content_slug(az_slug)
        entries << Entry.new(
          kind: :content,
          slug: az_slug,
          az_path: "/#{az_slug}/",
          ru_path: "/ru/#{ru_slug}/",
          az_file: File.join(ROOT, az_slug, "index.html"),
          ru_file: File.join(ROOT, "ru", ru_slug, "index.html")
        )
      end

      CategoryConfig::SLUGS.each do |az_slug|
        ru_slug = RussianConfig.ru_category_slug(az_slug)
        entries << Entry.new(
          kind: :category,
          slug: az_slug,
          az_path: "/#{az_slug}/",
          ru_path: "/ru/#{ru_slug}/",
          az_file: File.join(ROOT, az_slug, "index.html"),
          ru_file: File.join(ROOT, "ru", ru_slug, "index.html")
        )
      end

      entries
    end

    def audit_inventory
      @errors << "Expected #{EXPECTED_AZ_PAGE_COUNT} Azerbaijani route entries, found #{@entries.size}" unless @entries.size == EXPECTED_AZ_PAGE_COUNT

      missing_az = @entries.reject { |entry| File.file?(entry.az_file) }
      missing_ru = @entries.reject { |entry| File.file?(entry.ru_file) }
      missing_az.each { |entry| @errors << "Missing Azerbaijani page #{relative(entry.az_file)} for #{entry.az_path}" }
      missing_ru.each { |entry| @errors << "Missing Russian counterpart #{relative(entry.ru_file)} for #{entry.ru_path}" }

      expected_ru_files = @entries.map(&:ru_file).sort
      actual_ru_files = Dir.glob(File.join(ROOT, "ru", "**", "index.html")).sort
      @errors << "Expected #{EXPECTED_RU_PAGE_COUNT} Russian pages, found #{actual_ru_files.size}" unless actual_ru_files.size == EXPECTED_RU_PAGE_COUNT

      unexpected_ru = actual_ru_files - expected_ru_files
      absent_ru = expected_ru_files - actual_ru_files
      unexpected_ru.each { |path| @errors << "Unexpected Russian page #{relative(path)}" }
      absent_ru.each { |path| @errors << "Expected Russian page is absent: #{relative(path)}" }

      @entries.reject { |entry| entry.kind == :home }.each do |entry|
        @errors << "Azerbaijani route must end with a slash: #{entry.az_path}" unless entry.az_path.end_with?("/")
        @errors << "Russian route must end with a slash: #{entry.ru_path}" unless entry.ru_path.end_with?("/")
      end
    end

    def audit_page_pairs
      @entries.each do |entry|
        next unless File.file?(entry.az_file) && File.file?(entry.ru_file)

        az_html = read(entry.az_file)
        ru_html = read(entry.ru_file)

        audit_page(
          entry,
          az_html,
          language: "az",
          own_path: entry.az_path,
          counterpart_path: entry.ru_path
        )
        audit_meta_pixel(entry.az_file, az_html)
        audit_page(
          entry,
          ru_html,
          language: "ru",
          own_path: entry.ru_path,
          counterpart_path: entry.az_path
        )
        audit_meta_pixel(entry.ru_file, ru_html)
        audit_react_asset_pair(entry, az_html, ru_html) if react_page?(entry)
        audit_react_metadata_parity(entry, ru_html) if react_page?(entry)
        audit_no_azerbaijani_letters(entry.ru_file, ru_html)
        audit_no_untranslated_units(entry.ru_file, ru_html)
        audit_no_corrupted_external_urls(entry.ru_file, ru_html)
        audit_russian_navigation(entry, ru_html)
      end
    end

    def audit_page(entry, html, language:, own_path:, counterpart_path:)
      file = language == "az" ? entry.az_file : entry.ru_file
      label = relative(file)
      own_url = absolute(own_path)
      az_url = absolute(entry.az_path)
      ru_url = absolute(entry.ru_path)

      html_languages = html.scan(/<html\b[^>]*\blang=(?:"([^"]+)"|'([^']+)')/i).map { |values| values.compact.first }
      @errors << "#{label}: expected one html lang=\"#{language}\", found #{html_languages.inspect}" unless html_languages == [language]

      canonicals = link_tags(html).each_with_object([]) do |tag, values|
        attrs = attributes(tag)
        values << attrs["href"] if attrs["rel"] == "canonical"
      end
      @errors << "#{label}: self-canonical must be exactly #{own_url}; found #{canonicals.inspect}" unless canonicals == [own_url]
      if own_path != "/"
        slashless_url = own_url.delete_suffix("/")
        slashless_pattern = %r!#{Regexp.escape(slashless_url)}(?=["\\#?<\s,}\]]|\z)!
        @errors << "#{label}: contains slashless self URL #{slashless_url}" if html.match?(slashless_pattern)
      end

      expected_hreflang = {
        "az" => az_url,
        "ru" => ru_url,
        "x-default" => az_url
      }
      alternate_pairs = link_tags(html).each_with_object([]) do |tag, pairs|
        attrs = attributes(tag)
        next unless attrs["rel"] == "alternate" && attrs["hreflang"]

        pairs << [attrs["hreflang"], attrs["href"]]
      end
      actual_hreflang = alternate_pairs.to_h
      exact_alternates = alternate_pairs.size == 3 && alternate_pairs.map(&:first).uniq.size == 3 && actual_hreflang == expected_hreflang
      @errors << "#{label}: hreflang set must be exactly #{expected_hreflang.inspect}; found #{alternate_pairs.inspect}" unless exact_alternates

      expected_locale = language == "ru" ? "ru_RU" : "az_AZ"
      expected_alternate_locale = language == "ru" ? "az_AZ" : "ru_RU"
      audit_meta_value(html, label, "property", "og:url", own_url)
      audit_meta_value(html, label, "property", "og:locale", expected_locale)
      audit_meta_value(html, label, "property", "og:locale:alternate", expected_alternate_locale)

      audit_language_switch(
        html,
        label,
        language: language,
        counterpart_path: counterpart_path
      )
      audit_schema(html, label, language: language, own_url: own_url)
    end

    def audit_meta_value(html, label, key, name, expected)
      values = meta_tags(html).each_with_object([]) do |tag, found|
        attrs = attributes(tag)
        found << attrs["content"] if attrs[key] == name
      end
      @errors << "#{label}: #{name} must be exactly #{expected}; found #{values.inspect}" unless values == [expected]
    end

    def audit_meta_pixel(path, html)
      label = relative(path)
      normalized = html.gsub("&amp;", "&")
      body_open = html.index(%r{<body\b[^>]*>}i)
      body_close = html.index("</body>")
      body_marker = html.index(META_PIXEL_BODY_START)
      gtm_body_marker = html.index(GTM_BODY_START)

      @errors << "#{label}: expected one GTM head marker pair" unless html.scan(GTM_HEAD_START).size == 1 && html.scan(GTM_HEAD_END).size == 1
      @errors << "#{label}: expected one GTM body marker pair" unless html.scan(GTM_BODY_START).size == 1 && html.scan(GTM_BODY_END).size == 1
      @errors << "#{label}: expected one GTM loader" unless html.scan("googletagmanager.com/gtm.js?id='+i+dl").size == 1 && html.scan("'#{GOOGLE_TAG_MANAGER_ID}'").size == 1
      @errors << "#{label}: expected one GTM noscript iframe" unless html.scan("googletagmanager.com/ns.html?id=#{GOOGLE_TAG_MANAGER_ID}").size == 1
      @errors << "#{label}: expected one Meta Pixel head marker pair" unless html.scan(META_PIXEL_HEAD_START).size == 1 && html.scan(META_PIXEL_HEAD_END).size == 1
      @errors << "#{label}: expected one Meta Pixel body marker pair" unless html.scan(META_PIXEL_BODY_START).size == 1 && html.scan(META_PIXEL_BODY_END).size == 1
      @errors << "#{label}: expected one Meta Pixel loader" unless html.scan("connect.facebook.net/en_US/fbevents.js").size == 1
      @errors << "#{label}: expected one Meta Pixel init" unless html.scan("fbq('init','#{META_PIXEL_ID}')").size == 1
      @errors << "#{label}: expected one Meta Pixel PageView" unless html.scan("fbq('track','PageView')").size == 1
      @errors << "#{label}: expected one Meta Pixel noscript image" unless normalized.scan(/#{Regexp.escape(META_PIXEL_NOSCRIPT)}/).size == 1
      @errors << "#{label}: GTM body marker must be inside <body>" unless body_open && body_close && gtm_body_marker && gtm_body_marker > body_open && gtm_body_marker < body_close
      @errors << "#{label}: Meta Pixel body marker must be inside <body>" unless body_open && body_close && body_marker && body_marker > body_open && body_marker < body_close
    end

    def audit_language_switch(html, label, language:, counterpart_path:)
      starts = html.scan(Regexp.new(Regexp.escape(LANGUAGE_START))).size
      ends = html.scan(Regexp.new(Regexp.escape(LANGUAGE_END))).size
      @errors << "#{label}: expected one language-switcher marker pair, found #{starts} starts and #{ends} ends" unless starts == 1 && ends == 1

      block = html[%r{#{Regexp.escape(LANGUAGE_START)}(.*?)#{Regexp.escape(LANGUAGE_END)}}m, 1]
      return unless block

      anchors = block.scan(/<a\b[^>]*>/i).map { |tag| attributes(tag) }
      expected_link_language = language == "ru" ? "az" : "ru"
      expected_anchor = anchors.select do |attrs|
        attrs["href"] == counterpart_path &&
          attrs["lang"] == expected_link_language &&
          attrs["hreflang"] == expected_link_language
      end
      @errors << "#{label}: language switch must link exactly to #{counterpart_path}" unless anchors.size == 1 && expected_anchor.size == 1

      active_language = language.upcase
      active_spans = block.scan(%r{<span\b[^>]*aria-current="page"[^>]*>(.*?)</span>}mi).flatten.map { |text| strip_tags(text).strip }
      @errors << "#{label}: language switch must mark #{active_language} as current" unless active_spans == [active_language]
      @errors << "#{label}: missing language.css" unless html.scan(%r{<link\b[^>]*href="/assets/language\.css"[^>]*>}i).size == 1
    end

    def audit_schema(html, label, language:, own_url:)
      schema_blocks = html.scan(%r{<script\b[^>]*type="application/ld\+json"[^>]*>(.*?)</script>}mi).flatten
      @errors << "#{label}: missing JSON-LD" if schema_blocks.empty?

      schema_blocks.each_with_index do |raw, index|
        begin
          schema = JSON.parse(raw)
        rescue JSON::ParserError => error
          @errors << "#{label}: JSON-LD block #{index + 1} is invalid (#{error.message})"
          next
        end

        next unless language == "ru"

        walk(schema) do |value|
          next unless value.is_a?(Hash)

          types = Array(value["@type"])
          if types.include?("WebPage")
            @errors << "#{label}: WebPage schema inLanguage must be ru" unless value["inLanguage"] == "ru"
            @errors << "#{label}: WebPage schema URL must match self-canonical #{own_url}" if value["url"] && value["url"] != own_url
          end
          if types.include?("BreadcrumbList")
            home_item = Array(value["itemListElement"]).find { |item| item.is_a?(Hash) && item["position"] == 1 }
            @errors << "#{label}: Russian breadcrumb home must point to #{SITE_ORIGIN}/ru/" unless home_item && home_item["item"] == "#{SITE_ORIGIN}/ru/"
          end
        end

        audit_schema_internal_urls(schema, label)
      end
    end

    def audit_schema_internal_urls(schema, label)
      walk(schema) do |value|
        next unless value.is_a?(String) && value.start_with?("#{SITE_ORIGIN}/")

        suffix = value.delete_prefix(SITE_ORIGIN)
        slashless_route = suffix.match?(%r{\A/(?:ru/)?model/[a-z0-9-]+\z}i) ||
          ContentConfig::SLUGS.any? { |slug| suffix == "/#{slug}" } ||
          RussianConfig::CONTENT_ROUTES.values.any? { |slug| suffix == "/ru/#{slug}" }
        @errors << "#{label}: JSON-LD route URL must end with a slash: #{value}" if slashless_route
        next if suffix == "/" || suffix.start_with?("/#organization", "/#website")
        next if suffix.start_with?("/ru/")
        next if static_public_path?(suffix)

        if unprefixed_az_route?(suffix)
          @errors << "#{label}: Russian JSON-LD contains Azerbaijani page URL #{value}"
        end
      end
    end

    def audit_react_asset_pair(entry, az_html, ru_html)
      label = relative(entry.ru_file)
      az_refs = versioned_asset_refs(az_html)
      ru_refs = versioned_asset_refs(ru_html)
      expected_ru_refs = az_refs.map do |path|
        source_version = RussianConfig::ASSET_SOURCE_VERSIONS.find { |version| path.include?(version) }
        source_version ? path.sub(source_version, RussianConfig::ASSET_RUSSIAN_VERSION) : path
      end

      @errors << "#{label}: React page does not reference versioned locale assets" if ru_refs.empty?
      @errors << "#{label}: Russian React asset references do not mirror the Azerbaijani page" unless ru_refs.sort == expected_ru_refs.sort
      if RussianConfig::ASSET_SOURCE_VERSIONS.any? { |version| ru_html.include?(version) }
        @errors << "#{label}: contains Azerbaijani React asset version"
      end
      @errors << "#{label}: embedded React root language must be ru" unless ru_html.include?('\\"lang\\":\\"ru\\"')
      @errors << "#{label}: embedded React root still declares Azerbaijani" if ru_html.include?('\\"lang\\":\\"az\\"')

      ru_refs.uniq.each do |public_path|
        disk_path = File.join(ROOT, public_path.delete_prefix("/"))
        @errors << "#{label}: referenced Russian asset is missing: #{public_path}" unless File.file?(disk_path)
      end
    end

    def audit_react_metadata_parity(entry, html)
      label = relative(entry.ru_file)
      title = html[%r{<title>(.*?)</title>}m, 1]
      description = html[%r{<meta name="description" content="([^"]*)"\s*/>}, 1]
      return unless title && description

      embedded_title = %Q{\\"children\\":\\"#{title}\\"}
      embedded_description = %Q{\\"content\\":\\"#{description}\\"}
      @errors << "#{label}: embedded React title differs from static title" unless html.include?(embedded_title)
      @errors << "#{label}: embedded React description differs from static description" unless html.include?(embedded_description)

      return unless entry.kind == :model

      instagram = %Q{\\"href\\":\\"#{DomainConfig::INSTAGRAM_URL}\\",\\"target\\":\\"_blank\\",\\"rel\\":\\"noreferrer\\",\\"children\\":\\"Instagram\\"}
      @errors << "#{label}: embedded React footer is missing Instagram" unless html.include?(instagram)
    end

    def audit_russian_assets
      source_assets = RussianConfig::ASSET_SOURCE_VERSIONS.flat_map do |version|
        Dir.glob(File.join(ROOT, "assets", "*#{version}*"))
      end.uniq
      russian_assets = Dir.glob(File.join(ROOT, "assets", "*#{RussianConfig::ASSET_RUSSIAN_VERSION}*"))
      expected_russian_assets = source_assets.map do |path|
        source_version = RussianConfig::ASSET_SOURCE_VERSIONS.find { |version| path.include?(version) }
        path.sub(source_version, RussianConfig::ASSET_RUSSIAN_VERSION)
      end

      @errors << "Expected 13 Russian locale assets, found #{russian_assets.size}" unless russian_assets.size == 13
      @errors << "Russian locale asset set does not mirror the 13 source assets" unless russian_assets.sort == expected_russian_assets.sort
      RussianConfig::LEGACY_RUSSIAN_ASSET_VERSIONS.each do |version|
        legacy = Dir.glob(File.join(ROOT, "assets", "*#{version}*"))
        @errors << "Obsolete Russian locale assets remain for #{version}" unless legacy.empty?
      end

      russian_javascript = russian_assets.select { |path| File.extname(path) == ".js" }
      russian_javascript.each do |path|
        javascript = read(path)
        audit_no_azerbaijani_letters(path, javascript)
        audit_no_untranslated_units(path, javascript)
        audit_no_corrupted_external_urls(path, javascript)
        audit_unprefixed_route_tokens(path, javascript)
        @errors << "#{relative(path)}: imports Azerbaijani locale assets" if RussianConfig::ASSET_SOURCE_VERSIONS.any? { |version| javascript.include?(version) }
      end

      menu_asset = russian_javascript.find { |path| File.basename(path).start_with?("ProductMegaMenu-") }
      finance_asset = russian_javascript.find { |path| File.basename(path).start_with?("ModelFinance-") }
      if menu_asset
        menu_javascript = read(menu_asset)
        @errors << "#{relative(menu_asset)}: client count label still uses model instead of моделей" if menu_javascript.include?("` model`")
        @errors << "#{relative(menu_asset)}: client count label must use Russian plural моделей" unless menu_javascript.include?("` моделей`")
        @errors << "#{relative(menu_asset)}: standalone Touring segment is not translated" if menu_javascript.include?("segment:`Touring`")
      end
      if finance_asset
        finance_javascript = read(finance_asset)
        @errors << "#{relative(finance_asset)}: client duration label still uses ay instead of мес." if finance_javascript.include?("` ay`")
        @errors << "#{relative(finance_asset)}: client slider label still contains Azerbaijani faizi" if finance_javascript.include?(" faizi")
      end

      home_asset = russian_javascript.find { |path| File.basename(path).start_with?("page-") }
      if home_asset
        home_javascript = read(home_asset)
        @errors << "#{relative(home_asset)}: home calculator label is not translated to Модель" unless home_javascript.include?("children:[`Модель`,")
      end
    end

    def audit_no_azerbaijani_letters(path, content)
      matches = content.scan(AZERBAIJANI_SPECIAL_LETTERS).uniq
      ascii_matches = AZERBAIJANI_ASCII_FRAGMENTS.select { |fragment| content.include?(fragment) }
      return if matches.empty? && ascii_matches.empty?

      details = []
      details << "special letters #{matches.join(" ")}" unless matches.empty?
      details << "phrases #{ascii_matches.join(", ")}" unless ascii_matches.empty?
      @errors << "#{relative(path)}: contains Azerbaijani #{details.join(" and ")}"
    end

    def audit_no_untranslated_units(path, content)
      units = content.scan(/\d+(?:[.,]\d+)? (?:cc|mm|kW|Nm|lb)\b/).uniq
      return if units.empty?

      @errors << "#{relative(path)}: contains untranslated technical unit(s): #{units.first(8).join(", ")}"
    end

    def audit_no_corrupted_external_urls(path, content)
      urls = content.scan(%r{https?://[^"'`\s<>]+/ru/model/[^"'`\s<>]*}i).uniq
      urls.reject! { |url| url.start_with?("#{SITE_ORIGIN}/ru/model/") }
      return if urls.empty?

      @errors << "#{relative(path)}: external URL was incorrectly localized: #{urls.first(3).join(", ")}"
    end

    def audit_russian_navigation(entry, html)
      scrubbed = html.dup
      scrubbed.gsub!(%r{#{Regexp.escape(LANGUAGE_START)}.*?#{Regexp.escape(LANGUAGE_END)}}m, "")
      scrubbed.gsub!(%r{<link\b[^>]*rel="alternate"[^>]*>}mi, "")
      scrubbed.gsub!(%r{<script\b[^>]*type="application/ld\+json"[^>]*>.*?</script>}mi, "")

      scrubbed.scan(%r{<a\b[^>]*\bhref=(?:"([^"]*)"|'([^']*)')[^>]*>}mi).each do |captures|
        href = captures.compact.first
        next unless az_navigation_target?(href)

        @errors << "#{relative(entry.ru_file)}: Russian navigation links to Azerbaijani target #{href}"
      end

      audit_unprefixed_route_tokens(entry.ru_file, scrubbed)

      embedded_href_values(scrubbed).uniq.each do |href|
        next unless az_navigation_target?(href)

        @errors << "#{relative(entry.ru_file)}: embedded Russian navigation links to Azerbaijani target #{href}"
      end
    end

    def audit_unprefixed_route_tokens(path, content)
      route_pattern = %r{
        (?<!/ru)
        (
          /model/[a-z0-9-]+
          |
          /(?:kredit|servis|zemanet|ehtiyat-hisseleri|model-muqayisesi|motosiklet|kvadrosikl|buggy)
        )
        (?=[/?#"'`\\<\s]|$)
      }ix
      matches = content.scan(route_pattern).flatten.uniq
      @errors << "#{relative(path)}: contains unprefixed Azerbaijani route token(s): #{matches.join(", ")}" unless matches.empty?
    end

    def embedded_href_values(content)
      values = []
      patterns = [
        %r{(?:\\?["']href\\?["']|\bhref)\s*:\s*(?:\\?["']|`)(/[^"'`\\\s<>]*)},
        %r{(?:\\?["']pathname\\?["']|\bpathname)\s*:\s*(?:\\?["']|`)(/[^"'`\\\s<>]*)}
      ]
      patterns.each { |pattern| values.concat(content.scan(pattern).flatten) }
      values
    end

    def az_navigation_target?(href)
      return false if href.nil? || href.empty? || href.start_with?("#")
      return false if href.start_with?("/ru/") || href == "/ru"
      return false if href.match?(%r{\A(?:https?:)?//}) && !href.start_with?(SITE_ORIGIN)
      return false if href.match?(%r{\A(?:tel|mailto|sms|whatsapp):}i)
      return false if static_public_path?(href)

      if href.start_with?(SITE_ORIGIN)
        suffix = href.delete_prefix(SITE_ORIGIN)
        return false if suffix.start_with?("/ru/") || suffix == "/ru"
        return suffix == "/" || suffix.start_with?("/#") || unprefixed_az_route?(suffix)
      end

      href == "/" || href.start_with?("/#") || unprefixed_az_route?(href) || href.start_with?("/")
    end

    def unprefixed_az_route?(path)
      path.match?(%r{\A/model/[a-z0-9-]+(?:[/#?]|\z)}i) ||
        path.match?(%r{\A/(?:kredit|servis|zemanet|ehtiyat-hisseleri|model-muqayisesi|motosiklet|kvadrosikl|buggy)(?:[/#?]|\z)}i)
    end

    def static_public_path?(path)
      local_path = path.start_with?(SITE_ORIGIN) ? path.delete_prefix(SITE_ORIGIN) : path
      local_path.start_with?("/assets/", "/models/", "/gallery/", "/atv/", "/motorcycle/", "/sxs/") ||
        local_path.match?(%r{\A/[^?#]+\.(?:avif|css|gif|ico|jpe?g|js|json|png|svg|webp|xml)(?:[?#].*)?\z}i)
    end

    def audit_sitemap
      path = File.join(ROOT, "sitemap.xml")
      unless File.file?(path)
        @errors << "Missing sitemap.xml"
        return
      end

      xml = read(path)
      @errors << "sitemap.xml: missing xhtml namespace" unless xml.include?('xmlns:xhtml="http://www.w3.org/1999/xhtml"')
      nodes = xml.scan(%r{<url>(.*?)</url>}m).flatten
      @errors << "Sitemap must contain #{EXPECTED_SITEMAP_URL_COUNT} URL nodes, found #{nodes.size}" unless nodes.size == EXPECTED_SITEMAP_URL_COUNT

      parsed = {}
      nodes.each_with_index do |node, index|
        locations = node.scan(%r{<loc>(.*?)</loc>}m).flatten.map { |url| CGI.unescapeHTML(url.strip) }
        if locations.size != 1
          @errors << "sitemap.xml URL node #{index + 1}: expected one loc, found #{locations.inspect}"
          next
        end

        location = locations.first
        @errors << "sitemap.xml: duplicate loc #{location}" if parsed.key?(location)
        alternate_pairs = node.scan(%r{<xhtml:link\b[^>]*>}i).each_with_object([]) do |tag, pairs|
          attrs = attributes(tag)
          next unless attrs["rel"] == "alternate"

          pairs << [attrs["hreflang"], attrs["href"]]
        end
        parsed[location] = alternate_pairs
      end

      expected_urls = @entries.flat_map { |entry| [absolute(entry.az_path), absolute(entry.ru_path)] }
      missing = expected_urls - parsed.keys
      unexpected = parsed.keys - expected_urls
      @errors << "sitemap.xml is missing URL(s): #{missing.join(", ")}" unless missing.empty?
      @errors << "sitemap.xml contains unexpected URL(s): #{unexpected.join(", ")}" unless unexpected.empty?

      @entries.each do |entry|
        az_url = absolute(entry.az_path)
        ru_url = absolute(entry.ru_path)
        expected = {
          "az" => az_url,
          "ru" => ru_url,
          "x-default" => az_url
        }

        [az_url, ru_url].each do |location|
          pairs = parsed[location]
          next unless pairs

          actual = pairs.to_h
          exact = pairs.size == 3 && pairs.map(&:first).uniq.size == 3 && actual == expected
          @errors << "sitemap.xml #{location}: reciprocal xhtml alternates must be #{expected.inspect}; found #{pairs.inspect}" unless exact
        end
      end
    end

    def link_tags(html)
      html.scan(/<link\b[^>]*>/i)
    end

    def meta_tags(html)
      html.scan(/<meta\b[^>]*>/i)
    end

    def attributes(tag)
      tag.scan(/([:\w-]+)\s*=\s*(?:"([^"]*)"|'([^']*)')/).each_with_object({}) do |captures, result|
        name, double_quoted, single_quoted = captures
        result[name.downcase] = CGI.unescapeHTML(double_quoted || single_quoted)
      end
    end

    def versioned_asset_refs(html)
      html.scan(%r{(?:href|src)="(/assets/[^"?#]*Cfmoto[^"?#]+\.(?:css|js))"}i).flatten
    end

    def walk(value, &block)
      yield value
      case value
      when Hash
        value.each_value { |nested| walk(nested, &block) }
      when Array
        value.each { |nested| walk(nested, &block) }
      end
    end

    def strip_tags(text)
      CGI.unescapeHTML(text.gsub(%r{<[^>]+>}, ""))
    end

    def read(path)
      File.read(path, encoding: "UTF-8")
    rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError => error
      @errors << "#{relative(path)}: invalid UTF-8 (#{error.message})"
      ""
    end

    def absolute(path)
      "#{SITE_ORIGIN}#{path}"
    end

    def relative(path)
      path.delete_prefix("#{ROOT}/")
    end

    def react_page?(entry)
      entry.kind == :home || entry.kind == :model
    end
  end

  module_function

  def run
    Auditor.new.run
  end
end

exit(RussianSiteAudit.run ? 0 : 1)
