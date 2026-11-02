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

  test "parent and child placements consume one usage including a parent site's count" do
    parent = ParentRecord.create!(site: @site, published: true)
    child = ChildRecord.create!(parent:)
    parent.create_cover_placement!(file: @image)
    child.image_placements.create!(file: @image)

    assert_equal 1, Folio::File::PublishedUsageCounter.count(@image)
    assert_equal 1, Folio::File::PublishedUsageCounter.count(@image, site: @site)
  end

  test "a new child can select a photo used only by a sibling" do
    parent = ParentRecord.create!(site: @site, published: true)
    ChildRecord.create!(parent:).image_placements.create!(file: @image)
    context = Folio::File::UsageRecord.new(ChildRecord.new(parent:))

    assert_equal Folio::File::UsageRecord.sgid_for(parent), context.sgid
    assert context.reuses?(@image)
  end

  test "a signed child context is checked against its parent site" do
    other_site = create_site(force: true)
    parent = ParentRecord.create!(site: other_site, published: true)
    child = ChildRecord.create!(parent:)
    unrestricted_ability = ability(@superadmin)
    unrestricted_ability.can :do_anything, :all

    assert_nil Folio::File::UsageRecord.from_param(child.to_sgid(for: Folio::File::UsageRecord::SGID_PURPOSE).to_s,
                                                 user: @superadmin, ability: unrestricted_ability)
  end

  test "child placement validation uses the parent site without a site on the child" do
    with_config(folio_shared_files_between_sites: true) do
      other_site = create_site(force: true)
      parent = ParentRecord.create!(site: other_site, published: true)
      child = ChildRecord.create!(parent:)
      @image.allowed_sites = [other_site]

      assert child.image_placements.build(file: @image).valid?
    end
  end

  test "a child without a published column cannot bypass an exhausted license" do
    @article.create_cover_placement!(file: @image)
    parent = ParentRecord.create!(site: @site, published: true)
    child = ChildRecord.create!(parent:)

    assert_not child.image_placements.build(file: @image).valid?
  end

  test "a child without a published column cannot bypass site restrictions" do
    with_config(folio_shared_files_between_sites: true) do
      @image.allowed_sites = [create_site(force: true)]
      parent = ParentRecord.create!(site: @site, published: true)
      child = ChildRecord.create!(parent:)

      assert_not child.image_placements.build(file: @image).valid?
    end
  end

  class ParentRecord < ActiveRecord::Base
    self.table_name = "dummy_blog_articles"
    include Folio::HasAttachments

    belongs_to :site, class_name: "Folio::Site"
    has_many :children, class_name: "Folio::File::UsageRecordTest::ChildRecord",
                        foreign_key: :dummy_blog_article_id, inverse_of: :parent

    self.folio_file_usage_child_associations = [:children]
  end

  class ChildRecord < ActiveRecord::Base
    self.table_name = "dummy_blog_author_article_links"
    include Folio::HasAttachments

    belongs_to :parent, class_name: "Folio::File::UsageRecordTest::ParentRecord",
                        foreign_key: :dummy_blog_article_id, inverse_of: :children

    self.folio_file_usage_parent_association = :parent
  end

  private
    def ability(user)
      Folio::Ability.new(user, @site)
    end
end
