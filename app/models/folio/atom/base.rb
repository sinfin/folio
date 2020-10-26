# frozen_string_literal: true

class Folio::Atom::Base < Folio::ApplicationRecord
  include Folio::Atom::MethodMissing
  include Folio::HasAttachments
  include Folio::Positionable
  include Folio::StiPreload

  KNOWN_STRUCTURE_TYPES = %i[
    string
    text
    richtext
    code
    integer
    float
    date
    datetime
    color
    boolean
  ]

  ATTACHMENTS = []

  STRUCTURE = {}

  ASSOCIATIONS = {}

  self.table_name = "folio_atoms"

  audited associated_with: :placement,
          except: [:data_for_search],
          if: :placement_has_audited_atoms?

  attr_readonly :type
  after_initialize :validate_structure

  belongs_to :placement,
             polymorphic: true,
             touch: true,
             required: true
  scope :by_type, -> (type) { where(type: type.to_s) }

  before_save :set_data_for_search

  validates :type, presence: true

  def self.cell_name
    nil
  end

  def cell_options
    nil
  end

  def partial_name
    model_name.element
  end

  def to_h
    {
      id: id,
      type: type,
      position: position,
      placement_type: placement_type,
      placement_id: placement_id,
      data: data || {},
    }.merge(attachments_to_h).merge(associations_to_h)
  end

  def attachments_to_h
    h = {}

    klass::ATTACHMENTS.each do |key|
      reflection = klass.reflections[key.to_s]
      plural = reflection.through_reflection.is_a?(ActiveRecord::Reflection::HasManyReflection)
      placement_key = klass.reflections[key.to_s].options[:through]

      if plural
        if (placements = send(placement_key)).present?
          h["#{placement_key}_attributes".to_sym] = placements.map do |placement|
            {
              id: placement.id,
              file_id: placement.file_id,
              file: Folio::Console::FileSerializer.new(placement.file)
                                                  .serializable_hash[:data],
              alt: placement.alt,
              title: placement.title,
            }
          end
        end
      else
        if (placement = send(placement_key)).present?
          h["#{placement_key}_attributes".to_sym] = {
            id: placement.id,
            file_id: placement.file_id,
            file: Folio::Console::FileSerializer.new(placement.file)
                                                .serializable_hash[:data],
            alt: placement.alt,
            title: placement.title,
          }
        end
      end
    end

    h
  end

  def associations_to_h
    h = {}

    klass::ASSOCIATIONS.keys.each do |key|
      record = send(key)
      if record
        h[key] = Folio::Atom.association_to_h(record)
      else
        h[key] = nil
      end
    end

    { associations: h }
  end

  def self.scoped_model_resource(resource)
    resource.all
  end

  def self.structure_as_safe_hash
    self::STRUCTURE.dup
  end

  def self.molecule
    nil
  end

  def self.molecule_cell_name
    molecule.try(:cell_name)
  end

  def self.molecule_singleton
    false
  end

  def self.molecule_secondary
    false
  end

  def self.attachment_placements
    self::ATTACHMENTS.map do |key|
      self.reflections[key.to_s].options[:through]
    end
  end

  def self.console_icon
  end

  def self.contentable?
    self::ATTACHMENTS.present? ||
    self::STRUCTURE.present? ||
    self::ASSOCIATIONS.present?
  end

  def self.sti_paths
    [
      Folio::Engine.root.join("app/models/folio/atom"),
      Rails.root.join("app/models/**/atom"),
    ]
  end

  # audited fix
  def self.default_ignored_attributes
    super - [inheritance_column]
  end

  private
    def klass
      # as type can be changed
      type ? self.type.constantize : self.class
    end

    def positionable_last_record
      if placement.present?
        if placement.new_record?
          placement.atoms.last
        else
          placement.reload.atoms.last
        end
      end
    end

    def validate_structure
      klass::STRUCTURE.values.each do |value|
        next if value.is_a?(Array)
        next if KNOWN_STRUCTURE_TYPES.include?(value)
        fail ArgumentError, "Unknown field type: #{value}"
      end
    end

    def set_data_for_search
      self.data_for_search = data.try(:values).try(:join, "\n").presence
    end

    def placement_has_audited_atoms?
      placement.class.try(:has_audited_atoms?)
    end
end

# == Schema Information
#
# Table name: folio_atoms
#
#  id              :bigint(8)        not null, primary key
#  type            :string
#  position        :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  placement_type  :string
#  placement_id    :bigint(8)
#  locale          :string
#  data            :jsonb
#  associations    :jsonb
#  data_for_search :text
#
# Indexes
#
#  index_folio_atoms_on_placement_type_and_placement_id  (placement_type,placement_id)
#
