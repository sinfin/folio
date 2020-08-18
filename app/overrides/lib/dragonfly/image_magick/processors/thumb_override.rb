# frozen_string_literal: true

Dragonfly::ImageMagick::Processors::Thumb.class_eval do
  def call(content, geometry, opts = {})
    content.process!(:convert, args_for_geometry_extended(geometry, opts), opts)
  end

  def args_for_geometry_extended(geometry, opts = {})
    case geometry
    when ::Dragonfly::ImageMagick::Processors::Thumb::RESIZE_GEOMETRY
      resize_args(geometry)
    when ::Dragonfly::ImageMagick::Processors::Thumb::CROPPED_RESIZE_GEOMETRY
      resize_and_crop_args_extended($1, $2, $3, opts: opts)
    when ::Dragonfly::ImageMagick::Processors::Thumb::CROP_GEOMETRY
      crop_args(
        "width" => $1,
        "height" => $2,
        "x" => $3,
        "y" => $4,
        "gravity" => $5
      )
    else raise ArgumentError, "Didn't recognise the geometry string #{geometry}"
    end
  end

  private
    def resize_and_crop_args_extended(width, height, gravity, opts: {})
      x = 0
      y = 0
      gravity_str = ""

      ox = opts[:x] || opts["x"]
      oy = opts[:y] || opts["y"]

      if ox || oy
        if ox
          x = (ox * width.to_i).round
        end
        if oy
          y = (oy * height.to_i).round
        end
      else
        gravity_str = "-gravity #{::Dragonfly::ImageMagick::Processors::Thumb::GRAVITIES[gravity || 'c']}"
      end

      "-resize #{width}x#{height}^^ #{gravity_str} -crop #{width}x#{height}+#{x}+#{y} +repage"
    end
end
