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

    page.cover = create(:folio_file_image)
    image_count += 1

    create_atom(CoverAtom, :cover, placement: page)
    image_count += 1

    create_atom(ImagesAtom, :images, placement: page)
    image_count += 1

    # don't include duplicates
    page.images << page.cover
    image_count += 0

    Folio::File::Image.find_each do |img|
      img.update!(thumbnail_sizes: {
        "100x100" => {
          uid: "foo",
          signature: "bar",
          url: "/media/foo/bar-100x100",
          width: 100,
          height: 100,
          quality: 90,
        },
        "200x200" => {
          uid: "foo",
          signature: "bar",
          url: "/media/foo/bar-200x200",
          width: 200,
          height: 200,
          quality: 90,
        },
        "50x50" => {
          uid: "foo",
          signature: "bar",
          url: "/media/foo/bar-50x50",
          width: 50,
          height: 50,
          quality: 90,
        },
      })
    end


    # specified thumbnail size
    sitemap = page.reload.image_sitemap("100x100")
    assert_equal(image_count, sitemap.size)
    assert_includes(sitemap.last[:loc], "100x100")

    # biggest thumbnail size available
    sitemap = page.reload.image_sitemap
    assert_equal(image_count, sitemap.size)
    assert_includes(sitemap.last[:loc], "200x200")
  end
end
