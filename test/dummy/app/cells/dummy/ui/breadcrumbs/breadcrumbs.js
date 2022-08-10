$(document).on('turbolinks:load', () => {
  $('.d-ui-breadcrumbs__link--pagy-page').each((i, el) => {
    const match = window.location.search.match(/page=(\d+)/)

    if (match && match[1] && parseInt(match[1]) > 1) {
      const joiner = el.href.indexOf('?') === -1 ? '?' : '&'
      el.href = `${el.href}${joiner}${match[0]}`
    }
  })
})
