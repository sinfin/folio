loadAutocomplete = (input) ->
  $input = $(input)
  $wrap = $input.closest('.d-ui-header-search')

  $.ajax
    url: input.getAttribute('data-autocomplete-url')
    data:
      q: $input.val()
    method: 'GET'
    success: (response) ->
      $wrap
        .find('.d-ui-header-search__autocomplete-results')
        .html(response.data)
    error: ->
      $wrap.removeClass('d-ui-header-search--autocomplete')

debouncedLoadAutocomplete = window.folioDebounce(loadAutocomplete, 300)

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

  .on 'keyup', '.d-ui-header-search__input', ->
    if @value is ""
      $(this)
        .closest('.d-ui-header-search')
        .removeClass('d-ui-header-search--autocomplete')
        .find('.d-ui-header-search__autocomplete-results')
        .html('')
    else
      $(this)
        .closest('.d-ui-header-search')
        .addClass('d-ui-header-search--autocomplete')
        .find('.d-ui-header-search__autocomplete-results')
        .html('')

      debouncedLoadAutocomplete(this)
