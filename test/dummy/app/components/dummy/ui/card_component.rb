# frozen_string_literal: true

class Dummy::Ui::CardComponent < ApplicationComponent
  THUMB_SIZE = {
    l: {
      vertical: { true => "400x700", false => "400x700" },
      horizontal: { true => "400x700", false => "400x700" },
    },
    m: {
      vertical: { true => "436x238#", false => "500x270#" },
      horizontal: { true => "200x200#", false => "240x240#" },
    },
    s: {
      vertical: { true => "306x208#", false => "370x240#" },
      horizontal: { true => "306x208#", false => "370x240#" },
    },
    xs: {
      vertical: { true => "80x80#", false => "80x80#" },
      horizontal: { true => "80x80#", false => "80x80#" },
    }
  }

  THUMB_SIZES = begin
    ary = []

    THUMB_SIZE.values.each do |orientations|
      orientations.values.each do |image_paddings|
        ary += image_paddings.values
      end
    end

    ary.uniq
  end

  def initialize(size: :m,
                 image: nil,
                 image_padding: false,
                 orientation: :vertical,
                 title: nil,
                 subtitle: nil,
                 html: nil,
                 text: nil,
                 button_label: nil,
                 button_variant: nil,
                 href: nil,
                 target: nil,
                 rel: nil,
                 link_title: nil,
                 links: nil,
                 topics: nil,
                 tag: :div,
                 box: false,
                 title_tag: nil,
                 data: nil,
                 class_name: nil,
                 transparent: false,
                 border: true,
                 date: nil)
    @size = size
    @image = image
    @image_padding = size == :l ? false : image_padding

    @orientation = case size
                   when :l, :xs
                     :horizontal
                   when :s
                     :vertical
                   else
                     orientation
    end

    @title = title
    @subtitle = size == :xs ? subtitle : nil
    @html = html
    @text = text
    @button_label = button_label
    @button_variant = button_variant || default_button_variant
    @links = size.in?(%i[s l]) ? links : nil
    @href = href
    @link_title = link_title
    @target = target
    @rel = rel
    @topics = size.in?(%i[xs m l]) ? topics : nil
    @box = size == :xs ? box : true
    @tag = tag
    @title_tag = title_tag || default_title_tag
    @data = data
    @date = date # TODO
    @class_name = class_name
    @transparent = transparent
    @border = border
  end

  def tag
    class_name = "d-ui-card d-ui-card--size-#{@size} d-ui-card--orientation-#{@orientation} d-ui-card--image-padding-#{@image_padding}"

    class_name += " d-ui-card--box-false" unless @box
    class_name += " d-ui-card--border-false" unless @border
    class_name += " d-ui-card--transparent-true" if @transparent
    class_name += " #{@class_name}" if @class_name
    class_name += " d-ui-image-hover-zoom-wrap" if @href.present?

    { tag: @tag, class: class_name, data: @data, title: @title }
  end

  def default_title_tag
    case @size
    when :lg
      :h2
    when :xs
      :h4
    else
      :h3
    end
  end

  def default_button_variant
    if @size == :l
      :primary
    elsif @size == :s
      :secondary
    end
  end

  def render?
    render_image? || render_content_box?
  end

  def render_image?
    @image.present?
  end

  def render_content_box?
    return @render_content_box unless @render_content_box.nil?
    @render_content_box = render_description? || render_topics_or_date? || render_button_or_links?
  end

  def render_topics_or_date?
    @topics.present? || @date.present?
  end

  def render_description?
    return @render_description unless @render_description.nil?
    @render_description = @title.present? || @subtitle.present? || render_content?
  end

  def render_content?
    return @render_content unless @render_content.nil?
    @render_content = @size != :xs && (@html.present? || @text.present?)
  end

  def render_button_or_links?
    return @render_button unless @render_button.nil?
    @render_button = (@button_label.present? && @button_variant.present?) || @links.present?
  end
end
