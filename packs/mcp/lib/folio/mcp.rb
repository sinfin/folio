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

        pack_root = File.expand_path("../../..", __dir__)
        app_lib = File.join(pack_root, "app/lib")

        # Load base classes first
        require File.join(app_lib, "folio/mcp/tools/base.rb")

        # Load serializers
        Dir[File.join(app_lib, "folio/mcp/serializers/**/*.rb")].each { |f| require f }

        # Load tools
        Dir[File.join(app_lib, "folio/mcp/tools/**/*.rb")].each { |f| require f }

        # Load resources
        Dir[File.join(app_lib, "folio/mcp/resources/**/*.rb")].each { |f| require f }

        # Load prompts
        Dir[File.join(app_lib, "folio/mcp/prompts/**/*.rb")].each { |f| require f }

        # Load other components
        Dir[File.join(app_lib, "folio/mcp/*.rb")].each { |f| require f }

        @components_loaded = true
      end
    end
  end
end

require_relative "mcp/configuration"
require_relative "mcp/server_factory"
