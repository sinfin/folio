import React, { Component } from 'react'
import { connect } from 'react-redux'
import styled from 'styled-components'

import Select from 'react-select'
import selectStyles from './selectStyles'

import {
  filtersSelector,
  tagsSelector,
  setFilter,
  resetFilters,
} from 'ducks/filters'

const Wrap = styled.div`
  position: relative;
  z-index: 2;

  .redactor-modal-tab & {
    padding-bottom: 30px;
  }

  .form-group {
    margin-right: 30px;
  }

  .form-group--react-select {
    flex: 0 0 250px;

    > div {
      width: 250px;
    }
  }
`

class FileFilter extends Component {
  onNameChange = (e) => {
    this.props.dispatch(
      setFilter('name', e.target.value)
    )
  }

  onTagsChange = (tags) => {
    this.props.dispatch(
      setFilter('tags', tags.map((tag) => tag.value))
    )
  }

  onReset = () => {
    this.props.dispatch(
      resetFilters()
    )
  }

  booleanButton (bool) {
    if (bool) {
      return 'btn btn-primary'
    } else {
      return 'btn'
    }
  }

  formatTags (tags) {
    return tags.map((tag) => ({
      value: tag,
      label: tag,
    }))
  }

  render() {
    const { filters, margined } = this.props

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
          <Select
            name="form-field-name"
            value={this.formatTags(filters.tags)}
            onChange={this.onTagsChange}
            options={this.formatTags(this.props.tags)}
            placeholder='Tags'
            className='react-select-container'
            classNamePrefix='react-select'
            styles={selectStyles}
            isMulti
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
      </Wrap>
    )
  }
}

const mapStateToProps = (state) => ({
  filters: filtersSelector(state),
  tags: tagsSelector(state),
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(FileFilter)
