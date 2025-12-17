# frozen_string_literal: true

module Folio::HasConsoleUrl
  extend ActiveSupport::Concern

  def self.rewrite_console_url(url)
    return url if url.nil?

    rewriter = Rails.application.config.folio_rewriter_lambda_for_has_console_url
    return url if rewriter.nil?

    rewriter.call(url)
  end

  included do
    scope :currently_editing_url, ->(url) do
      rewritten_url = Folio::HasConsoleUrl.rewrite_console_url(url)
      where(console_url: rewritten_url, console_url_updated_at: 5.minutes.ago..)
    end
  end

  def update_console_url!(console_url)
    rewritten_url = Folio::HasConsoleUrl.rewrite_console_url(console_url)
    update_columns(console_url: rewritten_url,
                   console_url_updated_at: Time.current)
  end
end
