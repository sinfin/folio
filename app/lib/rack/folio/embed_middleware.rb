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
          render_embed_html(env["HTTP_IF_NONE_MATCH"])
        else
          @app.call(env)
        end
      end

      def render_embed_html(if_none_match)
        content, etag = self.class.embed_html_with_etag

        # Check if client has current version via If-None-Match header
        if if_none_match == etag
          [304, {
            "ETag" => etag,
            "Cache-Control" => "max-age=15, public, must-revalidate, stale-while-revalidate=15, stale-if-error=300"
          }, []]
        else
          [200, {
            "Content-Type" => "text/html",
            "ETag" => etag,
            "Cache-Control" => "max-age=15, public, must-revalidate, stale-while-revalidate=15, stale-if-error=300"
          }, [content]]
        end
      end

      def self.embed_html_with_etag
        if should_cache_embed_html?
          @embed_html_with_etag ||= read_embed_html_with_etag
        else
          read_embed_html_with_etag
        end
      end

      def self.should_cache_embed_html?
        return @should_cache_embed_html if defined?(@should_cache_embed_html)

        @should_cache_embed_html = if Rails.env.development?
          false
        else
          true
        end
      end

      def self.read_embed_html_with_etag
        content = ::File.read(::Folio::Engine.root.join("data/embed/dist/folio-embed-dist.html"))

        etag_content = if ENV["CURRENT_RELEASE_COMMIT_HASH"]
          "#{content} #{ENV["CURRENT_RELEASE_COMMIT_HASH"]}"
        elsif Rails.env.development?
          "#{content} #{Time.now.to_i}"
        else
          content
        end

        etag = Digest::MD5.hexdigest(etag_content)

        [content, etag]
      end
    end
  end
end
