#= require selectize/standalone/selectize

makeItems = (separator, string) ->
  if string
    string.split(separator)
  else
    []

$ ->
  $inputs = $('.folio-tagsinput').not('.folio-bound')
  return if $inputs.length is 0
  $inputs.addClass('folio-bound').removeClass('form-control')

  $inputs.each ->
    $this = $(this)

    if $this.data('allow-create')
      createOption = (input) -> { value: input }
    else
      createOption = false

    if $this.data('comma-separated')
      separator = /,\s*/
    else
      separator = ' '

    $this.selectize
      delimiter: ','
      persist: false
      labelField: 'value'
      searchField: 'value'
      items: makeItems(separator, $this.val())
      options: makeItems(separator, $this.data('tags')).map((tag) -> { value: tag })
      create: createOption
