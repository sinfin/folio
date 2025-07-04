import React, { Component } from 'react'
import { connect } from 'react-redux'
import { FormGroup, Input } from 'reactstrap'

import {
  makeFiltersSelector,
  setFilter,
  resetFilters
} from 'ducks/filters'

import { fileUsageSelector, photoArchiveEnabledSelector } from 'ducks/app'

import TagsInput from 'components/TagsInput'
import FolioConsoleUiButton from 'components/FolioConsoleUiButton'
import InputWithSearchIcon from 'components/InputWithSearchIcon'

import Wrap from './styled/Wrap'

class FileFilter extends Component {
  onInputChange = (e) => {
    this.props.dispatch(
      setFilter(this.props.fileType, this.props.filesUrl, e.target.name, e.target.value)
    )
  }

  onTagsChange = (tags) => {
    this.props.dispatch(setFilter(this.props.fileType, this.props.filesUrl, 'tags', tags))
  }

  onReset = () => {
    this.props.dispatch(
      resetFilters(this.props.fileType, this.props.filesUrl)
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
    const { filters, margined, fileUsage, taggable, className, photoArchiveEnabled } = this.props

    return (
      <Wrap margined={margined} className={`f-c-r-file-filter-wrap ${className}`}>
        <div className='row'>
          <div className='col-12 col-sm-6 col-xl-3'>
            <FormGroup className='mb-2 mb-sm-2 mb-xl-0'>
              <InputWithSearchIcon
                value={filters.file_name || ''}
                onChange={this.onInputChange}
                placeholder={window.FolioConsole.translations.fileNameFilter}
                name='file_name'
              />
            </FormGroup>
          </div>

          {fileUsage && (
            <div className='col-12 col-sm-6 col-xl-3'>
              <FormGroup className='mb-2 mb-sm-2 mb-xl-0'>
                <InputWithSearchIcon
                  value={filters.placement || ''}
                  onChange={this.onInputChange}
                  placeholder={window.FolioConsole.translations.usageFilter}
                  name='placement'
                />
              </FormGroup>
            </div>
          )}

          {fileUsage && (
            <div className='col-12 col-sm-6 col-xl-2'>
              <FormGroup className='mb-2 mb-xl-0'>
                <Input
                  type='select'
                  value={filters.used}
                  onChange={this.onInputChange}
                  placeholder={window.FolioConsole.translations.usagePlaceholder}
                  name='used'
                  className='form-control--select select'
                  required
                >
                  <option value=''>{window.FolioConsole.translations.usagePlaceholder}</option>
                  <option value='used'>{window.FolioConsole.translations.usageUsed}</option>
                  <option value='unused'>{window.FolioConsole.translations.usageUnused}</option>
                </Input>
              </FormGroup>
            </div>
          )}

          {photoArchiveEnabled && (
            <div className='col-12 col-sm-6 col-xl-2'>
            <FormGroup className='mb-2 mb-xl-0'>
              <Input
                type='select'
                value={filters.photo_archive}
                onChange={this.onInputChange}
                placeholder={window.FolioConsole.translations.photoArchiveFilter}
                name='photo_archive'
                className='form-control--select select'
                required
              >
                <option value=''>{window.FolioConsole.translations.photoArchivePlaceholder}</option>
                <option value='from_photo_archive'>{window.FolioConsole.translations.photoArchiveFromPhotoArchive}</option>
                <option value='not_from_photo_archive'>{window.FolioConsole.translations.photoArchiveNotFromPhotoArchive}</option>
              </Input>
            </FormGroup>
          </div>
          )}

          {taggable && (
            <div className={`col-12 col-sm-6 col-xl-3 ${photoArchiveEnabled ? 'mt-xl-2' : ''}`}>
              <FormGroup className='mb-0 mb-xl-0 form-group--react-select'>
                <TagsInput
                  value={filters.tags}
                  dataTestId='file-filter-tags'
                  onTagsChange={this.onTagsChange}
                  noAutofocus
                  notCreatable
                />
              </FormGroup>
            </div>
          )}

          {filters.active && (
            <div className={`col-12 col-xl-1 ${photoArchiveEnabled ? 'mt-sm-2' : ''}`}>
              <FormGroup className='mb-0 mt-2 mt-sm-0 form-group--react-reset ms-auto text-center text-xl-right'>
                <FolioConsoleUiButton onClick={this.onReset} variant='danger' icon='close' />
              </FormGroup>
            </div>
          )}
        </div>
      </Wrap>
    )
  }
}

const mapStateToProps = (state, props) => ({
  filters: makeFiltersSelector(props.fileType)(state),
  fileUsage: fileUsageSelector(state),
  photoArchiveEnabled: photoArchiveEnabledSelector(state) && props.fileType === 'Folio::File::Image'
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(FileFilter)
