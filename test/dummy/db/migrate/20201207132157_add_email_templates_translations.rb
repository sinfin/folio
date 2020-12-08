# frozen_string_literal: true

class AddEmailTemplatesTranslations < ActiveRecord::Migration[6.0]
  def change
    add_column :folio_email_templates, :subject_cs, :string
    add_column :folio_email_templates, :body_html_cs, :text
    add_column :folio_email_templates, :body_text_cs, :text
  end
end
