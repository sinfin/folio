# frozen_string_literal: true

module Folio::Audited
  extend ActiveSupport::Concern

  included do
    before_validation :store_folio_audited_data
  end

  class_methods do
    def audited(opts = {})
      super(opts[:on].present? ? opts : opts.merge(on: %i[create update destroy]))

      define_singleton_method(:folio_audited_data_additional_keys) do
        opts[:relations]
      end

      define_singleton_method(:audited_console_enabled?) do
        opts[:console] != false
      end

      define_singleton_method(:audited_console_restorable?) do
        opts[:restore] == false ? false : true
      end

      # override audited - don't ignore inheritance_column
      define_singleton_method(:default_ignored_attributes) do
        [primary_key] | Audited.ignored_attributes
      end
    end
  end

  def reconstruct_folio_data
    Folio::Audited::Auditor.new(self).reconstruct
  end

  def reconstruct_file_placements
    assign_attributes(get_file_placements_attributes_for_reconstruction(record: self))
  end

  private
    def store_folio_audited_data
      if respond_to?(:folio_audited_data)
        self.folio_audited_data = Folio::Audited::Auditor.new(self).get_folio_audited_data
      end
    end
end
