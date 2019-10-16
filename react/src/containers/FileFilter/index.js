import React, { Component } from 'react'
import { connect } from 'react-redux'

import {
  makeFiltersSelector,
  makeTagsSelector,
  setFilter,
  resetFilters
} from 'ducks/filters'

import {
  setCardsDisplay,
  setThumbsDisplay,
  displaySelector
} from 'ducks/display'

import TagsInput from 'components/TagsInput'

import Wrap from './styled/Wrap'
import DisplayButtons from './DisplayButtons'

class FileFilter extends Component {
  onInputChange = (e) => {
    this.props.dispatch(
      setFilter(this.props.filesKey, e.target.name, e.target.value)
    )
  }

  onTagsChange = (tags) => {
    this.props.dispatch(setFilter(this.props.filesKey, 'tags', tags))
  }

  onReset = () => {
    this.props.dispatch(
      resetFilters(this.props.filesKey)
    )
  }

  setCardsDisplay = (e) => { this.props.dispatch(setCardsDisplay()) }

  setThumbsDisplay = (e) => { this.props.dispatch(setThumbsDisplay()) }

  booleanButton (bool) {
    if (bool) {
      return 'btn btn-primary'
    } else {
      return 'btn'
    }
  }

  render () {
    const { filters, margined, display, fileTypeIsImage } = this.props

    return (
      <Wrap margined={margined}>
        <div className='form-group'>
          <input
            className='form-control'
            value={filters.file_name}
            onChange={this.onInputChange}
            placeholder={window.FolioConsole.translations.fileNameFilter}
            name='file_name'
          />
        </div>

        <div className='form-group form-group--react-select'>
          <TagsInput
            options={this.props.tags}
            value={filters.tags}
            onTagsChange={this.onTagsChange}
            noAutofocus
            notCreatable
          />
        </div>

        <div className='form-group form-group--react-select'>
          <input
            className='form-control'
            value={filters.placement}
            onChange={this.onInputChange}
            placeholder={window.FolioConsole.translations.usageFilter}
            name='placement'
          />
        </div>

        {filters.active && (
          <div className='form-group form-group--reset'>
            <button
              type='button'
              className='btn btn-danger fa fa-times'
              onClick={this.onReset}
            />
          </div>
        )}

        {fileTypeIsImage && (
          <DisplayButtons
            display={display}
            setCardsDisplay={this.setCardsDisplay}
            setThumbsDisplay={this.setThumbsDisplay}
          />
        )}
      </Wrap>
    )
  }
}

const mapStateToProps = (state, props) => ({
  filters: makeFiltersSelector(props.filesKey)(state),
  tags: makeTagsSelector(props.filesKey)(state),
  display: displaySelector(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(FileFilter)
