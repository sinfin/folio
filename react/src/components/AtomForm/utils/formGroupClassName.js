export default function formGroupClassName (key, errors = {}, structure = {}) {
  const classNames = []

  if (errors[key]) {
    classNames.push('form-group-invalid')
  } else {
    classNames.push('form-group-valid')
  }

  if (structure[key]) {
    if (structure[key].type === 'date') {
      classNames.push('date')
    } else if (structure[key].type === 'datetime') {
      classNames.push('datetime')
    } else if (structure[key].type === 'color') {
      classNames.push('color')
    } else if (structure[key].type === 'boolean') {
      classNames.push('mb-3')
    } else if (structure[key].type === 'richtext') {
      classNames.push('redactor')
    }

    if (structure[key].character_counter) {
      classNames.push('f-input-character-counter-wrap__parent')
    }
  }

  return classNames.join(' ')
}
