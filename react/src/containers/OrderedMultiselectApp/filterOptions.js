const optionIdentifier = (option) => {
  if (option.id !== undefined && option.id !== null) return option.id

  return option.value
}

const optionIsSelected = (option, selectedValues) => {
  return selectedValues.has(String(optionIdentifier(option)))
}

const filterOptions = (options, items) => {
  if (!options) return null

  const selectedValues = new Set(items.map((item) => String(item.value)))

  return options.map((option) => {
    if (option.options) {
      const groupOptions = option.options.filter((groupOption) => {
        return !optionIsSelected(groupOption, selectedValues)
      })

      if (!groupOptions.length) return null

      return {
        ...option,
        options: groupOptions
      }
    }

    return optionIsSelected(option, selectedValues) ? null : option
  }).filter(Boolean)
}

export default filterOptions
