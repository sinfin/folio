export default function getJsonFromMultiSelectDom ($element) {
  const h = []
  const $ = window.jQuery

  $element.find('.f-c-file-placement').each((i, el) => {
    const $el = $(el)
    const $fileId = $el.find('input[type="hidden"]').filter((index, input) => input.name.indexOf('file_id') !== -1)

    h.push({
      file_id: $fileId.val(),
      title: $el.find('.f-c-file-placement__title .form-control').val(),
      alt: $el.find('.f-c-file-placement__alt .form-control').val(),
      position: i + 1
    })
  })

  return h
}
