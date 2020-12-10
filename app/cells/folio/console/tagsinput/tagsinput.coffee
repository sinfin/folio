optionMapper = (str) -> { value: str }

makeItems = (string) ->
  if string
    string.split(', ').map(optionMapper)
  else
    []

init = ->
  $inputs = $('.f-c-tagsinput')
  return if $inputs.length is 0

  $inputs.each ->
    $selectize = $(this)
    $formGroup = $selectize.closest('.form-group')

    if $formGroup.data('allow-create')
      createOption = optionMapper
    else
      createOption = false

    $selectize.selectize
      dropdownParent: 'body'
      labelField: 'value'
      searchField: 'value'
      delimiter: ', '
      plugins: ['remove_button']
      create: createOption
      createFilter: (val) ->
        return false if @items.indexOf(val) isnt -1
        valid = true
        @currentResults.items.forEach (item) ->
          valid = valid and item.id isnt val
        return valid
      maxOptions: 50000
      preload: 'focus'
      onChange: (_value) ->
        $selectize.trigger('change')
      load: (q, callback) ->
        $.ajax
          url: '/console/api/tags/react_select'
          method: 'GET'
          data:
            q: q
            context: $selectize.data('context')
          error: ->
            callback()
          success: (res) ->
            callback(res.data.map(optionMapper))
      render:
        option_create: (data, escape) ->
          """
            <div class="create">
              #{window.FolioConsole.translations.add}
              <strong>#{escape(data.input)}</strong>&hellip;
            </div>
          """

dispose = ->
  $('.f-c-tagsinput').each ->
    @selectize?.destroy()

if Turbolinks?
  $(document)
    .on 'turbolinks:load', init
    .on 'turbolinks:before-cache', dispose

else
  $ init
