function truncate (string, length = 30) {
  if (string.length > length) return `${string.substr(0, 27)}...`
  return string
}

export default truncate
