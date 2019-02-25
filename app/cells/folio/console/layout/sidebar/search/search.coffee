ESCAPE_KEY = 27
lastValue = null
$input = null
$wrap = null
$form = null

search = (input) ->
  $input ||= $(input)
  return if $input.val() is lastValue
  lastValue = $input.val()

  $form ||= $input.closest('form')

  $.ajax "#{$form.prop('action')}.json",
    data:
      q: lastValue
    method: 'GET'
    success: (response) ->
      $wrap
        .find('.f-c-layout-sidebar-search__results-inner')
        .html($(response).find('.f-c-searches-results__ul'))
    complete: ->
      $wrap.removeClass('f-c-layout-sidebar-search--loading')
      if $wrap.find('.f-c-searches-results__li').length is 0
        $wrap.addClass('f-c-layout-sidebar-search--error')

debouncedSearch = $.debounce(search, 300)

handle = (e) ->
  $wrap ||= $('.f-c-layout-sidebar-search')

  if @value is '' or e.keyCode is ESCAPE_KEY
    $wrap.removeClass('f-c-layout-sidebar-search--searching \
                       f-c-layout-sidebar-search--loading \
                       f-c-layout-sidebar-search--error')
    if e.keyCode is ESCAPE_KEY
      $input ||= $wrap.find('.f-c-layout-sidebar-search__input')
      $input.val('')

  else if @value isnt lastValue
    $wrap.removeClass('f-c-layout-sidebar-search--error')
    $wrap.addClass('f-c-layout-sidebar-search--searching \
                    f-c-layout-sidebar-search--loading')

  debouncedSearch(this)

cancel = (e) ->
  e.preventDefault()
  $wrap ||= $('.f-c-layout-sidebar-search')
  $input ||= $wrap.find('.f-c-layout-sidebar-search__input')
  $input.val('')
  $wrap.removeClass('f-c-layout-sidebar-search--error \
                     f-c-layout-sidebar-search--searching \
                     f-c-layout-sidebar-search--loading')


$(document)
  .on 'submit', '.f-c-layout-sidebar-search__form', (e) -> e.preventDefault()
  .on 'keyup', '.f-c-layout-sidebar-search__input', handle
  .on 'click', '.js-f-c-layout-sidebar-search-cancel', cancel
