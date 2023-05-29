# frozen_string_literal: true

module Folio::Console::DefaultActions
  extend ActiveSupport::Concern

  def index
    records = folio_console_records.accessible_by(current_ability, self.class.cancancan_accessible_by_action)

    unless @sorted_by_param
      if records.respond_to?(:ordered)
        records = records.ordered
      else
        records = records.order(id: :desc)
      end
    end

    if self.folio_console_controller_for_handle_csv
      respond_with(records) do |format|
        format.html do
          pagy, records = pagy(records)
          instance_variable_set("@pagy", pagy)
          instance_variable_set(folio_console_record_variable_name(plural: true),
                                records)
        end
        format.csv do
          render_csv(records)
        end
      end
    else
      pagy, records = pagy(records)
      instance_variable_set("@pagy", pagy)
      instance_variable_set(folio_console_record_variable_name(plural: true),
                            records)
    end
  end

  def edit
    folio_console_record.valid? if params[:prevalidate]
  end

  def merge
    @folio_console_merge = @klass
    index
    render :index
  end

  def new
    if !Rails.application.config.folio_site_is_a_singleton && @klass.try(:has_belongs_to_site?)
      folio_console_record.site = current_site
    end
  end

  def create
    instance_variable_set(folio_console_record_variable_name,
                          @klass.create(folio_console_params_with_site))

    if folio_console_record.persisted? && params[:created_from_modal]
      label = folio_console_record.try(:to_console_label) ||
              folio_console_record.try(:to_label) ||
              folio_console_record.try(:title) ||
              folio_console_record.id

      render json: { label:, id: folio_console_record.id }, layout: false
    else
      respond_with folio_console_record, location: respond_with_location
    end
  end

  def update
    folio_console_record.update(folio_console_params)

    respond_to do |format|
      format.html do
        respond_with folio_console_record, location: respond_with_location
      end
      format.json do
        if folio_console_record.valid?
          response_with_json_for_valid_update
        else
          errors = [
            {
              status: 422,
              title: I18n.t("flash.actions.update.alert",
                            resource_name: @klass.model_name.human),
              detail: invalid_flash_error,
            }
          ]

          render json: { errors: }, status: 422
        end
      end
    end
  end

  def destroy
    folio_console_record.destroy
    respond_with folio_console_record, location: respond_with_location
  end

  def discard
    folio_console_record.discard
    respond_with folio_console_record,
                 location: request.referrer || url_for([:console, @klass])
  end

  def undiscard
    folio_console_record.undiscard
    respond_with folio_console_record,
                 location: request.referrer || url_for([:console, @klass])
  end

  def ancestry
    @klass.transaction do
      params.require(:ancestry).each do |i, hash|
        @klass.find(hash[:id])
              .update!(position: hash[:position],
                       parent_id: hash[:parent_id])
      end
    end

    redirect_to url_for([:console, @klass]),
                flash: { notice: I18n.t("folio.console.base_controller.ancestry.success") }
  rescue
    redirect_to url_for([:console, @klass]),
                flash: { error: I18n.t("folio.console.base_controller.ancestry.error") }
  end

  def revision
    instance_variable_set(folio_console_record_variable_name, @audited_revision)
    render @klass.audited_view_name
  end

  def restore
    @audited_revision.save!

    redirect_to url_for([:edit, :console, @audited_revision]),
                flash: { notice: I18n.t("folio.console.base_controller.restore.success") }
  end

  def event
    event_name = params.require(:aasm_event).to_sym

    if folio_console_record.valid?
      event = folio_console_record.aasm
                                  .events(possible: true)
                                  .find { |e| e.name == event_name }

      if event && !event.options[:private]
        folio_console_record.send("#{event_name}!")
        location = request.referer || respond_with_location
        respond_with folio_console_record, location:
      else
        human_event = AASM::Localizer.new.human_event_name(@klass, event_name)

        redirect_back fallback_location: url_for([:console, @klass]),
                      flash: { error: I18n.t("folio.console.base_controller.invalid_event", event: human_event) }
      end
    else
      alert = I18n.t("flash.actions.update.alert",
                     resource_name: @klass.model_name.human)
      redirect_to respond_with_location(prevalidate: true),
                  flash: { alert: }
    end
  end

  def collection_destroy
    ids = params.require(:ids).split(",")

    destroyed = @klass.where(id: ids).collect do |record|
      record.destroy
      record.destroyed?
    end

    if destroyed.all?
      redirect_back fallback_location: url_for([:console, @klass]),
                    flash: { success: I18n.t("folio.console.base_controller.collection_destroy.success") }
    else
      redirect_back fallback_location: url_for([:console, @klass]),
                    flash: { error: I18n.t("folio.console.base_controller.collection_destroy.error") }
    end
  end

  def collection_discard
    ids = params.require(:ids).split(",")

    discarded = @klass.where(id: ids).collect do |record|
      record.discard
      record.discarded?
    end

    if discarded.all?
      redirect_back fallback_location: url_for([:console, @klass]),
                    flash: { success: I18n.t("folio.console.base_controller.collection_discard.success") }
    else
      redirect_back fallback_location: url_for([:console, @klass]),
                    flash: { error: I18n.t("folio.console.base_controller.collection_discard.error") }
    end
  end

  def collection_undiscard
    ids = params.require(:ids).split(",")

    undiscarded = @klass.where(id: ids).collect do |record|
      record.undiscard
      !record.discarded?
    end

    if undiscarded.all?
      redirect_back fallback_location: url_for([:console, @klass]),
                    flash: { success: I18n.t("folio.console.base_controller.collection_undiscard.success") }
    else
      redirect_back fallback_location: url_for([:console, @klass]),
                    flash: { error: I18n.t("folio.console.base_controller.collection_undiscard.error") }
    end
  end

  def collection_csv
    ids = params.require(:ids).split(",")
    render_csv(@klass.where(id: ids))
  end

  private
    def folio_console_name_base(plural: false)
      if try(:folio_console_controller_for_as).present?
        if plural
          folio_console_controller_for_as.pluralize
        else
          folio_console_controller_for_as
        end
      else
        if plural
          params[:controller].split("/").last
        else
          params[:controller].split("/").last.singularize
        end
      end
    end

    def folio_console_params
      send("#{folio_console_name_base}_params")
    end

    def folio_console_params_with_site
      if !Rails.application.config.folio_site_is_a_singleton && @klass.try(:has_belongs_to_site?)
        folio_console_params.merge(site: current_site)
      else
        folio_console_params
      end
    end

    def respond_with_location(prevalidate: nil)
      if folio_console_record.destroyed?
        index_url = through_aware_console_url_for(@klass)

        if !request.referrer || request.referrer.include?(index_url)
          index_url
        else
          request.referrer
        end
      else
        if folio_console_record.persisted?
          begin
            if action_name == "create"
              console_show_or_edit_path(folio_console_record,
                                        other_params: { prevalidate: prevalidate ? 1 : nil })
            else
              through_aware_console_url_for(folio_console_record,
                                            action: :edit,
                                            hash: prevalidate ? { prevalidate: 1 } : nil)
            end
          rescue ActionController::UrlGenerationError, NoMethodError
            url_for([:console, @klass])
          end
        end
      end
    end

    def invalid_flash_error
      folio_console_record.valid?
      messages = folio_console_record.errors.full_messages
      messages.join(" ")
    end

    def response_with_json_for_valid_update
      if params[:_trigger] == "f-c-boolean-toggle"
        render json: {
          data: {
            f_c_catalogue_published_dates: cell("folio/console/catalogue/published_dates", folio_console_record).show,
          },
          meta: {
            flash: {
              success: t("flash.actions.update.success", resource_name: @klass.model_name.human)
            },
          }
        }, status: 200
      else
        render json: {}, status: 200
      end
    end
end
