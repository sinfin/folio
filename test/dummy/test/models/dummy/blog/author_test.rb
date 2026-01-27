# frozen_string_literal: true

require Folio::Engine.root.join("test/test_helper")

class Dummy::Blog::AuthorTest < ActiveSupport::TestCase
  test "cannot change locale with offending articles" do
    author = create(:dummy_blog_author, locale: "cs")
    create(:dummy_blog_article, locale: "cs", authors: [author])

    author.locale = "en"
    assert_not author.valid?
    assert author.errors[:locale]
  end

  test "cannot change site with offending articles" do
    site = create_and_host_site
    site_2 = create_site(force: true)

    author = create(:dummy_blog_author, site:)
    create(:dummy_blog_article, authors: [author], site:)

    author.site = site_2
    assert_not author.valid?
    assert author.errors[:site]
  end

  test "validate_name_uniqueness" do
    create(:dummy_blog_author, first_name: "John", last_name: "Doe", locale: "cs")

    author = build(:dummy_blog_author, first_name: "John", last_name: "Doe", locale: "cs")
    assert_not author.valid?
    assert author.errors[:first_name]

    assert create(:dummy_blog_author, last_name: "Doe", locale: "cs")
    author = build(:dummy_blog_author, last_name: "Doe", locale: "cs")
    assert_not author.valid?
    assert author.errors[:last_name]
  end
end
