const FOLIO_CONSOLE_BLUE = '#4C84FD'
const FOLIO_CONSOLE_BLUE_CONTRAST = '#fff'

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
  groupHeading: (base) => ({
    ...base,
    color: 'inherit',
    fontSize: 'inherit',
    fontWeight: 700,
    margin: 0,
    padding: '0px 12px 8px 12px',
    textTransform: 'none'
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
    const activeStyles = state.isDisabled
      ? base[':active']
      : {
        ...base[':active'],
        backgroundColor: FOLIO_CONSOLE_BLUE,
        color: FOLIO_CONSOLE_BLUE_CONTRAST
      }

    if (state.isFocused) {
      backgroundColor = FOLIO_CONSOLE_BLUE
      color = FOLIO_CONSOLE_BLUE_CONTRAST
    } else if (state.isSelected) {
      backgroundColor = FOLIO_CONSOLE_BLUE
      color = FOLIO_CONSOLE_BLUE_CONTRAST
    }

    return ({
      ...base,
      color,
      backgroundColor,
      ':active': activeStyles,
      whiteSpace: 'normal'
    })
  }
}
