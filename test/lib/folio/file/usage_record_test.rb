# frozen_string_literal: true

require "test_helper"

class Folio::File::UsageRecordTest < ActiveSupport::TestCase
  def setup
    @site = create_and_host_site
    @image = create(:folio_file_image, site: @site, attribution_max_usage_count: 1)
    @article = create(:dummy_blog_article, site: @site, published: true)
    @superadmin = create(:folio_user, :superadmin)
  end

  test "reuses files placed directly or through atoms in a published record" do
    atom_image = create(:folio_file_image, site: @site)
    other_image = create(:folio_file_image, site: @site)
    @article.create_cover_placement!(file: @image)
    create_atom(Dummy::Atom::Contents::ImageAndText, placement: @article, cover: atom_image, content: "content")

    usage_record = Folio::File::UsageRecord.new(@article)

    assert usage_record.reuses?(@image)
    assert usage_record.reuses?(atom_image)
    assert_not usage_record.reuses?(other_image)
  end

  test "does not reuse files of an unpublished record" do
    @article.update!(published: false)
    @article.create_cover_placement!(file: @image)

    assert_not Folio::File::UsageRecord.new(@article).reuses?(@image)
  end

  test "builds the signed id from the record, its placement or its atom" do
    atom = create_atom(Dummy::Atom::Contents::ImageAndText,
                       placement: @article,
                       cover: create(:folio_file_image, site: @site),
                       content: "content")
    placement = @article.create_cover_placement!(file: @image)
    sgid = Folio::File::UsageRecord.sgid_for(@article)

    assert_equal @article, Folio::File::UsageRecord.from_param(sgid, user: @superadmin, ability: ability(@superadmin)).record
    assert_equal sgid, Folio::File::UsageRecord.sgid_for(placement)
    assert_equal sgid, Folio::File::UsageRecord.sgid_for(atom)
    assert_nil Folio::File::UsageRecord.sgid_for(Dummy::Blog::Article.new)
    assert_nil Folio::File::UsageRecord.sgid_for(@image)
  end

  test "ignores records the user cannot update and invalid signed ids" do
    user = create(:folio_user)
    sgid = Folio::File::UsageRecord.sgid_for(@article)
    other_purpose_sgid = @article.to_sgid(for: "other").to_s

    assert_nil Folio::File::UsageRecord.from_param(sgid, user:, ability: ability(user))
    assert_nil Folio::File::UsageRecord.from_param(other_purpose_sgid, user: @superadmin, ability: ability(@superadmin))
    assert_nil Folio::File::UsageRecord.from_param("invalid", user: @superadmin, ability: ability(@superadmin))
    assert_nil Folio::File::UsageRecord.from_param(nil, user: @superadmin, ability: ability(@superadmin))
  end

  test "ignores another site's record even with unrestricted update permissions" do
    other_site = create_site(force: true)
    other_article = create(:dummy_blog_article, site: other_site, published: true)
    unrestricted_ability = ability(@superadmin)
    unrestricted_ability.can :do_anything, :all

    assert_nil Folio::File::UsageRecord.from_param(Folio::File::UsageRecord.sgid_for(other_article),
                                                 user: @superadmin,
                                                 ability: unrestricted_ability)
  end

  test "by_usage_constraints_for_usage_record keeps site restrictions with shared files" do
    with_config(folio_shared_files_between_sites: true) do
      Folio::Current.site = @site
      other_site = create_site(force: true)
      restricted_image = create(:folio_file_image, site: @site, attribution_max_usage_count: 1)
      @article.create_cover_placement!(file: @image)
      @article.image_placements.create!(file: restricted_image)
      restricted_image.file_site_links.create!(site: other_site)
      usage_record = Folio::File::UsageRecord.new(@article)

      usable = Folio::File::Image.by_usage_constraints_for_usage_record("usable", usage_record)
      unusable = Folio::File::Image.by_usage_constraints_for_usage_record("unusable", usage_record)

      assert_includes usable, @image
      assert_not_includes usable, restricted_image
      assert_not_includes unusable, @image
      assert_includes unusable, restricted_image
    end
  end

  private
    def ability(user)
      Folio::Ability.new(user, @site)
    end
end
