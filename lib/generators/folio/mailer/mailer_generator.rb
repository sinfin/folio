# frozen_string_literal: true

require Folio::Engine.root.join("lib/generators/folio/generator_base")

class Folio::MailerGenerator < Rails::Generators::NamedBase
  include Folio::GeneratorBase

  source_root File.expand_path("templates", __dir__)

  def copy_templates
    path = File.expand_path("templates", __dir__)

    Dir.glob("#{path}/**/*.tt").each do |file_path|
      template_path = file_path.gsub("#{path}/", "")
      target_path = template_path.gsub(/\.tt\Z/, "")
                                 .gsub("application_namespace_path",
                                       application_namespace_path)

      template template_path, target_path
    end
  end
end
