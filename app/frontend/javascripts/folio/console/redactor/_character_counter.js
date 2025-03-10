//= require folio/i18n

// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files

(function ($R) {
  let i18n
  i18n = {
    cs: {
      shortForCharacter: 'zn.'
    },
    en: {
      shortForCharacter: 'ch.'
    }
  }
  $R.add('plugin', 'character_counter', {
    init: function (app) {
      this.app = app
      this.lang = app.lang
      this.utils = app.utils
      this.editor = app.editor
      this.statusbar = app.statusbar
    },
    start: function () {
      let $editor
      $editor = this.editor.getElement()
      $editor.on('keyup.redactor-plugin-character_counter', this.count.bind(this))
      this.count()
    },
    stop: function () {
      let $editor
      $editor = this.editor.getElement()
      $editor.off('.redactor-plugin-character_counter')
      this.statusbar.remove('chars')
    },
    count: function () {
      let $editor, characters, data, formattedMax, html, result, text
      characters = 0
      $editor = this.editor.getElement()
      html = $editor.html()
      result = window.Folio.wordCount({
        text: html
      })
      data = {
        characters: result.charactersWithSpaces
      }
      // callback
      this.app.broadcast('character_counter', data)
      // statusbar
      if (this.app.opts.characterCounterMax) {
        formattedMax = new Intl.NumberFormat('en-US', {
          maximumFractionDigits: 0,
          useGrouping: true
        }).format(this.app.opts.characterCounterMax).replace(/,/g, ' ')
        text = `${result.formattedCharacters} / ${formattedMax} ${window.Folio.i18n(i18n, 'shortForCharacter')}`
      } else {
        text = `${result.formattedCharacters} ${window.Folio.i18n(i18n, 'shortForCharacter')}`
      }
      this.statusbar.add('chars', text)
    },
    _clean: function (html) {
      html = html.replace(/<\/(.*?)>/gi, ' ')
      html = html.replace(/<(.*?)>/gi, '')
      html = html.replace(/\t/gi, '')
      html = html.replace(/\n/gi, ' ')
      html = html.replace(/\r/gi, ' ')
      html = html.replace(/&nbsp;/g, '1')
      html = html.trim()
      html = this.utils.removeInvisibleChars(html)
      return html
    }
  })
})(window.Redactor)
