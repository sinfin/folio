resultsCache = []
closed = null
keydownListening = false

onDocumentKeydown = (e) ->
  if e.key is "ArrowDown" or e.key is "ArrowUp"
    $records = $('.d-searches-autocomplete__record')
    focused = null
    $records.each (i, el) ->
      if el.classList.contains('d-searches-autocomplete__record--focused')
        focused = i
        return false

    if focused isnt null
      shift = if e.key is "ArrowDown" then 1 else -1
      target = focused + shift
      if target < -1
        target = -1
      else if target > $records.length - 1
        target = 0
    else
      target = if e.key is "ArrowDown" then 0 else -1

    $records
      .removeClass('d-searches-autocomplete__record--focused')
      .eq(target)
      .addClass('d-searches-autocomplete__record--focused')

  else if e.key is "Enter"
    focused = document.querySelector('.d-searches-autocomplete__record--focused')
    if focused
      e.preventDefault()
      e.stopPropagation()
      focused.click()

startAutocomplete = ($wrap) ->
  $wrap
    .addClass('d-ui-header-search--autocomplete')

  unless keydownListening
    keydownListening = true
    $(document).on 'keydown.vUiHeaderSearch', onDocumentKeydown

stopAutocomplete = ($wrap) ->
  $wrap
    .removeClass('d-ui-header-search--autocomplete')
    .find('.d-ui-header-search__autocomplete-results')
    .html('')

  if keydownListening
    keydownListening = false
    $(document).off 'keydown.vUiHeaderSearch'

close = ($wrap) ->
  closed = Number(new Date())

  stopAutocomplete($wrap)

  $wrap.removeClass('d-ui-header-search--expanded')

  $(window).trigger('resize.uiHeaderMenu')

getCachedResult = (q) ->
  result = null
  resultsCache.forEach (ary) -> result = ary[1] if q is ary[0]
  return result

loadAutocomplete = (input) ->
  $input = $(input)
  $wrap = $input.closest('.d-ui-header-search')
  value = input.value
  cachedResult = getCachedResult(value)

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
      stopAutocomplete($wrap)

debouncedLoadAutocomplete = window.Folio.debounce(loadAutocomplete, 300)

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

  .on 'keyup', '.d-ui-header-search__input', (e) ->
    if e.key is 'ArrowUp' or e.key is 'ArrowDown'
      e.preventDefault()
      return

    if e.key is 'Enter' and $('.d-searches-autocomplete__record--focused').length
      e.preventDefault()
      return

    if e.key is 'Escape'
      e.preventDefault()
      @value = ""
      return $(this).blur()

    if @value is ""
      stopAutocomplete($(this).closest('.d-ui-header-search'))
    else
      cachedResult = getCachedResult(@value)

      $wrap = $(this).closest('.d-ui-header-search')
      startAutocomplete($wrap)

      $wrap
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
