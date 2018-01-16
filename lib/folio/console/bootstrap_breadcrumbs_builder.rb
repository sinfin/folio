# frozen_string_literal: true

# https://gist.github.com/SaladFork/270a4cb3ac20be9715b7117551c31ec7
#
# `Bootstrap4BreadcrumbsBuilder `is a Bootstrap 4 (alpha6) compatible breadcrumb
# builder. It is designed to work with the `breadcrumbs_on_rails` gem as a
# drop-in builder replacement.
#
# Bootstrap4BreadcrumbsBuilder accepts a limited set of options:
#
#   | option           | default | description                                |
#   | ---------------- | ------- | ------------------------------------------ |
#   | `:container_tag` | `:ol`   | What tag to use for the list container     |
#   | `:tag`           | `:li`   | What HTML tag to use for breadcrumb items  |
#   | `:show_empty`    | `false` | Whether to render container when no crumbs |
#
# You can use it by passing it to the `:builder` option on `render_breadcrumbs`:
#
#   <%= render_breadcrumbs builder: ::Bootstrap4BreadcrumbsBuilder %>
#
# You will need to place this class in a location that is loaded by Rails. One
# suggested is `lib/bootstrap4_breadcrumbs_builder.rb`. You may need to adjust
# Rails' load path in `config/application.rb`:
#
#   config.eager_load_paths << Rails.root.join('lib')
#
#
# See also:
#  <https://v4-alpha.getbootstrap.com/components/breadcrumb/>
#
# Based on:
#  - BreadcrumbsOnRails::Breadcrumbs::SimpleBuilder
#      <https://github.com/weppos/breadcrumbs_on_rails/blob/v3.0.1/lib/breadcrumbs_on_rails/breadcrumbs.rb#L79>
#  - BootstrapBreadcrumbsBuilder
#      <https://gist.github.com/riyad/1933884>
#
class Folio::Console::BootstrapBreadcrumbsBuilder < BreadcrumbsOnRails::Breadcrumbs::Builder
  def render
    return '' unless should_render?

    container_tag = @options.fetch(:container_tag, :ol)

    @context.content_tag container_tag, class: 'breadcrumb' do
      @elements.collect do |element|
        render_element(element)
      end.join.html_safe
    end
  end

  def render_element(element)
    name = compute_name(element)
    path = compute_path(element)

    current = @context.current_page?(path)

    item_tag = @options.fetch(:tag, :li)

    @context.content_tag(item_tag, class: ['breadcrumb-item', ('active' if current)]) do
      opts = element.options.merge(class: 'text-dark')
      @context.link_to_unless_current(name, path, opts)
    end
  end

  private

    def should_render?
      @elements.any? || @options[:show_empty]
    end
end
