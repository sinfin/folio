# frozen_string_literal: true

class Folio::EmailTemplate < Folio::ApplicationRecord
  include Folio::BelongsToSite
  include Folio::FriendlyId

  validates :mailer, :action,
            presence: true

  validate :validate_subjects
  validate :validate_bodies

  validates :action,
            uniqueness: { scope: %i[mailer site_id] },
            presence: true

  scope :ordered, -> { order(:title) }

  translates :subject, :body

  def self.load_templates_from_yaml(file_path)
    return false unless File.exist?(file_path)

    records = YAML.load_file(file_path)
    return 0 unless records

    Folio::Site.find_each do |site|
      records.each do |raw|
        msg_action = "Adding"

        next if raw["site_class"] && raw["site_class"] != site.class.to_s

        find_by = { mailer: raw["mailer"], action: raw["action"], site: }

        if em = Folio::EmailTemplate.find_by(find_by)
          if raw["destroy"]
            msg_action = "Destroying"
            em.destroy!
          elsif ENV["FORCE"]
            msg_action = "Overwriting (FORCE=1)"
            em.destroy!
          else
            unless Rails.env.test?
              puts "Skipping existing email template for #{raw["mailer"]}##{raw["action"]} for site #{site.to_label}"
            end
            next
          end
        end

        unless Rails.env.test?
          puts "#{msg_action} email template for #{raw["mailer"]}##{raw["action"]} for site #{site.to_label}"
        end

        next if raw["destroy"]

        data = raw.slice(*Folio::EmailTemplate.column_names)

        default_locale = Rails.application.config.folio_console_locale
        data["title"] = raw["title_#{default_locale}"].presence
        data["title"] ||= data["title_en"]
        data["site"] = site

        Folio::EmailTemplate.create!(data)
      end
    end
    records.size
  end

  def to_label
    title.presence || "#{mailer}##{action}"
  end

  def slug_candidates
    if site && site.slug
      "#{mailer.gsub('::', '_')}-#{action}-#{site.slug}"
    else
      "#{mailer.gsub('::', '_')}-#{action}"
    end
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
        keywords.sort.map do |keyword|
          label = self.class.human_attribute_name("keyword/#{keyword}")
          h[key] << [label, keyword]
        end
      end
    end

    h
  end

  def render_html(data, locale: nil)
    locale ||= I18n.default_locale
    render_string(send("body_html_#{locale}"), data)
  end

  def render_text(data, locale: nil)
    locale ||= I18n.default_locale
    render_string(send("body_text_#{locale}"), data)
  end

  def render_subject(data, locale: nil)
    locale ||= I18n.default_locale
    render_string(send("subject_#{locale}"), data)
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
                self.errors.add column_name, :missing_keyword, message:
              end
            end
          end
        end
      end
    end

    def render_string(str, data)
      result = str

      data.each do |keyword, value|
        # strip extra redactor js <p></p>
        if keyword.ends_with?("_HTML")
          result = result.gsub("<p>{#{keyword}}</p>", value.to_s)
        end

        result = result.gsub("{#{keyword}}", value.to_s)
      end

      result
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
#  body_html_en      :text
#  body_text_en      :text
#  required_keywords :jsonb
#  optional_keywords :jsonb
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  subject_cs        :string
#  body_html_cs      :text
#  body_text_cs      :text
#  site_id           :bigint(8)
#
# Indexes
#
#  index_folio_email_templates_on_site_id  (site_id)
#  index_folio_email_templates_on_slug     (slug)
#
