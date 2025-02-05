import React from 'react'
import { FormGroup, FormText, Label } from 'reactstrap'

import formGroupClassName from './utils/formGroupClassName'
import AtomInput from './AtomInput'
import SplittableButton from './SplittableButton'

export default function Field ({ atom, field, index, onChange, onValueChange, startSplittingAtom }) {
  const { meta } = atom.record
  const isCheck = meta.structure[field] && meta.structure[field].type === 'boolean'

  return (
    <FormGroup
      key={field}
      className={formGroupClassName(field, atom.errors, meta.structure)}
      check={isCheck}
    >
      <Label
        className='form-label'
        check={isCheck}
      >
        {isCheck && (
          <AtomInput
            key={field}
            field={field}
            atom={atom}
            index={index}
            onChange={onChange}
            onValueChange={onValueChange}
          />
        )}
        {isCheck && ' '}
        {meta.structure[field].label}
      </Label>

      {!isCheck && (
        <AtomInput
          key={field}
          field={field}
          atom={atom}
          index={index}
          onChange={onChange}
          onValueChange={onValueChange}
          characterCounter={meta.structure[field].character_counter}
        />
      )}

      {meta.structure[field].hint && (
        <FormText>
          {meta.structure[field].hint.split(/\n/).map((part, i) => <div key={i}>{part}</div>)}
        </FormText>
      )}

      {atom.errors[field] && (
        <FormText className='invalid-feedback' color='danger'>{atom.errors[field]}</FormText>
      )}

      {meta.structure[field].splittable && (
        <SplittableButton startSplittingAtom={() => { startSplittingAtom(atom, field) }} />
      )}
    </FormGroup>
  )
}
