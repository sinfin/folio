# frozen_string_literal: true

class Folio::Console::ContentTemplatesController < Folio::Console::BaseController
  folio_console_controller_for "Folio::ContentTemplate", except: %w[index edit update]
  before_action { @no_react_modals = true }
  before_action :set_klass, only: %i[edit update]

  def index
    @content_template_classes = Folio::ContentTemplate.recursive_subclasses(include_self: false)
  end

  def edit
    @content_templates = @klass.ordered
  end

  def update
    @klass.transaction do
      content_template_params.each do |attrs|
        dup = attrs.dup
        destroy = dup.delete(:_destroy)
        id = dup.delete(:id)

        if destroy == "1"
          if id
            @klass.find(id).destroy!
          end
        else
          if id
            ct = @klass.find(id)
            ct.update!(dup)
          else
            @klass.create!(dup)
          end
        end
      end
    end

    flash.notice = t(".success")
    redirect_to action: :edit
  end

  private
    def set_klass
      klass = params.require(:type).safe_constantize

      if klass < @klass
        @klass = klass
        add_breadcrumb @klass.model_name.human(count: 2)
      else
        fail ActionController::ParameterMissing, :klass
      end
    end

    def content_template_params
      params.require(:content_template)
            .permit(content_templates_attributes: [
              :content,
              :title,
              *current_site.locales.map { |l| "content_#{l}".to_sym },
              :position,
              :_destroy,
              :id
            ])
            .require(:content_templates_attributes)
            .to_h
            .values
    end
end
