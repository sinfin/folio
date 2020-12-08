# frozen_string_literal: true

class CreateFolioEmailTemplates < ActiveRecord::Migration[6.0]
  def change
    create_table :folio_email_templates do |t|
      t.string :title
      t.string :slug, index: true

      t.string :mailer
      t.string :action

      t.string :subject_en
      t.text :body_html_en
      t.text :body_text_en

      t.jsonb :required_keywords
      t.jsonb :optional_keywords

      t.timestamps
    end
  end
end
