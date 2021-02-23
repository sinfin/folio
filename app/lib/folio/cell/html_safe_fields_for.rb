# frozen_string_literal: true

module Folio::Cell::HtmlSafeFieldsFor
  def html_safe_fields_for(f, key, build: false, &block)
    obj = f.object.send(key)

    if build && obj.blank?
      obj = f.object.send("build_#{key}")
    end

    f.simple_fields_for key, obj do |subfields|
      (yield subfields).html_safe
    end
  end
end
