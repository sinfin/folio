export default {
  container: (base) => ({
    ...base,
    borderRadius: '0.15rem',
  }),
  control: (base, state) => ({
    ...base,
    borderColor: state.isFocused ? '#86c8ec' : base.borderColor,
    borderRadius: '0.15rem',
    boxShadow: state.isFocused ? '0 0 0 0.2rem rgba(33, 148, 210, 0.25)' : base.boxShadow,
    minHeight: '36px',
    '&:hover': {
      borderColor: state.isFocused ? '#86c8ec' : base.borderColor,
      boxShadow: state.isFocused ? '0 0 0 0.2rem rgba(33, 148, 210, 0.25)' : base.boxShadow,
    }
  }),
  dropdownIndicator: (base) => ({
    ...base,
    padding: '7px',
  }),
  option: (base, state) => ({
    ...base,
    backgroundColor: state.isFocused ? '#c7e4f4' : base.backgroundColor,
  }),
}
