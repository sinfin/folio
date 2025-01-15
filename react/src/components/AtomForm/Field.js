import React from 'react'
import { FormText, Label } from 'reactstrap'

import formGroupClassName from './utils/formGroupClassName'
import AtomInput from './AtomInput'
import SplittableButton from './SplittableButton'

class Field extends React.PureComponent {
  constructor (props) {
    super(props)
    this.formGroupRef = React.createRef()
  }

  componentDidMount () {
    if (!this.formGroupRef.current) return

    const type = this.props.atom.record.meta.structure[this.props.field].type

    if (type === 'url' || type === 'url_json') {
      window.Folio.Input.Url.initFormGroup(this.formGroupRef.current, { json: type === 'url_json' })
    }
  }

  componentWillUnmount () {
    if (!this.formGroupRef.current) return

    const type = this.props.atom.record.meta.structure[this.props.field].type

    if (type === 'url' || type === 'url_json') {
      window.Folio.Input.Url.disposeFormGroup(this.formGroupRef.current)
    }
  }

  render () {
    const { atom, field, index, onChange, onValueChange, startSplittingAtom } = this.props
    const { meta } = atom.record
    const isCheck = meta.structure[field] && meta.structure[field].type === 'boolean'

    return (
      <div
        className={`form-group ${formGroupClassName(field, atom.errors, meta.structure)} ${isCheck ? 'form-check' : ''}`}
        ref={this.formGroupRef}
        hidden={meta.structure[field].type === 'deprecated'}
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
      </div>
    )
  }
}

export default Field
