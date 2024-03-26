import React from 'react'
import { FormGroup, FormText, Label } from 'reactstrap'

import Select from 'components/Select'
import formGroupClassName from './utils/formGroupClassName'

class Associations extends React.PureComponent {
  constructor (props) {
    super(props)
    this.selectRef = React.createRef()
  }

  render () {
    const { atom, asyncData, index, onBlur, onChange, onFocus, addAtomSettings } = this.props
    const { associations } = atom.record.meta

    return (
      <React.Fragment>
        {Object.keys(associations).map((key) => (
          <FormGroup key={key} className={formGroupClassName(key, atom.errors)}>
            <Label className='form-label'>{associations[key].label}</Label>

            <Select
              async={associations[key].url}
              asyncData={asyncData}
              value={atom.record.associations[key]}
              options={atom.record.associations[key] ? [atom.record.associations[key]] : []}
              onChange={(record) => onChange(record, index, key)}
              onBlur={onBlur}
              onFocus={onFocus}
              innerRef={this.selectRef}
              addAtomSettings={addAtomSettings}
              defaultOptions
              selectize
            />

            {associations[key].hint && <FormText>{associations[key].hint}</FormText>}
            {atom.errors[key] && <FormText className='invalid-feedback' color='danger'>{atom.errors[key]}</FormText>}
          </FormGroup>
        ))}
      </React.Fragment>
    )
  }
}

export default Associations
