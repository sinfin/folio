# frozen_string_literal: true

# adopted from https://github.com/exAspArk/auto_breadcrumbs

module Folio
  module Console
    module AutoBreadcrumbs
      extend ActiveSupport::Concern

      included do
        before_action :add_breadcrumb_on_action, except: :destroy
      end

      private

        def add_breadcrumb_on_action(options = {})
          add_breadcrumb '<i class="fa fa-home"></i>'.html_safe,
                         console_root_path

          return if request.path == console_root_path

          # nested resources
          Rails.application.routes.router.recognize(request) do |route, matches, param|
            route.required_parts[0...-1].each do |required_part|
              resources_name              = required_part.to_s.gsub('_id', '').pluralize
              resource_index_path         = index_path(resources_name)
              nested_resource_translation = resource_translation(resources_name)
              nested_action_translation   = action_translation(resources_name, 'show')

              add_breadcrumb(nested_resource_translation, resource_index_path) if nested_resource_translation
              add_breadcrumb(nested_action_translation)                        if nested_action_translation
            end
          end

          resource_index_path = index_path(params[:controller])
          add_breadcrumb(resource_translation, resource_index_path) if resource_translation
          add_breadcrumb(action_translation)                        if action_translation
        end

        def resource_translation(resources_name = nil)
          resources_name ||= params[:controller].split('/').pop

          if index_path(resources_name)
            breadcrumbs_t("#{ resources_name }.index.title") ||
            resources_name.humanize
          end
        end

        def action_translation(resources_name = nil, action_name = nil)
          resources_name ||= params[:controller].split('/').pop
          action_name ||= params[:action]

          mapped_action_name = breadcrumbs_action_name(action_name)

          unless mapped_action_name == 'index'
            breadcrumbs_t("breadcrumbs.actions.#{ mapped_action_name }") ||
            mapped_action_name.humanize
          end
        end

        def index_path(resources_name)
          url_for(controller: resources_name) rescue nil
        end

        def breadcrumbs_action_name(action_name)
          case action_name
          when 'create'
            'new'
          when 'update'
            'edit'
          else
            action_name
          end
        end

        def breadcrumbs_t(path)
          I18n.t("folio.console.#{path}", default: '').presence
        end
    end
  end
end
