import React from 'react'

import ReactSelect from 'react-select'
import CreatableSelect from 'react-select/lib/Creatable'

import selectStyles from './selectStyles'
import formatOption from './formatOption'
import formatOptions from './formatOptions'
import formatCreateLabel from './formatCreateLabel'
import makeNoOptionsMessage from './makeNoOptionsMessage'

class Select extends React.Component {
  onChange = (value) => {
    if (this.props.isMulti) {
      return this.props.onChange(value.map((item) => item.value))
    } else {
      return this.props.onChange(value ? value.value : null)
    }
  }

  render () {
    const { createable, value, options, onChange, innerRef, ...rest } = this.props
    let SelectComponent = CreatableSelect
    if (!createable) SelectComponent = ReactSelect

    let formattedValue = null
    if (value) {
      formattedValue = this.props.isMulti ? formatOptions(value) : formatOption(value)
    }

    return (
      <SelectComponent
        name='form-field-name'
        className='react-select-container'
        classNamePrefix='react-select'
        value={formattedValue}
        options={formatOptions(options)}
        formatCreateLabel={formatCreateLabel}
        onChange={this.onChange}
        createable={createable}
        noOptionsMessage={makeNoOptionsMessage(options)}
        ref={innerRef}
        styles={selectStyles}
        {...rest}
      />
    )
  }
}

export default Select
