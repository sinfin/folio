import React from 'react'

const FormGroup = ({ value, onChange, label, placeholder, name, hint }) => (
  <div className='form-group'>
    {label && <label className='control-label'>{label}</label>}

    <input
      className='form-control'
      value={value || ''}
      onChange={onChange}
      placeholder={placeholder}
      name={name}
      type='text'
    />

    {hint && <small className='form-text'>{hint}</small>}
  </div>
)

export default FormGroup
