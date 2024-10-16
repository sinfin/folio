# frozen_string_literal: true

module Folio::Audited
  extend ActiveSupport::Concern

  included do
    attr_accessor :audit

    has_associated_audits

    before_update :write_audit_if_atoms_or_file_placements_changed
  end

  class_methods do
    def audited(opts = {})
      super(opts)

      define_singleton_method(:audited_console_enabled?) do
        !!opts[:console]
      end

      define_singleton_method(:audited_console_view_name) do
        opts[:console_view_name] || :show
      end

      define_singleton_method(:audited_console_restorable?) do
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

    def write_audit(attrs)
      super(attrs)
      @audit_written = true
    end

    def has_audited_file_placements?
      try(:has_folio_attachments?) || false
    end

    def has_audited_atoms?
      false
    end

    def has_audited_atoms
      define_singleton_method(:has_audited_atoms?) { true }

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
            atom = atom_audit.revision
            atom.reconstruct_file_placements
            atom
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
            atom = a.revision
            atom.reconstruct_file_placements
            association(:atoms).add_to_target(atom, skip_callbacks: true) if a.action != "destroy"
            revived << a.auditable_id
          end
        end

        # fixes atoms order
        define_singleton_method(:atoms) { super().sort_by(&:position) }

        self.atoms
      end
    end
  end

  def write_audit_if_atoms_or_file_placements_changed
    return if @audit_written

    if atoms.any? { |a| a.changed? } || try(:any_folio_attachment_changed?)
      write_audit(action: "update",
                  audited_changes: {},
                  comment: audit_comment)
    end
  end

  def reconstruct_file_placements
    keys = self.class.try(:folio_attachment_keys)
    return unless keys.present?

    keys[:has_one].each do |key|
      placement_audit = Audited::Audit.where(associated: self, auditable_type: "Folio::FilePlacement::Base")
                                      .reorder(placement_version: :desc, version: :desc)
                                      .where("placement_version <= ?", audit_version)
                                      .where(comment: key.to_s)
                                      .first

      # if key == :cover_placement
      #   require "pry"; binding.pry
      # end

      if placement_audit && placement_audit.action != "destroy"
        file_id = placement_audit.revision.file_id

        if send(key).try(:file_id) != file_id
          if file = Folio::File.find_by(id: file_id)
            if send(key).present?
              send(key).file = file
            else
              send("build_#{key}", file:)
            end
          elsif send(key).present?
            send(key).try(:mark_for_destruction)
          end
        end
      else
        send(key).try(:mark_for_destruction)
      end
    end

    keys[:has_many].each do |key|
      send(key).map do |a|
        placement_audit = a.audits
                           .reorder(placement_version: :desc, version: :desc)
                           .where("placement_version <= ?", audit_version)
                           .first

        if placement_audit.nil?
          placement = a
          placement.mark_for_destruction
          placement
        else
          placement_audit.revision
        end
      end

      # add destroyed placements
      revived = []

      Audited::Audit.where(associated: self, auditable_type: "Folio::FilePlacement::Base")
                    .where.not(auditable_id: atoms.ids)
                    .reorder(placement_version: :desc, version: :desc)
                    .where("placement_version <= ?", audit_version)
                    .where(comment: key.to_s)
                    .each do |a|
        if revived.exclude?(a.auditable_id)
          association(key).add_to_target(a.revision, skip_callbacks: true) if a.action != "destroy"
          revived << a.auditable_id
        end
      end
    end
  end
end
