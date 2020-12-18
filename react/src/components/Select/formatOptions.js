export default (values) => {
  if (values) {
    return values.map((value) => ({ value, label: value }))
  } else {
    return values
  }
}
