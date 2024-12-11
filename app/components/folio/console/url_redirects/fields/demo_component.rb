# frozen_string_literal: true

class Folio::Console::UrlRedirects::Fields::DemoComponent < Folio::Console::ApplicationComponent
  def initialize(url_redirect:)
    @url_redirect = url_redirect
  end

  def urls
    return [] if @url_redirect.url_from.blank?

    value = { @url_redirect.url_from.split("?").first => [@url_redirect.to_redirect_hash] }

    random_query_h = { "a#{SecureRandom.hex(4)}" => "a#{SecureRandom.hex(4)}" }

    query_variants = [
      nil,
      random_query_h,
    ]

    url_from_with_domain = if @url_redirect.url_from.start_with?("/")
      "#{Folio::Current.site.env_aware_root_url}#{@url_redirect.url_from[1..]}"
    else
      @url_redirect.url_from
    end

    url_from_as_uri = URI.parse(url_from_with_domain)

    if url_from_as_uri.query
      url_from_query_h = Rack::Utils.parse_query(url_from_as_uri.query)

      query_variants << url_from_query_h
      query_variants << random_query_h.merge(url_from_query_h)
    end

    query_variants.map do |query_h|
      uri = url_from_as_uri.dup
      uri.query = query_h.present? ? query_h.to_query : nil

      status_code, target_url = Folio::UrlRedirect.get_status_code_and_url(env_path: uri.path,
                                                                           env_query: uri.query,
                                                                           value:)

      if target_url.present? && target_url.start_with?("/")
        target_url = "#{Folio::Current.site.env_aware_root_url}#{target_url[1..]}"
      end

      [uri.to_s, target_url, status_code]
    end
  end
end
