# frozen_string_literal: true

class Folio::Console::FilePlacementSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id

  attribute :url do |object|
    placement = object.placement

    if placement.is_a?(Folio::Atom::Base)
      placement = placement.placement
    end

    begin
      Folio::Engine.app.url_helpers.url_for([:edit, :console, placement, only_path: true])
    rescue StandardError
      begin
        Folio::Engine.app.url_helpers.url_for([:console, placement, only_path: true])
      rescue StandardError
        begin
          Rails.application.routes.url_helpers.url_for([:edit, :console, placement, only_path: true])
        rescue StandardError
          begin
            Rails.application.routes.url_helpers.url_for([:console, placement, only_path: true])
          rescue StandardError
            nil
          end
        end
      end
    end
  end

  attribute :label do |object|
    placement = object.placement

    if placement.is_a?(Folio::Atom::Base)
      placement = placement.placement
    end

    "#{placement.class.model_name.human}: #{placement.to_label}"
  rescue StandardError
    nil
  end
end
