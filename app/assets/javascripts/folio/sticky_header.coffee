#= require folio/bind_raf

window.makeFolioStickyHeader = (opts = {}) ->
  unless opts.selector and opts.max and opts.min and opts.mqSelector
    throw 'Invalid makeFolioStickyHeader options'

  opts.step ||= 10
  diff = opts.max - opts.min
  $window = $(window)

  mqMobile = -> $(opts.mqSelector).is(':visible')

  makeOnScroll = ($window) ->
    onScroll = bindRaf ->
      scrollTop = $window.scrollTop()
      progress = 0

      if scrollTop <= 0
        progress = 0
      else if scrollTop > diff
        progress = 100
      else
        progress = Math.round(scrollTop / diff * opts.step) * opts.step

      $(document.body).attr('data-affix', progress)

  $(document).on 'turbolinks:before-render', ->
    $window.scrollTop(0)
    $(document.body).attr('data-affix', 0)

  $ ->
    scrollHandler = makeOnScroll($window)
    wasMobile = mqMobile()
    didInit = false

    initScrollHandler = ->
      isMobile = mqMobile()
      return if (isMobile is wasMobile) and didInit

      shouldQuit = isMobile and not didInit
      didInit = true
      return if shouldQuit

      if isMobile and not wasMobile
        $window.off('scroll.folioStickyHeader', scrollHandler)
      else
        $window.on('scroll.folioStickyHeader', scrollHandler)
        scrollHandler()

      wasMobile = isMobile

    $window.on 'resize orientationchange', initScrollHandler
    initScrollHandler()
