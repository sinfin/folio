# frozen_string_literal: true

class Folio::Console::MergesController < Folio::Console::BaseController
  before_action do
    class_name = params.require(:klass)
    klass = class_name.try(:safe_constantize)

    if klass && klass < ActiveRecord::Base
      @klass = klass
      merger_klass = "#{class_name}::Merger".safe_constantize

      original_id = params.require(:original_id)
      duplicate_id = params.require(:duplicate_id)

      if original_id == duplicate_id
        flash[:alert] = I18n.t("folio.console.merges.cannot_merge_into_itself")
        redirect_back fallback_location: url_for([:console, @klass])
        next
      end

      if merger_klass
        scope = if @klass.respond_to?(:by_site)
          @klass.by_site(Folio::Current.site)
        else
          @klass
        end

        @merger = merger_klass.new(scope.find(original_id),
                                   scope.find(duplicate_id),
                                   klass: @klass)

        add_breadcrumb @klass.model_name.human(count: 2),
                       url_for([:console, @klass])

        add_breadcrumb I18n.t("folio.console.merges.form.title")
        next
      end
    end

    raise ActionController::ParameterMissing, :klass
  end

  def new
  end

  def create
    if @merger.merge(params.require(:merge).permit(@merger.permitted_params))
      flash[:notice] = t(".success")
      redirect_to params[:url] || url_for([:edit, :console, @merger.original])
    else
      flash.now[:alert] = t(".failure")
      render :new
    end
  end
end
