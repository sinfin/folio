# frozen_string_literal: true

module Folio
  module Singleton
    extend ActiveSupport::Concern

    class MissingError < StandardError; end

    included do
      validate :validate_singularity
    end

    class_methods do
      def instance
        self.first.presence || fail(MissingError, self.class.to_s)
      end

      def console_selectable?
        to_s != 'Folio::NodeSingleton' && !exists?
      end
    end

    def singleton?
      true
    end

    private

      def validate_singularity
        param = respond_to?(:type) ? :type : :id

        if new_record?
          errors.add(param, :invalid) if self.class.exists?
        else
          errors.add(param, :invalid) if self.class.where.not(id: id).exists?
        end
      end
  end
end
