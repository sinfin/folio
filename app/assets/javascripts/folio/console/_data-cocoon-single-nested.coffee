$(document).on 'single-nested-change', '[data-cocoon-single-nested]', (e) ->
  $this = $(this)
  $fields = $this.find('.nested-fields').not('[hidden]')
  $this.toggleClass('folio-console-has-nested', $fields.length > 0)
