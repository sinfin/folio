import React from 'react'
import { FormGroup, FormText, Label } from 'reactstrap'

import formGroupClassName from './utils/formGroupClassName'
import AtomInput from './AtomInput'

export default function Fields ({ form, onChange, onValueChange }) {
  const { meta } = form.atom

  return (
    <React.Fragment>
      {Object.keys(meta.structure).map((key) => {
        const isCheck = meta.structure[key] && meta.structure[key].type === 'boolean'

        return (
          <FormGroup
            key={key}
            className={formGroupClassName(key, form.errors, meta.structure)}
            check={isCheck}
          >
            <Label
              check={isCheck}
            >
              {isCheck && (
                <AtomInput
                  key={key}
                  field={key}
                  form={form}
                  onChange={onChange}
                  onValueChange={onValueChange}
                />
              )}
              {isCheck && ' '}
              {meta.structure[key].label}
            </Label>

            {!isCheck && (
              <AtomInput
                key={key}
                field={key}
                form={form}
                onChange={onChange}
                onValueChange={onValueChange}
              />
            )}

            {meta.structure[key].hint && <FormText>{meta.structure[key].hint}</FormText>}

            {form.errors[key] && (
              <FormText className='invalid-feedback' color='danger'>{form.errors[key]}</FormText>
            )}
          </FormGroup>
        )
      })}
    </React.Fragment>
  )
}
