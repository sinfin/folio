window.makeFolioPhotoSwapper = (options) ->
  return if !options.wrap || !options.main || !options.thumbs

  $(document).on 'mouseenter', options.thumbs, ->
    return if $(options.main).filter(':visible').length is 0

    $img = $(this)
    index = $img.index(options.thumbs)

    $wrap = $img.closest(options.wrap)
    $main = $wrap.find(options.main)

    $main.html($img.clone().data('index', index))

  $(document).on 'click', options.main, ->
    $img = $(this)
    index = $img.data('index') or 0

    $wrap = $img.closest(options.wrap)
    $wrap.find(options.thumbs).eq(index).click()
