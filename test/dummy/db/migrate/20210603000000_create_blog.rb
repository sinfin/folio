# frozen_string_literal: true

class CreateBlog < ActiveRecord::Migration[6.0]
  def change
    create_table :dummy_blog_articles do |t|
      t.string :title
      t.string :slug
      t.text :perex

      t.string :locale, default: I18n.default_locale

      t.string :meta_title
      t.text :meta_description

      t.boolean :featured
      t.boolean :published
      t.datetime :published_at

      t.belongs_to :primary_category

      t.timestamps
    end

    add_index :dummy_blog_articles, :slug
    add_index :dummy_blog_articles, :locale
    add_index :dummy_blog_articles, :featured
    add_index :dummy_blog_articles, :published
    add_index :dummy_blog_articles, :published_at

    create_table :dummy_blog_categories do |t|
      t.string :title
      t.string :slug
      t.text :perex

      t.string :locale, default: I18n.default_locale

      t.boolean :published
      t.boolean :featured

      t.integer :articles_count, default: 0

      t.integer :position

      t.string :meta_title
      t.text :meta_description

      t.timestamps
    end

    add_index :dummy_blog_categories, :slug
    add_index :dummy_blog_categories, :locale
    add_index :dummy_blog_categories, :featured
    add_index :dummy_blog_categories, :published
    add_index :dummy_blog_categories, :position

    create_table :dummy_blog_category_article_links do |t|
      t.belongs_to :dummy_blog_category, index: { name: :dummy_blog_category_article_links_c_id }
      t.belongs_to :dummy_blog_article, index: { name: :dummy_blog_category_article_links_a_id }

      t.integer :position

      t.timestamps
    end
  end
end
