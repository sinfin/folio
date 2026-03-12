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
import OptionWithActions from './OptionWithActions'

const AUTOCOMPLETE_PAGY_ITEMS = 25

const Input = (props) => {
  const { dataTestId } = props.selectProps
  return <components.Input {...props} data-test-id={dataTestId} />
}

function buildAtomSettingsParams (params, asyncData, addAtomSettings) {
  if (asyncData) {
    Object.keys(asyncData).forEach((key) => {
      params.set(`atom_form_fields[${key}]`, asyncData[key])
    })
  }

  if (addAtomSettings) {
    const settingsHash = settingsToHash()
    Object.keys(settingsHash).forEach((key) => {
      if (key === 'loading') return
      Object.keys(settingsHash[key]).forEach((locale) => {
        const fullKey = locale && locale !== 'null'
          ? `by_atom_setting_${key}_${locale}`
          : `by_atom_setting_${key}`
        params.set(fullKey, settingsHash[key][locale])
      })
    })
  }
}

class Select extends React.Component {
  state = { key: 0, loadedOptions: [] }
  _createableLoadTimer = null

  // Changing key forces the select to reload options based on atom settings
  componentDidMount () {
    window.jQuery(document).on('folioAtomSettingChanged.folioReactSelect', () => {
      this.setState({ key: this.state.key + 1 })
    })
  }

  componentWillUnmount () {
    window.jQuery(document).off('folioAtomSettingChanged.folioReactSelect')
  }

  onChange = (value) => {
    this.props.onChange(this.props.isMulti ? (value || []) : value)
  }

  onKeyDown = (e) => {
    if (e.key === 'Enter') {
      if (this.props.createable) {
        // Do not preventDefault here — react-select checks defaultPrevented before
        // processing Enter (select/create). The parent wrapper handles form submission prevention.
        return
      } else if (this.props.innerRef && this.props.innerRef.current) {
        if (!this.props.innerRef.current.select.state.menuIsOpen) {
          e.preventDefault()
        }
      }
    }
  }

  isValidNewOption = (inputValue, selectValue, selectOptions) => {
    if (!inputValue) return false
    const normalized = inputValue.toLowerCase().trim()

    if (this.props.existingLabels) {
      for (const label of this.props.existingLabels) {
        if (label.toLowerCase().trim() === normalized) return false
      }
    }

    for (const opt of selectOptions) {
      if (opt.label && opt.label.toLowerCase().trim() === normalized) return false
    }

    // Also check last loaded API response — catches the debounce timing gap
    for (const opt of this.state.loadedOptions) {
      if (opt.label && opt.label.toLowerCase().trim() === normalized) return false
    }

    return true
  }

  render () {
    const { isClearable, createable, value, options, rawOptions, onChange, innerRef, async, asyncData, addAtomSettings, defaultOptions, placeholder, dataTestId, menuPlacement, existingLabels, onLoadedOptionsChange, ...rest } = this.props

    let formattedValue = null
    if (value) {
      if (typeof value === 'object' && value !== null && 'value' in value && 'label' in value) {
        formattedValue = this.props.isMulti ? [value] : value
      } else {
        formattedValue = this.props.isMulti ? formatOptions(value) : formatOption(value)
      }
    }

    let SelectComponent = createable ? CreatableSelect : ReactSelect
    let loadOptions

    if (async) {
      if (createable) {
        // AsyncCreatableSelect: react-select-async-paginate v0.4.1 does not support pagination for creatable
        SelectComponent = AsyncCreatableSelect

        loadOptions = (inputValue, handle) => {
          if (this._createableLoadTimer) clearTimeout(this._createableLoadTimer)
          this._createableLoadTimer = setTimeout(() => {
            const params = new URLSearchParams()
            buildAtomSettingsParams(params, asyncData, addAtomSettings)
            const qs = params.toString() ? `&${params.toString()}` : ''
            const join = async.indexOf('?') === -1 ? '?' : '&'

            apiGet(`${async}${join}q=${inputValue}${qs}`)
              .then((res) => {
                if (res && res.data) {
                  const formattedOptions = res.data.map((item) => ({
                    ...item,
                    value: item.value || item.id,
                    label: item.label || item.text || ''
                  }))
                  this.setState({ loadedOptions: formattedOptions })
                  if (this.props.onLoadedOptionsChange) this.props.onLoadedOptionsChange(formattedOptions)
                  handle(formattedOptions)
                } else {
                  handle([])
                }
              })
              .catch(() => handle([]))
          }, 250)
        }
      } else {
        SelectComponent = AsyncPaginate

        loadOptions = async (inputValue, loadedOptions) => {
          const selectedAsFallback = () => {
            if (inputValue && inputValue.trim()) return { options: [], hasMore: false }
            const vals = []
            if (formattedValue) {
              const arr = this.props.isMulti && Array.isArray(formattedValue) ? formattedValue : [formattedValue]
              arr.forEach(v => { if (v && v.value) vals.push(v) })
            }
            return { options: vals, hasMore: false }
          }

          const params = new URLSearchParams()
          params.set('page', Math.floor(loadedOptions.length / AUTOCOMPLETE_PAGY_ITEMS) + 1)
          buildAtomSettingsParams(params, asyncData, addAtomSettings)
          const qs = params.toString() ? `&${params.toString()}` : ''
          const join = async.indexOf('?') === -1 ? '?' : '&'

          try {
            const res = await apiGet(`${async}${join}q=${inputValue}${qs}`)
            if (!res) return selectedAsFallback()

            const formattedOptions = res.data.map((item) => ({
              ...item,
              value: item.value || item.id,
              label: item.label || item.text || ''
            }))

            const isFirstPage = loadedOptions.length === 0
            const noQuery = !inputValue || inputValue.trim() === ''
            const finalOptions = [...formattedOptions]

            if (isFirstPage && noQuery && formattedValue) {
              const existingValues = new Set(formattedOptions.map(opt => opt.value))
              if (this.props.isMulti && Array.isArray(formattedValue)) {
                formattedValue.forEach(val => {
                  if (val && val.value && !existingValues.has(val.value)) finalOptions.push(val)
                })
              } else if (!this.props.isMulti && formattedValue.value && !existingValues.has(formattedValue.value)) {
                finalOptions.unshift(formattedValue)
              }
            }

            return {
              options: finalOptions,
              hasMore: res.meta && res.meta.page < res.meta.pages
            }
          } catch (_e) {
            return selectedAsFallback()
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
        noOptionsMessage={({ inputValue }) => {
          if (createable && inputValue) {
            const normalized = inputValue.toLowerCase().trim()
            if (existingLabels && existingLabels.some((l) => l.toLowerCase().trim() === normalized)) {
              return window.FolioConsole.translations.alreadyExists || 'Already exists'
            }
            if (this.state.loadedOptions.some((o) => o.label && o.label.toLowerCase().trim() === normalized)) {
              return window.FolioConsole.translations.alreadyExists || 'Already exists'
            }
          }
          return makeNoOptionsMessage(options)({ inputValue })
        }}
        ref={innerRef}
        styles={selectStyles}
        loadOptions={loadOptions}
        onKeyDown={this.onKeyDown}
        key={this.state.key}
        isClearable={typeof isClearable === 'undefined' ? true : isClearable}
        placeholder={placeholder || window.FolioConsole.translations.selectPlaceholder}
        loadingMessage={() => window.FolioConsole.translations.loading}
        isValidNewOption={this.isValidNewOption}
        existingLabels={existingLabels}
        loadedOptions={this.state.loadedOptions}
        components={createable ? { Option: OptionWithActions, Input } : { Input }}
        dataTestId={dataTestId}
        menuPlacement={menuPlacement}
        debounceTimeout={async && !createable ? 250 : undefined}
        {...rest}
      />
    )
  }
}

export default Select
