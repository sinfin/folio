(() => {
  if (!window.flickrJustifiedLayout) {
    console.error("Missing window.flickrJustifiedLayout - add 'justified-layout' to application.js")
  } else if (!window.Folio.debounce) {
    console.error("Missing window.Folio.debounce - add 'folio/debounce' to application.js")
  } else {
    let bound = false

    const alignWrap = ($wrap) => {
      const height = parseFloat($wrap.data('target-height'))
      let ratios = []
      const $items = $wrap.find('.d-atom-images__dynamic-item')

      $items.each((i, el) => { ratios.push(parseFloat($(el).data('ratio'))) })

      const result = window.flickrJustifiedLayout(ratios, {
        containerWidth: $wrap.width(),
        containerPadding: 0,
        boxSpacing: parseFloat($wrap.data('margin')),
        targetRowHeight: height
      })

      $wrap.css('height', result.containerHeight)

      $items.each((i, el) => {
        var r
        r = result.boxes[i]
        return $(el).css({
          left: r.left,
          top: r.top,
          width: r.width,
          position: 'absolute'
        })
      })
    }

    const handleWraps = () => {
      $('.d-atom-images__dynamic').each((i, el) => {
        const $wrap = $(el)
        alignWrap($wrap)
        $wrap.addClass('d-atom-images__dynamic--loaded')
      })
    }

    const debouncedHandleWraps = window.Folio.debounce(handleWraps, 250)

    const onLoad = () => {
      if (!$('.d-atom-images__dynamic').length) return

      handleWraps()

      if (!bound) {
        $(window).on('resize.dAtomImages orientationchange.dAtomImages', debouncedHandleWraps)
        bound = true
      }
    }

    $(document).on('folioAtomsLoad', onLoad).on('folioAtomsUnload', () => {
      if (!bound) return
      bound = false
      $(window).off('resize.dAtomImages orientationchange.dAtomImages', debouncedHandleWraps)
    })
  }
})()
