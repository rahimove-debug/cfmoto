#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"

# Replace the legacy 250NK catalogue entry with the user-confirmed CFLITE 250NK
# offer. The public slug stays /model/250nk/ so existing links and indexing are
# preserved. The catalogue price is the lower Carb / no-ABS entry price; the
# detail page presents both Azerbaijan-market variants and their exact prices.

ROOT = File.expand_path(ARGV.fetch(0, ".."), __dir__)
MODEL_NAME = "CFLITE 250NK"
ENTRY_PRICE = 4_790
EFI_ABS_PRICE = 5_390
STYLE_URL = "/assets/cflite-250nk-v1.css"

AZ_SUMMARY = "CFLITE 250NK çevik şəhər idarəetməsi üçün hazırlanmış naked modelidir. Azərbaycanda iki versiya təqdim olunur: EFI + ABS və karburatorlu, ABS-siz versiya."
RU_SUMMARY = "CFLITE 250NK — манёвренный naked-байк для города. В Азербайджане модель представлена в двух версиях: EFI + ABS и карбюраторной версии без ABS."
RU_GENERATED_SUMMARY = "CFLITE 250NK çevik şəhər idarəetməsi üçün hazırlanmış naked modelidir. Азербайджанda iki versiya təqdim olunur: EFI + ABS və karburatorlu, ABS-siz versiya."

AZ_FINANCE = "Daxili hissəli ödəniş və bank krediti seçimləri ilə ilkin hesablamanı burada aparın. Fərdi və hüquqi şəxslər üçün dəqiq təklif satış mütəxəssisi tərəfindən hazırlanır. Hesablayıcı başlanğıc qiymət olan Carb / ABS-siz versiya (4,790 AZN) üzrə açılır; EFI + ABS versiyası 5,390 AZN-dir."
RU_FINANCE = "Рассчитайте предварительный платёж для внутренней рассрочки или банковского кредита. Точное предложение для физических и юридических лиц подготовит специалист по продажам. Калькулятор открывается с начальной ценой карбюраторной версии без ABS (4,790 AZN); версия EFI + ABS стоит 5,390 AZN."

def replace_model_name(text)
  text
    .gsub(/(?:CFLITE%20)+250NK/, "CFLITE%20250NK")
    .gsub("CFMOTO 250NK", MODEL_NAME)
    .gsub(/(?<!CFLITE )(?<!CFLITE%20)250NK/, MODEL_NAME)
end

def replace_entry_price(text)
  text.gsub("5,390", "4,790").gsub(/(?<!\d)5390(?!\d)/, ENTRY_PRICE.to_s)
end

def encode_whatsapp_spaces(text)
  text.gsub(%r{https://wa\.me/[^"'<>`]*}) { |url| url.gsub(" ", "%20") }
end

def catalogue_record(record)
  updated = replace_model_name(replace_entry_price(record))
  updated = updated.sub(/officialPage:`[^`]*`/, "officialPage:`https://www.cflite.com.mx/250-nk`")
  unless updated.include?("badge:")
    updated = updated.sub(/\}\z/, ',badge:`2 versiya`}')
  end
  updated
end

def configurator_record(record)
  replace_model_name(replace_entry_price(record))
end

def element(tag, props, key = nil)
  ["$", tag, key, props]
end

def variant_node(language)
  ru = language == :ru
  heading = ru ? "Доступные версии" : "Mövcud versiyalar"
  efi_copy = ru ? "Электронный впрыск · ABS" : "Elektron yanacaq püskürtməsi · ABS"
  carb_copy = ru ? "Карбюратор · без ABS" : "Karburator · ABS-siz"
  carb_badge = ru ? "Без ABS" : "ABS-siz"

  element("div", {
    "className" => "cflite-variants",
    "aria-label" => heading,
    "children" => [
      element("article", {
        "className" => "cflite-variant is-efi",
        "children" => [
          element("div", { "className" => "cflite-variant-head", "children" => [element("strong", { "children" => "EFI + ABS" }), element("span", { "children" => "ABS" })] }),
          element("p", { "children" => efi_copy }),
          element("strong", { "className" => "cflite-variant-price", "children" => "5,390 AZN" })
        ]
      }, "efi-abs"),
      element("article", {
        "className" => "cflite-variant is-carb",
        "children" => [
          element("div", { "className" => "cflite-variant-head", "children" => [element("strong", { "children" => "Carb" }), element("span", { "children" => carb_badge })] }),
          element("p", { "children" => carb_copy }),
          element("strong", { "className" => "cflite-variant-price", "children" => "4,790 AZN" })
        ]
      }, "carb-no-abs")
    ]
  })
end

def variant_html(language)
  if language == :ru
    '<div class="cflite-variants" aria-label="Доступные версии"><article class="cflite-variant is-efi"><div class="cflite-variant-head"><strong>EFI + ABS</strong><span>ABS</span></div><p>Электронный впрыск · ABS</p><strong class="cflite-variant-price">5,390 AZN</strong></article><article class="cflite-variant is-carb"><div class="cflite-variant-head"><strong>Carb</strong><span>Без ABS</span></div><p>Карбюратор · без ABS</p><strong class="cflite-variant-price">4,790 AZN</strong></article></div>'
  else
    '<div class="cflite-variants" aria-label="Mövcud versiyalar"><article class="cflite-variant is-efi"><div class="cflite-variant-head"><strong>EFI + ABS</strong><span>ABS</span></div><p>Elektron yanacaq püskürtməsi · ABS</p><strong class="cflite-variant-price">5,390 AZN</strong></article><article class="cflite-variant is-carb"><div class="cflite-variant-head"><strong>Carb</strong><span>ABS-siz</span></div><p>Karburator · ABS-siz</p><strong class="cflite-variant-price">4,790 AZN</strong></article></div>'
  end
end

def transform_detail_strings(value, language)
  summary = language == :ru ? RU_SUMMARY : AZ_SUMMARY
  finance = language == :ru ? RU_FINANCE : AZ_FINANCE
  mappings = if language == :ru
    {
      "250NK — управляй ритмом города." => "CFLITE 250NK — два варианта для города.",
      "Управляй ритмом города." => "Два варианта для города.",
      "Управляйте ритмом города." => "Два варианта для города.",
      "Şəhər üçün iki seçim." => "Два варианта для города.",
      "250NK — это манёвренный naked-байк для города с энергичным характером." => summary,
      "CFLITE 250NK — манёвренный нейкед для города с энергичным дорожным характером." => summary,
      AZ_SUMMARY => summary,
      AZ_FINANCE => finance,
      "Топливная система" => "Система питания",
      "Yanacaq sistemi" => "Система питания",
      "Режимы движения" => "Тормозная система",
      "Sürüş rejimləri" => "Тормозная система",
      "Sport / Eco" => "ABS (только в версии EFI + ABS)",
      "EFI" => "EFI или карбюратор (в зависимости от версии)",
      "EFI və ya karburator (versiyaya görə)" => "EFI или карбюратор (в зависимости от версии)",
      "ABS (yalnız EFI + ABS versiyasında)" => "ABS (только в версии EFI + ABS)",
      "151 кг" => "158 кг",
      "151 kq" => "158 кг",
      "37 мм USD / центральный моноамортизатор" => "37 мм телескопическая / центральный моноамортизатор",
      "37 mm USD / mərkəzi monoshock" => "37 мм телескопическая / центральный моноамортизатор",
      "37 мм teleskopik / mərkəzi monoshock" => "37 мм телескопическая / центральный моноамортизатор",
      "Athens Blue" => "Zephyr Blue",
      "Nebula Black" => "Ruby Red"
    }
  else
    {
      "Şəhərin ritmini idarə et." => "Şəhər üçün iki seçim.",
      "250NK çevik şəhər idarəetməsi və enerjili yol xarakteri üçün hazırlanmış naked modelidir." => summary,
      "Yanacaq sistemi" => "Yanacaq sistemi",
      "Sürüş rejimləri" => "Əyləc sistemi",
      "Sport / Eco" => "ABS (yalnız EFI + ABS versiyasında)",
      "EFI" => "EFI və ya karburator (versiyaya görə)",
      "151 kq" => "158 kq",
      "37 mm USD / mərkəzi monoshock" => "37 mm teleskopik / mərkəzi monoshock",
      "Athens Blue" => "Zephyr Blue",
      "Nebula Black" => "Ruby Red"
    }
  end

  case value
  when String
    updated = replace_model_name(replace_entry_price(value))
    updated = mappings.fetch(updated, updated)
    if language == :ru
      updated = updated.gsub(AZ_SUMMARY, summary).gsub(RU_GENERATED_SUMMARY, summary)
      updated = updated.gsub("EFI və ya karburator (versiyaya görə)", "EFI или карбюратор (в зависимости от версии)")
      updated = updated.gsub("Əyləc sistemi", "Тормозная система")
      updated = updated.gsub("ABS (yalnız EFI + ABS versiyasında)", "ABS (только в версии EFI + ABS)")
      updated = updated.gsub("37 мм teleskopik / mərkəzi monoshock", "37 мм телескопическая / центральный моноамортизатор")
    end
    if language == :ru && (updated.start_with?("CFLITE 250NK çevik şəhər") || updated.include?("Hesablayıcı başlanğıc"))
      updated = updated.include?("Hesablayıcı başlanğıc") ? finance : summary
    elsif updated.start_with?("Daxili hissəli ödəniş və bank krediti seçimləri")
      updated = finance
    elsif updated.start_with?("Рассчитайте предварительный платёж")
      updated = finance
    end
    encode_whatsapp_spaces(updated)
  when Array
    value.map! { |child| transform_detail_strings(child, language) }
    value
  when Hash
    value.transform_values! { |child| transform_detail_strings(child, language) }
    if value["name"] == "Zephyr Blue" && value.key?("image")
      value["value"] = "#39a8c7"
      value["image"] = "/models/250nk.webp"
    elsif value["name"] == "Ruby Red" && value.key?("image")
      value["value"] = "#a8242f"
      value["image"] = "/models/250nk-ruby-red.webp"
    end
    value
  else
    value == EFI_ABS_PRICE ? ENTRY_PRICE : value
  end
end

def insert_variant_node!(value, language)
  count = 0
  case value
  when Array
    if value[0] == "$" && value[1] == "div" && value.dig(3, "className") == "product-copy"
      children = value.dig(3, "children")
      if children.is_a?(Array)
        price_index = children.index { |child| child.is_a?(Array) && child.dig(3, "className").to_s.include?("product-price") }
        if price_index
          price = children[price_index]
          price[3]["className"] = "product-price cflite-price-range"
          price[3]["aria-label"] = language == :ru ? "Цена CFLITE 250NK: от 4,790 до 5,390 AZN" : "CFLITE 250NK qiyməti: 4,790–5,390 AZN"
          price[3]["children"] = [
            element("small", { "children" => language == :ru ? "Начальная цена" : "Başlanğıc nağd qiymət" }),
            element("strong", { "children" => language == :ru ? "от 4,790 AZN" : "4,790 AZN-dən" })
          ]
          existing = children.index { |child| child.is_a?(Array) && child.dig(3, "className") == "cflite-variants" }
          if existing
            children[existing] = variant_node(language)
          else
            children.insert(price_index + 1, variant_node(language))
          end
          count += 1
        end
      end
    else
      value.each { |child| count += insert_variant_node!(child, language) }
    end
  when Hash
    value.each_value { |child| count += insert_variant_node!(child, language) }
  end
  count
end

def transform_rsc!(html, language)
  variant_count = 0
  pattern = /(self\.__VINEXT_RSC_CHUNKS__\.push\()("(?:\\.|[^"\\])*")(\))/
  transformed = html.gsub(pattern) do
    before = Regexp.last_match(1)
    chunk = JSON.parse(Regexp.last_match(2))
    after = Regexp.last_match(3)
    lines = chunk.split("\n", -1).map do |line|
      match = line.match(/\A([0-9a-f]+:)([\[{].*)\z/)
      next line unless match
      begin
        node = JSON.parse(match[2])
      rescue JSON::ParserError
        next line
      end
      transform_detail_strings(node, language)
      variant_count += insert_variant_node!(node, language)
      "#{match[1]}#{JSON.generate(node)}"
    end
    "#{before}#{JSON.generate(lines.join("\n")).gsub("<", "\\u003c")}#{after}"
  end
  [transformed, variant_count]
end

def update_product_schema!(html, language)
  html.gsub(%r{<script type="application/ld\+json">(.*?)</script>}m) do |script|
    begin
      schema = JSON.parse(Regexp.last_match(1))
    rescue JSON::ParserError
      next script
    end
    next script unless schema["@type"] == "Product" && schema["url"].to_s.end_with?("/model/250nk/")

    schema["name"] = MODEL_NAME
    schema["model"] = MODEL_NAME
    schema["description"] = language == :ru ? RU_SUMMARY : AZ_SUMMARY
    schema["offers"]["price"] = ENTRY_PRICE if schema["offers"].is_a?(Hash)
    schema["additionalProperty"] = [
      { "@type" => "PropertyValue", "name" => "EFI + ABS", "value" => "5,390 AZN" },
      { "@type" => "PropertyValue", "name" => language == :ru ? "Carb / без ABS" : "Carb / ABS-siz", "value" => "4,790 AZN" }
    ]
    %(<script type="application/ld+json">#{JSON.generate(schema)}</script>)
  end
end

def transform_detail_page!(html, language)
  summary = language == :ru ? RU_SUMMARY : AZ_SUMMARY
  finance = language == :ru ? RU_FINANCE : AZ_FINANCE
  html = replace_model_name(replace_entry_price(html))
  html = html.gsub("Athens Blue", "Zephyr Blue").gsub("Nebula Black", "Ruby Red")
  html = html.gsub("#1f6797", "#39a8c7").gsub("#171717", "#a8242f")
  html = html.gsub("https://www.cfmoto.com/content/dam/cfmoto/site/global/product/motorcycle/nk---naked/250nk-/250NK_Nebula-Black.png", "/models/250nk-ruby-red.webp")

  if language == :ru
    html = html.gsub("Управляй ритмом города.", "Два варианта для города.")
    html = html.gsub("Управляйте ритмом города.", "Два варианта для города.")
    html = html.gsub("Şəhər üçün iki seçim.", "Два варианта для города.")
    html = html.gsub("CFLITE 250NK — это манёвренный naked-байк для города с энергичным характером.", summary)
    html = html.gsub("CFLITE 250NK — манёвренный нейкед для города с энергичным дорожным характером.", summary)
    html = html.gsub(AZ_SUMMARY, summary)
    html = html.gsub(RU_GENERATED_SUMMARY, summary)
    html = html.gsub(%r{<p class="product-summary">.*?</p>}, %(<p class="product-summary">#{summary}</p>))
    html = html.gsub("<span>Топливная система</span><strong>EFI</strong>", "<span>Система питания</span><strong>EFI или карбюратор (в зависимости от версии)</strong>")
    html = html.gsub("<span>Топливная система</span><strong>EFI və ya karburator (versiyaya görə)</strong>", "<span>Система питания</span><strong>EFI или карбюратор (в зависимости от версии)</strong>")
    html = html.gsub("<span>Режимы движения</span><strong>Sport / Eco</strong>", "<span>Тормозная система</span><strong>ABS (только в версии EFI + ABS)</strong>")
    html = html.gsub("<span>Əyləc sistemi</span><strong>ABS (yalnız EFI + ABS versiyasında)</strong>", "<span>Тормозная система</span><strong>ABS (только в версии EFI + ABS)</strong>")
    html = html.gsub(/<div class="product-price(?: cflite-price-range)?"[^>]*>.*?<\/div>(?:<div class="cflite-variants".*?<\/article><\/div>)?/m,
      '<div class="product-price cflite-price-range" aria-label="Цена CFLITE 250NK: от 4,790 до 5,390 AZN"><small>Начальная цена</small><strong>от 4,790 AZN</strong></div>' + variant_html(language))
  else
    html = html.gsub("Şəhərin ritmini idarə et.", "Şəhər üçün iki seçim.")
    html = html.gsub("CFLITE 250NK çevik şəhər idarəetməsi və enerjili yol xarakteri üçün hazırlanmış naked modelidir.", summary)
    html = html.gsub("<span>Yanacaq sistemi</span><strong>EFI</strong>", "<span>Yanacaq sistemi</span><strong>EFI və ya karburator (versiyaya görə)</strong>")
    html = html.gsub("<span>Sürüş rejimləri</span><strong>Sport / Eco</strong>", "<span>Əyləc sistemi</span><strong>ABS (yalnız EFI + ABS versiyasında)</strong>")
    html = html.gsub(/<div class="product-price(?: cflite-price-range)?"[^>]*>.*?<\/div>(?:<div class="cflite-variants".*?<\/article><\/div>)?/m,
      '<div class="product-price cflite-price-range" aria-label="CFLITE 250NK qiyməti: 4,790–5,390 AZN"><small>Başlanğıc nağd qiymət</small><strong>4,790 AZN-dən</strong></div>' + variant_html(language))
  end

  html = html.gsub(%r{<p>Daxili hissəli ödəniş və bank krediti seçimləri ilə ilkin hesablamanı burada aparın\..*?</p>}, "<p>#{AZ_FINANCE}</p>")
  html = html.gsub(%r{<p>Рассчитайте предварительный платёж для внутренней рассрочки или банковского кредита\..*?</p>}, "<p>#{RU_FINANCE}</p>")
  html = html.gsub(%r{<p>[^<]*(?:Hesablayıcı başlanğıc|Калькулятор открывается)[^<]*</p>}, "<p>#{finance}</p>")
  html = html.gsub("151 kq", "158 kq").gsub("151 кг", "158 кг")
  html = html.gsub("37 mm USD / mərkəzi monoshock", "37 mm teleskopik / mərkəzi monoshock")
  html = html.gsub("37 мм USD / центральный моноамортизатор", "37 мм телескопическая / центральный моноамортизатор")
  html = html.gsub("37 мм teleskopik / mərkəzi monoshock", "37 мм телескопическая / центральный моноамортизатор")
  html = encode_whatsapp_spaces(html)
  html = update_product_schema!(html, language)

  style_link = %(<link rel="stylesheet" href="#{STYLE_URL}"/>)
  html = html.sub("</head>", "#{style_link}</head>") unless html.include?(style_link)
  html, variant_count = transform_rsc!(html, language)
  abort "#{language}: CFLITE 250NK RSC hero was not updated" unless variant_count == 1
  html
end

public_files = Dir.glob(File.join(ROOT, "**", "*.{html,js,json,txt}"))
updated_files = 0

public_files.each do |path|
  next if path.include?("/scripts/")
  original = File.read(path, encoding: "UTF-8")
  content = replace_model_name(original)

  if path.end_with?(".js")
    content = content.gsub(/\{slug:`250nk`,[^{}]*\}/) { |record| catalogue_record(record) }
    content = content.gsub(/\{id:"250nk",[^{}]*\}/) { |record| configurator_record(record) }
  elsif path.end_with?(".html")
    # The numeric 5,390 catalogue price belongs only to the legacy 250NK entry
    # in this snapshot. Calculated finance values are regenerated in dist.
    content = replace_entry_price(content)
  end

  language = path.include?("/ru/model/250nk/index.html") ? :ru : :az
  if path.end_with?("/model/250nk/index.html")
    content = transform_detail_page!(content, language)
  end

  content = encode_whatsapp_spaces(content)

  next if content == original
  File.write(path, content, mode: "w", encoding: "UTF-8")
  updated_files += 1
end

detail_paths = {
  az: File.join(ROOT, "model", "250nk", "index.html"),
  ru: File.join(ROOT, "ru", "model", "250nk", "index.html")
}
detail_paths.each do |language, path|
  next unless File.file?(path)
  html = File.read(path, encoding: "UTF-8")
  abort "#{language}: legacy 250NK name remains" if html.match?(/(?<!CFLITE )(?<!CFLITE%20)250NK/)
  abort "#{language}: EFI + ABS price missing" unless html.include?("EFI + ABS") && html.include?("5,390 AZN")
  abort "#{language}: Carb / no-ABS price missing" unless html.include?("Carb") && html.include?("4,790 AZN")
  abort "#{language}: CFLITE stylesheet missing" unless html.include?(STYLE_URL)
end

puts "CFLITE 250NK applied: EFI + ABS 5,390 AZN; Carb / no ABS 4,790 AZN (#{updated_files} files updated)"
