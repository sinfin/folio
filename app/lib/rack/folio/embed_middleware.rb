# frozen_string_literal: true

require "digest"

module Rack
  module Folio
    class EmbedMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        if env["PATH_INFO"] == "/folio/embed"
          render_embed_html
        else
          @app.call(env)
        end
      end

      def render_embed_html
        content, etag = self.class.embed_html_with_etag

        [200, {
          "Content-Type" => "text/html",
          "ETag" => etag,
          "Cache-Control" => "max-age=15, public, must-revalidate, stale-while-revalidate=15, stale-if-error=300"
        }, [content]]
      end

      def self.embed_html_with_etag
        if Rails.env.development? && ENV["FOLIO_EMBED_DEV"]
          content = ::File.read(::Folio::Engine.root.join("data/embed/dist/folio-embed-dist.html"))
          etag = Digest::MD5.hexdigest(content)
          [content, etag]
        else
          @embed_html_with_etag ||= begin
            content = ::File.read(::Folio::Engine.root.join("data/embed/dist/folio-embed-dist.html"))
            etag = Digest::MD5.hexdigest(content)
            [content, etag]
          end
        end
      end
    end
  end
end
