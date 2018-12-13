export default function getPlacementField ($fields, name) {
  const $input = $fields.filter((_i, inp) => {
    return inp.name && inp.name.match(new RegExp(`\\[${name}\\]$`))
  })
  return $input.val()
}
