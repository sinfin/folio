import React from 'react'
import { FormGroup, FormText, Input, Label } from 'reactstrap'

import formGroupClassName from './utils/formGroupClassName'

export default function Associations ({ form, onChange }) {
  const { associations } = form.atom.meta

  return (
    <React.Fragment>
      {Object.keys(associations).map((key) => (
        <FormGroup key={key} className={formGroupClassName(key, form.errors)}>
          <Label>{associations[key].label}</Label>
          <Input
            type='select'
            name={key}
            defaultValue={form.atom.associations[key] ? form.atom.associations[key].value : ''}
            onChange={(e) => onChange(e, key)}
            invalid={Boolean(form.errors[key])}
          >
            <option value='' />
            {associations[key].records.map((record) => (
              <option key={record.value} value={record.value}>{record.label}</option>
            ))}
          </Input>

          {associations[key].hint && <FormText>{associations[key].hint}</FormText>}
          {form.errors[key] && <FormText className='invalid-feedback' color='danger'>{form.errors[key]}</FormText>}
        </FormGroup>
      ))}
    </React.Fragment>
  )
}
