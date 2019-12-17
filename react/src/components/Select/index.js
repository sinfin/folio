import React from 'react'

import ReactSelect from 'react-select'
import CreatableSelect from 'react-select/lib/Creatable'
import AsyncSelect from 'react-select/lib/Async'

import { apiGet } from 'utils/api'

import selectStyles from './selectStyles'
import formatOption from './formatOption'
import formatOptions from './formatOptions'
import formatCreateLabel from './formatCreateLabel'
import makeNoOptionsMessage from './makeNoOptionsMessage'

class Select extends React.Component {
  onChange = (value) => {
    if (this.props.selectize) {
      return this.props.onChange(value)
    } else if (this.props.isMulti) {
      return this.props.onChange(value.map((item) => item.value))
    } else {
      return this.props.onChange(value ? value.value : null)
    }
  }

  onKeyDown = (e) => {
    if (e.key === 'Enter') {
      if (this.props.innerRef && this.props.innerRef.current) {
        const ref = this.props.innerRef.current
        if (!ref.select.state.menuIsOpen) {
          e.preventDefault()
        }
      }
    }
  }

  render () {
    const { createable, value, options, onChange, innerRef, selectize, async, ...rest } = this.props
    let SelectComponent = CreatableSelect
    let loadOptions

    if (!createable) SelectComponent = ReactSelect

    if (async) {
      SelectComponent = AsyncSelect

      loadOptions = (inputValue, callback) => {
        apiGet(`${async}&q=${inputValue}`)
          .catch(() => callback([]))
          .then((res) => callback(res ? res.data : []))
      }
    }

    let formattedValue = null

    if (value) {
      if (selectize) {
        formattedValue = value
      } else {
        formattedValue = this.props.isMulti ? formatOptions(value) : formatOption(value)
      }
    }

    return (
      <SelectComponent
        name='form-field-name'
        className='react-select-container'
        classNamePrefix='react-select'
        value={formattedValue}
        options={options ? formatOptions(options) : []}
        formatCreateLabel={formatCreateLabel}
        onChange={this.onChange}
        createable={createable}
        noOptionsMessage={makeNoOptionsMessage(options)}
        ref={innerRef}
        styles={selectStyles}
        loadOptions={loadOptions}
        onKeyDown={this.onKeyDown}
        placeholder={window.FolioConsole.translations.selectPlaceholder}
        {...rest}
      />
    )
  }
}

export default Select
