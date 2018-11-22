import React from 'react'
import Select from 'react-select'
import CreatableSelect from 'react-select/lib/Creatable'

import selectStyles from './selectStyles'
import formatTags from './formatTags';

const makeNoOptionsMessage = (values) => ({ inputValue }) => {
  if (values.indexOf(inputValue) === -1) {
    return window.FolioConsole.translations.noTags
  } else {
    return window.FolioConsole.translations.tagUsed
  }
}
const formatCreateLabel = (input) => `${window.FolioConsole.translations.create} "${input}"`

class TagsInput extends React.Component {
  constructor (props) {
    super(props)
    this.selectRef = React.createRef()
  }

  onChange = (tags) => {
    this.props.onTagsChange(tags.map((tag) => tag.value))
  }

  onKeyDown = (e) => {
    if (e.key === 'Enter') {
      const { state } = this.selectRef.current
      if (!state.menuIsOpen && state.inputValue === '') {
        this.props.submit()
      }
    }
  }

  render () {
    let SelectComponent = CreatableSelect
    if (this.props.notCreatable) SelectComponent = Select

    return (
      <SelectComponent
        name="form-field-name"
        placeholder={window.FolioConsole.translations.tagsLabel}
        className='react-select-container'
        classNamePrefix='react-select'
        styles={selectStyles}
        onChange={this.onChange}
        value={formatTags(this.props.value)}
        options={formatTags(this.props.options)}
        autoFocus={!this.props.noAutofocus}
        noOptionsMessage={makeNoOptionsMessage(this.props.value)}
        formatCreateLabel={formatCreateLabel}
        onKeyDown={this.props.submit ? this.onKeyDown : null}
        closeMenuOnSelect={!!this.props.submit}
        ref={this.selectRef}
        isMulti
      />
    )
  }
}

export default TagsInput
