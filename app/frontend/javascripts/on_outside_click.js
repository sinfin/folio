(() => {
  window.Folio = window.Folio || {}

  let count = 0

  const counter = () => {
    count += 1
    return count
  }

  window.Folio.onOutsideClick = (selector, callback) => {
    const thisCount = counter()

    window.jQuery(document).on(`click.folioOnOutsideClick${thisCount}`, (e) => {
      const $target = window.jQuery(e.target)
      if ($target.closest(selector).length) return

      window.jQuery(document).off(`click.folioOnOutsideClick${thisCount}`)
      callback(e, [selector])
    })
  }
})()
