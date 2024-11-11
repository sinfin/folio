# frozen_string_literal: true

class CreateDummyBlogLocalizedArticles < ActiveRecord::Migration[7.1]
  def change
    create_table :dummy_blog_localized_articles do |t|
      t.string :title
      t.string :title_cs
      t.string :title_en
      t.string :slug
      t.string :slug_cs
      t.string :slug_en
      t.string :locale
      t.integer :site_id
      t.timestamps
    end
  end
end
