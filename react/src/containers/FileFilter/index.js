import React, { Component } from 'react'
import { connect } from 'react-redux'

import {
  filtersSelector,
  tagsSelector,
  placementsSelector,
  setFilter,
  resetFilters,
} from 'ducks/filters'

import {
  setCardsDisplay,
  setThumbsDisplay,
  displaySelector,
} from 'ducks/display'

import { fileTypeIsImageSelector } from 'ducks/app'

import TagsInput from 'components/TagsInput'
import Select from 'components/Select'

import Wrap from './styled/Wrap'
import DisplayButtons from './DisplayButtons'

class FileFilter extends Component {
  onNameChange = (e) => {
    this.props.dispatch(
      setFilter('name', e.target.value)
    )
  }

  onTagsChange = (tags) => {
    this.props.dispatch(setFilter('tags', tags))
  }

  onPlacementChange = (placement) => {
    this.props.dispatch(setFilter('placement', placement))
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
      <Wrap margined={margined}>
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
            noAutofocus
            notCreatable
          />
        </div>

        <div className='form-group form-group--react-select'>
          <Select
            options={this.props.placements}
            value={filters.placement}
            onChange={this.onPlacementChange}
            defaultValue={null}
            placeholder={window.FolioConsole.translations.placementsLabel}
            isClearable
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

const mapStateToProps = (state) => ({
  filters: filtersSelector(state),
  tags: tagsSelector(state),
  placements: placementsSelector(state),
  display: displaySelector(state),
  fileTypeIsImage: fileTypeIsImageSelector(state),
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(FileFilter)
