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

handle = ->
  $wrap ||= $('.f-c-layout-sidebar-search')
  $wrap.removeClass('f-c-layout-sidebar-search--error')

  if @value is ''
    $wrap.removeClass('f-c-layout-sidebar-search--searching \
                       f-c-layout-sidebar-search--loading')
  else if @value isnt lastValue
    $wrap.addClass('f-c-layout-sidebar-search--searching \
                    f-c-layout-sidebar-search--loading')

  debouncedSearch(this)

$(document).on 'keyup', '.f-c-layout-sidebar-search__input', handle
