# frozen_string_literal: true

require "test_helper"

class Folio::VipsUnblockedLoadersTest < ActiveSupport::TestCase
  PDF_PATH = Folio::Engine.root.join("test/fixtures/folio/empty.pdf").to_s
  SVG = "<svg xmlns='http://www.w3.org/2000/svg' width='1' height='1'/>"

  setup do
    @untrusted_blocked_on_boot = begin
      Vips::Image.svgload_buffer(SVG)
      false
    rescue Vips::Error => e
      e.message.include?("blocked")
    end
  end

  teardown do
    # restore the boot-time state
    Vips.block_untrusted(@untrusted_blocked_on_boot)
    Folio::Engine.unblock_vips_loaders(Rails.application.config.folio_vips_unblocked_loaders)
  end

  test "pdf loader works after boot" do
    assert Vips::Image.new_from_file(PDF_PATH).width.positive?
  end

  test "unblock_vips_loaders re-enables only the listed loaders" do
    # what Active Storage 8.1.3.1+ does on boot
    Vips.block_untrusted(true)
    assert_raises(Vips::Error) { Vips::Image.pdfload(PDF_PATH) }

    Folio::Engine.unblock_vips_loaders(%w[VipsForeignLoadPdf])

    assert Vips::Image.pdfload(PDF_PATH).width.positive?
    error = assert_raises(Vips::Error) { Vips::Image.svgload_buffer(SVG) }
    assert_match(/blocked/, error.message)
  end
end
