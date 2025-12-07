# frozen_string_literal: true

require "test_helper"

class Folio::Console::SharedFilesTest < Folio::Console::BaseControllerTest
  attr_reader :main_site, :site_lvh, :lvh_image, :main_site_image

  def setup
    # not calling `super` for reason
    @main_site = create_site(attributes: { domain: "main-site.localhost" })
    @site_lvh = create_site(attributes: { domain: "lvh.me", locale: "en" }, force: true)
    Folio.instance_variable_set(:@main_site, nil) # to clear the cached version from other tests
    @superadmin = create(:folio_user, :superadmin, auth_site: main_site)
  end

  test "`config.folio_shared_files_between_sites` is true: files are always stored under main_site" do
    Rails.application.config.stub(:folio_shared_files_between_sites, true) do
      create_sites_files
      assert_equal main_site, lvh_image.site # site is overwritten to main_site
      assert_equal main_site, main_site_image.site

      expected_files_for_sites = { all: [main_site_image, lvh_image],
                                   main_site => [main_site_image, lvh_image],
                                   site_lvh =>  [main_site_image, lvh_image] }

      expect_files_visibility_for_sites(expected_files_for_sites)
    end
  end

  test "`config.folio_shared_files_between_sites` is false: files are available only at theirs site" do
    Rails.application.config.stub(:folio_shared_files_between_sites, false) do
      create_sites_files
      assert_equal site_lvh, lvh_image.site # not overwritten to main_site
      assert_equal main_site, main_site_image.site

      expected_files_for_sites = { all: [main_site_image, lvh_image],
                                   main_site => [main_site_image],
                                   site_lvh =>  [lvh_image] }

      expect_files_visibility_for_sites(expected_files_for_sites)
    end
  end

  test "`config.folio_shared_files_between_sites` is true: console files menu is outside the sites block" do
    Rails.application.config.stub(:folio_shared_files_between_sites, true) do
      [main_site, site_lvh].each do |site|
        host_site(site)
        sign_in superadmin

        # it is redirected to pages: get console_root_url(host: main_site.domain, only_path: false)
        get console_pages_url(host: site.domain, only_path: false)

        assert_response :success, response.body

        expect_one_global_files_menu(response.body)
      end
    end
  end

  test "`config.folio_shared_files_between_sites` is false: console files menu is inside sites block" do
    Rails.application.config.stub(:folio_shared_files_between_sites, false) do
      [main_site, site_lvh].each do |site|
          host_site(site)
          sign_in superadmin

          # it is redirected to pages: get console_root_url(host: main_site.domain, only_path: false)
          get console_pages_url(host: site.domain, only_path: false)

          assert_response :success, response.body

          expect_files_menu_under_site(response.body, site)
        end
    end
  end


  test "`config.folio_shared_files_between_sites` is true: files are stored always under main_site" do
    # proces of creating file is
    # 1) run before_folio_api_s3_path to get s3_url
    # 2) upload file to s3_url
    # 3) run after_folio_api_s3_path to process file
    # so I will test only 3)

    Rails.application.config.stub(:folio_shared_files_between_sites, true) do
      [main_site, site_lvh].each do |site|
        host_site(site)
        sign_in superadmin

        assert_equal site, Folio::Current.site

        expect_new_files_are_stored_with(main_site)
      end
    end
  end

  test "`config.folio_shared_files_between_sites` is false: files are stored under Folio::Current.site" do
    Rails.application.config.stub(:folio_shared_files_between_sites, false) do
      [main_site, site_lvh].each do |site|
        host_site(site)
        sign_in superadmin

        assert_equal site, Folio::Current.site

        expect_new_files_are_stored_with(site)
      end
    end
  end

  test "`config.folio_shared_files_between_sites` is true: TAGS to files are reacheable from all sites" do
    # tags == keywords
    Rails.application.config.stub(:folio_shared_files_between_sites, true) do
      create_sites_files
      main_site_image.tag_list.add("tag_main")
      main_site_image.save
      lvh_image.tag_list.add("tag_lvh")
      lvh_image.save

      expected_reachable_tags_for_site = {
        "tag_main" => true,
        "tag_lvh" => true,
      }

      [main_site, site_lvh].each do |site|
        assert_reachable_tags_for(site, expected_reachable_tags_for_site)
      end
    end
  end

  test "`config.folio_shared_files_between_sites` is false: TAGS to files are reacheable only from their site" do
    # tags == keywords
    Rails.application.config.stub(:folio_shared_files_between_sites, false) do
      create_sites_files
      main_site_image.tag_list.add("tag_main")
      main_site_image.save
      lvh_image.tag_list.add("tag_lvh")
      lvh_image.save

      assert_equal ["tag_main"].sort, main_site_image.tags.collect(&:name).sort
      assert_equal ["tag_lvh"].sort, lvh_image.tags.collect(&:name).sort

      # main_site
      expected_reachable_tags_for_site = {
        "tag_main" => true,
        "tag_lvh" => false,
      }
      assert_reachable_tags_for(main_site, expected_reachable_tags_for_site)

      # lvh_site
      expected_reachable_tags_for_site = {
        "tag_main" => false,
        "tag_lvh" => true,
      }
      assert_reachable_tags_for(site_lvh, expected_reachable_tags_for_site)
    end
  end

  test "`config.folio_shared_files_between_sites` is true: files can be searched by tag from any site" do
    Rails.application.config.stub(:folio_shared_files_between_sites, true) do
      create_sites_files
      main_site_image.tag_list.add("same_tag_name")
      main_site_image.save
      lvh_image.tag_list.add("same_tag_name")
      lvh_image.save

      # both files are linked to same tag (Tags are siteless, taggings have site_id in `tenant` column)
      assert_equal lvh_image.tags.collect(&:id).sort, main_site_image.tags.collect(&:id).sort

      tag = main_site_image.tags.first

      # main_site
      host_site(main_site)
      sign_in superadmin

      get console_file_images_url(params: { by_tag_id: tag.id })

      assert response.body.include?(main_site_image.file_name), "File `#{main_site_image.file_name}` should be in response for `#{main_site.domain}`!"
      assert response.body.include?(lvh_image.file_name), "File `#{lvh_image.file_name}` should be in response for `#{main_site.domain}`!"

      # lvh_site
      host_site(site_lvh)
      sign_in superadmin

      get console_file_images_url(params: { by_tag_id: tag.id })

      assert response.body.include?(main_site_image.file_name), "File `#{main_site_image.file_name}` should be in response for `#{site_lvh.domain}`!"
      assert response.body.include?(lvh_image.file_name), "File `#{lvh_image.file_name}` should be in response for `#{site_lvh.domain}`!"
    end
  end

  test "`config.folio_shared_files_between_sites` is false: files can be searched by tag only from their site" do
    Rails.application.config.stub(:folio_shared_files_between_sites, false) do
      create_sites_files
      main_site_image.tag_list.add("same_tag_name")
      main_site_image.save
      lvh_image.tag_list.add("same_tag_name")
      lvh_image.save

      # both files are linked to same tag (Tags are siteless, taggings have site_id in `tenant` column)
      assert_equal lvh_image.tags.collect(&:id).sort, main_site_image.tags.collect(&:id).sort

      tag = main_site_image.tags.first

      # main_site
      host_site(main_site)
      sign_in superadmin

      get console_file_images_url(params: { by_tag_id: tag.id })

      assert response.body.include?(main_site_image.file_name), "File `#{main_site_image.file_name}` should be in response for `#{main_site.domain}`!"
      assert_not response.body.include?(lvh_image.file_name), "File `#{lvh_image.file_name}` should NOT be in response for `#{main_site.domain}`!"

      # lvh_site
      host_site(site_lvh)
      sign_in superadmin

      get console_file_images_url(params: { by_tag_id: tag.id })

      assert_not response.body.include?(main_site_image.file_name), "File `#{main_site_image.file_name}` should NOT be in response for `#{site_lvh.domain}`!"
      assert response.body.include?(lvh_image.file_name), "File `#{lvh_image.file_name}` should be in response for `#{site_lvh.domain}`!"
    end
  end

  private
    def file_data_in_json(json_body, file)
      json_data = JSON.parse(response.body)["data"]
      json_data.detect { |f_data| f_data["attributes"]["file_name"] == file.file_name }
    end

    def file_classes
      [Folio::File::Image, Folio::File::Document, Folio::File::Audio, Folio::File::Video]
    end

    def create_sites_files
      @main_site_image = create(:folio_file_image, :black, site: main_site, slug: "main_site_image")
      @lvh_image = create(:folio_file_image, site: site_lvh, slug: "lvh_image") # site will not be overwriten to main_site
      assert_not_equal lvh_image.file_name, main_site_image.file_name
    end

    def expect_files_visibility_for_sites(expected_files_for_sites)
      (expected_files_for_sites.keys - [:all]).each do |site|
        host_site(site)
        sign_in superadmin

        get console_api_file_images_url(host: site.domain,
                                        only_path: false,
                                        format: :json,
                                        params: { by_file_name: "test" }) # params are here to disable caching

        assert_response :success, response.body

        expected_files_for_sites[site].each do |file|
          assert file_data_in_json(response.body, file).present?, "Data for `#{file.file_name}` should be in response for `#{site.domain}`!"
        end

        (expected_files_for_sites[:all] - expected_files_for_sites[site]).each do |file|
          assert_nil file_data_in_json(response.body, file), "Data for `#{file.file_name}` should NOT be in response for `#{site.domain}`!"
        end
      end
    end

    def expect_one_global_files_menu(response)
      top_group = Nokogiri::HTML(response).css(".f-c-layout-sidebar__group").first # always expanded
      site_group = Nokogiri::HTML(response).css(".f-c-layout-sidebar__group--expanded").first

      assert top_group.css(".f-c-layout-sidebar__li:contains(\"Obrázky\")").present?
      assert site_group.css(".f-c-layout-sidebar__li:contains(\"Obrázky\")").blank?
      assert site_group.css(".f-c-layout-sidebar__li:contains(\"Images\")").blank?

      assert top_group.css(".f-c-layout-sidebar__part-title").blank?
      assert_equal site.domain, site_group.css(".f-c-layout-sidebar__part-title").text

      assert top_group.css(".f-c-layout-sidebar__li:contains(\"Obrázky\")")
                      .css("a")
                      .attribute("href")
                      .value
                      .starts_with?("/")
    end

    def expect_files_menu_under_site(response, site)
      site_group = Nokogiri::HTML(response).css(".f-c-layout-sidebar__group--expanded").first

      assert_equal site.domain, site_group.css(".f-c-layout-sidebar__part-title").text

      images_link_text = site == main_site ? "Obrázky" : "Images"
      images_node = site_group.css(".f-c-layout-sidebar__li:contains(\"#{images_link_text}\")")
      assert images_node.present?

      assert images_node.css("a")
                        .attribute("href")
                        .value
                        .include?(site.domain)
    end

    def expect_new_files_are_stored_with(site)
      file_classes.each do |klass|
        s3_name = create_downloaded_file(klass)

        assert_difference("#{klass}.count", 1) do
          perform_enqueued_jobs do
            post after_folio_api_s3_path, params: { s3_path: s3_name, type: klass.to_s, existing_id: nil, message_bus_client_id: "foo" }
            assert_response(:ok)
          end
        end

        file_record = klass.last
        assert_equal site, file_record.site
      end
    end

    def create_downloaded_file(klass)
      fixture_paths = {
        Folio::File::Image => "test/fixtures/folio/test.gif",
        Folio::File::Document => "test/fixtures/folio/empty.pdf",
        Folio::File::Audio => "test/fixtures/folio/blank.mp3",
        Folio::File::Video => "test/fixtures/folio/blank.mp4"
      }
      fixture_path = fixture_paths[klass]

      s3_name = "#{SecureRandom.hex}_test-#{klass.model_name.singular}.#{fixture_path.split(".").last}" # to avoid cross deletions in parallel tests
      test_path = "#{Folio::S3::Client::LOCAL_TEST_PATH}/#{s3_name}"
      FileUtils.mkdir_p(File.dirname(test_path))
      FileUtils.cp(Folio::Engine.root.join(fixture_path), test_path)
      s3_name
    end

    def assert_reachable_tags_for(site, tags)
      host_site(site)
      sign_in superadmin

      assert_equal site, Folio::Current.site


      #  Started GET "http://dummy.localhost:3000/console/api/autocomplete/select2?klass=ActsAsTaggableOn%3A%3ATag&q=karel&page=1&_=1765127222650" for ::1 at 2025-12-07 18:07:23 +0100
      #  Parameters: {"klass"=>"ActsAsTaggableOn::Tag", "q"=>"karel", "page"=>"1", "_"=>"1765127222650"}
      tags.each do |tag, expected_to_be_present|
        get select2_console_api_autocomplete_url(params: { klass: "ActsAsTaggableOn::Tag", q: tag }, format: :json)

        assert_response :success
        if expected_to_be_present
          assert_includes response.parsed_body["results"].collect { |r| r["text"] }, tag
        else
          assert_equal [], response.parsed_body["results"]
        end
      end
    end
end
