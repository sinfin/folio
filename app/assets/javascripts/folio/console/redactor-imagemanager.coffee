$R.add 'plugin', 'imagemanager',
  translations:
    cs:
      choose: 'Vybrat'
    en:
      choose: 'Choose'

  init: (app) ->
    @app = app
    @lang = app.lang
    @opts = app.opts
    return

  onmodal:
    image:
      open: ($modal, $form) ->
        @_load $modal
        return

  _load: ($modal) ->
    $box = $("""
      <div
        style="height: 300px; display: none;"
        class="redactor-modal-tab redactor-modal-bootstrap"
        data-title="Choose"
        data-mode="single-select"
        data-file-type="Folio::Image"
      >
      </div>
    """)
    $modal.getBody().append($box)
    folioConsoleInitReact($box[0])

    window.folioConsoleInsertImage = (image) =>
      json = Object.assign {}, image, id: image.file_id
      @_insert(json)

  _insert: (data) ->
    @app.api 'module.image.insert', image: data
