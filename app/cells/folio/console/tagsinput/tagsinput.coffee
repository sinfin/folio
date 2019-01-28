optionMapper = (str) -> { value: str }

makeItems = (string) ->
  if string
    string.split(', ').map(optionMapper)
  else
    []

$ ->
  $inputs = $('.folio-console-tagsinput').not('.folio-console-selectize--bound')
  return if $inputs.length is 0

  $inputs.each ->
    $this = $(this)
    $formGroup = $this.closest('.form-group')

    if $formGroup.data('allow-create')
      createOption = optionMapper
    else
      createOption = false

    $this.selectize
      dropdownParent: 'body'
      labelField: 'value'
      searchField: 'value'
      delimiter: ', '
      plugins: ['remove_button']
      create: createOption
      options: makeItems($formGroup.data('collection'))
      maxOptions: 50000
      render:
        option_create: (data, escape) ->
          """
            <div class="create">
              #{window.FolioConsole.translations.add}
              <strong>#{escape(data.input)}</strong>&hellip;
            </div>
          """
