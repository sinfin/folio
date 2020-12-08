# frozen_string_literal: true

class Folio::EmailTemplate < Folio::ApplicationRecord
  extend FriendlyId

  friendly_id :slug_candidate, use: %i[slugged]

  validates :mailer, :action,
            presence: true

  validate :validate_subjects
  validate :validate_bodies

  validates :action,
            uniqueness: { scope: %i[mailer] },
            presence: true

  translates :subject, :body

  def to_label
    title.presence || "#{mailer}##{action}"
  end

  def slug_candidate
    "#{mailer.gsub('::', '_')}-#{action}"
  end

  def human_keywords
    h = {
      required: [],
      optional: [],
    }

    [
      [:optional, optional_keywords],
      [:required, required_keywords],
    ].each do |key, keywords|
      if keywords.present?
        keywords.map do |keyword|
          label = self.class.human_attribute_name("keyword/#{keyword}")
          h[key] << [label, keyword]
        end
      end
    end

    h
  end

  def self.locales
    locales = []

    column_names.each do |column_name|
      if column_name.starts_with?("subject_")
        locales << column_name.gsub("subject_", "")
      end
    end

    locales.sort
  end

  private
    def validate_subjects
      self.class.column_names.each do |column_name|
        if column_name.starts_with?("subject_")
          if send(column_name).blank?
            self.errors.add column_name, :blank
          end
        end
      end
    end

    def validate_bodies
      self.class.column_names.each do |column_name|
        if column_name.starts_with?("body_")
          value = send(column_name)

          if value.blank?
            self.errors.add column_name, :blank
          elsif required_keywords.present?
            required_keywords.each do |key|
              unless value.include?("{#{key}}")
                message = I18n.t("activerecord.attributes.folio/email_template.missing_keyword", keyword: key)
                self.errors.add column_name, :missing_keyword, message: message
              end
            end
          end
        end
      end
    end
end

# == Schema Information
#
# Table name: folio_email_templates
#
#  id                :bigint(8)        not null, primary key
#  title             :string
#  slug              :string
#  mailer            :string
#  action            :string
#  subject_en        :string
#  body_en           :text
#  required_keywords :jsonb
#  optional_keywords :jsonb
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  subject_cs        :string
#  body_cs           :text
#
# Indexes
#
#  index_folio_email_templates_on_slug  (slug)
#
