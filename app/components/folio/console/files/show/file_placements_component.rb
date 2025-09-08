# frozen_string_literal: true

class Folio::Console::Files::Show::FilePlacementsComponent < Folio::Console::ApplicationComponent
  include Pagy::Backend
  include Pagy::Frontend

  def initialize(file:)
    @file = file
  end

  private
    def before_render
      @pagy, @file_placements = pagy(@file.file_placements.includes(:placement).order(created_at: :desc), items: 20)
    end

    def placement_label(placement)
      placement.try(:to_label) || "##{placement.id}"
    end

    def placement_action(placement)
      if can_now?(:update, placement)
        return { type: :edit, url: url_for([:edit, :console, placement]) }
      elsif can_now?(:read, placement)
        return { type: :show, url: url_for([:console, placement]) }
      end

      { type: :none }
    rescue StandardError
      { type: :none }
    end
end
