import React from 'react'
import Select from 'react-select'
import CreatableSelect from 'react-select/lib/Creatable'

import selectStyles from './selectStyles'
import formatTags from './formatTags';

class TagsInput extends React.Component {
  onChange = (tags) => {
    this.props.onTagsChange(tags.map((tag) => tag.value))
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
        isMulti
      />
    )
  }
}

export default TagsInput
