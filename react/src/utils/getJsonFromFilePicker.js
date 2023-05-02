const WHITELIST = ['file_id', 'alt', 'title']

const nameFromInput = (input) => input.name.match(/\[(\w+)\]/g).pop().replace('[', '').replace(']', '')

export default function getJsonFromFilePicker ($element) {
  console.log($element)
  const $inputs = $element.find('input')

  if ($inputs.length === 0) return null

  let destroy = false
  const data = {}

  $inputs.each((i, input) => {
    const name = nameFromInput(input)
    if (name === '_destroy' && input.value !== '0') {
      destroy = true
    } else if (WHITELIST.indexOf(name) !== -1) {
      data[name] = input.value
    }
  })

  if (!destroy && data['file_id']) {
    return data
  } else {
    return null
  }
}
