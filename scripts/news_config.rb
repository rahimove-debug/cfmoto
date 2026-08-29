# frozen_string_literal: true

module NewsConfig
  ROOT_SLUG = "xeberler"
  CFORCE_ARTICLE_SLUG = "cforce-c4-c5-artiq-azerbaycanda"
  Z10_ARTICLE_SLUG = "z10-z10-4-turbo-performans-azerbaycanda"
  ROMANIACS_ARTICLE_SLUG = "cfmoto-450mt-red-bull-romaniacs-2026"
  QUILES_ARTICLE_SLUG = "max-quiles-daniel-holgado-almaniya-gp-iki-podium"
  BREMBO_ARTICLE_SLUG = "cfmoto-brembo-strateji-terefdasliq-2026"

  INDEX_PAGE = {
    path: "/#{ROOT_SLUG}/",
    file: File.join(ROOT_SLUG, "index.html"),
    image: "/gallery/romaniacs-2026-450mt-hero.webp"
  }.freeze

  ARTICLES = [
    {
      slug: ROMANIACS_ARTICLE_SLUG,
      path: "/#{ROOT_SLUG}/#{ROMANIACS_ARTICLE_SLUG}/",
      file: File.join(ROOT_SLUG, ROMANIACS_ARTICLE_SLUG, "index.html"),
      image: "/gallery/romaniacs-2026-450mt-hero.webp",
      title: "CFMOTO Red Bull Romaniacs 2026-da üç Adventure sinfində qalib gəldi"
    },
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
    },
    {
      slug: QUILES_ARTICLE_SLUG,
      path: "/#{ROOT_SLUG}/#{QUILES_ARTICLE_SLUG}/",
      file: File.join(ROOT_SLUG, QUILES_ARTICLE_SLUG, "index.html"),
      image: "/gallery/quiles-sachsenring-2026-hero.jpg",
      title: "Max Quiles və Daniel Holgado CFMOTO-ya Almaniyada iki podium gətirdi"
    },
    {
      slug: BREMBO_ARTICLE_SLUG,
      path: "/#{ROOT_SLUG}/#{BREMBO_ARTICLE_SLUG}/",
      file: File.join(ROOT_SLUG, BREMBO_ARTICLE_SLUG, "index.html"),
      image: "/gallery/cfmoto-brembo-partnership-hero.jpg",
      title: "CFMOTO və Brembo uzunmüddətli strateji tərəfdaşlıq imzaladı"
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
