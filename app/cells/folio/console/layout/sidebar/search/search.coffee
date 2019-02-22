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
      console.log(response)
    error: ->
      console.log('error')

debouncedSearch = $.debounce(search, 300)

handle = ->
  debouncedSearch(this)

  $wrap ||= $('.f-c-layout-sidebar-search')
  if @value is ''
    $wrap.removeClass('f-c-layout-sidebar-search--searching \
                       f-c-layout-sidebar-search--loading')
  else
    $wrap.addClass('f-c-layout-sidebar-search--searching \
                    f-c-layout-sidebar-search--loading')

$(document).on 'keyup', '.f-c-layout-sidebar-search__input', handle
