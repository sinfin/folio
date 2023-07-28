#= require folio/i18n

(($R) ->
  i18n =
    cs:
      shortForCharacter: 'zn.'
    en:
      shortForCharacter: 'ch.'

  $R.add 'plugin', 'character_counter',
    init: (app) ->
      @app = app
      @lang = app.lang
      @utils = app.utils
      @editor = app.editor
      @statusbar = app.statusbar
      return
    start: ->
      $editor = @editor.getElement()
      $editor.on 'keyup.redactor-plugin-character_counter', @count.bind(this)
      @count()
      return
    stop: ->
      $editor = @editor.getElement()
      $editor.off '.redactor-plugin-character_counter'
      @statusbar.remove 'chars'
      return
    count: ->
      characters = 0
      $editor = @editor.getElement()
      html = $editor.html()
      html = @_clean(html)

      if html != ''
        characters = html.length

      data =
        characters: characters

      # callback
      @app.broadcast 'character_counter', data

      # statusbar

      if @app.opts.characterCounterMax
        text = "#{data.characters} / #{@app.opts.characterCounterMax} #{window.Folio.i18n(i18n, 'shortForCharacter')}"
      else
        text = "#{data.characters} #{window.Folio.i18n(i18n, 'shortForCharacter')}"

      @statusbar.add 'chars', text

      return
    _clean: (html) ->
      html = html.replace(/<\/(.*?)>/gi, ' ')
      html = html.replace(/<(.*?)>/gi, '')
      html = html.replace(/\t/gi, '')
      html = html.replace(/\n/gi, ' ')
      html = html.replace(/\r/gi, ' ')
      html = html.replace(/&nbsp;/g, '1')
      html = html.trim()
      html = @utils.removeInvisibleChars(html)
      html
  return
)(Redactor)
