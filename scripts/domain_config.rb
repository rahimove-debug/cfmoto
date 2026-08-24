# frozen_string_literal: true

module DomainConfig
  SITE_ORIGIN = "https://cfmoto.az"
  PAGES_SITE_ORIGIN_PATTERN = %r{https?://(?:[a-z0-9-]+\.)?cfmoto-azerbaijan\.pages\.dev}i.freeze

  # These origins may occur in imported snapshots or older generated metadata.
  # apply_seo.rb normalizes them before anything is published.
  NON_CANONICAL_SITE_ORIGINS = %w[
    http://cfmoto.az
    http://cfmoto.com.az
    https://cfmoto.com.az
    http://www.cfmoto.com.az
    https://www.cfmoto.com.az
    http://www.cfmoto.az
    https://www.cfmoto.az
    http://cfmoto-azerbaijan.pages.dev
    https://cfmoto-azerbaijan.pages.dev
    http://cfmoto-azerbaijan.dvhqpbbkmw.chatgpt.site
    https://cfmoto-azerbaijan.dvhqpbbkmw.chatgpt.site
  ].freeze

  # Confirmed paths from the former cfmoto.az site. These must remain explicit:
  # a generic wildcard cannot safely translate aliases such as /nk800.
  LEGACY_PATH_REDIRECTS = {
    "/cfmoto" => "/",
    "/motosiklet" => "/#modeller",
    "/motosi%CC%87klet" => "/#modeller",
    "/kvadrosikl" => "/#modeller",
    "/buggy" => "/#modeller",
    "/cflitemodelleri" => "/#modeller",
    "/800mt-explore-1" => "/model/800mt-explore",
    "/800mt-x-2" => "/model/800mt-x",
    "/nk800" => "/model/800nk-advanced",
    "/675sr-1" => "/model/675sr-r",
    "/450clc-bobber" => "/model/450cl-c-bobber",
    "/450clc" => "/model/450cl-c",
    "/450srs" => "/model/450sr-s",
    "/450sr-1" => "/model/450sr",
    "/300nk-1" => "/model/300nk",
    "/250sr" => "/model/250sr-fun",
    "/150-sc-scoter" => "/model/150sc",
    "/150-aura-scoter" => "/model/aura-150",
    "/papi%CC%87o-xo-125" => "/model/papio-xo",
    "/papio-xo-125" => "/model/papio-xo",
    "/1000mv" => "/model/cforce1000-mv",
    "/cforce1000o-touring-1" => "/model/cforce1000-touring",
    "/cforce850-touring" => "/model/cforce-850-touring",
    "/cforce625-touring" => "/model/cforce625eps-touring",
    "/cforce-520l" => "/model/cforce-520-l",
    "/goes-400" => "/model/goes-terrox-400l",
    "/cforce-110" => "/model/cforce-110-high",
    "/1000xl" => "/model/uforce-1000-xl",
    "/zforce-1000-sport" => "/model/zforce-1000-sport-r"
  }.freeze
end
