# frozen_string_literal: true

require "test_helper"

class Folio::HasSiteRolesTest < ActiveSupport::TestCase
  attr_reader :site, :user

  def setup
    super

    @site = create(:folio_site, available_user_roles: ["superuser", "administrator", "manager"])
    @user = create(:folio_user) # includes Folio::HasSiteRoles
  end

  test "differentiate roles against different sites" do
    site2 = build(:folio_site, available_user_roles: ["administrator", "manager"])
    def site2.validate_singularity
    end # hack to allow 2 sites after Folio::Site class initialization
    site2.save!

    assert_equal [], user.roles_for(site:)
    assert_equal [], user.roles_for(site: site2)

    user.set_roles_for(site:, roles: ["administrator"])
    user.set_roles_for(site: site2, roles: ["manager", "administrator"])

    assert_equal ["administrator"], user.roles_for(site:)
    assert_equal ["administrator", "manager"], user.roles_for(site: site2) # sorted roles!

    assert user.has_role?(site:, role: :administrator)
    assert_not user.has_role?(site:, role: :manager)
    assert user.has_role?(site: site2, role: :administrator)
    assert user.has_role?(site: site2, role: :manager)
  end

  test "validates roles againts site.availables_roles" do
    assert_equal ["superuser", "administrator", "manager"], site.available_user_roles

    user.set_roles_for(site:, roles: ["administrator", "manager"])

    assert user.valid?
    assert user.has_role?(site:, role: :administrator)
    assert user.has_role?(site:, role: :manager)

    user.set_roles_for(site:, roles: ["administrator"])

    assert user.valid?
    assert user.has_role?(site:, role: :administrator)
    assert_not user.has_role?(site:, role: :manager)

    user.set_roles_for(site:, roles: [])

    assert user.valid?
    assert_not user.has_role?(site:, role: :administrator)
    assert_not user.has_role?(site:, role: :manager)

    user.set_roles_for(site:, roles: ["spy", "manager"])

    assert_not user.valid?
    assert_includes user.errors[:site_roles], "Role [\"spy\"] nejsou dostupné pro web '#{site.domain}'."
  end

  test "can use agregate checks" do
    user.set_roles_for(site:, roles: ["administrator", "manager"])

    assert user.has_any_roles?(site:, roles: ["administrator", "superuser"])
    assert_not user.has_any_roles?(site:, roles: ["superuser"])

    assert user.has_all_roles?(site:, roles: ["administrator", "manager"])
    assert_not user.has_all_roles?(site:, roles: ["administrator", "superuser"])

    assert_equal ["Administrátor", "Manažer"], user.human_role_names(site:)
  end

  test ".roles_for_select" do
    expected_roles = [
      ["Superuser", "superuser"],
      ["Administrátor", "administrator"],
      ["Manažer", "manager"],
    ]
    assert_equal expected_roles, Folio::User.roles_for_select(site:)
    assert_equal expected_roles, Folio::User.roles_for_select(site:, selectable_roles: nil)
    assert_equal expected_roles, Folio::User.roles_for_select(site:, selectable_roles: [])

    assert_equal [["Superuser", "superuser"], ["Manažer", "manager"]],
                Folio::User.roles_for_select(site:,
                                             selectable_roles: ["superuser", "manager", "spy"])
  end
end
