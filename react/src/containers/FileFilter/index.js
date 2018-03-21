import React, { Component } from 'react'
import { connect } from 'react-redux'
import styled from 'styled-components'

import Select from 'react-select'
import 'react-select/dist/react-select.css'

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

  .Select {
    min-width: 280px;
  }

  .Select-control {
    border-radius: 0;
  }

  .Select-control, .Select-input {
    height: 35px;
  }

  .Select-placeholder, .Select--single > .Select-control .Select-value {
    line-height: 35px;
  }
`

class FileFilter extends Component {
  onNameChange = (e) => {
    this.props.dispatch(setFilter('name', e.target.value))
  }

  booleanButton (bool) {
    if (bool) {
      return 'btn btn-primary'
    } else {
      return 'btn'
    }
  }

  tagsOptions () {
    return this.props.tags.map((tag) => ({
      value: tag,
      label: tag,
    }))
  }

  render() {
    const { filters, dispatch, margined } = this.props

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

        <div className='form-group'>
          <Select
            name="form-field-name"
            value={filters.tags}
            onChange={(tags) => dispatch(setFilter('tags', tags.map((tag) => tag.value)))}
            options={this.tagsOptions()}
            placeholder='Tags'
            multi
          />
        </div>

        {filters.active && (
          <div className='form-group'>
            <button
              type='button'
              className='btn btn-danger'
              onClick={() => dispatch(resetFilters())}
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
