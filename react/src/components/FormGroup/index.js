import React from 'react'

const FormGroup = ({ value, onChange, onBlur, label, placeholder, name, hint }) => (
  <div className='form-group'>
    {label && <label className='control-label'>{label}</label>}

    <input
      className='form-control'
      value={value || ''}
      onChange={onChange}
      onBlur={onBlur}
      placeholder={placeholder}
      name={name}
      type='text'
    />

    {hint && <small className='form-text'>{hint}</small>}
  </div>
)

export default FormGroup
