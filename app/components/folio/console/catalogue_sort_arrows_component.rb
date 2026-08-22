# frozen_string_literal: true

class Folio::Console::CatalogueSortArrowsComponent < Folio::Console::ApplicationComponent
  bem_class_name :active, :desc

  def initialize(klass:, attr:)
    @klass = klass
    @attr = attr
  end

  def render?
    return false unless @klass.present?

    @klass.respond_to?("sort_by_#{asc_key}") && @klass.respond_to?("sort_by_#{desc_key}")
  end

  def url
    h = request.query_parameters.dup
    h.delete("page")

    if asc?
      h["sort"] = desc_key
    else
      h["sort"] = asc_key
    end

    "#{request.path}?#{h.to_query}"
  end

  def active?
    @active
  end

  def asc?
    @asc
  end

  def desc?
    @desc
  end

  def title
    if active?
      t(".sort_desc")
    else
      t(".sort_asc")
    end
  end

  private
    def before_render
      @asc = controller.params[:sort] == asc_key
      @desc = controller.params[:sort] == desc_key
      @active = @asc || @desc
    end

    def asc_key
      @asc_key ||= "#{@attr}_asc"
    end

    def desc_key
      @desc_key ||= "#{@attr}_desc"
    end
end
