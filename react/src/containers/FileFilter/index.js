import React, { Component } from 'react'
import { connect } from 'react-redux'

import {
  filtersSelector,
  tagsSelector,
  setFilter,
  resetFilters,
} from 'ducks/filters'

import {
  setCardsDisplay,
  setThumbsDisplay,
  displaySelector,
} from 'ducks/display'

import { fileTypeIsImageSelector } from 'ducks/app'

import TagsInput from 'components/TagsInput';

import Wrap from './styled/Wrap';
import DisplayButtons from './DisplayButtons';

class FileFilter extends Component {
  onNameChange = (e) => {
    this.props.dispatch(
      setFilter('name', e.target.value)
    )
  }

  onTagsChange = (tags) => {
    this.props.dispatch(setFilter('tags', tags))
  }

  onReset = () => {
    this.props.dispatch(
      resetFilters()
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

  render() {
    const { filters, margined, display, fileTypeIsImage } = this.props

    return (
      <Wrap className='form-inline' margined={margined}>
        <div className='form-group'>
          <input
            className='form-control'
            value={filters.name}
            onChange={this.onNameChange}
            placeholder='File name'
          />
        </div>

        <div className='form-group form-group--react-select'>
          <TagsInput
            options={this.props.tags}
            value={filters.tags}
            onTagsChange={this.onTagsChange}
            notCreatable
          />
        </div>

        {filters.active && (
          <div className='form-group'>
            <button
              type='button'
              className='btn btn-danger'
              onClick={this.onReset}
            >
              <i className='fa fa-times'></i>
            </button>
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

const mapStateToProps = (state) => ({
  filters: filtersSelector(state),
  tags: tagsSelector(state),
  display: displaySelector(state),
  fileTypeIsImage: fileTypeIsImageSelector(state),
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(FileFilter)
