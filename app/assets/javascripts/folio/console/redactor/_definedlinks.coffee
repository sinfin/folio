(($R) ->
  $R.add 'plugin', 'definedlinks',
    init: (app) ->
      @app = app
      @opts = app.opts
      @component = app.component
      # local
      @$select = null
      @$urlInput = null

    onmodal:
      link:
        open: ($modal, $form) ->
          return unless @opts.definedlinks
          @$modal = $modal
          @$form = $form
          @_load()
        close: ->
          if @$select and @$select.select2
            @$select.off 'select2:select'
            @$select.select2('destroy')
            @$select = null
            @$urlInput = null

    _load: ->
      @_build(this.opts.definedlinks) if @opts.definedlinks

    _build: (url) ->
      modal = @$modal.nodes[0]
      $modal = $(modal)

      @$urlInput = $modal.find('#modal-link-url')

      if $modal.find('.redactor-defined-links').length is 0
        @$urlInput.wrap '<div class=\'row\'></div>'
        @$urlInput.wrap '<div class=\'col-md-8\'></div>'
        $row = @$urlInput.closest('.row')
        $row.prepend '<div class="col-md-4"><select class="form-control redactor-defined-links" /></div>'

      @links = []

      @$select = $modal.find('.redactor-defined-links')

      @$select.select2
        width: "100%"
        language: document.documentElement.lang
        ajax:
          url: url
          dataType: "JSON"
          minimumInputLength: 0
          cache: false
          data: (params) -> { q: params.term }
        templateSelection: (data, container) ->
          $el = $(data.element)
          Object.keys(data).forEach (key) ->
            if key.indexOf('data-') is 0
              $el.attr(key, data[key])
          return data.text

      @$select.on 'select2:select', (e) =>
        @$urlInput
          .val(e.params.data.id)
          .addClass('form-control--hinted')

        $linkText = $modal.find('#modal-link-text')
        if $linkText.length and not $linkText.val()
          $linkText
            .val(e.params.data['data-title'])
            .addClass('form-control--hinted')

        setTimeout (=>
          $linkText.removeClass('form-control--hinted')
          @$urlInput.removeClass('form-control--hinted') if @$urlInput
        ), 1000

)(Redactor)
