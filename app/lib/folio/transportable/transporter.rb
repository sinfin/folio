# frozen_string_literal: true

class Folio::Transportable::Transporter
  def initialize(record)
    unless record.class.base_class.try(:transportable?) &&
           record.try(:transportable?)
      fail StandardError, "Non-transportable record"
    end

    @record = record
  end

  def to_hash
    {
      class_name: @record.class.base_class.to_s,
      id: @record.id,
      attributes: attributes_hash,
      associations: @record.transportable_associations,
      atoms: atoms_hash,
      attachments: attachments_hash(@record),
    }
  end

  def to_yaml
    to_hash.deep_stringify_keys.to_yaml
  end

  private
    def atoms_hash
      if @record.respond_to?(:atoms_locale)
        h = {}

        @record.atoms_locale.each do |locale|
          h[locale] = atoms_from_collection(@record.atoms(locale))
        end

        h
      elsif @record.respond_to?(:atoms)
        atoms_from_collection(@record.atoms)
      end
    end

    def atoms_from_collection(atoms)
      atoms.each_with_index.map do |atom, i|
        {
          type: atom.type,
          position: i + 1,
          locale: atom.locale,
          data: atom.data,
          associations: atom.associations,
          attachments: attachments_hash(atom)
        }
      end
    end

    def attachments_hash(record)
      if record.respond_to?(:file_placements)
        h = {}

        record.file_placements.each do |fp|
          h[fp.class] ||= []
          h[fp.class] << {
            file_id: fp.file_id,
            file_source: fp.file.file.remote_url,
            file_type: fp.file.type,
            file_attributes: {
              author: fp.file.author,
              description: fp.file.description,
            },
            alt: fp.alt,
            title: fp.title,
          }
        end

        h
      end
    end

    def attributes_hash
      h = {}

      @record.transportable_attributes.each do |attr|
        val = @record.send(attr).presence

        if val.is_a?(Date) || val.is_a?(DateTime) || val.is_a?(Time)
          val = val.iso8601
        end

        h[attr] = val
      end

      h
    end
end
