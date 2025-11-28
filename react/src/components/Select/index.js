import React from 'react'
import { debounce } from 'lodash'

import ReactSelect, { components } from 'react-select'
import CreatableSelect from 'react-select/creatable'
import AsyncSelect from 'react-select/async'
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
    const { isClearable, createable, value, options, rawOptions, onChange, innerRef, selectize, async, asyncData, addAtomSettings, defaultOptions, placeholder, dataTestId, menuPlacement, ...rest } = this.props
    let SelectComponent = CreatableSelect
    let loadOptions, loadOptionsRaw

    if (!createable) SelectComponent = ReactSelect

    if (async) {
      // Use AsyncPaginate for pagination support, but fall back to AsyncSelect for selectize mode
      if (selectize) {
        // Selectize mode doesn't support pagination, use old AsyncSelect
        if (createable) {
          SelectComponent = AsyncCreatableSelect
        } else {
          SelectComponent = AsyncSelect
        }

        loadOptionsRaw = (inputValue, handle) => {
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
            .catch(() => handle([]))
            .then((res) => {
              if (res) {
                handle(res.data)
              } else {
                handle([])
              }
            })
        }
      } else {
        // Use AsyncPaginate for pagination support
        // Note: AsyncCreatablePaginate is not available in older versions compatible with React 16
        // So we use AsyncCreatableSelect (without pagination) for creatable selects
        if (createable) {
          SelectComponent = AsyncCreatableSelect
          // For creatable selects, use the old loadOptions format without pagination
          loadOptionsRaw = (inputValue, handle) => {
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
              .catch(() => handle([]))
              .then((res) => {
                if (res) {
                  handle(formatOptions(res.data))
                } else {
                  handle([])
                }
              })
          }
        } else {
          SelectComponent = AsyncPaginate

          loadOptionsRaw = async (inputValue, loadedOptions, additional) => {
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
              const formattedOptions = formatOptions(res.data)
              // Check if there are more pages
              const hasMore = res.meta && res.meta.page < res.meta.pages
              return {
                options: formattedOptions,
                hasMore: hasMore
              }
            } else {
              return {
                options: [],
                hasMore: false
              }
            }
          } catch (error) {
            return {
              options: [],
              hasMore: false
            }
          }
          }
        }
      }

      if (loadOptionsRaw) {
        loadOptions = debounce(loadOptionsRaw, 300, { leading: true, trailing: true })
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

    let handledOptions
    if (options) {
      handledOptions = formatOptions(options)
    } else if (rawOptions) {
      handledOptions = rawOptions
    }

    return (
      <SelectComponent
        name='form-field-name'
        className='react-select-container'
        classNamePrefix='react-select'
        value={formattedValue}
        options={handledOptions}
        defaultOptions={defaultOptions}
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
        {...rest}
      />
    )
  }
}

export default Select
