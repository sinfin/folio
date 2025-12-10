# frozen_string_literal: true

require "test_helper"

class Folio::SharedFilesTest < ActionDispatch::IntegrationTest
  attr_reader :superadmin
  attr_reader :main_site, :other_site
  attr_reader :main_site_image, :other_site_image
  attr_reader :main_site_video, :other_site_video
  attr_reader :main_site_document, :other_site_document
  attr_reader :main_site_audio, :other_site_audio

  setup do
    @main_site = create_and_host_site
    @other_site = create_site(attributes: { domain: "lvh.me", locale: "en" })
    @superadmin = create(:folio_user, :superadmin)
  end

  test "shared files enabled - files are stored with Folio::File.correct_site(nil)" do
    Rails.application.config.stub(:folio_shared_files_between_sites, true) do
      assert_equal main_site, Folio::File.correct_site(nil)
      assert_equal main_site, Folio::File.correct_site(main_site)
      assert_equal main_site, Folio::File.correct_site(other_site)

      create_file_pairs(:images)
      assert_equal main_site, main_site_image.site
      assert_equal main_site, other_site_image.site # other_site was overridden to main_site
    end
  end

  test "shared files enabled - all files are available at all sites" do
    Rails.application.config.stub(:folio_shared_files_between_sites, true) do
      create_file_pairs(:images, :videos, :documents, :audios)
      assert_equal other_site, other_site_image.site # other_site was overridden to main_site
      assert_equal other_site, other_site_video.site # other_site was overridden to main_site
      assert_equal other_site, other_site_document.site # other_site was overridden to main_site
      assert_equal other_site, other_site_audio.site # other_site was overridden to main_site

      [main_site, other_site].each do |site|
        sign_in_to_site(site)

        get console_file_images_path

        assert_select "img[alt='#{main_site_image.file_name}']"
        assert_select "div.f-file-list-file__info-file-name", text: main_site_image.file_name
        assert_select "img[alt='#{other_site_image.file_name}']"
        assert_select "div.f-file-list-file__info-file-name", text: other_site_image.file_name

        get console_file_videos_path

        assert_select "img[alt='#{main_site_video.file_name}']"
        assert_select "div.f-file-list-file__info-file-name", text: main_site_video.file_name
        assert_select "img[alt='#{other_site_video.file_name}']"
        assert_select "div.f-file-list-file__info-file-name", text: other_site_video.file_name

        get console_file_documents_path

        assert_select "img[alt='#{main_site_document.file_name}']"
        assert_select "div.f-file-list-file__info-file-name", text: main_site_document.file_name
        assert_select "img[alt='#{other_site_document.file_name}']"
        assert_select "div.f-file-list-file__info-file-name", text: other_site_document.file_name

        get console_file_audios_path

        assert_select "div.f-file-list-file__info-file-name", text: main_site_audio.file_name
        assert_select "div.f-file-list-file__info-file-name", text: other_site_audio.file_name
      end
    end
  end

  test "shared files enabled - file tags are shared between sites" do
    Rails.application.config.stub(:folio_shared_files_between_sites, true) do
      create_file_pairs(:images)

      main_site_image.tag_list.add("tag_main")
      other_site_image.tag_list.add("tag_other")
      main_site_image.save

      other_site_image.tag_list.add("tag_main")
      other_site_image.tag_list.add("tag_other")
      other_site_image.save

      assert_equal main_site.id.to_s, other_site_image.taggings.last.tenant


      [main_site, other_site].each do |site|
        sign_in_to_site(site)

        # autocomplete endpoint
        get "/console/api/autocomplete/select2?klass=ActsAsTaggableOn%3A%3ATag&q=tag"

        assert_response :success

        assert_equal(["tag_main", "tag_other"].sort, response.parsed_body["results"].collect { |r| r["text"] }.sort)

        get "/console/api/autocomplete/select2?klass=ActsAsTaggableOn%3A%3ATag&q=tag_o"

        assert_response :success
        assert_equal(["tag_other"], response.parsed_body["results"].collect { |r| r["text"] })

        # console/api/tags(

        # pages do not share tags
      end
    end
  end

  private
    def sign_in_to_site(site)
      host_site(site)
      sign_in superadmin
      Folio::Current.user = superadmin
    end

    def create_file_pairs(*types)
      types.each do |type|
        case type
        when :images
          @main_site_image = create(:folio_file_image, file_name: "main_site_image.gif", site: main_site)
          @other_site_image = create(:folio_file_image, file_name: "other_site_image.gif", site: other_site)
        when :videos
          @main_site_video = create(:folio_file_video, file_name: "main_site_video.mp4", site: main_site)
          @other_site_video = create(:folio_file_video, file_name: "other_site_video.mp4", site: other_site)
        when :documents
          @main_site_document = create(:folio_file_document, file_name: "main_site_document.pdf", site: main_site)
          @other_site_document = create(:folio_file_document, file_name: "other_site_document.pdf", site: other_site)
        when :audios
          @main_site_audio = create(:folio_file_audio, file_name: "main_site_audio.mp3", site: main_site)
          @other_site_audio = create(:folio_file_audio, file_name: "other_site_audio.mp3", site: other_site)
        end
      end
    end
end
