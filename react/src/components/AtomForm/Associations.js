import React from 'react'
import { FormGroup, FormText, Label } from 'reactstrap'

import Select from 'components/Select'
import formGroupClassName from './utils/formGroupClassName'

const recordToReactSelectOption = (record) => {
  if (!record) return null
  return {
    value: record.value || record.id,
    label: record.text || record.label || ''
  }
}

const reactSelectOptionToRecord = (option) => {
  if (!option) return null
  
  // Extract id and type with fallbacks
  // option.value is the STI string like "Economia::List::Category -=- 48"
  // option.id is the numeric ID from the API response
  // option.type is the class name like "Economia::List::Category"
  let id = option.id
  let type = option.type
  
  if (id === undefined && typeof option.value === 'string' && option.value.includes(' -=- ')) {
    // Extract numeric ID and type from STI format: "Class -=- 48" -> {id: 48, type: "Class"}
    const parts = option.value.split(' -=- ')
    if (parts.length > 1) {
      id = parts[1]
      type = type || parts[0] // Use type from option if available, otherwise extract from value
    } else {
      id = option.value
    }
  } else if (id === undefined) {
    // Fallback to value if no id available
    id = option.value
  }
  
  // Pass through all fields from option, ensuring required ones are set
  return {
    ...option, // Pass through all fields (id, text, label, value, type, etc.)
    id: id, // Override with extracted/fallback id
    type: type || option.type, // Ensure type is set
    text: option.text || option.label, // Ensure text is set
    label: option.label || option.text || '' // Ensure label is set
  }
}

class Associations extends React.PureComponent {
  constructor (props) {
    super(props)
    this.selectRef = React.createRef()
  }

  handleChange = (key, option) => {
    const { onChange, index } = this.props
    const record = reactSelectOptionToRecord(option)
    onChange(record, index, key)
  }

  render () {
    const { atom, asyncData, index, onBlur, onFocus, addAtomSettings } = this.props
    const { associations } = atom.record.meta

    return (
      <React.Fragment>
        {Object.keys(associations).map((key) => {
          const record = atom.record.associations[key]
          const value = recordToReactSelectOption(record)

          return (
            <FormGroup key={key} className={formGroupClassName(key, atom.errors)}>
              <Label className='form-label'>{associations[key].label}</Label>

              <Select
                async={associations[key].url}
                asyncData={asyncData}
                value={value}
                onChange={(option) => this.handleChange(key, option)}
                onBlur={onBlur}
                onFocus={onFocus}
                innerRef={this.selectRef}
                addAtomSettings={addAtomSettings}
                defaultOptions
              />

              {associations[key].hint && <FormText>{associations[key].hint}</FormText>}
              {atom.errors[key] && <FormText className='invalid-feedback' color='danger'>{atom.errors[key]}</FormText>}
            </FormGroup>
          )
        })}
      </React.Fragment>
    )
  }
}

export default Associations
