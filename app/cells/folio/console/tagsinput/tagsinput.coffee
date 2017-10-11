#= require selectize/standalone/selectize

makeItems = (string) ->
  if string
    string.split(' ')
  else
    []

$ ->
  $inputs = $('.folio-tagsinput').not('.folio-bound')
  return if $inputs.length is 0
  $inputs.addClass('folio-bound').removeClass('form-control')

  $inputs.each ->
    $this = $(this)
    $this.selectize
      delimiter: ','
      persist: false
      labelField: 'value'
      searchField: 'value'
      items: makeItems($this.val())
      options: makeItems($this.data('tags')).map((tag) -> { value: tag })
      create: (input) ->
        { value: input }
