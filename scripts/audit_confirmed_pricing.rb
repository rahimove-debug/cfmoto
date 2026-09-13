#!/usr/bin/env ruby
require "json"

ROOT = File.expand_path(ARGV[0] || File.join("..", "dist"), __dir__)
errors = []

def read_utf8(path)
  File.read(path, encoding: "UTF-8")
end

def collect_schema(value, nodes)
  case value
  when Hash
    nodes << value
    value.each_value { |child| collect_schema(child, nodes) }
  when Array
    value.each { |child| collect_schema(child, nodes) }
  end
end

OLD_675_PRICE = /12,800|(?<!\d)12800(?!\d)/

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

def deep_contains_old_675_price?(value)
  case value
  when String
    value.match?(OLD_675_PRICE)
  when Integer
    value == 12_800
  when Array
    value.any? { |child| deep_contains_old_675_price?(child) }
  when Hash
    value.each_value.any? { |child| deep_contains_old_675_price?(child) }
  else
    false
  end
end

def stale_675_rsc_node?(html)
  stale = false
  pattern = /self\.__VINEXT_RSC_CHUNKS__\.push\(("(?:\\.|[^"\\])*")\)/
  html.scan(pattern).flatten.each do |encoded|
    chunk = JSON.parse(encoded)
    chunk.split("\n", -1).each do |line|
      match = line.match(/\A[0-9a-f]+:([\[{].*)\z/)
      next unless match

      begin
        node = JSON.parse(match[1])
      rescue JSON::ParserError
        next
      end
      visit = lambda do |value|
        case value
        when Array
          props = value[3].is_a?(Hash) ? value[3] : nil
          identifies_model = value[2].to_s.downcase == "675nk" ||
            props_identify_675nk?(props) ||
            schema_props_identify_675nk?(props) ||
            (props&.fetch("className", nil) == "product-hero" && deep_contains_675nk_name?(value))
          stale ||= deep_contains_old_675_price?(value) if identifies_model
          value.each { |child| visit.call(child) } unless identifies_model
        when Hash
          identifies_model = props_identify_675nk?(value) ||
            schema_props_identify_675nk?(value) ||
            (value["name"] == "675NK" && (value.key?("price") || value.key?("basePriceAzn")))
          stale ||= deep_contains_old_675_price?(value) if identifies_model
          value.each_value { |child| visit.call(child) } unless identifies_model
        end
      end
      visit.call(node)
    end
  end
  stale
end

required = {
  "AZ home" => File.join(ROOT, "index.html"),
  "RU home" => File.join(ROOT, "ru", "index.html"),
  "675NK AZ" => File.join(ROOT, "model", "675nk", "index.html"),
  "675NK RU" => File.join(ROOT, "ru", "model", "675nk", "index.html"),
  "C5 AZ" => File.join(ROOT, "model", "cforce-c5", "index.html"),
  "C5 RU" => File.join(ROOT, "ru", "model", "cforce-c5", "index.html"),
  "Z10-4 AZ" => File.join(ROOT, "model", "z10-4", "index.html"),
  "Z10-4 RU" => File.join(ROOT, "ru", "model", "z10-4", "index.html"),
  "AZ buggy" => File.join(ROOT, "buggy", "index.html"),
  "RU buggy" => File.join(ROOT, "ru", "buggy", "index.html"),
  "AZ compare" => File.join(ROOT, "model-muqayisesi", "index.html"),
  "RU compare" => File.join(ROOT, "ru", "sravnenie-modeley", "index.html")
}
required.each { |label, path| errors << "Missing #{label}" unless File.file?(path) }
abort errors.join("\n") unless errors.empty?

az_home = read_utf8(required.fetch("AZ home"))
ru_home = read_utf8(required.fetch("RU home"))
n675_az = read_utf8(required.fetch("675NK AZ"))
n675_ru = read_utf8(required.fetch("675NK RU"))
c5_az = read_utf8(required.fetch("C5 AZ"))
c5_ru = read_utf8(required.fetch("C5 RU"))
z10_az = read_utf8(required.fetch("Z10-4 AZ"))
z10_ru = read_utf8(required.fetch("Z10-4 RU"))

[az_home, ru_home].each_with_index do |home, index|
  locale = index.zero? ? "AZ" : "RU"
  errors << "#{locale} home is missing 675NK 13,290 AZN" unless home.include?("675NK") && home.include?("13,290 AZN")
  errors << "#{locale} home is missing Z10-4 campaign presentation" unless home.include?("49,900 AZN") && home.include?("47,900 AZN") && home.include?(index.zero? ? "Kampaniya" : "Акцион")
  errors << "#{locale} home is missing campaign stylesheet" unless home.include?('/assets/confirmed-pricing-v1.css')
  c5_card = home[%r{<article class="model-card">(?:(?!</article>).)*href="/(?:ru/)?model/cforce-c5/"(?:(?!</article>).)*</article>}m]
  errors << "#{locale} home is missing the C5 GEN4 badge" unless c5_card&.include?('<span class="badge">GEN⁴</span>')
end

{
  "AZ 675NK" => n675_az,
  "RU 675NK" => n675_ru
}.each do |label, html|
  errors << "#{label} visible cash price is wrong" unless html.include?("13,290 AZN")
  errors << "#{label} calculator down payment is wrong" unless html.include?("5,316<!-- --> AZN")
  errors << "#{label} calculator financed debt is wrong" unless html.include?("9,170<!-- --> AZN")
  errors << "#{label} calculator monthly payment is wrong" unless html.include?("764<!-- --> <small>AZN / ay</small>") || html.include?("764<!-- --> <small>AZN / мес.</small>")
end

errors << "C5 AZ price changed" unless c5_az.include?("13,900 AZN")
errors << "C5 AZ GEN4 positioning missing" unless c5_az.include?("Yeni GEN⁴ platforması") && c5_az.include?("yeni GEN⁴ platformalı")
errors << "C5 RU price changed" unless c5_ru.include?("13,900 AZN")
errors << "C5 RU GEN4 positioning missing" unless c5_ru.include?("Новая платформа GEN⁴") && c5_ru.include?("новой платформе GEN⁴")

az_atv = read_utf8(File.join(ROOT, "kvadrosikl", "index.html"))
ru_atv = read_utf8(File.join(ROOT, "ru", "kvadrocikly", "index.html"))
errors << "AZ ATV category is missing C5 GEN4 positioning" unless az_atv.include?("CFORCE C5") && az_atv.include?("Yeni GEN⁴ platforması")
errors << "RU ATV category is missing C5 GEN4 positioning" unless ru_atv.include?("CFORCE C5") && ru_atv.include?("Новая платформа GEN⁴")

{
  "AZ Z10-4" => [z10_az, "Kampaniya qiyməti", "2,000 AZN qənaət"],
  "RU Z10-4" => [z10_ru, "Акционная цена", "Экономия 2,000 AZN"]
}.each do |label, (html, campaign_label, saving)|
  errors << "#{label} list price missing" unless html.include?("49,900 AZN")
  errors << "#{label} campaign price missing" unless html.include?("47,900 AZN")
  errors << "#{label} campaign label missing" unless html.include?(campaign_label)
  errors << "#{label} saving missing" unless html.include?(saving)
  errors << "#{label} calculator does not use campaign price" unless html.include?("23,950<!-- --> AZN") && html.include?("27,542<!-- --> AZN")
end

[required.fetch("AZ buggy"), required.fetch("RU buggy"), required.fetch("AZ compare"), required.fetch("RU compare")].each do |path|
  html = read_utf8(path)
  errors << "#{path} is missing Z10-4 list/campaign price" unless html.include?("49,900 AZN") && html.include?("47,900 AZN") && html.include?("campaign")
end

news_path = File.join(ROOT, "xeberler", "z10-z10-4-turbo-performans-azerbaycanda", "index.html")
news = File.file?(news_path) ? read_utf8(news_path) : ""
errors << "Z10 story is missing the approved campaign prices" unless news.include?("49,900 AZN siyahı qiymətinə qarşı 47,900 AZN kampaniya qiyməti")

schemas = []
Dir.glob(File.join(ROOT, "**", "*.html")).each do |path|
  html = read_utf8(path)
  html.scan(%r{<script type="application/ld\+json">(.*?)</script>}m).flatten.each do |source|
    begin
      collect_schema(JSON.parse(source), schemas)
    rescue JSON::ParserError => error
      errors << "Malformed JSON-LD in #{path}: #{error.message}"
    end
  end
end

{
  "675NK" => "13290",
  "CFORCE C5" => "13900",
  "Z10-4" => "47900"
}.each do |name, expected|
  products = schemas.select { |node| node["@type"] == "Product" && node["name"] == name }
  errors << "No Product schema found for #{name}" if products.empty?
  products.each do |product|
    actual = product.dig("offers", "price").to_s
    errors << "#{name} Product Offer price #{actual.inspect}, expected #{expected}" unless actual == expected
  end
end

Dir.glob(File.join(ROOT, "**", "*.html")).each do |path|
  html = read_utf8(path)
  if path.match?(%r{/(?:ru/)?model/675nk/index\.html\z})
    product_price = html[%r{<div class="product-price"[^>]*>.*?</div>}m]
    finance = html[%r{<section class="model-finance\b.*?</section>}m]
    errors << "Stale 675NK product price remains on #{path}" if product_price&.match?(OLD_675_PRICE)
    errors << "Stale 675NK finance price remains on #{path}" if finance&.match?(OLD_675_PRICE)
  end
  %w[article tr option a].each do |tag|
    html.scan(%r{<#{tag}\b[^>]*>.*?</#{tag}>}m).each do |fragment|
      identifies_model = fragment.include?('href="/model/675nk') ||
        fragment.include?('href="/ru/model/675nk') ||
        fragment.include?('value="675NK"')
      errors << "Stale 675NK #{tag} price remains in #{path}" if identifies_model && fragment.match?(OLD_675_PRICE)
    end
  end
  errors << "Stale 675NK RSC price remains in #{path}" if stale_675_rsc_node?(html)
end

sales_manifest = File.join(ROOT, "sales-build.json")
if File.file?(sales_manifest)
  manifest = JSON.parse(read_utf8(sales_manifest))
  manifest.fetch("locales").each do |language, files|
    menu = read_utf8(File.join(ROOT, "assets", files.fetch("menu")))
    errors << "#{language} client catalog lost 675NK price" unless menu.include?('slug:`675nk`') && menu.include?('price:13290')
    errors << "#{language} client catalog lost Z10-4 list/campaign fields" unless menu.include?('price:47900,listPrice:49900,campaign:!0')
    errors << "#{language} client catalog lost C5 GEN4 badge" unless menu.match?(/slug:`cforce-c5`[^{}]*badge:`GEN⁴`/)
  end
end

config_index = read_utf8(File.join(ROOT, "aksesuar-konfiquratoru", "index.html"))
bundle_name = config_index[/page-cfmoto-improvements-[a-f0-9]+\.js/]
if bundle_name
  bundle = read_utf8(File.join(ROOT, "aksesuar-konfiquratoru", "_next", "static", "chunks", "app", bundle_name))
  errors << "Configurator lost 675NK price" unless bundle.include?('"id":"675nk"') && bundle.include?('"basePriceAzn":13290')
  errors << "Configurator Z10-4 must use campaign price" unless bundle.include?('"id":"z10-4"') && bundle.include?('"basePriceAzn":47900')
else
  errors << "Configurator improved bundle not referenced"
end

if errors.any?
  warn errors.map { |error| "- #{error}" }.join("\n")
  abort "Confirmed pricing audit failed with #{errors.size} error(s)"
end

puts "Confirmed pricing audit passed: 675NK 13,290; C5 13,900 + GEN⁴; Z10-4 49,900 list / 47,900 campaign across AZ/RU, calculators, schema and configurator"
