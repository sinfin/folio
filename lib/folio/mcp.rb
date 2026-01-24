# frozen_string_literal: true

module Folio
  module Mcp
    KNOWN_FIELD_TYPES = %i[
      string
      text
      rich_text
      integer
      url
      url_json
      image
      images
      video_cover
      documents
      embed
      relation
      folio_attachment
      deprecated
    ].freeze

    TRANSLATABLE_FIELD_TYPES = %i[string text rich_text].freeze

    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      def reset_configuration!
        @configuration = nil
      end

      def enabled?
        configuration&.enabled == true
      end

      def configured?
        configuration.present? && configuration.resources.present?
      end

      def load_components!
        return if @components_loaded

        engine_root = Folio::Engine.root
        app_lib = engine_root.join("app/lib")

        # Load base classes first
        require app_lib.join("folio/mcp/tools/base.rb")

        # Load serializers
        Dir[app_lib.join("folio/mcp/serializers/**/*.rb")].each { |f| require f }

        # Load tools
        Dir[app_lib.join("folio/mcp/tools/**/*.rb")].each { |f| require f }

        # Load resources
        Dir[app_lib.join("folio/mcp/resources/**/*.rb")].each { |f| require f }

        # Load prompts
        Dir[app_lib.join("folio/mcp/prompts/**/*.rb")].each { |f| require f }

        # Load other components
        Dir[app_lib.join("folio/mcp/*.rb")].each { |f| require f }

        @components_loaded = true
      end
    end
  end
end

require_relative "mcp/configuration"
require_relative "mcp/server_factory"
