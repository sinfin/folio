# frozen_string_literal: true

module Dummy
  module Ai
    class << self
      attr_writer :demo_provider_adapter_class

      def demo_provider_adapter_class
        @demo_provider_adapter_class || Dummy::Ai::DemoProviderAdapter
      end
    end
  end
end

require_relative "ai/demo_provider_adapter"
require_relative "ai/railtie"
