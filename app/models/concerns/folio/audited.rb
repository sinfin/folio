# frozen_string_literal: true

module Folio::Audited
  extend ActiveSupport::Concern

  included do
    attr_accessor :audit
  end

  module ClassMethods
    def audited(opts = {})
      super(opts)

      define_singleton_method(:audited_view_name) do
        opts[:view_name] || :show
      end

      define_singleton_method(:audited_restorable?) do
        opts[:restore] == false ? false : true
      end

      # https://github.com/collectiveidea/audited/blob/master/lib/audited/auditor.rb#L125
      # monkey patch: add related audit to revision
      define_method(:revisions) do |from_version = 1|
        targeted_audits = audits
        targeted_audits = targeted_audits.from_version(from_version) if from_version > 1

        return [] unless targeted_audits

        previous_attributes = reconstruct_attributes(audits - targeted_audits)

        targeted_audits.map do |audit|
          previous_attributes.merge!(audit.new_attributes)
          previous_attributes[:audit_version] = audit.version
          previous_attributes[:audit] = audit
          revision_with(previous_attributes)
        end
      end
    end

    def has_audited_atoms?
      false
    end

    def has_audited_atoms
      has_associated_audits
      define_singleton_method(:has_audited_atoms?) { true }

      define_method(:write_audit) do |attrs|
        super(attrs)
        @audit_written = true
      end

      # save audit if only atoms has changes
      before_update do
        if !@audit_written && atoms.any? { |a| a.changed? }
          write_audit(action: "update",
                      audited_changes: {},
                      comment: audit_comment)
        end
      end

      define_method(:reconstruct_atoms) do
        self.atoms = atoms.map do |a|
          atom_audit = a.audits.reorder(placement_version: :desc, version: :desc)
                               .where("placement_version <= ?", audit_version)
                               .first

          if atom_audit.nil?
            atom = a
            atom.mark_for_destruction
            atom
          else
            atom_audit.revision
          end
        end

        # add destroyed atoms
        revived = []
        Audited::Audit.where(associated: self, auditable_type: "Folio::Atom::Base")
                      .where.not(auditable_id: atoms.ids)
                      .reorder(placement_version: :desc, version: :desc)
                      .where("placement_version <= ?", audit_version)
                      .each do |a|
          if revived.exclude?(a.auditable_id)
            association(:atoms).add_to_target(a.revision, true) if a.action != "destroy"
            revived << a.auditable_id
          end
        end

        # fixes atoms order
        define_singleton_method(:atoms) { super().sort_by(&:position) }

        self.atoms
      end
    end
  end
end
