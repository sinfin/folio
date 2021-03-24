# frozen_string_literal: true

require "test_helper"

class Folio::SitemapTest < ActiveSupport::TestCase
  class CoverAtom < Folio::Atom::Base
    ATTACHMENTS = %i[cover]
  end

  class ImagesAtom < Folio::Atom::Base
    ATTACHMENTS = %i[images]
  end

  test "base" do
    image_count = 0
    page = create(:folio_page)

    page.cover = create(:folio_image)
    image_count += 1

    create_atom(CoverAtom, :cover, placement: page)
    image_count += 1

    create_atom(ImagesAtom, :images, placement: page)
    image_count += 1

    Folio::Image.find_each do |img|
      img.update!(thumbnail_sizes: {
        "100x100" => {
          uid: "foo",
          signature: "bar",
          url: "/media/foo/bar",
          width: 100,
          height: 100,
          quality: 90,
       },
        "200x200" => {
          uid: "foo",
          signature: "bar",
          url: "/media/foo/bar",
          width: 200,
          height: 200,
          quality: 90,
       },
      })
    end

    version_sitemap = page.reload.image_sitemap("200x200")
    sitemap = page.reload.image_sitemap

    assert_equal(image_count, version_sitemap.size)

    # Sitemap gets only the biggest thumbnail available
    assert_equal(image_count, sitemap.size)
  end
end
