$(document).on('turbolinks:load', () => {
  $('input[name="authenticity_token"]').val($('meta[name="csrf-param"]').prop('content'))
})
