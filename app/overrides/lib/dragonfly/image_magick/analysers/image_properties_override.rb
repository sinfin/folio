# frozen_string_literal: true

Dragonfly::ImageMagick::Analysers::ImageProperties.class_eval do
  def call(content)
    identify_command = content.env[:identify_command] || 'identify'
    details = content.shell_eval do |path|
      "#{identify_command} -ping -format '%m %w %h' #{path}[0]"
    end
    format, width, height = details.split
    {
      'format' => format.downcase,
      'width' => width.to_i,
      'height' => height.to_i
    }
  end
end
