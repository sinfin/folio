// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files

(function () {
  $.fn.cstypo = function () {
    let regexp
    regexp = /([szkvaiou%])/i
    return this.each(function () {
      let $this, replaced, words
      $this = window.jQuery(this)
      words = $this.html().split(' ')
      replaced = jQuery.map(words, function (word) {
        if (word.length === 1 && word.match(regexp)) {
          return word.replace(regexp, '$1&nbsp;')
        } else {
          return word + ' '
        }
      })
      return $this.html(replaced.join(''))
    })
  }

  if (window.jQuery('html').prop('lang') === 'cs') {
    window.jQuery(document).on('turbolinks:load', function () {
      return window.jQuery('p').cstypo()
    })
  }
})()
