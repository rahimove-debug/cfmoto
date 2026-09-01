#!/usr/bin/env ruby
# frozen_string_literal: true

ROOT = File.expand_path("..", __dir__)
errors = []

def read(path)
  File.read(path, encoding: "UTF-8")
end

def referenced_asset(html, prefix)
  html[%r{/assets/(#{Regexp.escape(prefix)}[^"']+\.js)}, 1]
end

def require_block_link(errors, html, pattern, href, label)
  block = html[pattern]
  if block.nil?
    errors << "#{label}: block is missing"
  elsif !block.include?(%(href="#{href}"))
    errors << "#{label}: must link directly to #{href}"
  end
end

locales = {
  "AZ" => {
    html: File.join(ROOT, "index.html"),
    motorcycle_path: "/motosiklet/",
    category_paths: %w[/motosiklet/ /kvadrosikl/ /buggy/]
  },
  "RU" => {
    html: File.join(ROOT, "ru", "index.html"),
    motorcycle_path: "/ru/motocikly/",
    category_paths: %w[/ru/motocikly/ /ru/kvadrocikly/ /ru/buggy/]
  }
}.freeze

locales.each do |locale, config|
  unless File.file?(config.fetch(:html))
    errors << "#{locale}: homepage is missing"
    next
  end

  html = read(config.fetch(:html))
  motorcycle_path = config.fetch(:motorcycle_path)
  require_block_link(
    errors,
    html,
    %r{<article class="category-hero-panel category-hero-moto.*?</article>}m,
    motorcycle_path,
    "#{locale} motorcycle hero"
  )
  require_block_link(
    errors,
    html,
    %r{<article class="category-panel motorcycles".*?</article>}m,
    motorcycle_path,
    "#{locale} motorcycle promo"
  )
  require_block_link(
    errors,
    html,
    %r{<aside class="mega-categories".*?</aside>}m,
    motorcycle_path,
    "#{locale} mega-menu CTA"
  )

  page_asset = referenced_asset(html, "page-Cfmoto")
  menu_asset = referenced_asset(html, "ProductMegaMenu-Cfmoto")
  if page_asset.nil?
    errors << "#{locale}: active homepage bundle reference is missing"
  else
    page_path = File.join(ROOT, "assets", page_asset)
    if !File.file?(page_path)
      errors << "#{locale}: active homepage bundle #{page_asset} is missing"
    else
      page = read(page_path)
      direct_count = page.scan(motorcycle_path).size
      errors << "#{locale}: active homepage bundle must contain direct motorcycle links in the hero, promo and footer" if direct_count < 3
    end
  end

  if menu_asset.nil?
    errors << "#{locale}: active mega-menu bundle reference is missing"
  else
    menu_path = File.join(ROOT, "assets", menu_asset)
    if !File.file?(menu_path)
      errors << "#{locale}: active mega-menu bundle #{menu_asset} is missing"
    else
      menu = read(menu_path)
      missing_paths = config.fetch(:category_paths).reject { |path| menu.include?(path) }
      errors << "#{locale}: active mega-menu bundle is missing direct category path(s): #{missing_paths.join(', ')}" unless missing_paths.empty?
    end
  end
end

%w[motosiklet kvadrosikl buggy].each do |slug|
  path = File.join(ROOT, slug, "index.html")
  errors << "Category target /#{slug}/ is missing" unless File.file?(path)
end

abort "Homepage category-link audit failed:\n- #{errors.join("\n- ")}" unless errors.empty?

puts "Homepage category-link audit passed: AZ/RU hero, motorcycle promo and category-aware mega-menu CTAs use direct routes"
