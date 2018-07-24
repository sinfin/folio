checkSubmit = ->
  $submit = $('.folio-console-index-checkboxes-submit')
  $checkboxes = $('.folio-console-index-checkboxes-checkbox:checked')
  count = $checkboxes.length

  if count > 0
    $submit.find('.folio-console-index-checkboxes-submit-count').html(" (#{count})")
    $submit.prop('disabled', false)
  else
    $submit.find('.folio-console-index-checkboxes-submit-count').html('')
    $submit.prop('disabled', true)

$(document).on 'click', '.folio-console-index-checkboxes-check-all', ->
  $('.folio-console-index-checkboxes-checkbox').prop('checked', true)
  checkSubmit()

$(document).on 'click', '.folio-console-index-checkboxes-uncheck-all', ->
  $('.folio-console-index-checkboxes-checkbox').prop('checked', false)
  checkSubmit()

$(document).on 'change', '.folio-console-index-checkboxes-checkbox', (e) ->
  $input = $(this)
  $input.closest('tr').toggleClass('folio-console-index-checkboxes-highlight', $input.prop('checked'))
  checkSubmit()

$(document).on 'click', '.folio-console-index-checkboxes-toggle', ->
  $('.folio-console-index-table').toggleClass('folio-console-index-checkboxes-on')

$(document).on 'click', '.folio-console-index-checkboxes-on td', ->
  $this = $(this)
  return if $this.hasClass('folio-console-index-checkboxes-td')
  $this.closest('tr').find('.folio-console-index-checkboxes-checkbox').click()
