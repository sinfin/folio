# frozen_string_literal: true

require "test_helper"

class Folio::SiteUserLinkTest < ActiveSupport::TestCase
  test "roles get dirty" do
    site = get_any_site
    user = create(:folio_user)

    link = create(:folio_site_user_link, roles: %w[administrator], site:, user:)
    assert_equal 1, link.roles.size
    assert_equal "administrator", link.roles.first

    user.assign_attributes("site_user_links_attributes" => { 0 => { "id" => link.id, "roles" => %w[manager], "site_id" => link.site_id } })

    auditor = Folio::Audited::Auditor.new(record: user)
    relations_changes = auditor.get_folio_audited_changed_relations
    assert_equal 1, relations_changes.size
    assert_equal "roles", relations_changes.first
  end
end
