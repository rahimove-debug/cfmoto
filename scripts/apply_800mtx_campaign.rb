#!/usr/bin/env ruby
require "json"

# Apply the approved 800MT-X cash campaign before the catalogue generators run.
# Every replacement is bound to a 800MT-X record or rendered component; an
# unrelated product that happens to cost 19,900 AZN must remain untouched.

ROOT = File.expand_path("..", __dir__)

PUBLIC_TEXT_PATHS = (
  [File.join(ROOT, "index.html")] +
  Dir.glob(File.join(ROOT, "{model,ru,motosiklet,kvadrosikl,buggy,model-muqayisesi}", "**", "*.html")) +
  Dir.glob(File.join(ROOT, "assets", "*.js")) +
  Dir.glob(File.join(ROOT, "aksesuar-konfiquratoru", "**", "*.{html,js,json,txt}"))
).uniq.freeze

OLD_PRICE = /19,900|(?<!\d)19900(?!\d)/

def replace_price_tokens(value)
  case value
  when String
    value.gsub("19,900", "17,900").gsub(/(?<!\d)19900(?!\d)/, "17900")
  when Integer
    value == 19_900 ? 17_900 : value
  else
    value
  end
end

def replace_deep!(value)
  replacements = 0
  return 0 if value.is_a?(Array) && value[0] == "$" && value[1] == "del"
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
      # Final-state campaign markup keeps the public list price inside its
      # accessibility label. The approved presentation pass owns that label,
      # so a repeat build must not rewrite 19,900 there as 17,900.
      next if key == "listPrice" || key == "aria-label"
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

def props_identify_800mtx?(props)
  return false unless props.is_a?(Hash)

  props["slug"] == "800mt-x" ||
    props["id"] == "800mt-x" ||
    props["value"] == "800MT-X" ||
    props["model"] == "800MT-X" ||
    props["href"].to_s.match?(%r{/model/800mt-x/?\z})
end

def deep_contains_800mtx_name?(value)
  case value
  when String
    value.include?("800MT-X")
  when Array
    value.any? { |child| deep_contains_800mtx_name?(child) }
  when Hash
    value.each_value.any? { |child| deep_contains_800mtx_name?(child) }
  else
    false
  end
end

def schema_props_identify_800mtx?(props)
  schema = props.is_a?(Hash) ? props.dig("dangerouslySetInnerHTML", "__html") : nil
  schema.is_a?(String) && schema.include?('"name":"800MT-X"')
end

def transform_rsc_800mtx!(html)
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
          identifies_model = value[2].to_s.downcase == "800mt-x" ||
            props_identify_800mtx?(props) ||
            schema_props_identify_800mtx?(props) ||
            (props&.fetch("className", nil) == "product-hero" && deep_contains_800mtx_name?(value))
          if identifies_model
            replacements += replace_deep!(value)
          else
            value.each { |child| visit.call(child) }
          end
        when Hash
          if props_identify_800mtx?(value) ||
              schema_props_identify_800mtx?(value) ||
              (value["name"] == "800MT-X" && (value.key?("price") || value.key?("basePriceAzn")))
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


def transform_800mtx_detail!(html)
  replacements = 0

  html = html.gsub(%r{<script type="application/ld\+json">(.*?)</script>}m) do |script|
    source = Regexp.last_match(1)
    begin
      schema = JSON.parse(source)
    rescue JSON::ParserError
      next script
    end
    unless schema["@type"] == "Product" && schema["name"] == "800MT-X"
      next script
    end

    price = schema.dig("offers", "price")
    if price.to_s == "19900"
      schema["offers"]["price"] = price.is_a?(String) ? "17900" : 17_900
      replacements += 1
    end
    %(<script type="application/ld+json">#{JSON.generate(schema)}</script>)
  end

  html = html.gsub(%r{<div class="product-price"[^>]*>.*?</div>}m) do |fragment|
    next fragment if fragment.include?("is-campaign") || fragment.include?("<del>")
    changed = replace_price_tokens(fragment)
    replacements += fragment.scan(OLD_PRICE).size if changed != fragment
    changed
  end

  html = html.gsub(%r{<section class="model-finance\b.*?</section>}m) do |fragment|
    next fragment if fragment.include?("is-campaign") || fragment.include?("<del>")
    changed = replace_price_tokens(fragment)
    replacements += fragment.scan(OLD_PRICE).size if changed != fragment
    changed
  end

  [html, replacements]
end

def transform_rendered_800mtx!(html)
  replacements = 0
  # Prices can sit inside the linked card itself, a surrounding product card,
  # a comparison row, or a calculator option. Each fragment must explicitly
  # identify 800MT-X before its price is changed.
  %w[article tr option a].each do |tag|
    html = html.gsub(%r{<#{tag}\b[^>]*>.*?</#{tag}>}m) do |fragment|
      identifies_model = fragment.include?('href="/model/800mt-x') ||
        fragment.include?('href="/ru/model/800mt-x') ||
        fragment.include?('value="800MT-X"')
      unless identifies_model
        next fragment
      end

      next fragment if fragment.include?("is-campaign") || fragment.include?("<del>")
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
    content, rendered = transform_rendered_800mtx!(content)
    detail = 0
    if path.match?(%r{/(?:ru/)?model/800mt-x/index\.html\z})
      content, detail = transform_800mtx_detail!(content)
    end
    content, rsc = transform_rsc_800mtx!(content)
    replacements += rendered + detail + rsc
  elsif path.include?("/assets/")
    content = content.gsub(/\{slug:`800mt-x`,[^{}]*\}/) do |record|
      changed = replace_price_tokens(record)
      replacements += record.scan(OLD_PRICE).size if changed != record
      changed
    end
  elsif path.include?("/aksesuar-konfiquratoru/")
    content = content.gsub(/\{id:"800mt-x",[^{}]*\}/) do |record|
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

model_page = File.read(File.join(ROOT, "model", "800mt-x", "index.html"), encoding: "UTF-8")
probe, rendered_remaining = transform_rendered_800mtx!(model_page.dup)
probe, detail_remaining = transform_800mtx_detail!(probe)
_probe, rsc_remaining = transform_rsc_800mtx!(probe)
abort "800MT-X model page still contains a scoped old price" unless rendered_remaining + detail_remaining + rsc_remaining == 0
abort "800MT-X model page was not updated" unless model_page.include?("17,900") && model_page.include?("17900")

menu_bundles = Dir.glob(File.join(ROOT, "assets", "ProductMegaMenu-*.js"))
abort "800MT-X catalogue price missing" unless menu_bundles.any? { |path| File.read(path, encoding: "UTF-8").match?(/slug:`800mt-x`[^{}]*price:17900/) }
Dir.glob(File.join(ROOT, "assets", "*.js")).each do |path|
  content = File.read(path, encoding: "UTF-8")
  changed = content.gsub(/\{slug:`800mt-x`,[^{}]*\}/) do |record|
    record.include?("listPrice:19900") ? record : record.sub("price:17900", "price:17900,listPrice:19900,campaign:!0")
  end
  File.write(path, changed, encoding: "UTF-8") if changed != content
end
puts "800MT-X cash campaign applied: 19,900 → 17,900 AZN (#{updated_prices} scoped values in #{updated_files} files)"
