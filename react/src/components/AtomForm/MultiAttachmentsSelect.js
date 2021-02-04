import React from 'react'
import { connect } from 'react-redux'

import {
  getFiles,
  makeFilesStatusSelector,
  makeFilesPaginationSelector,
  changeFilesPage,
  makeRawUnselectedFilesForListSelector,
  makeFilesReactTypeIsImageSelector
} from 'ducks/files'

import {
  atomFormPlacementsSelect,
  atomFormPlacementsUnselect,
  atomFormPlacementsSort,
  atomFormPlacementsChangeTitle,
  atomFormPlacementsChangeAlt
} from 'ducks/atoms'

import { displayAsThumbsSelector } from 'ducks/display'

import MultiSelectComponent from 'components/MultiSelectComponent'

class MultiAttachmentsSelect extends React.PureComponent {
  getFiles = () => {
    this.props.dispatch(getFiles(this.props.fileType, this.props.filesUrl))
  }

  changeFilesPage = (page) => {
    this.props.dispatch(changeFilesPage(this.props.fileType, this.props.filesUrl, page))
  }

  onSortEnd = ({ oldIndex, newIndex }) => {
    this.props.dispatch(
      atomFormPlacementsSort(
        this.props.index,
        this.props.attachmentType.key,
        oldIndex,
        newIndex
      )
    )
  }

  onAltChange = (_fileType, filePlacement, alt) => {
    this.props.dispatch(
      atomFormPlacementsChangeAlt(
        this.props.index,
        this.props.attachmentType.key,
        filePlacement,
        alt
      )
    )
  }

  onTitleChange = (_fileType, filePlacement, title) => {
    this.props.dispatch(
      atomFormPlacementsChangeTitle(
        this.props.index,
        this.props.attachmentType.key,
        filePlacement,
        title
      )
    )
  }

  unselectFilePlacement = (_fileType, filePlacement) => {
    this.props.dispatch(
      atomFormPlacementsUnselect(
        this.props.index,
        this.props.attachmentType.key,
        filePlacement
      )
    )
  }

  selectFile = (file) => {
    this.props.dispatch(
      atomFormPlacementsSelect(
        this.props.index,
        this.props.attachmentType.key,
        file
      )
    )
  }

  render () {
    return (
      <MultiSelectComponent
        fileType={this.props.fileType}
        filesUrl={this.props.filesUrl}
        filesStatus={this.props.filesStatus}
        fileTypeIsImage={this.props.fileTypeIsImage}
        getFiles={this.getFiles}
        filePlacements={this.props.filePlacements}
        onSortEnd={this.onSortEnd}
        onAltChange={this.onAltChange}
        onTitleChange={this.onTitleChange}
        unselectFilePlacement={this.unselectFilePlacement}
        unselectedFilesForList={this.props.unselectedFilesForList}
        displayAsThumbs={this.props.displayAsThumbs}
        selectFile={this.selectFile}
        filesPagination={this.props.filesPagination}
        changeFilesPage={this.changeFilesPage}
        openFileModal={(file) => this.props.openFileModal(this.props.fileType, this.props.filesUrl, file)}
        shouldLoadFiles
        nested
      />
    )
  }
}

const mapStateToProps = (state, props) => {
  const all = props.atom.record[props.attachmentType.key]
  const selected = []
  const deleted = []
  const selectedFileIds = []

  if (all && all.length) {
    all.forEach((placement) => {
      if (placement._destroy) {
        deleted.push(placement)
      } else {
        selected.push(placement)
        selectedFileIds.push(String(placement.file_id))
      }
    })
  }

  const fileType = props.attachmentType['file_type']
  const filesUrl = props.attachmentType['files_url']
  const filePlacements = {
    selected,
    deleted,
    attachmentable: 'foo',
    placementType: props.attachmentType.key.replace('_attributes', '')
  }

  return {
    fileType,
    filesUrl,
    filesStatus: makeFilesStatusSelector(fileType)(state),
    displayAsThumbs: displayAsThumbsSelector(state),
    filesPagination: makeFilesPaginationSelector(fileType)(state),
    fileTypeIsImage: makeFilesReactTypeIsImageSelector(fileType)(state),
    filePlacements,
    unselectedFilesForList: makeRawUnselectedFilesForListSelector(fileType, selectedFileIds)(state)
  }
}

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export { MultiAttachmentsSelect }
export default connect(mapStateToProps, mapDispatchToProps)(MultiAttachmentsSelect)
