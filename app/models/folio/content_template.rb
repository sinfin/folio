# frozen_string_literal: true

module Folio::ContentTemplateFormMock
  extend ActiveSupport::Concern

  included do
    # mock for simple_fields_for
    has_many :content_templates, class_name: "Folio::ContentTemplate",
                                 foreign_key: :id
    accepts_nested_attributes_for :content_templates
  end
end

class Folio::ContentTemplate < Folio::ApplicationRecord
  include Folio::InheritenceBaseNaming
  include Folio::Positionable
  include Folio::ContentTemplateFormMock
  include Folio::StiPreload

  self.table_name = "folio_content_templates"

  validates :type,
            presence: true

  def base_class
    Folio::ContentTemplate
  end

  def to_label
    title.presence || content
  end

  def self.to_data_attribute
    if Rails.application.config.folio_using_traco
      ordered.map do |ct|
        {
          label: ct.to_label,
          contents: I18n.available_locales.map do |locale|
            ct.send("content_#{locale}")
          end
        }
      end.to_json
    else
      ordered.map do |ct|
        {
          label: ct.to_label,
          contents: [ct.content],
        }
      end.to_json
    end
  end

  def self.sti_paths
    [
      Folio::Engine.root.join("app/models/folio/content_template"),
      Rails.root.join("app/models/**/content_template"),
    ]
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
#  title      :string
#
# Indexes
#
#  index_folio_content_templates_on_position  (position)
#  index_folio_content_templates_on_type      (type)
#
