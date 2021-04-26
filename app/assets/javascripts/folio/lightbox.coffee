#= require folio/webp
#= require photoswipe/dist/photoswipe
#= require photoswipe/dist/photoswipe-ui-default

window.makeFolioLightboxCalls = []

class window.FolioLightbox
  constructor: (selector, additionalSelector = false, data = null) ->
    @selector = selector
    if additionalSelector
      @full_selector = "#{selector}, #{additionalSelector}"
    else
      @full_selector = selector
    @eventIdentifier = "folioLightbox"
    @$html = $(document.documentElement)
    @bind(data)

  pswp: ->
    @$pswp ||= $('.pswp')
    @$pswp

  bind: (data) ->
    @unbind()
    that = this

    $(document).on "click.#{@eventIdentifier}", @full_selector, (e) ->
      e.preventDefault()
      $img = $(this)

      items = data || that.items()
      index = 0
      items.forEach (item, i) =>
        if item.el is this
          index = i

      options =
        index: index
        bgOpacity: 0.7
        showHideOpacity: true
        history: false
        errorMsg: that.pswp().data('error-msg')

      that.photoSwipe = new PhotoSwipe(that.pswp()[0], PhotoSwipeUI_Default, items, options)
      that.photoSwipe.init()

  items: ->
    items = []
    $(@selector).each (i, el) =>
      item = @item(i, el)
      items.push(item) if item
    items

  item: (index, el) ->
    $el = $(el)

    if $el.hasClass('f-image--sensitive-content')
      return unless @$html.hasClass('f-html--show-sensitive-content')

    unless $el.data('lightbox-src')
      $el = $(el).find('[data-lightbox-src]')

    return null unless $el.length

    item =
      w: parseInt($el.data('lightbox-width'))
      h: parseInt($el.data('lightbox-height'))
      title: $el.data('lightbox-title') or $el.next('figcaption').text()
      src: $el.data('lightbox-webp-src') if window.FolioWebpSupported
      el: el

    item.src ||= $el.data('lightbox-src')

    item

  unbind: ->
    $(document).off "click.#{@eventIdentifier}", @full_selector

  destroy: ->
    try
      @photoSwipe.close()
      @photoSwipe.destroy()
    catch e
    @photoSwipe = null
    @unbind()
    @$pswp = null

window.makeFolioLightbox = (selector, opts = {}) ->
  window.folioLightboxInstances ?= []

  window.makeFolioLightboxCalls ?= []
  window.makeFolioLightboxCalls.push([selector, opts])

  init = ->
    $items = $(selector)
    return if $items.length is 0
    if opts.individual
      $items.each ->
        subSelector = ".#{@className.replace(/\s+/g, '.')}"
        if opts.itemSelector
          subSelector = "#{subSelector} #{opts.itemSelector}"

        window.folioLightboxInstances.push(new window.FolioLightbox(subSelector))
    else if opts.fromData
      $items.each ->
        window.folioLightboxInstances.push(
          new window.FolioLightbox(selector,
                                   false,
                                   $(this).data('lightbox-image-data'))
        )
    else
      window.folioLightboxInstances.push(new window.FolioLightbox(selector))

  if Turbolinks?
    $(document).on 'turbolinks:load', init

    $(document).on 'turbolinks:before-cache turbolinks:before-render', ->
      return unless window.folioLightboxInstances.length > 0

      window.folioLightboxInstances.forEach (instance) ->
        instance.destroy()

      window.folioLightboxInstances = []
  else
    $ -> setTimeout(init, 0)

window.updateAllFolioLightboxInstances = ->
  window.folioLightboxInstances.forEach (instance) -> instance.destroy()
  window.folioLightboxInstances = []

  window.makeFolioLightboxCalls.forEach (call) ->
    window.makeFolioLightbox(call[0], call[1])
