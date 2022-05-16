$(document).on('turbolinks:load', () => {
  const $param = $('meta[name="csrf-param"]')

  if ($param && $param.prop('content')) {
    $(`input[name="${$param.prop('content')}"]`).val($('meta[name="csrf-token"]').prop('content'))
  }
})
