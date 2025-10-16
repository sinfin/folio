# frozen_string_literal: true

require "test_helper"

class Folio::FileList::FileComponentTest < Folio::ComponentTest
  def test_file
    file = create(:folio_file_image)

    render_inline(Folio::FileList::FileComponent.new(file:))

    assert_selector(".f-file-list-file")
    assert_selector(".f-file-list-file__image-wrap")
    assert_no_selector(".f-file-list-loader")
  end

  def test_template
    render_inline(Folio::FileList::FileComponent.new(file: Folio::File::Image.new, template: true))

    assert_selector(".f-file-list-file")
    assert_selector(".f-file-list-file__image-wrap")
    assert_selector(".f-file-list-loader")
  end

  def test_allow_selection_for_site_returns_true_for_files_without_usage_constraints
    file = create(:folio_file_image)

    component = Folio::FileList::FileComponent.new(file:)

    assert component.allow_selection_for_site?
  end

  def test_allow_selection_for_site_returns_true_when_file_is_allowed_and_usage_not_exceeded
    file = create(:folio_file_image, attribution_max_usage_count: 10, published_usage_count: 5)
    component = Folio::FileList::FileComponent.new(file:)

    assert component.allow_selection_for_site?
  end

  def test_allow_selection_for_site_returns_false_when_usage_limit_exceeded
    file = create(:folio_file_image, attribution_max_usage_count: 10, published_usage_count: 10)
    component = Folio::FileList::FileComponent.new(file:)

    assert_not component.allow_selection_for_site?
  end

  def test_allow_selection_for_site_returns_false_when_site_not_allowed
    if Rails.application.config.folio_shared_files_between_sites
      site1 = create(:folio_site, domain: "site1.localhost", type: "Folio::Site")
      site2 = create(:folio_site, domain: "site2.localhost", type: "Folio::Site")
      file = create(:folio_file_image)

      Folio::FileSiteLink.create!(file:, site: site1)
      Folio::Current.site = site2
      component = Folio::FileList::FileComponent.new(file:)

      assert_not component.allow_selection_for_site?
    end
  end

  def test_allow_selection_for_site_returns_true_when_site_is_allowed
    if Rails.application.config.folio_shared_files_between_sites
      site1 = create(:folio_site, domain: "site1.localhost", type: "Folio::Site")
      site2 = create(:folio_site, domain: "site2.localhost", type: "Folio::Site")
      file = create(:folio_file_image)

      Folio::FileSiteLink.create!(file:, site: site1)
      Folio::Current.site = site1

      component = Folio::FileList::FileComponent.new(file:)

      assert component.allow_selection_for_site?
    end
  end

  def test_allow_selection_for_site_returns_false_when_both_conditions_fail
    if Rails.application.config.folio_shared_files_between_sites
      site1 = create(:folio_site, domain: "site1.localhost", type: "Folio::Site")
      site2 = create(:folio_site, domain: "site2.localhost", type: "Folio::Site")
      file = create(:folio_file_image, attribution_max_usage_count: 10, published_usage_count: 10)
      Folio::Current.site = site2

      component = Folio::FileList::FileComponent.new(file:)

      assert_not component.allow_selection_for_site?
    end
  end
end
