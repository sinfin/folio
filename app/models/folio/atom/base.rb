# frozen_string_literal: true

class Folio::Atom::Base < Folio::ApplicationRecord
  include Folio::HasAttachments
  include Folio::Positionable

  STRUCTURE = {
    title: :string,
  }

  self.table_name = 'folio_atoms'

  after_save :unlink_extra_files, if: :saved_change_to_type?

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
    }
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

  private

    def klass
      # as type can be changed
      self.type.constantize
    end

    def unlink_extra_files
      if klass::STRUCTURE[:cover].nil?
        self.cover_placement.destroy! if cover_placement.present?
      end

      if klass::STRUCTURE[:images].nil?
        if image_placements.exists?
          self.image_placements.each(&:destroy!)
        end
      end

      if klass::STRUCTURE[:documents].nil?
        if document_placements.exists?
          if klass::STRUCTURE[:document].nil?
            self.document_placements.each(&:destroy!)
          else
            self.document_placements.offset(1).each(&:destroy!)
          end
        end
      end
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
#  model_type     :string
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
