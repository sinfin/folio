import React from 'react'

import Select from 'components/Select';

class TagsInput extends React.Component {
  constructor (props) {
    super(props)
    this.selectRef = React.createRef()
  }

  onChange = (tags) => {
    console.log(tags)
    this.props.onTagsChange(tags)
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
        options={this.props.options}
        isMulti
      />
    )
  }
}

export default TagsInput
