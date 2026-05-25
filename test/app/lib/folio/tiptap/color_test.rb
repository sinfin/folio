# frozen_string_literal: true

require "test_helper"

class Folio::Tiptap::ColorTest < ActiveSupport::TestCase
  test "normalize supports hex rgb rgba hsl and hsla" do
    {
      "#F0A" => "#ff00aa",
      "#FF00AA" => "#ff00aa",
      " rgb(255, 0, 170) " => "#ff00aa",
      "rgb(100% 0% 66.6667%)" => "#ff00aa",
      "rgba(255 0 170 / 1)" => "#ff00aa",
      "rgba(255, 0, 170, 100%)" => "#ff00aa",
      "hsl(320 100% 50%)" => "#ff00aa",
      "hsla(320, 100%, 50%, 100%)" => "#ff00aa",
    }.each do |input, output|
      assert_equal output, Folio::Tiptap::Color.normalize(input)
    end
  end

  test "normalize rejects unsupported or non opaque colors" do
    [
      "red",
      "transparent",
      "currentColor",
      "rgba(255 0 170 / .5)",
      "hsla(320, 100%, 50%, 0.5)",
      "rgb(256 0 0)",
      "rgb(255, 0)",
      "hsl(320 50 50%)",
      "hwb(320 0% 0%)",
      "#ff00aa80",
    ].each do |input|
      assert_nil Folio::Tiptap::Color.normalize(input)
    end
  end

  test "valid only accepts blank or normalized hex colors" do
    assert Folio::Tiptap::Color.valid?(nil)
    assert Folio::Tiptap::Color.valid?("")
    assert Folio::Tiptap::Color.valid?("#ff00aa")

    assert_not Folio::Tiptap::Color.valid?("#FF00AA")
    assert_not Folio::Tiptap::Color.valid?("#f0a")
    assert_not Folio::Tiptap::Color.valid?("rgb(255 0 170)")
  end
end
