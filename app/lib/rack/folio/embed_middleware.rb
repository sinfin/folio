# frozen_string_literal: true

module Rack
  module Folio
    class EmbedMiddleware
      def initialize(app)
        @app = app
      end

      def call(env)
        if env["REQUEST_PATH"] == "/folio/embed"
          render_embed_html
        else
          @app.call(env)
        end
      end

      def render_embed_html
        [200, { "Content-Type" => "text/html" }, [self.class.embed_html]]
      end

      def self.embed_html
        if Rails.env.development? && ENV["FOLIO_EMBED_DEV"]
          ::File.read(::Folio::Engine.root.join("data/embed/dist/folio-embed-dist.html"))
        else
          @embed_html ||= ::File.read(::Folio::Engine.root.join("data/embed/dist/folio-embed-dist.html"))
        end
      end
    end
  end
end
