# frozen_string_literal: true

class Folio::Console::CatalogueSortArrowsCell < Folio::ConsoleCell
  class_name "f-c-catalogue-sort-arrows", :active?, :desc?

  def show
    if model.present?
      if model[:klass].respond_to?("sort_by_#{asc_key}") && model[:klass].respond_to?("sort_by_#{desc_key}")
        render
      end
    end
  end

  def asc_key
    @asc_key ||= "#{model[:attr]}_asc"
  end

  def desc_key
    @desc_key ||= "#{model[:attr]}_desc"
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
    asc? || desc?
  end

  def asc?
    params[:sort] == asc_key
  end

  def desc?
    params[:sort] == desc_key
  end

  def title
    if active?
      t(".sort_desc")
    else
      t(".sort_asc")
    end
  end
end
