# frozen_string_literal: true

module NewsConfig
  ROOT_SLUG = "xeberler"
  ARTICLE_SLUG = "cforce-c4-c5-artiq-azerbaycanda"

  PAGES = [
    {
      path: "/#{ROOT_SLUG}/",
      file: File.join(ROOT_SLUG, "index.html")
    },
    {
      path: "/#{ROOT_SLUG}/#{ARTICLE_SLUG}/",
      file: File.join(ROOT_SLUG, ARTICLE_SLUG, "index.html")
    }
  ].freeze

  module_function

  def html_paths(root)
    PAGES.map { |page| File.join(root, page.fetch(:file)) }
  end

  def urls(site_origin)
    PAGES.map { |page| "#{site_origin}#{page.fetch(:path)}" }
  end
end
