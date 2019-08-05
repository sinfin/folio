# frozen_string_literal: true

class Folio::Atom::Base < Folio::ApplicationRecord
  include Folio::HasAttachments
  include Folio::Positionable

  KNOWN_STRUCTURE_TYPES = %i[
    string
    text
    richtext
    code
    integer
    float
    date
    datetime
  ]

  ATTACHMENTS = []

  STRUCTURE = {
    title: :string,
  }

  self.table_name = 'folio_atoms'

  attr_readonly :type
  after_initialize :validate_structure

  belongs_to :placement,
             polymorphic: true,
             touch: true,
             required: true

  scope :by_type, -> (type) { where(type: type.to_s) }

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
    }.merge(attachments_to_h)
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
              file: placement.file.to_h,
              alt: placement.alt,
              title: placement.title,
            }
          end
        end
      else
        if (placement = send(placement_key)).present?
          h["#{placement_key}_attributes".to_sym] = {
            file_id: placement.file_id,
            file: placement.file.to_h,
            alt: placement.alt,
            title: placement.title,
          }
        end
      end
    end

    h
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

  def self.form_hints
    prefix = "simple_form.hints.#{name.underscore}"
    {
      title: I18n.t("#{prefix}.title", default: nil),
      perex: I18n.t("#{prefix}.perex", default: nil),
      content: I18n.t("#{prefix}.content", default: nil),
    }
  end

  def self.form_placeholders
    {
      title: self.human_attribute_name(:title),
      perex: self.human_attribute_name(:perex),
      content: self.human_attribute_name(:content),
    }
  end

  def self.attachment_placements
    self::ATTACHMENTS.map do |key|
      self.reflections[key.to_s].options[:through]
    end
  end

  def self.console_icon
  end

  def method_missing(method_name, *arguments, &block)
    name_without_operator = method_name.to_s.gsub('=', '').to_sym
    if respond_to_missing?(name_without_operator)
      if method_name.to_s.include?('=')
        self.data ||= {}
        self.data[name_without_operator.to_s] = arguments[0]
      else
        (self.data || {})[name_without_operator.to_s]
      end
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    name_without_operator = method_name.to_s.gsub('=', '').to_sym
    klass::STRUCTURE.keys.include?(name_without_operator) || super
  end

  def model(key, includes = nil)
    delim = Folio::Console::BaseController::TYPE_ID_DELIMITER
    class_name, id = data[key.to_s].split(delim)
    scope = class_name.constantize
    if includes
      scope = scope.includes(includes)
    end
    scope.find_by(id: id)
  end

  private

    def klass
      # as type can be changed
      self.type.constantize
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
#
# Indexes
#
#  index_folio_atoms_on_placement_type_and_placement_id  (placement_type,placement_id)
#

if Rails.env.development?
  Dir[
    Folio::Engine.root.join('app/models/folio/atom/**/*.rb'),
    Rails.root.join('app/models/**/atom/**/*.rb')
  ].each do |file|
    require_dependency file
  end
end
