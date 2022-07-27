# frozen_string_literal: true

require "test_helper"

class Folio::PageSingletonTest < ActiveSupport::TestCase
  class FirstSingleton < Folio::Page
    include Folio::Singleton
  end

  class SecondSingleton < Folio::Page
    include Folio::Singleton
  end

  test "fails when no instance is present" do
    assert_raises(Folio::Singleton::MissingError) do
      FirstSingleton.instance
    end
  end

  test "can only have one" do
    create_and_host_site

    assert FirstSingleton.create!(title: "foo")

    assert_equal("foo", FirstSingleton.instance.title)
    assert FirstSingleton.instance.update!(title: "oof"), "can update"
    assert_equal("oof", FirstSingleton.instance.title, "can update")

    assert_raises(ActiveRecord::RecordInvalid) do
      FirstSingleton.create!(title: "bar")
    end

    assert SecondSingleton.create!(title: "baz")
    assert_raises(ActiveRecord::RecordInvalid) do
      SecondSingleton.create!(title: "bax")
    end
  end

  test "cannot be destroyed" do
    assert FirstSingleton.create!(title: "foo")
    assert_raises(ActiveRecord::RecordNotDestroyed) do
      FirstSingleton.instance.destroy!
    end

    page = FirstSingleton.instance
    page.force_destroy = true
    assert page.destroy!
  end
end

# == Schema Information
#
# Table name: folio_pages
#
#  id               :integer          not null, primary key
#  site_id          :integer
#  title            :string
#  slug             :string
#  perex            :text
#  content          :text
#  meta_title       :string(512)
#  meta_description :string(1024)
#  code             :string
#  ancestry         :string
#  type             :string
#  featured         :boolean
#  position         :integer
#  published        :boolean
#  published_at     :datetime
#  original_id      :integer
#  locale           :string(6)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_folio_pages_on_ancestry      (ancestry)
#  index_folio_pages_on_code          (code)
#  index_folio_pages_on_featured      (featured)
#  index_folio_pages_on_locale        (locale)
#  index_folio_pages_on_original_id   (original_id)
#  index_folio_pages_on_position      (position)
#  index_folio_pages_on_published     (published)
#  index_folio_pages_on_published_at  (published_at)
#  index_folio_pages_on_site_id       (site_id)
#  index_folio_pages_on_slug          (slug)
#  index_folio_pages_on_type          (type)
#
