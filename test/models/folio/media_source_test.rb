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

  test "site rules inherit max usage count from media source" do
    site = create(:dummy_site)
    media_source = create(:folio_media_source, max_usage_count: 3)

    media_source.media_source_site_links.create!(site:)

    assert_equal 3, media_source.effective_max_usage_count(site:)
  end

  test "site rules can override max usage count" do
    site = create(:dummy_site)
    media_source = create(:folio_media_source, max_usage_count: 3)

    media_source.media_source_site_links.create!(
      site:,
      max_usage_count: 1
    )

    assert_equal 1, media_source.effective_max_usage_count(site:)
  end

  test "site rules are ordered by creation time" do
    media_source = create(:folio_media_source)
    newest_site = create(:dummy_site)
    oldest_site = create(:dummy_site)

    newest_link = media_source.media_source_site_links.create!(
      site: newest_site,
      created_at: 1.hour.ago
    )
    oldest_link = media_source.media_source_site_links.create!(
      site: oldest_site,
      created_at: 2.hours.ago
    )
    oldest_link.update!(max_usage_count: 2)

    assert_equal [oldest_link, newest_link], media_source.reload.media_source_site_links.to_a
  end

  test "nested site rules can destroy and recreate the same site rule" do
    media_source = create(:folio_media_source)
    site = create(:dummy_site)
    existing_link = media_source.media_source_site_links.create!(site:, max_usage_count: 20)

    media_source.assign_attributes(
      media_source_site_links_attributes: {
        "0" => {
          "id" => existing_link.id.to_s,
          "site_id" => site.id.to_s,
          "max_usage_count" => existing_link.max_usage_count.to_s,
          "_destroy" => "1"
        },
        "1" => {
          "id" => "",
          "site_id" => site.id.to_s,
          "max_usage_count" => "7",
          "_destroy" => ""
        }
      }
    )

    assert media_source.save
    assert_not Folio::MediaSourceSiteLink.exists?(existing_link.id)
    assert_equal [site.id], media_source.reload.media_source_site_links.pluck(:site_id)
    assert_equal 7, media_source.media_source_site_links.first.max_usage_count
  end

  test "site rules reject active duplicates" do
    media_source = create(:folio_media_source)
    site = create(:dummy_site)
    media_source.media_source_site_links.create!(site:)

    duplicate = media_source.media_source_site_links.build(site:)

    assert_not duplicate.valid?
    assert_includes duplicate.errors.details[:media_source_id].map { |e| e[:error] }, :taken
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
