# frozen_string_literal: true

module Folio::ContentTemplateFormMock
  extend ActiveSupport::Concern

  included do
    # mock for simple_fields_for
    has_many :content_templates, class_name: 'Folio::ContentTemplate',
                                 foreign_key: :id
    accepts_nested_attributes_for :content_templates
  end
end

class Folio::ContentTemplate < Folio::ApplicationRecord
  include Folio::Positionable
  include Folio::ContentTemplateFormMock

  self.table_name = 'folio_content_templates'

  validates :type,
            presence: true
end

if Rails.env.development?
  Dir[
    Folio::Engine.root.join('app/models/folio/content_template/**/*.rb'),
    Rails.root.join('app/models/**/content_template/**/*.rb'),
  ].each do |file|
    require_dependency file
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
