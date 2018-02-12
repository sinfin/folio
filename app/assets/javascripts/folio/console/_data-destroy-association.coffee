$(document).on 'click', '[data-destroy-association]', (e) ->
  $this = $(this)
  $fields = $this.closest('.nested-fields')

  $fields.find('input').filter(->
    this.name.indexOf('[_destroy]') isnt -1
  ).val(1)

  $fields.attr('hidden', true)
