import React from 'react'
import { FormGroup, FormText, Input, Label } from 'reactstrap'

import formGroupClassName from './utils/formGroupClassName'

export default function Associations ({ atom, index, onChange }) {
  const { associations } = atom.record.meta

  return (
    <React.Fragment>
      {Object.keys(associations).map((key) => (
        <FormGroup key={key} className={formGroupClassName(key, atom.errors)}>
          <Label>{associations[key].label}</Label>
          <Input
            type='select'
            name={key}
            defaultValue={atom.record.associations[key] ? atom.record.associations[key].value : ''}
            onChange={(e) => onChange(e, index, key)}
            invalid={Boolean(atom.errors[key])}
          >
            <option value='' />
            {associations[key].records.map((record) => (
              <option key={record.value} value={record.value}>{record.label}</option>
            ))}
          </Input>

          {associations[key].hint && <FormText>{associations[key].hint}</FormText>}
          {atom.errors[key] && <FormText className='invalid-feedback' color='danger'>{atom.errors[key]}</FormText>}
        </FormGroup>
      ))}
    </React.Fragment>
  )
}
