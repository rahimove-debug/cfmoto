#!/usr/bin/env ruby
require "json"

# Apply the user-confirmed 675NK cash price before the normal generators run.
# Every replacement is bound to a 675NK record or rendered component; an
# unrelated product that happens to cost 12,800 AZN must remain untouched.

ROOT = File.expand_path("..", __dir__)

PUBLIC_TEXT_PATHS = (
  [File.join(ROOT, "index.html")] +
  Dir.glob(File.join(ROOT, "{model,ru,motosiklet,kvadrosikl,buggy,model-muqayisesi}", "**", "*.html")) +
  Dir.glob(File.join(ROOT, "assets", "*.js")) +
  Dir.glob(File.join(ROOT, "aksesuar-konfiquratoru", "**", "*.{html,js,json,txt}"))
).uniq.freeze

OLD_PRICE = /12,800|(?<!\d)12800(?!\d)/

def replace_price_tokens(value)
  case value
  when String
    value.gsub("12,800", "13,290").gsub(/(?<!\d)12800(?!\d)/, "13290")
  when Integer
    value == 12_800 ? 13_290 : value
  else
    value
  end
end

def replace_deep!(value)
  replacements = 0
  case value
  when Array
    value.map! do |child|
      if child.is_a?(String) || child.is_a?(Integer)
        changed = replace_price_tokens(child)
        replacements += 1 if changed != child
        changed
      else
        replacements += replace_deep!(child)
        child
      end
    end
  when Hash
    value.each do |key, child|
      if child.is_a?(String) || child.is_a?(Integer)
        changed = replace_price_tokens(child)
        replacements += 1 if changed != child
        value[key] = changed
      else
        replacements += replace_deep!(child)
      end
    end
  end
  replacements
end

def props_identify_675nk?(props)
  return false unless props.is_a?(Hash)

  props["slug"] == "675nk" ||
    props["id"] == "675nk" ||
    props["value"] == "675NK" ||
    props["model"] == "675NK" ||
    props["href"].to_s.match?(%r{/model/675nk/?\z})
end

def deep_contains_675nk_name?(value)
  case value
  when String
    value.include?("675NK")
  when Array
    value.any? { |child| deep_contains_675nk_name?(child) }
  when Hash
    value.each_value.any? { |child| deep_contains_675nk_name?(child) }
  else
    false
  end
end

def schema_props_identify_675nk?(props)
  schema = props.is_a?(Hash) ? props.dig("dangerouslySetInnerHTML", "__html") : nil
  schema.is_a?(String) && schema.include?('"name":"675NK"')
end

def transform_rsc_675nk!(html)
  replacements = 0
  pattern = /(self\.__VINEXT_RSC_CHUNKS__\.push\()("(?:\\.|[^"\\])*")(\))/

  transformed = html.gsub(pattern) do
    before = Regexp.last_match(1)
    encoded = Regexp.last_match(2)
    after = Regexp.last_match(3)
    chunk = JSON.parse(encoded)

    lines = chunk.split("\n", -1).map do |line|
      match = line.match(/\A([0-9a-f]+:)([\[{].*)\z/)
      next line unless match

      begin
        node = JSON.parse(match[2])
      rescue JSON::ParserError
        next line
      end

      visit = lambda do |value|
        case value
        when Array
          props = value[3].is_a?(Hash) ? value[3] : nil
          identifies_model = value[2].to_s.downcase == "675nk" ||
            props_identify_675nk?(props) ||
            schema_props_identify_675nk?(props) ||
            (props&.fetch("className", nil) == "product-hero" && deep_contains_675nk_name?(value))
          if identifies_model
            replacements += replace_deep!(value)
          else
            value.each { |child| visit.call(child) }
          end
        when Hash
          if props_identify_675nk?(value) ||
              schema_props_identify_675nk?(value) ||
              (value["name"] == "675NK" && (value.key?("price") || value.key?("basePriceAzn")))
            replacements += replace_deep!(value)
          else
            value.each_value { |child| visit.call(child) }
          end
        end
      end
      visit.call(node)
      "#{match[1]}#{JSON.generate(node)}"
    end

    encoded_chunk = JSON.generate(lines.join("\n")).gsub("<", "\\u003c")
    "#{before}#{encoded_chunk}#{after}"
  end

  [transformed, replacements]
end


def transform_675nk_detail!(html)
  replacements = 0

  html = html.gsub(%r{<script type="application/ld\+json">(.*?)</script>}m) do |script|
    source = Regexp.last_match(1)
    begin
      schema = JSON.parse(source)
    rescue JSON::ParserError
      next script
    end
    unless schema["@type"] == "Product" && schema["name"] == "675NK"
      next script
    end

    price = schema.dig("offers", "price")
    if price.to_s == "12800"
      schema["offers"]["price"] = price.is_a?(String) ? "13290" : 13_290
      replacements += 1
    end
    %(<script type="application/ld+json">#{JSON.generate(schema)}</script>)
  end

  html = html.gsub(%r{<div class="product-price"[^>]*>.*?</div>}m) do |fragment|
    changed = replace_price_tokens(fragment)
    replacements += fragment.scan(OLD_PRICE).size if changed != fragment
    changed
  end

  html = html.gsub(%r{<section class="model-finance\b.*?</section>}m) do |fragment|
    changed = replace_price_tokens(fragment)
    replacements += fragment.scan(OLD_PRICE).size if changed != fragment
    changed
  end

  [html, replacements]
end

def transform_rendered_675nk!(html)
  replacements = 0
  # Prices can sit inside the linked card itself, a surrounding product card,
  # a comparison row, or a calculator option. Each fragment must explicitly
  # identify 675NK before its price is changed.
  %w[article tr option a].each do |tag|
    html = html.gsub(%r{<#{tag}\b[^>]*>.*?</#{tag}>}m) do |fragment|
      identifies_model = fragment.include?('href="/model/675nk') ||
        fragment.include?('href="/ru/model/675nk') ||
        fragment.include?('value="675NK"')
      unless identifies_model
        next fragment
      end

      changed = replace_price_tokens(fragment)
      replacements += fragment.scan(OLD_PRICE).size if changed != fragment
      changed
    end
  end
  [html, replacements]
end

updated_files = 0
updated_prices = 0
PUBLIC_TEXT_PATHS.each do |path|
  next unless File.file?(path)

  original = File.read(path, encoding: "UTF-8")
  content = original.dup
  replacements = 0

  if path.end_with?(".html")
    content, rendered = transform_rendered_675nk!(content)
    detail = 0
    if path.match?(%r{/(?:ru/)?model/675nk/index\.html\z})
      content, detail = transform_675nk_detail!(content)
    end
    content, rsc = transform_rsc_675nk!(content)
    replacements += rendered + detail + rsc
  elsif path.include?("/assets/")
    content = content.gsub(/\{slug:`675nk`,[^{}]*\}/) do |record|
      changed = replace_price_tokens(record)
      replacements += record.scan(OLD_PRICE).size if changed != record
      changed
    end
  elsif path.include?("/aksesuar-konfiquratoru/")
    content = content.gsub(/\{id:"675nk",[^{}]*\}/) do |record|
      changed = replace_price_tokens(record)
      replacements += record.scan(OLD_PRICE).size if changed != record
      changed
    end
  end

  next if content == original

  File.write(path, content, mode: "w", encoding: "UTF-8")
  updated_files += 1
  updated_prices += replacements
end

model_page = File.read(File.join(ROOT, "model", "675nk", "index.html"), encoding: "UTF-8")
probe, rendered_remaining = transform_rendered_675nk!(model_page.dup)
probe, detail_remaining = transform_675nk_detail!(probe)
_probe, rsc_remaining = transform_rsc_675nk!(probe)
abort "675NK model page still contains a scoped old price" unless rendered_remaining + detail_remaining + rsc_remaining == 0
abort "675NK model page was not updated" unless model_page.include?("13,290") && model_page.include?("13290")

menu_bundles = Dir.glob(File.join(ROOT, "assets", "ProductMegaMenu-*.js"))
abort "675NK catalog price was not updated" unless menu_bundles.any? do |path|
  File.read(path, encoding: "UTF-8").include?('slug:`675nk`,name:`675NK`,type:`Motosiklet`,segment:`Naked`,engineClass:`675 cc`,price:13290')
end

configurator = Dir.glob(File.join(ROOT, "aksesuar-konfiquratoru", "_next", "static", "chunks", "app", "page-*.js"))
  .find { |path| File.read(path, encoding: "UTF-8").include?('id:"675nk",name:"675NK"') }
abort "675NK configurator catalog not found" unless configurator
abort "675NK configurator price was not updated" unless File.read(configurator, encoding: "UTF-8").include?('id:"675nk",name:"675NK",family:"Naked",years:"Cari model ili",basePriceAzn:13290')

U10_OLD_PRICE = /39,900|(?<!\d)39900(?!\d)/

def replace_u10_price_tokens(value)
  case value
  when String
    value.gsub("39,900", "45,900").gsub(/(?<!\d)39900(?!\d)/, "45900")
  when Integer
    value == 39_900 ? 45_900 : value
  else
    value
  end
end

def replace_u10_finance_tokens(value)
  replace_u10_price_tokens(value)
    .gsub("19,950", "22,950")
    .gsub("22,943", "26,392")
    .gsub("1,912", "2,199")
    .gsub("19%2C950", "22%2C950")
end

def replace_u10_deep!(value)
  replacements = 0
  case value
  when Array
    value.map! do |child|
      if child.is_a?(String) || child.is_a?(Integer)
        changed = replace_u10_price_tokens(child)
        replacements += 1 if changed != child
        changed
      else
        replacements += replace_u10_deep!(child)
        child
      end
    end
  when Hash
    value.each do |key, child|
      if child.is_a?(String) || child.is_a?(Integer)
        changed = replace_u10_price_tokens(child)
        replacements += 1 if changed != child
        value[key] = changed
      else
        replacements += replace_u10_deep!(child)
      end
    end
  end
  replacements
end

def props_identify_u10_xl?(props)
  return false unless props.is_a?(Hash)

  props["slug"] == "u10-xl-pro" ||
    props["id"] == "u10-xl-pro" ||
    props["value"] == "U10 XL PRO" ||
    props["model"] == "U10 XL PRO" ||
    props["href"].to_s.match?(%r{/(?:ru/)?model/u10-xl-pro/?\z})
end

def deep_contains_u10_xl_name?(value)
  case value
  when String
    value.include?("U10 XL PRO")
  when Array
    value.any? { |child| deep_contains_u10_xl_name?(child) }
  when Hash
    value.each_value.any? { |child| deep_contains_u10_xl_name?(child) }
  else
    false
  end
end

def schema_props_identify_u10_xl?(props)
  schema = props.is_a?(Hash) ? props.dig("dangerouslySetInnerHTML", "__html") : nil
  schema.is_a?(String) && schema.include?('"name":"U10 XL PRO"')
end

def transform_rsc_u10_xl!(html)
  replacements = 0
  pattern = /(self\.__VINEXT_RSC_CHUNKS__\.push\()("(?:\\.|[^"\\])*")(\))/

  transformed = html.gsub(pattern) do
    before = Regexp.last_match(1)
    encoded = Regexp.last_match(2)
    after = Regexp.last_match(3)
    chunk = JSON.parse(encoded)

    lines = chunk.split("\n", -1).map do |line|
      match = line.match(/\A([0-9a-f]+:)([\[{].*)\z/)
      next line unless match

      begin
        node = JSON.parse(match[2])
      rescue JSON::ParserError
        next line
      end

      visit = lambda do |value|
        case value
        when Array
          props = value[3].is_a?(Hash) ? value[3] : nil
          identifies_model = value[2].to_s == "u10-xl-pro" ||
            props_identify_u10_xl?(props) ||
            schema_props_identify_u10_xl?(props) ||
            (props&.fetch("className", nil) == "product-hero" && deep_contains_u10_xl_name?(value))
          if identifies_model
            replacements += replace_u10_deep!(value)
          else
            value.each { |child| visit.call(child) }
          end
        when Hash
          identifies_model = props_identify_u10_xl?(value) ||
            schema_props_identify_u10_xl?(value) ||
            (value["name"] == "U10 XL PRO" && (value.key?("price") || value.key?("basePriceAzn")))
          if identifies_model
            replacements += replace_u10_deep!(value)
          else
            value.each_value { |child| visit.call(child) }
          end
        end
      end
      visit.call(node)
      "#{match[1]}#{JSON.generate(node)}"
    end

    encoded_chunk = JSON.generate(lines.join("\n")).gsub("<", "\\u003c")
    "#{before}#{encoded_chunk}#{after}"
  end

  [transformed, replacements]
end

def transform_u10_xl_detail!(html)
  replacements = 0

  html = html.gsub(%r{<script type="application/ld\+json">(.*?)</script>}m) do |script|
    source = Regexp.last_match(1)
    begin
      schema = JSON.parse(source)
    rescue JSON::ParserError
      next script
    end
    unless schema["@type"] == "Product" && schema["name"] == "U10 XL PRO"
      next script
    end

    price = schema.dig("offers", "price")
    if price.to_s == "39900"
      schema["offers"]["price"] = price.is_a?(String) ? "45900" : 45_900
      replacements += 1
    end
    %(<script type="application/ld+json">#{JSON.generate(schema)}</script>)
  end

  html = html.gsub(%r{<div class="product-price"[^>]*>.*?</div>}m) do |fragment|
    changed = replace_u10_price_tokens(fragment)
    replacements += fragment.scan(U10_OLD_PRICE).size if changed != fragment
    changed
  end

  html = html.gsub(%r{<section class="model-finance\b.*?</section>}m) do |fragment|
    changed = replace_u10_finance_tokens(fragment)
    replacements += fragment.scan(U10_OLD_PRICE).size if changed != fragment
    changed
  end

  [html, replacements]
end

def transform_rendered_u10_xl!(html)
  replacements = 0
  %w[article tr option a].each do |tag|
    html = html.gsub(%r{<#{tag}\b[^>]*>.*?</#{tag}>}m) do |fragment|
      identifies_model = fragment.include?('href="/model/u10-xl-pro') ||
        fragment.include?('href="/ru/model/u10-xl-pro') ||
        fragment.include?('value="U10 XL PRO"')
      next fragment unless identifies_model

      changed = replace_u10_finance_tokens(fragment)
      replacements += fragment.scan(U10_OLD_PRICE).size if changed != fragment
      changed
    end
  end
  [html, replacements]
end

u10_updated_files = 0
u10_updated_prices = 0
PUBLIC_TEXT_PATHS.each do |path|
  next unless File.file?(path)

  original = File.read(path, encoding: "UTF-8")
  content = original.dup
  replacements = 0

  if path.end_with?(".html")
    content, rendered = transform_rendered_u10_xl!(content)
    detail = 0
    if path.match?(%r{/(?:ru/)?model/u10-xl-pro/index\.html\z})
      content, detail = transform_u10_xl_detail!(content)
    end
    content, rsc = transform_rsc_u10_xl!(content)
    replacements += rendered + detail + rsc
  elsif path.include?("/assets/")
    content = content.gsub(/\{slug:`u10-xl-pro`,[^{}]*\}/) do |record|
      changed = replace_u10_price_tokens(record)
      replacements += record.scan(U10_OLD_PRICE).size if changed != record
      changed
    end
  elsif path.include?("/aksesuar-konfiquratoru/")
    content = content.gsub(/\{id:"u10-xl-pro",[^{}]*\}/) do |record|
      changed = replace_u10_price_tokens(record)
      replacements += record.scan(U10_OLD_PRICE).size if changed != record
      changed
    end
  end

  next if content == original

  File.write(path, content, mode: "w", encoding: "UTF-8")
  u10_updated_files += 1
  u10_updated_prices += replacements
end

u10_page = File.read(File.join(ROOT, "model", "u10-xl-pro", "index.html"), encoding: "UTF-8")
abort "U10 XL PRO visible price was not updated" unless u10_page.include?("45,900 AZN")
abort "U10 XL PRO Product Offer was not updated" unless u10_page.include?('"price":45900')
abort "U10 XL PRO down payment was not updated" unless u10_page.include?("22,950<!-- --> AZN")
abort "U10 XL PRO financed debt was not updated" unless u10_page.include?("26,392<!-- --> AZN")
abort "U10 XL PRO monthly payment was not updated" unless u10_page.include?("2,199<!-- --> <small>AZN / ay</small>")
abort "U10 XL PRO model page still contains the old price" if u10_page.match?(U10_OLD_PRICE)

u10_menu_bundles = menu_bundles.select do |path|
  File.read(path, encoding: "UTF-8").include?('slug:`u10-xl-pro`')
end
abort "U10 XL PRO catalog record not found" if u10_menu_bundles.empty?
u10_menu_bundles.each do |path|
  record = File.read(path, encoding: "UTF-8")[/\{slug:`u10-xl-pro`,[^{}]*\}/]
  abort "U10 XL PRO catalog price was not updated in #{File.basename(path)}" unless record&.include?("price:45900")
end

u10_configurator = Dir.glob(File.join(ROOT, "aksesuar-konfiquratoru", "_next", "static", "chunks", "app", "page-*.js"))
  .find { |path| File.read(path, encoding: "UTF-8").include?('id:"u10-xl-pro",name:"U10 XL PRO"') }
abort "U10 XL PRO configurator catalog not found" unless u10_configurator
abort "U10 XL PRO configurator price was not updated" unless File.read(u10_configurator, encoding: "UTF-8").include?('id:"u10-xl-pro",name:"U10 XL PRO",vehicleType:"utv",family:"Utility / İş",years:"Cari model ili",basePriceAzn:45900')

puts "Confirmed model prices applied: 675NK 13,290 AZN (#{updated_prices} scoped values in #{updated_files} files); U10 XL PRO 45,900 AZN (#{u10_updated_prices} scoped values in #{u10_updated_files} files)"
