import React from 'react'
import { FormGroup, FormText, Label } from 'reactstrap'

import formGroupClassName from './utils/formGroupClassName'
import AtomInput from './AtomInput'
import CharacterCounter from './CharacterCounter'
import EmptyFormText from './EmptyFormText'

export default function Fields ({ atom, index, onChange, onValueChange }) {
  const { meta } = atom.record

  return (
    <React.Fragment>
      {Object.keys(meta.structure).map((key) => {
        const isCheck = meta.structure[key] && meta.structure[key].type === 'boolean'

        return (
          <FormGroup
            key={key}
            className={formGroupClassName(key, atom.errors, meta.structure)}
            check={isCheck}
          >
            <Label
              check={isCheck}
            >
              {isCheck && (
                <AtomInput
                  key={key}
                  field={key}
                  atom={atom}
                  index={index}
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
                atom={atom}
                index={index}
                onChange={onChange}
                onValueChange={onValueChange}
              />
            )}

            {meta.structure[key].hint && (
              <FormText>
                {meta.structure[key].hint.split(/\n/).map((part, i) => <div key={i}>{part}</div>)}
              </FormText>
            )}

            {atom.errors[key] && (
              <FormText className='invalid-feedback' color='danger'>{atom.errors[key]}</FormText>
            )}

            <EmptyFormText hasErrors={atom.errors[key]} structure={meta.structure[key]} />

            {meta.structure[key].character_counter && <CharacterCounter value={atom.record.data[key]} />}
          </FormGroup>
        )
      })}
    </React.Fragment>
  )
}
