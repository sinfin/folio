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

  def reconstruct_atoms
    data = folio_audited_atoms_data

    existing_atoms_ary = all_atoms_in_array

    if data.blank?
      existing_atoms_ary.each(&:mark_for_destruction)
      return existing_atoms_ary
    end

    new_atoms_ary = []
    handled_ids = []

    data.each do |atom_data|
      atom = atom_data["id"] && existing_atoms_ary.find { |a| a.id.to_s == atom_data["id"] }
      atom ||= Folio::Atom::Base.new

      handled_ids << atom.id if atom.id

      new_atoms_ary << atom.from_audited_data(atom_data)
    end

    existing_atoms_ary.each do |atom|
      if handled_ids.exclude?(atom.id)
        atom.mark_for_destruction
        new_atoms_ary << atom
      end
    end

    new_atoms_ary.sort do |a, b|
      if a.marked_for_destruction? && !b.marked_for_destruction?
        1
      elsif !a.marked_for_destruction? && b.marked_for_destruction?
        -1
      else
        a.position.to_i <=> b.position.to_i
      end
    end.each_with_index.map do |atom, index|
      atom.position = index + 1

      if atom.new_record?
        association(:atoms).add_to_target(atom, skip_callbacks: true)
      end

      atom
    end
  end

  def get_file_placements_attributes_for_reconstruction
    hash = {}

    keys = self.class.folio_attachment_keys

    keys[:has_one].each do |key|
      if placement = send(key)
        hash["#{key}_attributes"] = placement.to_audited_hash.merge("_destroy" => "1")
      end
    end

    keys[:has_many].each do |key|
      send(key).each do |placement|
        hash["#{key}_attributes"] ||= []
        hash["#{key}_attributes"] << placement.to_audited_hash.merge("_destroy" => "1")
      end
    end

    if folio_audited_file_placements_data.present?
      folio_audited_file_placements_data.each do |key, value_or_array|
        next if value_or_array.blank?

        if value_or_array.is_a?(Array)
          value_or_array.each do |value|
            if hash["#{key}_attributes"].present? && value["id"].present? && ref = hash["#{key}_attributes"].find { |h| h["id"] == value["id"] }
              ref = ref.merge(value)
              ref.delete("_destroy")
            else
              if value["_destroy"] != "1"
                hash["#{key}_attributes"] ||= []
                hash["#{key}_attributes"] << value
              end
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
    assign_attributes(get_file_placements_attributes_for_reconstruction)
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
