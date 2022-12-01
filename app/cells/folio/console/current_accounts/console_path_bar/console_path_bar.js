$(() => {
  const $bar = $('.f-c-current-accounts-console-path-bar')
  if ($bar.length !== 1) return

  const url = $bar.data('url')

  window.setInterval(() => {
    $.ajax({
      url,
      method: "POST",
      data: { path: window.location.pathname }
    })
  }, 10000)
})
