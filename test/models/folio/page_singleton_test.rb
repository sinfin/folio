# frozen_string_literal: true

require "test_helper"

class Folio::PageSingletonTest < ActiveSupport::TestCase
  attr_reader :site

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

    assert FirstSingleton.create!(title: "foo", site:)

    assert_equal("foo", FirstSingleton.instance.title)
    assert FirstSingleton.instance.update!(title: "oof"), "can update"
    assert_equal("oof", FirstSingleton.instance.title, "can update")

    assert_raises(ActiveRecord::RecordInvalid) do
      FirstSingleton.create!(title: "bar", site:)
    end

    assert SecondSingleton.create!(title: "baz", site:)
    assert_raises(ActiveRecord::RecordInvalid) do
      SecondSingleton.create!(title: "bax", site:)
    end
  end

  test "cannot be destroyed" do
    assert FirstSingleton.create!(title: "foo", site: get_any_site)
    assert_raises(ActiveRecord::RecordNotDestroyed) do
      FirstSingleton.instance.destroy!
    end

    page = FirstSingleton.instance
    page.force_destroy = true
    assert page.destroy!
  end
end
