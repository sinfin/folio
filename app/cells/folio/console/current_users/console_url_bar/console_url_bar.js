$(() => {
  const $bar = $('.f-c-current-users-console-url-bar')
  if ($bar.length !== 1) return

  const url = $bar.data('url')

  window.setInterval(() => {
    $.ajax({
      url,
      method: "POST",
      data: { url: window.location.href.split('?')[0] }
    })
  }, 10000)
})
