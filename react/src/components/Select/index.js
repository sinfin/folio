import React from 'react'
import { debounce } from 'lodash'

import ReactSelect from 'react-select'
import CreatableSelect from 'react-select/creatable'
import AsyncSelect from 'react-select/async'
import AsyncCreatableSelect from 'react-select/async-creatable'

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
      if (value) {
        return this.props.onChange(value.map((item) => item.value))
      } else {
        return this.props.onChange([])
      }
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

  isValidNewOption = (inputValue, selectValue, selectOptions) => {
    if (!inputValue) return false
    let isValid = true

    selectValue.forEach((opt) => {
      if (opt.value === inputValue) isValid = false
    })

    if (isValid) {
      selectOptions.forEach((opt) => {
        if (opt.value === inputValue) isValid = false
      })
    }

    return isValid
  }

  render () {
    const { createable, value, options, onChange, innerRef, selectize, async, asyncData, defaultOptions, ...rest } = this.props
    let SelectComponent = CreatableSelect
    let loadOptions, loadOptionsRaw

    if (!createable) SelectComponent = ReactSelect

    if (async) {
      if (createable) {
        SelectComponent = AsyncCreatableSelect
      } else {
        SelectComponent = AsyncSelect
      }

      loadOptionsRaw = (inputValue, handle) => {
        let data = ''

        if (asyncData) {
          const params = new URLSearchParams()
          Object.keys(asyncData).forEach((key) => {
            params.set(`atom_form_fields[${key}]`, asyncData[key])
          })
          data = params.toString()
          if (data !== '') data = `&${data}`
        }

        const join = async.indexOf('?') === -1 ? '?' : '&'
        apiGet(`${async}${join}q=${inputValue}${data}`)
          .catch(() => handle([]))
          .then((res) => {
            if (res) {
              if (selectize) {
                handle(res.data)
              } else {
                handle(formatOptions(res.data))
              }
            } else {
              handle([])
            }
          })
      }

      loadOptions = debounce(loadOptionsRaw, 300, { leading: true, trailing: true })
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
        options={options ? formatOptions(options) : undefined}
        defaultOptions={defaultOptions}
        formatCreateLabel={formatCreateLabel}
        onChange={this.onChange}
        createable={createable}
        noOptionsMessage={makeNoOptionsMessage(options)}
        ref={innerRef}
        styles={selectStyles}
        loadOptions={loadOptions}
        onKeyDown={this.onKeyDown}
        isClearable
        placeholder={window.FolioConsole.translations.selectPlaceholder}
        loadingMessage={() => window.FolioConsole.translations.loading}
        isValidNewOption={this.isValidNewOption}
        {...rest}
      />
    )
  }
}

export default Select
