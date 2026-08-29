# frozen_string_literal: true

module NewsConfig
  ROOT_SLUG = "xeberler"
  CFORCE_ARTICLE_SLUG = "cforce-c4-c5-artiq-azerbaycanda"
  Z10_ARTICLE_SLUG = "z10-z10-4-turbo-performans-azerbaycanda"

  INDEX_PAGE = {
    path: "/#{ROOT_SLUG}/",
    file: File.join(ROOT_SLUG, "index.html"),
    image: "/gallery/z10-4-1.webp"
  }.freeze

  ARTICLES = [
    {
      slug: Z10_ARTICLE_SLUG,
      path: "/#{ROOT_SLUG}/#{Z10_ARTICLE_SLUG}/",
      file: File.join(ROOT_SLUG, Z10_ARTICLE_SLUG, "index.html"),
      image: "/gallery/z10-4-1.webp",
      title: "Z10 və Z10-4: turbo performans Azərbaycanda"
    },
    {
      slug: CFORCE_ARTICLE_SLUG,
      path: "/#{ROOT_SLUG}/#{CFORCE_ARTICLE_SLUG}/",
      file: File.join(ROOT_SLUG, CFORCE_ARTICLE_SLUG, "index.html"),
      image: "/gallery/cforce-c4-1.webp",
      title: "CFORCE C4 və C5 artıq Azərbaycanda"
    }
  ].freeze

  FEATURED_ARTICLE = ARTICLES.first
  PAGES = [INDEX_PAGE, *ARTICLES].freeze

  module_function

  def html_paths(root)
    PAGES.map { |page| File.join(root, page.fetch(:file)) }
  end

  def urls(site_origin)
    PAGES.map { |page| "#{site_origin}#{page.fetch(:path)}" }
  end
end
