# frozen_string_literal: true

class Folio::Audited::Auditor
  def initialize(record)
    @record = record
    fail "Not an audited record" unless @record.class.respond_to?(:folio_audited_data_additional_keys)
  end

  def reconstruct
    reconstruct_atoms(@record)
    reconstruct_file_placements(@record)

    if @record.class.folio_audited_data_additional_keys.present?
      @record.class.folio_audited_data_additional_keys.each do |key|
        if self.folio_audited_data[key.to_s]
          self.folio_audited_data[key.to_s] = if respond_to?("reconstruct_#{key}")
            send("reconstruct_#{key}")
          else
            # TODO do this in a generic manner
          end
        end
      end
    end

    after_reconstruct_folio_data(@record)

    @record
  end

  def after_reconstruct_folio_data(record)
    # to be overriden
  end

  def get_folio_audited_data
    h = {}

    if @record.class.respond_to?(:atom_keys)
      h["atoms"] = get_folio_audited_data_atoms
    end

    if @record.class.try(:has_folio_attachments?)
      h["file_placements"] = get_folio_audited_data_file_placements
    end

    if @record.class.folio_audited_data_additional_keys.present?
      @record.class.folio_audited_data_additional_keys.each do |key|
        h[key.to_s] = if @record.respond_to?("#{key}_to_audited_hash")
          @record.send("#{key}_to_audited_hash")
        else
          @record.send(key).map(&:to_audited_hash)
        end
      end
    end

    h.compact
  end

  private
    def file_placements_to_audited_hash(record)
      return unless record.class.try(:has_folio_attachments?)

      h = {}

      keys = record.class.folio_attachment_keys

      keys[:has_one].each do |key|
        placement = record.send(key)
        next if placement.blank?
        next if placement.marked_for_destruction?

        ah = file_placement_to_audited_hash(placement)
        h[key.to_s] = ah if ah.present?
      end

      keys[:has_many].each do |key|
        placements = record.send(key)
        next if placements.blank?

        ary = placements.filter_map do |placement|
          next if placement.marked_for_destruction?
          file_placement_to_audited_hash(placement).presence
        end

        h[key.to_s] = ary if ary.present?
      end

      h
    end

    def atom_to_audited_hash(atom)
      {
        "id" => atom.id,
        "type" => atom.type,
        "position" => atom.position,
        "locale" => atom.locale,
        "data" => atom.data,
        "associations" => atom.associations,
        "_file_placements" => file_placements_to_audited_hash(atom),
      }
    end

    def file_placement_to_audited_hash(file_placement)
      {
        "id" => file_placement.id,
        "file_id" => file_placement.file_id,
        "position" => file_placement.position || 1,
        "type" => file_placement.type,
      }
    end

    def get_folio_audited_data_atoms
      return unless @record.class.respond_to?(:atom_keys)

      h = {}

      @record.class.atom_keys.each do |atom_key|
        h[atom_key.to_s] = @record.send(atom_key).filter_map do |atom|
          next if atom.marked_for_destruction?
          atom_to_audited_hash(atom)
        end
      end

      h
    end

    def get_folio_audited_data_file_placements
      file_placements_to_audited_hash(@record)
    end

    def get_file_placements_attributes_for_reconstruction(record:, data: nil)
      h = {}

      if record
        keys = record.class.folio_attachment_keys

        keys[:has_one].each do |key|
          if placement = record.send(key)
            h["#{key}_attributes"] = file_placement_to_audited_hash(placement).merge("_destroy" => "1")
          end
        end

        keys[:has_many].each do |key|
          record.send(key).each do |placement|
            h["#{key}_attributes"] ||= []
            h["#{key}_attributes"] << file_placement_to_audited_hash(placement).merge("_destroy" => "1")
          end
        end
      end

      if data.present?
        data.each do |key, value_or_array|
          next if value_or_array.blank?

          if value_or_array.is_a?(Array)
            value_or_array.each do |value|
              if h["#{key}_attributes"].present? && value["id"].present? && ref = h["#{key}_attributes"].find { |h| h["id"] == value["id"] }
                ref.merge!(value).delete("_destroy")
              else
                h["#{key}_attributes"] ||= []
                h["#{key}_attributes"] << value.without("id")
              end
            end
          else
            h["#{key}_attributes"] = (h["#{key}_attributes"] || {}).merge(value_or_array.without("id"))
            h["#{key}_attributes"].delete("_destroy")
          end
        end
      end

      h.each do |key, value_or_array|
        if value_or_array.is_a?(Array)
          position = -1

          value_or_array.sort_by { |hh| hh["position"].to_i }.each do |value|
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

      h
    end

    def get_atoms_attributes_for_reconstruction(record)
      h = {}
      atoms_array = []

      record.class.atom_keys.each do |key|
        h["#{key}_attributes"] = []

        record.send(key).each do |atom|
          atoms_array << atom

          ah = atom_to_audited_hash(atom)
          ah["_destroy"] = "1"

          h["#{key}_attributes"] << ah
        end
      end

      if record.try(:folio_audited_data).present? && record.folio_audited_data["atoms"].present?
        record.folio_audited_data["atoms"].each do |key, values|
          next if values.blank?

          values.each do |value|
            h["#{key}_attributes"] ||= []

            if value["id"].present? && ref = h["#{key}_attributes"].find { |h| h["id"] == value["id"] }
              ref.merge!(value).delete("_destroy")
            else
              h["#{key}_attributes"] << value.without("id")
            end
          end
        end
      end

      h.each do |key, values|
        position = -1

        h[key] = values.sort_by { |h| h["position"].to_i }.map do |value|
          if value["_destroy"] == "1"
            value.without("position", "associations", "_file_placements")
          else
            value["position"] = (position += 1)

            file_placements_data = value.delete("_file_placements")

            if file_placements_data.present?
              atom = value["id"] ? (atoms_array.find { |atom| atom.id == value["id"] }) : nil
              value.merge!(get_file_placements_attributes_for_reconstruction(record: atom,
                                                                             data: file_placements_data))
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

          value.without("_file_placements")
        end
      end

      h
    end

    def reconstruct_atoms(record)
      record.assign_attributes(get_atoms_attributes_for_reconstruction(record))

      record.class.atom_keys.each do |key|
        record.send(key).each do |atom|
          next if atom.valid?
          ah = atom_to_audited_hash(atom)
          error_messages = atom.errors.full_messages

          atom.mark_for_destruction

          replacement = record.send(key)
                              .build(atom_validation_errors: error_messages.join(". ") + ".",
                                     atom_audited_hash_json: ah.to_json,
                                     position: atom.position,
                                     type: "Folio::Atom::Audited::Invalid")

          replacement.becomes!(Folio::Atom::Audited::Invalid)
        end
      end
    end

    def reconstruct_file_placements(record)
      return unless record.try(:folio_audited_data).present? && record.folio_audited_data["file_placements"].present?

      attrs = get_file_placements_attributes_for_reconstruction(record:,
                                                                data: record.folio_audited_data["file_placements"])

      record.assign_attributes(attrs)
    end
end
