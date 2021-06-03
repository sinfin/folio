# frozen_string_literal: true

class CreateBlog < ActiveRecord::Migration[6.0]
  def change
    create_table :dummy_blog_articles do |t|
      t.string :title
      t.string :slug
      t.text :perex

      t.string :locale, default: "en"

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

      t.string :locale, default: "en"

      t.boolean :published
      t.boolean :featured

      t.integer :articles_count

      t.string :meta_title
      t.text :meta_description

      t.timestamps
    end

    add_index :dummy_blog_categories, :slug
    add_index :dummy_blog_categories, :locale
    add_index :dummy_blog_categories, :featured
    add_index :dummy_blog_categories, :published

    create_join_table :dummy_blog_categories, :dummy_blog_articles do |t|
      t.index :dummy_blog_category_id, name: :index_blog_articles_categories_on_blog_category_id
      t.index :dummy_blog_article_id, name: :index_blog_articles_categories_on_blog_article_id
    end
  end
end
