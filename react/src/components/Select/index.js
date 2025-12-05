import React from 'react'

import ReactSelect, { components } from 'react-select'
import CreatableSelect from 'react-select/creatable'
import AsyncCreatableSelect from 'react-select/async-creatable'
import { AsyncPaginate } from 'react-select-async-paginate'

import { apiGet } from 'utils/api'
import settingsToHash from 'utils/settingsToHash'

import selectStyles from './selectStyles'
import formatOption from './formatOption'
import formatOptions from './formatOptions'
import formatCreateLabel from './formatCreateLabel'
import makeNoOptionsMessage from './makeNoOptionsMessage'

const AUTOCOMPLETE_PAGY_ITEMS = 25

const Input = (props) => {
  const { dataTestId } = props.selectProps
  return <components.Input {...props} data-test-id={dataTestId} />
}

class Select extends React.Component {
  state = { key: 0 }

  // changing key force the select to reload options based on atom settings
  componentDidMount () {
    window.jQuery(document).on('folioAtomSettingChanged.folioReactSelect', () => {
      this.setState({ key: this.state.key + 1 })
    })
  }

  componentWillUnmount () {
    window.jQuery(document).off('folioAtomSettingChanged.folioReactSelect')
  }

  onChange = (value) => {
    if (this.props.isMulti) {
      if (value) {
        // For multi-select, pass array of option objects
        // This allows parent components to access full option data (value, label, id, etc.)
        return this.props.onChange(value)
      } else {
        return this.props.onChange([])
      }
    } else {
      // For single select, pass the full option object
      // This allows parent components to access full option data (value, label, id, etc.)
      return this.props.onChange(value)
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
    const { isClearable, createable, value, options, rawOptions, onChange, innerRef, async, asyncData, addAtomSettings, defaultOptions, placeholder, dataTestId, menuPlacement, ...rest } = this.props

    // Format value early so we can use it in loadOptions
    let formattedValue = null
    if (value) {
      // Check if value is already in react-select format {value, label}
      if (typeof value === 'object' && value !== null && 'value' in value && 'label' in value) {
        formattedValue = this.props.isMulti ? [value] : value
      } else {
        formattedValue = this.props.isMulti ? formatOptions(value) : formatOption(value)
      }
    }
    let SelectComponent = CreatableSelect
    let loadOptions
    let useDebounceTimeout = false

    if (!createable) SelectComponent = ReactSelect

    if (async) {
      if (createable) {
        // Creatable selects don't support pagination in react-select-async-paginate v0.4.1
        // Use AsyncCreatableSelect without pagination
        SelectComponent = AsyncCreatableSelect

        loadOptions = (inputValue, handle) => {
          let data = ''
          const params = new URLSearchParams()

          if (asyncData) {
            Object.keys(asyncData).forEach((key) => {
              params.set(`atom_form_fields[${key}]`, asyncData[key])
            })
          }

          if (addAtomSettings) {
            const settingsUrlData = {}
            const settingsHash = settingsToHash()

            Object.keys(settingsHash).forEach((key) => {
              if (key !== 'loading') {
                Object.keys(settingsHash[key]).forEach((locale) => {
                  let fullKey

                  if (locale && locale !== 'null') {
                    fullKey = `by_atom_setting_${key}_${locale}`
                  } else {
                    fullKey = `by_atom_setting_${key}`
                  }

                  settingsUrlData[fullKey] = settingsHash[key][locale]
                })
              }
            })

            Object.keys(settingsUrlData).forEach((key) => {
              params.set(key, settingsUrlData[key])
            })
          }

          data = params.toString()
          if (data !== '') data = `&${data}`

          const join = async.indexOf('?') === -1 ? '?' : '&'
          apiGet(`${async}${join}q=${inputValue}${data}`)
            .then((res) => {
              if (res) {
                handle(formatOptions(res.data))
              } else {
                handle([])
              }
            })
            .catch(() => {
              handle([])
            })
        }
      } else {
        // Use AsyncPaginate for pagination support
        SelectComponent = AsyncPaginate
        useDebounceTimeout = true

        loadOptions = async (inputValue, loadedOptions, additional) => {
          let data = ''
          const params = new URLSearchParams()

          // Calculate page from loadedOptions length
          const page = Math.floor(loadedOptions.length / AUTOCOMPLETE_PAGY_ITEMS) + 1
          params.set('page', page)

          if (asyncData) {
            Object.keys(asyncData).forEach((key) => {
              params.set(`atom_form_fields[${key}]`, asyncData[key])
            })
          }

          if (addAtomSettings) {
            const settingsUrlData = {}
            const settingsHash = settingsToHash()

            Object.keys(settingsHash).forEach((key) => {
              if (key !== 'loading') {
                Object.keys(settingsHash[key]).forEach((locale) => {
                  let fullKey

                  if (locale && locale !== 'null') {
                    fullKey = `by_atom_setting_${key}_${locale}`
                  } else {
                    fullKey = `by_atom_setting_${key}`
                  }

                  settingsUrlData[fullKey] = settingsHash[key][locale]
                })
              }
            })

            Object.keys(settingsUrlData).forEach((key) => {
              params.set(key, settingsUrlData[key])
            })
          }

          data = params.toString()
          if (data !== '') data = `&${data}`

          const join = async.indexOf('?') === -1 ? '?' : '&'
          try {
            const res = await apiGet(`${async}${join}q=${inputValue}${data}`)
            if (res) {
              // Transform API response, passing through all fields
              // Ensure value and label are always set for react-select compatibility
              const formattedOptions = res.data.map((item) => ({
                ...item, // Pass through all fields from API (id, text, label, value, type, etc.)
                value: item.value || item.id, // Ensure value is set for react-select
                label: item.label || item.text || '' // Ensure label is set for react-select
              }))

              // Ensure selected value is included in options so react-select can display it
              // This is critical for AsyncSelect/AsyncPaginate which only use options from loadOptions
              // Use a Set to track existing values to prevent duplicates
              const existingValues = new Set(formattedOptions.map(opt => opt.value))
              const finalOptions = [...formattedOptions]

              // Only include selected value on the first page (when loadedOptions is empty)
              // and when there's no search query. Don't prepend on subsequent pages.
              const isFirstPage = loadedOptions.length === 0
              const shouldIncludeSelected = isFirstPage && (!inputValue || inputValue.trim() === '')

              if (formattedValue && !this.props.isMulti && shouldIncludeSelected) {
                const selectedValue = formattedValue
                // Only add if not already present in the API results
                if (selectedValue && selectedValue.value && !existingValues.has(selectedValue.value)) {
                  // Prepend selected value so it appears first
                  finalOptions.unshift(selectedValue)
                  existingValues.add(selectedValue.value)
                }
              } else if (formattedValue && this.props.isMulti && Array.isArray(formattedValue) && shouldIncludeSelected) {
                formattedValue.forEach(selectedVal => {
                  if (selectedVal && selectedVal.value && !existingValues.has(selectedVal.value)) {
                    finalOptions.push(selectedVal)
                    existingValues.add(selectedVal.value)
                  }
                })
              }

              // Check if there are more pages
              const hasMore = res.meta && res.meta.page < res.meta.pages
              return {
                options: finalOptions,
                hasMore: hasMore
              }
            } else {
              // Only include selected value if no search query
              const shouldIncludeSelected = !inputValue || inputValue.trim() === ''
              const finalOptions = []
              if (shouldIncludeSelected) {
                if (formattedValue && !this.props.isMulti && formattedValue.value) {
                  finalOptions.push(formattedValue)
                } else if (formattedValue && this.props.isMulti && Array.isArray(formattedValue)) {
                  formattedValue.forEach(val => {
                    if (val && val.value) finalOptions.push(val)
                  })
                }
              }
              return {
                options: finalOptions,
                hasMore: false
              }
            }
          } catch (error) {
            // Only include selected value if no search query
            const shouldIncludeSelected = !inputValue || inputValue.trim() === ''
            const finalOptions = []
            if (shouldIncludeSelected) {
              if (formattedValue && !this.props.isMulti && formattedValue.value) {
                finalOptions.push(formattedValue)
              } else if (formattedValue && this.props.isMulti && Array.isArray(formattedValue)) {
                formattedValue.forEach(val => {
                  if (val && val.value) finalOptions.push(val)
                })
              }
            }
            return {
              options: finalOptions,
              hasMore: false
            }
          }
        }
      }
    }

    let handledOptions
    if (options) {
      handledOptions = formatOptions(options)
    } else if (rawOptions) {
      handledOptions = rawOptions
    }

    // For async selects, loadOptions handles including the selected value
    // So we don't need to modify defaultOptions - let react-select handle it normally
    // The selected value will be included via loadOptions when it's called
    const handledDefaultOptions = defaultOptions

    return (
      <SelectComponent
        name='form-field-name'
        className='react-select-container'
        classNamePrefix='react-select'
        value={formattedValue}
        options={handledOptions}
        defaultOptions={handledDefaultOptions}
        formatCreateLabel={formatCreateLabel}
        onChange={this.onChange}
        noOptionsMessage={makeNoOptionsMessage(options)}
        ref={innerRef}
        styles={selectStyles}
        loadOptions={loadOptions}
        onKeyDown={this.onKeyDown}
        key={this.state.key}
        isClearable={typeof isClearable === 'undefined' ? true : isClearable}
        placeholder={placeholder || window.FolioConsole.translations.selectPlaceholder}
        loadingMessage={() => window.FolioConsole.translations.loading}
        isValidNewOption={this.isValidNewOption}
        components={{ Input }}
        dataTestId={dataTestId}
        menuPlacement={menuPlacement}
        debounceTimeout={useDebounceTimeout ? 250 : undefined}
        {...rest}
      />
    )
  }
}

export default Select
