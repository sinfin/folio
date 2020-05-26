# frozen_string_literal: true

module Folio::ActiveClass
  def active_class(*paths, start_with: true, base: '')
    request_path = request.path.split('?').first || ''
    request_url = request.url.split('?').first || ''

    active = paths.any? do |raw_path|
      next if raw_path.nil?
      path = raw_path.split('?').first

      if start_with && ['/', '/cs', '/en'].exclude?(path)
        request_path.start_with?(path) || request_url.start_with?(path)
      else
        request_path == path || request_url == path
      end
    end

    if active
      if base.present?
        "#{base}--active"
      else
        'active'
      end
    end
  end

  def active_class_with_children(url, children, base: '', start_with: true)
    return active_class(url, base: base) if children.blank?
    paths = [url]
    children.each { |mi, _ch| paths << menu_url_for(mi) }
    active_class(*paths, base: base, start_with: start_with)
  end
end
