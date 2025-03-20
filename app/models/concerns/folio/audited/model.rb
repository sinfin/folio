# frozen_string_literal: true

module Folio::Audited::Model
  extend ActiveSupport::Concern

  included do
    before_validation :set_folio_audited_changed_relations

    attribute :folio_audited_changed_relations, :jsonb, default: []
  end

  class_methods do
    def audited(opts = {})
      opts_with_folio_defaults = opts.without(:relations)

      opts_with_folio_defaults[:on] ||= %i[create update destroy]
      opts_with_folio_defaults[:if] ||= :should_audit_changes?

      super(opts_with_folio_defaults)

      define_singleton_method(:folio_audited_data_additional_keys) do
        opts[:relations]
      end

      define_singleton_method(:audited_console_enabled?) do
        opts[:console] != false
      end

      define_singleton_method(:audited_columns) do
        column_names - non_audited_columns + %w[folio_audited_changed_relations]
      end

      define_method(:should_audit_changes?) do
        true
      end

      define_method(:audited_console_restorable?) do
        opts[:restore] == false ? false : true
      end

      # override audited - don't ignore inheritance_column
      define_singleton_method(:default_ignored_attributes) do
        [primary_key, :atoms_data_for_search, :aasm_state_log] | Audited.ignored_attributes
      end
    end
  end

  def reconstruct_folio_audited_data(audit:)
    Folio::Audited::Auditor.new(record: self, audit:).reconstruct
  end

  private
    def set_folio_audited_changed_relations
      auditor = Folio::Audited::Auditor.new(record: self)
      self.folio_audited_changed_relations = auditor.get_folio_audited_changed_relations
    end
end
