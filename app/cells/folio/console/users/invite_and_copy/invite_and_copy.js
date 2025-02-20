// converted via https://coffeescript.org/#try
// once you update it, remove it from package.json standard js ignored files
window.jQuery(function () {
  return window.jQuery('.f-c-users-invite-and-copy__button').on('click', function (e) {
    e.preventDefault()
    const $this = window.jQuery(this)
    return window.jQuery.ajax({
      method: 'POST',
      url: $this.data('url'),
      success: function (res) {
        let $res
        if (res && res.data) {
          $res = window.jQuery(res.data)
          $this.closest('.f-c-users-invite-and-copy').replaceWith($res)
          $res.find('.f-c-users-invite-and-copy__input').focus().select()
          return window.bindFolioConsoleClipboardCopyIn($res)
        } else {
          return window.alert($this.data('failure'))
        }
      },
      failure: function () {
        return window.alert($this.data('failure'))
      }
    })
  })
})
