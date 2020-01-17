import React, { Component } from 'react'
import { connect } from 'react-redux'
import { FormGroup, Input } from 'reactstrap'

import {
  makeFiltersSelector,
  makeTagsSelector,
  setFilter,
  resetFilters
} from 'ducks/filters'

import TagsInput from 'components/TagsInput'
import InputWithSearchIcon from 'components/InputWithSearchIcon'

import Wrap from './styled/Wrap'

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

  booleanButton (bool) {
    if (bool) {
      return 'btn btn-primary'
    } else {
      return 'btn'
    }
  }

  render () {
    const { filters, margined } = this.props

    return (
      <Wrap margined={margined} className='bg-100'>
        <div className='row'>
          <div className='col-12 col-sm-6 col-xl-3'>
            <FormGroup className='mb-2 mb-sm-2 mb-xl-0'>
              <InputWithSearchIcon
                value={filters.file_name}
                onChange={this.onInputChange}
                placeholder={window.FolioConsole.translations.fileNameFilter}
                name='file_name'
              />
            </FormGroup>
          </div>

          <div className='col-12 col-sm-6 col-xl-3'>
            <FormGroup className='mb-2 mb-sm-2 mb-xl-0'>
              <InputWithSearchIcon
                value={filters.placement}
                onChange={this.onInputChange}
                placeholder={window.FolioConsole.translations.usageFilter}
                name='placement'
              />
            </FormGroup>
          </div>

          <div className='col-12 col-sm-6 col-xl-2'>
            <FormGroup className='mb-2 mb-xl-0'>
              <Input
                type='select'
                value={filters.used}
                onChange={this.onInputChange}
                placeholder={window.FolioConsole.translations.usagePlaceholder}
                name='used'
                className='form-control--select'
                required
              >
                <option value=''>{window.FolioConsole.translations.usagePlaceholder}</option>
                <option value='used'>{window.FolioConsole.translations.usageUsed}</option>
                <option value='unused'>{window.FolioConsole.translations.usageUnused}</option>
              </Input>
            </FormGroup>
          </div>

          <div className='col-12 col-sm-6 col-xl-3'>
            <FormGroup className='mb-0 mb-xl-0 form-group--react-select'>
              <TagsInput
                options={this.props.tags}
                value={filters.tags}
                onTagsChange={this.onTagsChange}
                noAutofocus
                notCreatable
              />
            </FormGroup>
          </div>

          {filters.active && (
            <div className='col-12 col-xl-1'>
              <FormGroup className='mb-0 mt-2 mt-sm-0 form-group--react-reset ml-auto text-center text-xl-right'>
                <button
                  type='button'
                  className='btn btn-danger fa fa-times'
                  onClick={this.onReset}
                />
              </FormGroup>
            </div>
          )}
        </div>
      </Wrap>
    )
  }
}

const mapStateToProps = (state, props) => ({
  filters: makeFiltersSelector(props.filesKey)(state),
  tags: makeTagsSelector(props.filesKey)(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(FileFilter)
