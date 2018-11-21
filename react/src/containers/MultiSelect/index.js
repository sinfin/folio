import React from 'react'
import { connect } from 'react-redux'

import LazyLoadCheckingComponent from 'utils/LazyLoadCheckingComponent';
import {
  selectFile,
  unselectFile,
  onSortEnd,
} from 'ducks/files'
import { placementTypeSelector } from 'ducks/app'
import { uploadsSelector } from 'ducks/uploads'
import { filteredFilesSelector } from 'ducks/filters'

import FileFilter from 'containers/FileFilter'
import Uploader from 'containers/Uploader'
import { File, UploadingFile, DropzoneTrigger } from 'components/File'
import Loader from 'components/Loader'
import Card from 'components/Card'

import SortableList from './SortableList';

class MultiSelect extends LazyLoadCheckingComponent {
  render() {
    const { files, uploads, dispatch, placementType } = this.props
    if (files.loading) return <Loader />

    return (
      <Uploader>
        <Card
          highlighted
          header='Selected'
        >
          <SortableList
            items={files.selected}
            attachmentable={files.attachmentable}
            placementType={placementType}
            onSortEnd={({ oldIndex, newIndex }) => dispatch(onSortEnd(oldIndex, newIndex))}
            onClick={(file) => dispatch(unselectFile(file))}
            dispatch={dispatch}
            axis='xy'
            distance={5}
          />
        </Card>

        <Card
          header='Available'
          filters={<FileFilter />}
        >
          <DropzoneTrigger />

          {uploads.records.map((upload, index) => (
            <UploadingFile
              upload={upload}
              key={upload.id}
            />
          ))}

          {files.selectable.map((file) => (
            <File
              file={file}
              key={file.file_id}
              onClick={() => dispatch(selectFile(file))}
              attachmentable={files.attachmentable}
              placementType={placementType}
              selected={false}
            />
          ))}
        </Card>
      </Uploader>
    )
  }
}

const mapStateToProps = (state) => ({
  files: filteredFilesSelector(state),
  uploads: uploadsSelector(state),
  placementType: placementTypeSelector(state),
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(MultiSelect)
