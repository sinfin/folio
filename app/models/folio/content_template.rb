# frozen_string_literal: true

class Folio::ContentTemplate < Folio::ApplicationRecord
  include Folio::Positionable

  validates :type,
            presence: true

  if Rails.application.config.folio_using_traco
    I18n.available_locales.each do |locale|
      validates "content_#{locale}".to_sym,
                presence: true
    end
  else
    validates :content,
              presence: true
  end
end

# == Schema Information
#
# Table name: folio_content_templates
#
#  id         :bigint(8)        not null, primary key
#  content    :text
#  position   :integer
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_folio_content_templates_on_position  (position)
#  index_folio_content_templates_on_type      (type)
#
