window.Folio = window.Folio || {}

window.Folio.onOutsideClick = (selector, callback) => {
  window.jQuery(document).on('click.folioOnOutsideClick', (e) => {
    const $target = window.jQuery(e.target)
    if ($target.closest(selector).length) return

    window.jQuery(document).off('click.folioOnOutsideClick')
    callback(e, [selector])
  })
}
