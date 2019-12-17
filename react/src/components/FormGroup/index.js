import React from 'react'

import preventEnterSubmit from 'utils/preventEnterSubmit'

const FormGroup = ({ value, onChange, onBlur, label, placeholder, name, hint }) => (
  <div className='form-group'>
    {label && <label className='control-label'>{label}</label>}

    <input
      className='form-control'
      value={value || ''}
      onChange={onChange}
      onBlur={onBlur}
      onKeyPress={preventEnterSubmit}
      placeholder={placeholder}
      name={name}
      type='text'
    />

    {hint && <small className='form-text'>{hint}</small>}
  </div>
)

export default FormGroup
