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
    url
  ]

  ATTACHMENTS = []

  STRUCTURE = {}

  ASSOCIATIONS = {}

  VALID_PLACEMENT_TYPES = nil

  VALID_SITE_TYPES = nil

  MOLECULE = false

  FORM_LAYOUT = {
    rows: [
      "ATTACHMENTS",
      "ASSOCIATIONS",
      "STRUCTURE",
    ]
  }

  CONSOLE_INSERT_ROWS = {
    primary: 1,
    contents: 2,
    cards: 3,
    images: 4,
    forms: 5,
    embeds: 6,
    listings: 7,
    default: 10,
  }

  self.table_name = "folio_atoms"

  audited associated_with: :placement,
          if: :placement_has_audited_atoms?

  after_initialize :validate_structure

  belongs_to :placement,
             polymorphic: true,
             touch: true,
             required: true
  scope :by_type, -> (type) { where(type: type.to_s) }

  validates :type, presence: true
  validate :validate_placement

  def self.cell_name
  end

  def self.component_class
    if cell_name.nil?
      "#{self}Component".constantize
    end
  end

  def self.molecule_component_class
    if self::MOLECULE && molecule_cell_name.nil?
      "#{self}Component".gsub("::Atom::", "::Molecule::").constantize
    end
  end

  def self.splittable_by_attribute
  end

  def cell_options
  end

  def partial_name
    model_name.element
  end

  def to_h
    {
      id:,
      type:,
      position:,
      placement_type:,
      placement_id:,
      data: data_to_h,
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

  def data_to_h
    if data.present?
      h = data.dup

      klass::STRUCTURE.each do |key, value|
        if value == :date || value == :datetime
          if h[key.to_s].present?
            date_or_datetime = try(key)
            if date_or_datetime.present?
              if value == :datetime
                date_or_datetime = date_or_datetime.to_datetime
              elsif value == :date
                date_or_datetime = date_or_datetime.to_date
              end

              h[key.to_s] = I18n.l(date_or_datetime, format: :console_short)
            else
              h.delete(key.to_s)
            end
          end
        end
      end

      h
    else
      {}
    end
  end

  def valid_for_placement?(placement)
    if placement.class.atom_class_names_whitelist.present?
      if placement.class.atom_class_names_whitelist.exclude?(type)
        return false
      end
    end

    if self.class::VALID_PLACEMENT_TYPES.present?
      if self.class::VALID_PLACEMENT_TYPES.none? { |type| placement.is_a?(type.constantize) }
        return false
      end
    end

    true
  end

  def self.valid_for_placement_class?(placement_class)
    if self::VALID_PLACEMENT_TYPES.present?
      if self::VALID_PLACEMENT_TYPES.none? { |type| placement_class <= type.constantize }
        return false
      end
    end

    true
  end

  def self.valid_for_site_class?(site_klass)
    if self::VALID_SITE_TYPES.present?
      if self::VALID_SITE_TYPES.none? { |type| site_klass <= type.constantize }
        return false
      end
    end

    true
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

  def self.console_insert_row
    CONSOLE_INSERT_ROWS[:default]
  end

  def self.contentable?
    self::ATTACHMENTS.present? ||
    self::STRUCTURE.present? ||
    self::ASSOCIATIONS.present?
  end

  def self.molecule?
    self::MOLECULE || !molecule_cell_name.nil? || !molecule_component_class.nil?
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

  def self.default_atom_values
    # { STRUCTURE_KEY => value }
    # i.e. { content: "<p>hello</p>" }
    {}
  end

  def data_for_search
    data.try(:values).try(:join, "\n").presence
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

    def placement_has_audited_atoms?
      placement.class.try(:has_audited_atoms?)
    end

    def validate_placement
      unless valid_for_placement?(placement)
        errors.add(:placement, :invalid)
      end

      if self.class::VALID_SITE_TYPES.present? && placement.present? && placement.class.try(:has_belongs_to_site?)
        if placement.site && !self.class.valid_for_site_class?(placement.site.class)
          errors.add(:placement, :invalid)
        end
      end
    end
end

# == Schema Information
#
# Table name: folio_atoms
#
#  id             :bigint(8)        not null, primary key
#  type           :string
#  position       :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  placement_type :string
#  placement_id   :bigint(8)
#  locale         :string
#  data           :jsonb
#  associations   :jsonb
#
# Indexes
#
#  index_folio_atoms_on_placement_type_and_placement_id  (placement_type,placement_id)
#
