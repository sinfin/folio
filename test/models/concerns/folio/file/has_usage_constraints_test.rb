# frozen_string_literal: true

require "test_helper"

class Folio::File::HasUsageConstraintsTest < ActiveSupport::TestCase
  def setup
    @site = create_and_host_site
  end

  # usable / true, shared OFF
  test "by_usage_constraints 'usable' without sharing filters by usage limit only" do
    with_sharing(false) do
      allowed_no_limit = img(attribution_max_usage_count: nil, published_usage_count: 0)
      allowed_below = img(attribution_max_usage_count: 10, published_usage_count: 5)
      denied_at_limit = img(attribution_max_usage_count: 10, published_usage_count: 10)

      results = Folio::File::Image.by_usage_constraints("usable")
      assert_includes results, allowed_no_limit
      assert_includes results, allowed_below
      assert_not_includes results, denied_at_limit
    end
  end

  test "by_usage_constraints 'true' acts as alias for 'usable'" do
    with_sharing(false) do
      allowed = img(attribution_max_usage_count: 2, published_usage_count: 1)
      denied = img(attribution_max_usage_count: 2, published_usage_count: 2)

      results = Folio::File::Image.by_usage_constraints("true")
      assert_includes results, allowed
      assert_not_includes results, denied
    end
  end

  # usable, shared ON
  test "by_usage_constraints 'usable' with sharing requires within limit and allowed or unrestricted site" do
    with_sharing(true) do
      other_site = create_site(force: true)

      allowed_no_links = img(attribution_max_usage_count: 10, published_usage_count: 1)
      allowed_current_site = link_to_site(img(attribution_max_usage_count: 10, published_usage_count: 1), @site)
      denied_other_site_only = link_to_site(img(attribution_max_usage_count: 10, published_usage_count: 1), other_site)
      denied_over_limit = link_to_site(img(attribution_max_usage_count: 1, published_usage_count: 1), @site)

      results = Folio::File::Image.by_usage_constraints("usable")
      assert_includes results, allowed_no_links
      assert_includes results, allowed_current_site
      assert_not_includes results, denied_other_site_only
      assert_not_includes results, denied_over_limit
    end
  end

  test "by_usage_constraints with sharing stays SQL-backed" do
    with_sharing(true) do
      sql = Folio::File::Image.by_usage_constraints("usable").to_sql

      assert_includes sql, "folio_file_site_links"
      assert_includes sql, "folio_media_source_site_links"
    end
  end

  test "by_usage_constraints with media source rules counts current site usage" do
    with_sharing(true) do
      other_site = create_site(force: true)
      ms = media_source(title: "Wire")
      ms.media_source_site_links.create!(site: @site, max_usage_count: 1)
      ms.media_source_site_links.create!(site: other_site, max_usage_count: 1)
      image = img(attribution_source: ms.title)

      other_article = create(:dummy_blog_article, site: other_site, published: true)
      other_article.image_placements.create!(file: image)
      image.reload.update_file_placements_counts!

      assert_equal 1, image.reload.published_usage_count
      assert_equal 0, image.published_usage_count_for_site(@site)
      assert_equal 1, image.published_usage_count_for_site(other_site)
      assert_includes Folio::File::Image.by_usage_constraints("usable"), image
      assert_not_includes Folio::File::Image.by_usage_constraints("unusable"), image
    end
  end

  # unusable / false, shared OFF
  test "by_usage_constraints 'unusable' without sharing matches usage limit exceeded only" do
    with_sharing(false) do
      below = img(attribution_max_usage_count: 3, published_usage_count: 2)
      no_limit = img(attribution_max_usage_count: nil, published_usage_count: 100)
      exceeded = img(attribution_max_usage_count: 3, published_usage_count: 3)

      results = Folio::File::Image.by_usage_constraints("unusable")
      assert_includes results, exceeded
      assert_not_includes results, below
      assert_not_includes results, no_limit
    end
  end

  test "by_usage_constraints 'false' acts as alias for 'unusable'" do
    with_sharing(false) do
      exceeded = img(attribution_max_usage_count: 1, published_usage_count: 1)
      below = img(attribution_max_usage_count: 2, published_usage_count: 1)

      results = Folio::File::Image.by_usage_constraints("false")
      assert_includes results, exceeded
      assert_not_includes results, below
    end
  end

  # unusable, shared ON
  test "by_usage_constraints 'unusable' with sharing matches over limit or site not allowed" do
    with_sharing(true) do
      other_site = create_site(force: true)
      ms = media_source(title: "MS")

      over_limit = img(attribution_max_usage_count: 1, published_usage_count: 1)
      site_blocked = link_to_site(img(attribution_max_usage_count: 10, published_usage_count: 1, attribution_source: ms.title), other_site)
      allowed_here = link_to_site(img(attribution_max_usage_count: 10, published_usage_count: 1, attribution_source: ms.title), @site)
      no_links = img(attribution_max_usage_count: 10, published_usage_count: 1, attribution_source: ms.title)
      no_media_source = link_to_site(img(attribution_max_usage_count: 10, published_usage_count: 1), other_site)

      results = Folio::File::Image.by_usage_constraints("unusable")
      assert_includes results, over_limit
      assert_includes results, site_blocked
      assert_includes results, no_media_source
      assert_not_includes results, allowed_here
      assert_not_includes results, no_links
    end
  end

  test "by_usage_constraints with unknown value returns none" do
    create(:folio_file_image, site: @site)
    assert_empty Folio::File::Image.by_usage_constraints("unknown")
    assert_empty Folio::File::Image.by_usage_constraints(nil)
  end

  test "prefills attribution fields when media source is assigned" do
    ms = media_source(title: "Getty Images")
    ms.update!(
      licence: "Commercial License",
      copyright_text: "© 2024 Getty Images",
      max_usage_count: 5
    )

    image = img(
      attribution_source: ms.title,
      attribution_licence: nil,
      attribution_copyright: nil,
      attribution_max_usage_count: nil
    )

    assert_equal ms, image.media_source
    assert_equal "Commercial License", image.attribution_licence
    assert_equal "© 2024 Getty Images", image.attribution_copyright
    assert_equal 5, image.attribution_max_usage_count
  end

  test "prefills current site max usage count and global metadata when media source is assigned" do
    with_sharing(true) do
      ms = media_source(title: "Getty Images")
      ms.update!(
        licence: "Commercial License",
        copyright_text: "© 2024 Getty Images",
        max_usage_count: 5
      )
      ms.media_source_site_links.create!(
        site: @site,
        max_usage_count: 3
      )

      image = img(
        attribution_source: ms.title,
        attribution_licence: nil,
        attribution_copyright: nil,
        attribution_max_usage_count: nil
      )

      assert_equal ms, image.media_source
      assert_equal "Commercial License", image.attribution_licence
      assert_equal "© 2024 Getty Images", image.attribution_copyright
      assert_equal 3, image.attribution_max_usage_count
    end
  end

  test "assigns media source by normalized attribution source without changing stored source" do
    ms = media_source(title: "Zdrój")
    image = img(attribution_source: "Zdroj")

    assert_equal "Zdroj", image.attribution_source
    assert_equal ms, image.media_source
  end

  test "replaces attribution fields when media source changes" do
    ms1 = media_source(title: "Source A")
    ms1.update!(licence: "License A", copyright_text: "Copyright A", max_usage_count: 1)

    ms2 = create(:folio_media_source, title: "Source B", site: @site)
    ms2.update!(licence: "License B", copyright_text: "Copyright B", max_usage_count: 10)

    image = img(attribution_source: ms1.title)

    assert_equal "License A", image.attribution_licence
    assert_equal "Copyright A", image.attribution_copyright
    assert_equal 1, image.attribution_max_usage_count

    image.update!(attribution_source: ms2.title)

    assert_equal ms2, image.media_source
    assert_equal "License B", image.attribution_licence
    assert_equal "Copyright B", image.attribution_copyright
    assert_equal 10, image.attribution_max_usage_count
  end

  test "can publish article with images that have media_source" do
    article = create(:dummy_blog_article, site: @site, published: false)
    ms = media_source(title: "Getty Images")
    image_with_source = img(media_source: ms, attribution_source: ms.title)

    article.image_placements.create!(file: image_with_source)

    article.published = true

    assert article.valid?
  end

  test "can save unpublished article with images without media_source" do
    article = create(:dummy_blog_article, site: @site, published: false)
    image_without_source = img(media_source: nil, attribution_source: nil)

    article.image_placements.create!(file: image_without_source)

    assert article.valid?
  end

  test "site-specific media source max usage is counted per site" do
    with_sharing(true) do
      other_site = create_site(force: true)
      ms = media_source(title: "Wire")
      ms.media_source_site_links.create!(site: @site, max_usage_count: 1)
      ms.media_source_site_links.create!(site: other_site, max_usage_count: 1)
      image = img(attribution_source: ms.title)

      article = create(:dummy_blog_article, site: @site, published: true)
      article.image_placements.create!(file: image)

      other_article = create(:dummy_blog_article, site: other_site, published: false)
      other_article.image_placements.create!(file: image)
      other_article.published = true

      assert other_article.save
      assert_equal 1, image.reload.published_usage_count_for_site(@site)
      assert_equal 1, image.published_usage_count_for_site(other_site)
    end
  end

  test "site-specific media source max usage blocks second published usage on same site" do
    with_sharing(true) do
      ms = media_source(title: "Wire")
      ms.media_source_site_links.create!(site: @site, max_usage_count: 1)
      image = img(attribution_source: ms.title)

      article = create(:dummy_blog_article, site: @site, published: true)
      article.image_placements.create!(file: image)

      second_article = create(:dummy_blog_article, site: @site, published: false)
      second_article.image_placements.create!(file: image)
      second_article.published = true

      assert_not second_article.valid?
      assert second_article.errors[:base].any? { |error| error.include?(image.file_name) }
    end
  end

  test "site-specific media source max usage allows repeated file in same published record" do
    with_sharing(true) do
      ms = media_source(title: "Wire")
      ms.media_source_site_links.create!(site: @site, max_usage_count: 1)
      image = img(attribution_source: ms.title)

      article = create(:dummy_blog_article, site: @site, published: true)
      article.image_placements.create!(file: image)

      assert create_atom(Dummy::Atom::Contents::ImageAndText, placement: article, cover: image, content: "content")
      assert_equal 1, image.reload.published_usage_count
      assert_equal 1, image.reload.published_usage_count_for_site(@site)
    end
  end

  test "site-specific media source max usage includes atom attachments when publishing parent" do
    with_sharing(true) do
      ms = media_source(title: "Wire")
      ms.media_source_site_links.create!(site: @site, max_usage_count: 1)
      image = img(attribution_source: ms.title)

      article = create(:dummy_blog_article, site: @site, published: true)
      article.image_placements.create!(file: image)

      second_article = create(:dummy_blog_article, site: @site, published: false)
      create_atom(Dummy::Atom::Contents::ImageAndText, placement: second_article, cover: image, content: "content")

      second_article.published = true

      assert_not second_article.valid?
      assert second_article.errors[:base].any? { |error| error.include?(image.file_name) }
    end
  end

  test "site-specific media source max usage blocks atom attachment on another published record" do
    with_sharing(true) do
      ms = media_source(title: "Wire")
      ms.media_source_site_links.create!(site: @site, max_usage_count: 1)
      image = img(attribution_source: ms.title)

      article = create(:dummy_blog_article, site: @site, published: true)
      article.image_placements.create!(file: image)

      second_article = create(:dummy_blog_article, site: @site, published: true)
      atom = Dummy::Atom::Contents::ImageAndText.new(placement: second_article,
                                                     cover: image,
                                                     content: "content")

      assert_not atom.valid?
      assert atom.errors.any?
    end
  end

  test "media source site rules block usage on unrelated sites" do
    with_sharing(true) do
      other_site = create_site(force: true)
      ms = media_source(title: "Wire")
      ms.media_source_site_links.create!(site: other_site, max_usage_count: 1)
      image = img(attribution_source: ms.title)

      article = create(:dummy_blog_article, site: @site, published: false)
      article.image_placements.create!(file: image)
      article.published = true

      assert_not article.valid?
      assert article.errors[:base].any? { |error| error.include?(image.file_name) }
    end
  end

  private
    def with_sharing(enabled, &block)
      with_config(folio_shared_files_between_sites: enabled) do
        Folio::Current.site = @site if enabled
        yield
      end
    end

    def img(attrs = {})
      create(:folio_file_image, { site: @site }.merge(attrs))
    end

    def link_to_site(file, site)
      file.file_site_links.create!(site: site)
      file
    end

    def media_source(title: "MS")
      create(:folio_media_source, title:, site: @site)
    end
end
