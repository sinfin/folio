# frozen_string_literal: true

class AddEmailTemplatesTranslations < ActiveRecord::Migration[6.0]
  def change
    add_column :folio_email_templates, :subject_cs, :string
    add_column :folio_email_templates, :body_cs, :text
  end
end
