// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files
window.bindFolioConsoleClipboardCopyIn = function ($wrap) {
  return window.bindFolioConsoleClipboardCopy($wrap.find('.f-c-clipboard-copy'))
}

window.bindFolioConsoleClipboardCopy = function ($elements) {
  return $elements.each(function () {
    let clipboard
    clipboard = new ClipboardJS(this)
    clipboard.on('success', function (e) {
      let $trigger
      $trigger = window.jQuery(e.trigger)
      $trigger.addClass('f-c-clipboard-copy--copied')
      return setTimeout(function () {
        return $trigger.removeClass('f-c-clipboard-copy--copied')
      }, 1000)
    })
    return window.jQuery(this).data('clipboard', clipboard)
  })
}

window.unbindFolioConsoleClipboardCopy = function ($elements) {
  return $elements.each(function () {
    let $this, clipboard
    $this = window.jQuery(this)
    clipboard = $this.data('clipboard')
    if (clipboard) {
      clipboard.destroy()
      return $this.data('clipboard', null)
    }
  })
}

window.jQuery(function () {
  if (window.jQuery('.f-c-clipboard-copy').length) {
    return window.bindFolioConsoleClipboardCopy(window.jQuery('.f-c-clipboard-copy'))
  }
})
