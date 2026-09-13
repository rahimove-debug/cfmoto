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

puts "Confirmed model prices applied: 675NK 13,290 AZN (#{updated_prices} scoped values in #{updated_files} files)"
