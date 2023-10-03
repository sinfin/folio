# frozen_string_literal: true

require "test_helper"

class Folio::HasSiteRolesTest < ActiveSupport::TestCase
  attr_reader :site1, :user

  def setup
    super

    @site1 = create(:folio_site, available_user_roles: ["admin", "operator"])
    @user = create(:folio_user) # includes Folio::HasSiteRoles
  end

  test "differentiate roles against different sites" do
    site2 = build(:folio_site, available_user_roles: ["admin", "operator"])
    def site2.validate_singularity
    end # hack to allow 2 sites after Folio::Site class initialization
    site2.save!

    assert_equal [], user.roles_for_site(site1)
    assert_equal [], user.roles_for_site(site2)

    user.set_roles_for_site(site1, ["admin"])
    user.set_roles_for_site(site2, ["operator", "admin"])

    assert_equal ["admin"], user.roles_for_site(site1)
    assert_equal ["admin", "operator"], user.roles_for_site(site2) # sorted roles!

    assert user.has_site_role?(:admin, site: site1)
    assert_not user.has_site_role?(:operator, site: site1)
    assert user.has_site_role?(:admin, site: site2)
    assert user.has_site_role?(:operator, site: site2)
  end

  test "validates roles againts site.availables_roles" do
    assert_equal ["admin", "operator"], site1.available_user_roles

    user.set_roles_for_site(site1, ["admin", "operator"])

    assert user.valid?
    assert user.has_site_role?(:admin, site: site1)
    assert user.has_site_role?(:operator, site: site1)

    user.set_roles_for_site(site1, ["admin"])

    assert user.valid?
    assert user.has_site_role?(:admin, site: site1)
    assert_not user.has_site_role?(:operator, site: site1)

    user.set_roles_for_site(site1, [])

    assert user.valid?
    assert_not user.has_site_role?(:admin, site: site1)
    assert_not user.has_site_role?(:operator, site: site1)

    user.set_roles_for_site(site1, ["spy", "operator"])

    assert_not user.valid?
    assert_includes user.errors[:site_roles], "Role [\"spy\"] nejsou dostupné pro web '#{site1.domain}'."
  end
end
