# frozen_string_literal: true

require "test_helper"

class Folio::MediaSourceTest < ActiveSupport::TestCase
  test "validations" do
    media_source = Folio::MediaSource.new
    assert_not media_source.valid?
    assert_includes media_source.errors.details[:title].map { |e| e[:error] }, :blank

    create(:folio_media_source, title: "Existing Title")
    media_source.title = "Existing Title"
    assert_not media_source.valid?
    assert_includes media_source.errors.details[:title].map { |e| e[:error] }, :taken

    media_source.max_usage_count = 0
    assert_not media_source.valid?
    assert_includes media_source.errors.details[:max_usage_count].map { |e| e[:error] }, :greater_than
  end

  test "scopes" do
    source1 = create(:folio_media_source)
    source2 = create(:folio_media_source)
    assert_equal [source2, source1], Folio::MediaSource.ordered.to_a

    site = create(:dummy_site)
    source1.allowed_sites << site
    assert_equal [source1], Folio::MediaSource.by_allowed_site_slug(site.slug).to_a
  end

  test "with_assigned_media_counts" do
    media_source = create(:folio_media_source)
    create_list(:folio_file_image, 2, media_source: media_source, attribution_source: media_source.title)

    source_with_count = Folio::MediaSource.with_assigned_media_counts.find(media_source.id)
    assert_equal 2, source_with_count.assigned_media_count
  end

  test "site rules inherit blank values from media source" do
    site = create(:dummy_site)
    media_source = create(:folio_media_source,
                          licence: "Parent licence",
                          copyright_text: "Parent copyright",
                          max_usage_count: 3)

    media_source.media_source_site_links.create!(site:)

    assert_equal "Parent licence", media_source.effective_licence(site:)
    assert_equal "Parent copyright", media_source.effective_copyright_text(site:)
    assert_equal 3, media_source.effective_max_usage_count(site:)
  end

  test "site rules can override media source values" do
    site = create(:dummy_site)
    media_source = create(:folio_media_source,
                          licence: "Parent licence",
                          copyright_text: "Parent copyright",
                          max_usage_count: 3)

    media_source.media_source_site_links.create!(
      site:,
      licence: "Site licence",
      copyright_text: "Site copyright",
      max_usage_count: 1
    )

    assert_equal "Site licence", media_source.effective_licence(site:)
    assert_equal "Site copyright", media_source.effective_copyright_text(site:)
    assert_equal 1, media_source.effective_max_usage_count(site:)
  end

  test "destroy nullifies attached files attributes and removes only media-source sites" do
    media_source = create(:folio_media_source)
    site1 = create(:folio_site, domain: "site1.localhost", type: "Folio::Site")
    site2 = create(:folio_site, domain: "site2.localhost", type: "Folio::Site")

    image = create(:folio_file_image,
                   media_source: media_source,
                   attribution_source: media_source.title,
                   attribution_max_usage_count: media_source.max_usage_count,
                   attribution_licence: media_source.licence,
                   attribution_copyright: media_source.copyright_text)

    media_source.allowed_sites << site1

    Folio::FileSiteLink.create!(file: image, site: site1)
    Folio::FileSiteLink.create!(file: image, site: site2)
    assert_equal 2, Folio::FileSiteLink.where(file: image).count

    media_source.destroy

    image.reload
    assert_nil image.media_source_id
    assert_nil image.attribution_source
    assert_nil image.attribution_max_usage_count
    assert_nil image.attribution_licence
    assert_nil image.attribution_copyright
    assert_equal [site2.id], Folio::FileSiteLink.where(file: image).pluck(:site_id)
  end

  test "destroy removes allowed sites created via preset" do
    media_source = create(:folio_media_source)
    site1 = create(:folio_site, domain: "site1.localhost", type: "Folio::Site")
    media_source.allowed_sites << site1
    image = create(:folio_file_image)
    image.update!(media_source: media_source)

    assert_equal [site1.id], Folio::FileSiteLink.where(file: image).pluck(:site_id)

    media_source.destroy

    image.reload
    assert_nil image.media_source_id
  end
end
