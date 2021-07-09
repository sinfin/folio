export default {
  container: (base) => ({
    ...base,
    borderRadius: '0.15rem'
  }),
  control: (base, state) => ({
    ...base,
    borderColor: state.isFocused ? '#86c8ec' : base.borderColor,
    borderRadius: '0.15rem',
    boxShadow: state.isFocused ? '0 0 0 0.2rem rgba(33, 148, 210, 0.25)' : base.boxShadow,
    minHeight: '35px',
    '&:hover': {
      borderColor: state.isFocused ? '#86c8ec' : base.borderColor,
      boxShadow: state.isFocused ? '0 0 0 0.2rem rgba(33, 148, 210, 0.25)' : base.boxShadow
    }
  }),
  menuList: (base) => ({
    ...base,
    maxHeight: '304px'
  }),
  dropdownIndicator: (base) => ({
    ...base,
    padding: '6px'
  }),
  clearIndicator: (base) => ({
    ...base,
    padding: '6px'
  }),
  placeholder: (base) => ({
    ...base,
    color: '#bfc4c4'
  }),
  option: (base, state) => {
    let { color, backgroundColor } = base

    if (state.isFocused) {
      backgroundColor = '#c7e4f4'
      color = 'inherit'
    } else if (state.isSelected) {
      backgroundColor = '#2684FF'
    }

    return ({
      ...base,
      color,
      backgroundColor,
      textOverflow: 'ellipsis',
      overflow: 'hidden'
    })
  }
}
