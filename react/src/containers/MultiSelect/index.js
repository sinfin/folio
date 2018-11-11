import React from 'react'
import { connect } from 'react-redux'
import { SortableContainer, SortableElement } from 'react-sortable-hoc'

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

const SortableList = SortableContainer(({ attachmentable, placementType, items, dispatch }) => {
  return (
    <div>
      {items.map((file, index) => (
        <SortableItem
          key={file.file_id}
          attachmentable={attachmentable}
          placementType={placementType}
          index={index}
          file={file}
          dispatch={dispatch}
          position={index}
        />
      ))}
    </div>
  )
})

const SortableItem = SortableElement(({ file, position, dispatch, attachmentable, placementType }) => {
  return (
    <File
      file={file}
      key={file.file_id}
      onClick={() => dispatch(unselectFile(file))}
      position={position}
      attachmentable={attachmentable}
      placementType={placementType}
      selected
    />
  )
})

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
