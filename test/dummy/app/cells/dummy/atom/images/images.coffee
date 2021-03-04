if not window.flickrJustifiedLayout
  console.error("Missing window.flickrJustifiedLayout - add 'justified-layout' to application.js")
else if not window.folioDebounce
  console.error("Missing window.folioDebounce - add 'folio/debounce' to application.js")
else
  bound = false

  alignWrap = ($wrap) ->
    height = parseFloat($wrap.data('target-height'))
    ratios = []
    $items = $wrap.find('.d-atom-images__dynamic-item')
    $items.each -> ratios.push(parseFloat($(this).data('ratio')))

    result = window.flickrJustifiedLayout ratios,
      containerWidth: $wrap.width()
      containerPadding: 0
      boxSpacing: parseFloat($wrap.data('margin'))
      targetRowHeight: height

    $wrap.css('height', result.containerHeight)
    $items.each (i, el) ->
      r = result.boxes[i]
      $(el).css
        left: r.left
        top: r.top
        width: r.width
        position: 'absolute'

  handleWraps = ($wraps) ->
    $('.d-atom-images__dynamic').each ->
      $wrap = $(this)
      alignWrap($wrap)
      $wrap.addClass('d-atom-images__dynamic--loaded')

  debouncedHandleWraps = window.folioDebounce(handleWraps, 250)

  $(document)
    .on 'turbolinks:load', ->
      $wraps = $('.d-atom-images__dynamic')
      return unless $wraps.length
      bound = true
      handleWraps($wraps)
      $(window).on 'resize.dAtomImages orientationchange.dAtomImages', debouncedHandleWraps

    .on 'turbolinks:before-render', ->
      return unless bound
      bound = false
      $(window).off 'resize.dAtomImages orientationchange.dAtomImages', debouncedHandleWraps
