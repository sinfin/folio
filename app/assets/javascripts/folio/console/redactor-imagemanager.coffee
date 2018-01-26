$.Redactor.prototype.imagemanager = ->
  langs:
    en:
      upload: 'Upload'
      choose: 'Choose'

  init: ->
    return unless @opts.imageManagerJson
    @modal.addCallback 'image', @imagemanager.load

  load: ->
    $box = $("""
      <div
        style="height: 300px; display: none;"
        class="redactor-modal-tab redactor-modal-bootstrap"
        data-title="Choose"
        data-mode="single-select"
      >
      </div>
    """)
    @modal.getModal().append($box)
    folioConsoleInitReact($box[0])

    window.folioConsoleInsertImage = (image) =>
      @image.insert(image)
