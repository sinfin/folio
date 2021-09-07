$(document)
  .on 'click', '.d-ui-header-search__a', (e) ->
    $this = $(this)
    $wrap = $this.closest('.d-ui-header-search')

    isDesktop = $wrap.find('.d-ui-header-search__mq:visible').length
    return unless isDesktop

    e.preventDefault()
    if $wrap.hasClass('d-ui-header-search--expanded')
      $wrap.find('form').submit()
    else
      $wrap
        .addClass('d-ui-header-search--expanded')
        .find('.d-ui-header-search__input')
        .focus()

      $(window).trigger('resize.uiHeaderMenu')

  .on 'blur', '.d-ui-header-search__input', ->
    if @value is ""
      $(this)
        .closest('.d-ui-header-search')
        .removeClass('d-ui-header-search--expanded')

      $(window).trigger('resize.uiHeaderMenu')
