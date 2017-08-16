# frozen_string_literal: true

class Folio::NodeTranslation < Folio::Node
  # Relations
  belongs_to :node_original, class_name: 'Folio::Node', foreign_key: :original_id

  # Validations
  validates :locale, uniqueness: { scope: [:original_id] }

  # Scopes
  delegate :original, to: :node_original
  delegate :translations, to: :node_original

  # Casting ActiveRecord class to an original Node class
  def cast
    self.becomes(node_original.class)
  end

  def translate(locale)
    case locale
    when locale == self.locale
      cast
    when node_original.node_translations.where(locale: locale).exists?
      self.node_translations.find_by(locale: locale).cast
    else
      node_original.cast
    end
  end
end
