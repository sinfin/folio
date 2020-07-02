export default (values) => {
  if (values === true) {
    return true
  } else if (values) {
    return values.map((value) => ({ value, label: value }))
  } else {
    return []
  }
}
