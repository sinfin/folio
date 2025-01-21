# frozen_string_literal: true

module Folio::Audited
  extend ActiveSupport::Concern

  included do
    attr_accessor :audit

    before_validation :store_folio_audited_data
  end

  class_methods do
    def audited(opts = {})
      super(opts[:on].present? ? opts : opts.merge(on: %i[create update destroy]))

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
  end

  def get_atoms_attributes_for_reconstruction
    hash = {}
    atoms_array = []

    self.class.atom_keys.each do |key|
      hash["#{key}_attributes"] = send(key).map do |atom|
        atoms_array << atom
        h = atom.to_audited_hash
        h["_destroy"] = "1"
        h
      end
    end

    if try(:folio_audited_atoms_data).present?
      folio_audited_atoms_data.each do |key, values|
        next if values.blank?

        values.each do |value|
          if hash["#{key}_attributes"].present? && value["id"].present? && ref = hash["#{key}_attributes"].find { |h| h["id"] == value["id"] }
            ref.merge!(value).delete("_destroy")
          else
            hash["#{key}_attributes"] ||= []
            hash["#{key}_attributes"] << value.without("id")
          end
        end
      end
    end

    hash.each do |key, values|
      position = 0

      hash[key] = values.sort_by { |h| h["position"].to_i }.map do |value|
        if value["_destroy"] == "1"
          value.without("position", "associations", "attachments")
        else
          value["position"] = (position += 1)

          attachments = value.delete("attachments")

          if attachments.present?
            atom = value["id"] ? (atoms_array.find { |atom| atom.id == value["id"] }) : nil
            value.merge!(get_file_placements_attributes_for_reconstruction(record: atom, data: attachments))
          end

          associations = {}

          if value["associations"].present?
            value["associations"].each do |association_key, association_hash|
              if association_hash && association_hash["id"].present? && association_hash["type"].present?
                record_klass = association_hash["type"].safe_constantize

                if record_klass && record_klass < ActiveRecord::Base
                  record = record_klass.find_by(id: association_hash["id"])

                  if record
                    associations[association_key] = association_hash
                  end
                end
              end
            end
          end

          value["associations"] = associations
        end

        value.without("attachments")
      end
    end

    hash
  end

  def reconstruct_atoms
    assign_attributes(get_atoms_attributes_for_reconstruction)

    self.class.atom_keys.each do |key|
      send(key).each do |atom|
        next if atom.valid?
        ah = atom.to_audited_hash
        error_messages = atom.errors.full_messages

        atom.mark_for_destruction

        replacement = send(key).build(atom_validation_errors: error_messages.join(". ") + ".",
                                      atom_audited_hash_json: ah.to_json,
                                      position: atom.position,
                                      type: "Folio::Atom::Audited::Invalid")

        replacement.becomes!(Folio::Atom::Audited::Invalid)
      end
    end
  end

  def get_file_placements_attributes_for_reconstruction(record:, data: nil)
    hash = {}

    if record
      keys = record.class.folio_attachment_keys

      keys[:has_one].each do |key|
        if placement = record.send(key)
          hash["#{key}_attributes"] = placement.to_audited_hash.merge("_destroy" => "1")
        end
      end

      keys[:has_many].each do |key|
        record.send(key).each do |placement|
          hash["#{key}_attributes"] ||= []
          hash["#{key}_attributes"] << placement.to_audited_hash.merge("_destroy" => "1")
        end
      end
    end

    data ||= record.try(:folio_audited_file_placements_data)

    if data.present?
      data.each do |key, value_or_array|
        next if value_or_array.blank?

        if value_or_array.is_a?(Array)
          value_or_array.each do |value|
            if hash["#{key}_attributes"].present? && value["id"].present? && ref = hash["#{key}_attributes"].find { |h| h["id"] == value["id"] }
              ref.merge!(value).delete("_destroy")
            else
              hash["#{key}_attributes"] ||= []
              hash["#{key}_attributes"] << value.without("id")
            end
          end
        else
          hash["#{key}_attributes"] = (hash["#{key}_attributes"] || {}).merge(value_or_array.without("id"))
          hash["#{key}_attributes"].delete("_destroy")
        end
      end
    end

    hash.each do |key, value_or_array|
      if value_or_array.is_a?(Array)
        position = 0

        value_or_array.sort_by { |h| h["position"].to_i }.each do |value|
          if value["_destroy"] == "1"
            value.delete("position")
          else
            value["position"] = (position += 1)
          end
        end
      else
        if value_or_array["_destroy"] != "1"
          value_or_array["position"] = 1
        end
      end
    end

    hash
  end

  def reconstruct_file_placements
    assign_attributes(get_file_placements_attributes_for_reconstruction(record: self))
  end

  private
    def store_folio_audited_data
      if respond_to?(:folio_audited_atoms_data) && respond_to?(:atoms_to_audited_hash)
        self.folio_audited_atoms_data = atoms_to_audited_hash
      end

      if respond_to?(:folio_audited_file_placements_data) && respond_to?(:folio_attachments_to_audited_hash)
        self.folio_audited_file_placements_data = folio_attachments_to_audited_hash
      end
    end
end
