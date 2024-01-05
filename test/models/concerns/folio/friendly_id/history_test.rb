# frozen_string_literal: true

require "test_helper"

class Folio::FriendlyId::HistoryTest < ActiveSupport::TestCase
  test "remove_conflicting_history_slugs" do
    page = create(:folio_page, slug: "foo")
    page.update!(slug: "bar")

    site_id_scope = "site_id:#{page.site_id}"

    assert FriendlyId::Slug.exists?(slug: "foo",
                                    sluggable_id: page.id,
                                    sluggable_type: "Folio::Page",
                                    scope: site_id_scope)

    assert FriendlyId::Slug.exists?(slug: "bar",
                                    sluggable_id: page.id,
                                    sluggable_type: "Folio::Page",
                                    scope: site_id_scope)

    new_page = create(:folio_page, slug: "foo")

    assert FriendlyId::Slug.exists?(slug: "foo",
                                    sluggable_id: new_page.id,
                                    sluggable_type: "Folio::Page",
                                    scope: site_id_scope)

    assert_not FriendlyId::Slug.exists?(slug: "foo",
                                        sluggable_id: page.id,
                                        sluggable_type: "Folio::Page",
                                        scope: site_id_scope)

    assert FriendlyId::Slug.exists?(slug: "bar",
                                    sluggable_id: page.id,
                                    sluggable_type: "Folio::Page",
                                    scope: site_id_scope)
  end
end
