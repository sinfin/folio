resultsCache = []
closed = null

close = ($wrap) ->
  closed = Number(new Date())
  $wrap
    .removeClass('d-ui-header-search--expanded')
    .removeClass('d-ui-header-search--autocomplete')
    .find('.d-ui-header-search__autocomplete-results')
    .html('')
  $(window).trigger('resize.uiHeaderMenu')

getCachedResult = (q) ->
  result = null
  resultsCache.forEach (ary) -> result = ary[1] if q is ary[0]
  return result

loadAutocomplete = (input) ->
  $input = $(input)
  $wrap = $input.closest('.d-ui-header-search')
  cachedResult = getCachedResult(input.value)
  value = input.value

  if cachedResult
    $wrap
      .find('.d-ui-header-search__autocomplete-results')
      .html(cachedResult)

    return

  $.ajax
    url: input.getAttribute('data-autocomplete-url')
    data:
      q: value
    method: 'GET'
    success: (response) ->
      $wrap
        .find('.d-ui-header-search__autocomplete-results')
        .html(response.data)

      resultsCache = resultsCache.slice(0, 4)
      resultsCache.unshift([value, response.data])
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

    if $wrap.hasClass('d-ui-header-search--expanded') or (closed and (Number(new Date()) - closed < 500))
      $form = $wrap.find('form')

      if $form.find('.d-ui-header-search__input').val()
        $form.submit()
      else
        close($wrap)
    else
      $wrap
        .addClass('d-ui-header-search--expanded')
        .find('.d-ui-header-search__input')
        .focus()

      $(window).trigger('resize.uiHeaderMenu')

  .on 'blur', '.d-ui-header-search__input', ->
    if @value is ""
      close($(this).closest('.d-ui-header-search'))

  .on 'keyup', '.d-ui-header-search__input', ->
    if @value is ""
      $(this)
        .closest('.d-ui-header-search')
        .removeClass('d-ui-header-search--autocomplete')
        .find('.d-ui-header-search__autocomplete-results')
        .html('')
    else
      cachedResult = getCachedResult(@value)

      $(this)
        .closest('.d-ui-header-search')
        .addClass('d-ui-header-search--autocomplete')
        .find('.d-ui-header-search__autocomplete-results')
        .html(cachedResult or '')

      debouncedLoadAutocomplete(this) unless cachedResult

  .on 'change', '.d-ui-header-search__input', ->
    $(this)
      .closest('.d-ui-header-search')
      .toggleClass('d-ui-header-search--expanded', if @value then true else false)

  .on 'click', '.d-ui-header-search__overlay', ->
    $wrap = $(this).closest('.d-ui-header-search')
    close($wrap)
