# frozen_string_literal: true

class Folio::MenuItem < Folio::ApplicationRecord
  attribute :unique_id, :string
  attribute :parent_unique_id, :string

  # Relations
  has_ancestry orphan_strategy: :adopt, touch: true
  belongs_to :menu, touch: true, required: true
  belongs_to :target, optional: true, polymorphic: true

  belongs_to :page, class_name: "Folio::Page",
                    optional: true,
                    foreign_key: :folio_page_id

  # Scopes
  scope :ordered, -> { order(position: :asc) }

  # Validations
  validate :validate_menu_available_targets_and_paths
  validate :validate_style

  before_validation :nullify_empty_rails_path
  before_validation :set_specific_relations

  def to_label
    return title if title.present?
    return target.try(:title) || target.try(:to_label) if target.present?
    return menu.class.rails_paths[rails_path.to_sym] if rails_path.present?
    self.class.model_name.human
  end

  def to_h
    {
      id: id,
      position: position,
      rails_path: rails_path,
      target_id: target_id,
      target_type: target_type,
      title: title,
      url: url,
      open_in_new: open_in_new,
      style: style,
    }
  end

  def self.class_names
    {
      "Folio::Page" => "folio_page_id",
    }
  end

  private
    def validate_menu_available_targets_and_paths
      if target && menu.available_targets.map { |t| [t.id, t.class.name] }.exclude?([target.id, target.class.name])
        errors.add(:target, :invalid)
      end
      if rails_path && menu.class.rails_paths.keys.exclude?(rails_path.to_sym)
        errors.add(:rails_path, :invalid)
      end
    end

    def validate_style
      if style.present? && menu.class.styles.exclude?(style)
        errors.add(:style, :invalid)
      end
    end

    def nullify_empty_rails_path
      if rails_path.is_a?(String) && rails_path.blank?
        self.rails_path = nil
      end
    end

    def set_specific_relations
      self.class.class_names.each do |class_name, key|
        self.send("#{key}=", nil)
      end

      if target_type.present? && target_id.present? && self.class.class_names[target_type]
        key = self.class.class_names[target_type]
        self.send("#{key}=", target_id)
      end
    end
end

# == Schema Information
#
# Table name: folio_menu_items
#
#  id            :bigint(8)        not null, primary key
#  menu_id       :bigint(8)
#  ancestry      :string
#  title         :string
#  rails_path    :string
#  position      :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  target_type   :string
#  target_id     :bigint(8)
#  url           :string
#  open_in_new   :boolean
#  style         :string
#  folio_page_id :integer
#
# Indexes
#
#  index_folio_menu_items_on_ancestry                   (ancestry)
#  index_folio_menu_items_on_menu_id                    (menu_id)
#  index_folio_menu_items_on_target_type_and_target_id  (target_type,target_id)
#
