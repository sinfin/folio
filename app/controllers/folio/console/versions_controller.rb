# frozen_string_literal: true

class Folio::Console::VersionsController < Folio::Console::BaseController
  folio_console_controller_for 'Folio::Version'
  before_action :find_item
  before_action do
    add_breadcrumb(@item.model_name.human(count: 2),
                   url_for([:console, @item.class]))
    add_breadcrumb(@item.title,
                   url_for([:console, @item, action: :edit]))
    add_breadcrumb(I18n.t('folio.console.versions.title'),
                   url_for([:console, @item, Folio::Version]))
  end

  def index
    @versions = @versions.where(item: @item)
                         .map(&:reify)
  end

  private

    def find_item
      item_class = params[:item_class].safe_constantize
      id_param = :"#{item_class.to_s.demodulize.parameterize}_id"

      @item = item_class.find(params[id_param])
    end
end
