import React from 'react'

import Select from 'components/Select'

class TagsInput extends React.Component {
  constructor (props) {
    super(props)
    this.selectRef = React.createRef()
  }

  onChange = (tags) => {
    // Extract values from option objects if tags is an array of objects
    // Tags are stored as strings, so we need to convert {value, label} -> value
    const tagValues = tags && Array.isArray(tags) && tags.length > 0 && typeof tags[0] === 'object'
      ? tags.map(tag => tag.value || tag)
      : tags
    this.props.onTagsChange(tagValues)
  }

  onKeyDown = (e) => {
    if (e.key === 'Enter') {
      const { state } = this.selectRef.current
      if (this.props.submit && !state.menuIsOpen && state.inputValue === '') {
        this.props.submit()
      } else if (state.inputValue !== '' && this.props.notCreatable) {
        e.preventDefault()
        e.stopPropagation()
      }
    }
  }

  render () {
    return (
      <Select
        placeholder={window.FolioConsole.translations.tagsLabel}
        onChange={this.onChange}
        autoFocus={!this.props.noAutofocus}
        onKeyDown={this.onKeyDown}
        closeMenuOnSelect={!!this.props.submit}
        innerRef={this.selectRef}
        createable={!this.props.notCreatable}
        value={this.props.value}
        defaultOptions
        async='/console/api/tags'
        isMulti
        dataTestId={this.props.dataTestId}
      />
    )
  }
}

export default TagsInput
