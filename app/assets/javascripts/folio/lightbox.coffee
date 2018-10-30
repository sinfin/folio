#= require jquery3
#= require photoswipe/photoswipe
#= require photoswipe/photoswipe-ui-default

class window.FolioLightbox
  constructor: (selector, additionalSelector = false) ->
    @selector = selector
    if additionalSelector
      @full_selector = "#{selector}, #{additionalSelector}"
    else
      @full_selector = selector
    @eventIdentifier = "folioLightbox"
    @bind()

  pswp: ->
    @$pswp ||= $('.pswp')
    @$pswp

  bind: ->
    $(document).on "click.#{@eventIdentifier}", @full_selector, (e) =>
      e.preventDefault()
      $img = $(e.target)

      options =
        index: $img.index(@full_selector)
        bgOpacity: 0.7
        showHideOpacity: true
        history: false
        errorMsg: @pswp().data('error-msg')

      @photoSwipe = new PhotoSwipe(@pswp()[0], PhotoSwipeUI_Default, @items(), options)
      @photoSwipe.init()

  items: ->
    $(@selector).map(@item.bind(this)).toArray()

  item: (index, el) ->
    if el.tagName.toLowerCase() is 'img'
      $el = $(el)
    else
      $el = $(el).find('img')

    item =
      src: $el.data('lightbox-src')
      w: parseInt($el.data('lightbox-width'))
      h: parseInt($el.data('lightbox-height'))
    item.title = $el.next('figcaption').text()
    item

  destroy: ->
    @photoSwipe?.close()
    $(document).off "click.#{@eventIdentifier}", @full_selector
    @$pswp = null

window.makeFolioLightbox = (selector, opts = {}) ->
  window.folioLightboxInstances ?= []

  $(document).on 'turbolinks:load', ->
    $wrap = $(selector)
    return if $wrap.length is 0
    if opts.individual
      $wrap.each ->
        subSelector = ".#{@className.replace(/\s+/, '.')}"
        window.folioLightboxInstances.push(new window.FolioLightbox(subSelector))
    else
      window.folioLightboxInstances.push(new window.FolioLightbox(selector))

  $(document).on 'turbolinks:before-cache', ->
    return unless window.folioLightboxInstances.length > 0

    for instance in window.folioLightboxInstances
      instance.destroy()

    window.folioLightboxInstances = []
