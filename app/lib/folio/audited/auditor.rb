# frozen_string_literal: true

class Folio::Audited::Auditor
  def initialize(record:, audit: nil)
    @record = record
    fail "Not an audited record" unless @record.class.respond_to?(:folio_audited_data_additional_keys)

    @audit = audit
  end

  def reconstruct
    fail "Need a Folio::Audited::Audit to reconstruct" unless @audit.is_a?(Folio::Audited::Audit)

    reconstruct_atoms(record: @record, audit: @audit)
    reconstruct_file_placements(record: @record, audit: @audit)

    if @record.class.folio_audited_data_additional_keys.present?
      @record.class.folio_audited_data_additional_keys.each do |key|
        if @audit.folio_data && @audit.folio_data[key.to_s]
          @audit.folio_data[key.to_s] = if respond_to?("reconstruct_#{key}")
            send("reconstruct_#{key}", @audit)
          else
            reconstruct_related_records(key: key.to_s, record: @record, audit: @audit)
          end
        end
      end
    end

    after_reconstruct_folio_audited_data(record: @record, audit: @record)

    @record
  end

  def after_reconstruct_folio_audited_data(record:, audit:)
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
          @record.send(key).map do |related_record|
            related_record_to_audited_hash(related_record)
          end
        end
      end
    end

    h.compact
  end

  def get_folio_audited_changed_relations
    ary = []

    if @record.class.respond_to?(:atom_keys)
      @record.class.atom_keys.each do |atom_key|
        if @record.send(atom_key).any? { |atom| atom.changed? || atom.marked_for_destruction? }
          ary << "atoms"
        end
      end
    end

    if @record.class.try(:has_folio_attachments?)
      keys = @record.class.folio_attachment_keys

      if keys[:has_one].any? { |key| fp = @record.send(key); fp && (fp.changed? || fp.marked_for_destruction?) } ||
         keys[:has_many].any? { |key| @record.send(key).any? { |fp| fp.changed? || fp.marked_for_destruction? } }
        ary << "file_placements"
      end
    end

    if @record.class.folio_audited_data_additional_keys.present?
      @record.class.folio_audited_data_additional_keys.each do |key|
        collection_or_record = @record.send(key)

        # TODO: rm the bellow block after fixin g
        if @record.persisted? && key == :site_user_links
          # collection_or_record.first.changed? is false even though the roles changed!
          puts collection_or_record.first
          binding.pry
        end
        # TODO: rm the above block after fixing

        if collection_or_record.is_a?(ActiveRecord::Relation)
          if collection_or_record.any? { |r| r.changed? || r.marked_for_destruction? }
            ary << key.to_s
          end
        else
          if collection_or_record.changed? || collection_or_record.marked_for_destruction?
            ary << key.to_s
          end
        end
      end
    end

    ary
  end

  def fill_ids_to_folio_data(folio_data:)
    changed = false
    runner = folio_data.deep_dup

    get_folio_audited_data.each do |root_key, root_value|
      next if runner[root_key].blank?

      if %w[atoms file_placements].include?(root_key)
        # root_value is a folio-specific Hash
        # such as { "atoms" => { "cs_atoms" => [] } }
        # or { "file_placements" => { "cover_placement" => { "id" => 1, "file_id" => 1 } } }
        root_value.each do |subroot_key, value_or_array|
          next if runner[root_key][subroot_key].blank?

          if value_or_array.is_a?(Array)
            next unless runner[root_key][subroot_key].is_a?(Array)

            value_or_array.each_with_index do |value, index|
              next if runner[root_key][subroot_key][index].blank?
              next unless folio_data_hashes_equal_apart_from_ids(one: value, two: runner[root_key][subroot_key][index])

              runner[root_key][subroot_key][index] = value
              changed = true
            end
          else
            next unless runner[root_key][subroot_key].is_a?(Hash)
            next if runner[root_key][subroot_key].blank?
            next unless folio_data_hashes_equal_apart_from_ids(one: value_or_array, two: runner[root_key][subroot_key])

            runner[root_key][subroot_key] = value_or_array
            changed = true
          end
        end
      else
        # root_value is an array of related records
        root_value.each_with_index do |value, index|
          next if runner[root_key][index].blank?
          next unless folio_data_hashes_equal_apart_from_ids(one: value, two: runner[root_key][index])

          runner[root_key][index] = value
          changed = true
        end
      end
    end

    { changed:, folio_data: runner }
  end

  private
    def file_placements_to_audited_hash(record:)
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

    def related_record_to_audited_hash(related_record)
      without = %w[created_at updated_at]

      related_record.class.column_names.each do |column_name|
        without << column_name if column_name.ends_with?("_id")
      end

      h = related_record.attributes.without(*without)

      if related_record.class.try(:has_folio_attachments?)
        h["_file_placements"] = file_placements_to_audited_hash(record: related_record)
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
        "_file_placements" => file_placements_to_audited_hash(record: atom),
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
      file_placements_to_audited_hash(record: @record)
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
          position = 0

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

    def get_atoms_attributes_for_reconstruction(record:, audit:)
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

      if audit.folio_data && audit.folio_data["atoms"].present?
        audit.folio_data["atoms"].each do |key, values|
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
        position = 0

        h[key] = values.sort_by { |h| h["position"].to_i }.map do |value|
          if value["_destroy"] == "1"
            value.without("position", "associations", "_file_placements")
          else
            value["position"] = (position += 1)

            file_placements_data = value.delete("_file_placements")

            atom = value["id"] ? (atoms_array.find { |atom| atom.id == value["id"] }) : nil
            value.merge!(get_file_placements_attributes_for_reconstruction(record: atom,
                                                                           data: file_placements_data))

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

    def get_related_records_attributes_for_reconstruction(key:, record:, audit:)
      records_ary = []
      nested_attributes = []

      record.send(key).each do |related_record|
        records_ary << related_record

        ah = related_record_to_audited_hash(related_record)
        ah["_destroy"] = "1"

        nested_attributes << ah
      end

      if audit.folio_data && audit.folio_data[key].present?
        audit.folio_data[key].each do |value|
          if value["id"].present? && ref = nested_attributes.find { |h| h["id"] == value["id"] }
            ref.merge!(value).delete("_destroy")
          else
            nested_attributes << value.without("id")
          end
        end
      end

      handle_position = nested_attributes.any? { |h| h["position"].present? }
      position = 0

      if handle_position
        nested_attributes.sort_by! { |h| h["position"].to_i }
      end

      nested_attributes.map! do |value|
        if value["_destroy"] == "1"
          value.without("position", "associations", "_file_placements")
        else
          value["position"] = (position += 1) if handle_position

          file_placements_data = value.delete("_file_placements")

          related_record = value["id"] ? (records_ary.find { |related_record| related_record.id == value["id"] }) : nil
          value.merge!(get_file_placements_attributes_for_reconstruction(record: related_record,
                                                                         data: file_placements_data))
        end

        value.without("_file_placements")
      end

      { "#{key}_attributes" => nested_attributes }
    end

    def reconstruct_atoms(record:, audit:)
      record.assign_attributes(get_atoms_attributes_for_reconstruction(record:, audit:))

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

    def reconstruct_file_placements(record:, audit:)
      attrs = get_file_placements_attributes_for_reconstruction(record:,
                                                                data: audit.folio_data && audit.folio_data["file_placements"])

      record.assign_attributes(attrs)
    end

    def reconstruct_related_records(key:, record:, audit:)
      record.assign_attributes(get_related_records_attributes_for_reconstruction(key:, record:, audit:))
    end

    def strip_ids_from_folio_data_hash(folio_data_hash)
      runner = folio_data_hash.without("id")

      if runner["_file_placements"].present?
        runner["_file_placements"].each do |key, value|
          runner["_file_placements"][key] = if value.is_a?(Array)
            value.map do |h|
              h.without("id")
            end
          else
            value.without("id")
          end
        end
      end

      runner
    end

    def folio_data_hashes_equal_apart_from_ids(one:, two:)
      strip_ids_from_folio_data_hash(one.deep_dup) == strip_ids_from_folio_data_hash(two.deep_dup)
    end
end
