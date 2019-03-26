(($R) ->
  $R.add 'plugin', 'button',
    modals:
      button: """
        <form action="">
          <div class="form-item">
            <label>## button-link ##</label>
            <input name="link">
          </div>

          <div class="form-item">
            <label>## button-text ##</label>
            <input name="text">
          </div>
        </form>
      """
    translations:
      cs:
        "button": "Tlačítko"
        "button-link": "Odkaz"
        "button-text": "Text"
        "change": "Upravit"
      en:
        "button": "Button"
        "button-link": "Link"
        "button-text": "Text"
        "change": "Change"

    onmodal:
      button:
        open: ($modal, $form) ->
          node = $modal.app.selection.getCurrent()
          if node?.classList?.contains('folio-redactor-button')
            $a = $(node).find('a')
            $form.getField('link').val($a.attr('href'))
            $form.getField('text').val($a.text())

        opened: ($modal, $form) ->
          $form.getField('link').focus()

        insert: ($modal, $form) ->
          data = $form.getData()
          @insert(data)

    init: (app) ->
      @app = app
      @lang = app.lang
      @toolbar = app.toolbar
      @insertion = app.insertion
      @component = app.component
      return

    start: ->
      $button = @toolbar.addButton 'button',
        title: @lang.get('button')
        api: 'plugin.button.open'

      $button.setIcon('<i class="fa fa-hand-pointer"></i>')

    open: ->
      @app.api 'module.modal.build',
        title: @lang.get('button')
        width: '600px'
        name: 'button'
        handle: 'insert'
        commands:
          insert:
            title: @lang.get('insert')
          cancel:
            title: @lang.get('cancel')

    oncontextbar: (e, contextbar) ->
      e.preventDefault()
      data = @app.inspector.parse(e.target)
      return unless data.isComponentType('button')
      node = data.getComponent()
      buttons =
        change:
          title: @lang.get('change')
          api: 'plugin.button.open'
          args: node
        remove:
          title: @lang.get('delete')
          api: 'plugin.button.remove'
          args: node

      contextbar.set(e, node, buttons, 'bottom')

    remove: (node) ->
      @component.remove(node)

    insert: (data) ->
      @app.api('module.modal.close')

      return if data.text.trim() is ''
      return if data.link.trim() is ''

      $component = @component.create('button', data)
      @insertion.insertHtml($component)

  $R.add 'class', 'button.component',
    mixins: [
      'dom'
      'component'
    ]

    init: (app, data) ->
      @app = app
      @_init(data)

    _init: (data) ->
      @parse("<p class=\"redactor-component folio-redactor-button\"><a href=\"#{data.link}\">#{data.text}</a></p>")
      @attr
        'data-redactor-type': 'button'
        'tabindex': '-1'
        'contenteditable': false

)(Redactor)
