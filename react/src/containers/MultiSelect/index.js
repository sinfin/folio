import React, { Component } from 'react'
import { connect } from 'react-redux'
import { SortableContainer, SortableElement } from 'react-sortable-hoc'

import {
  filesSelector,
  selectFile,
  unselectFile,
  onSortEnd,
} from 'ducks/files'

import { uploadsSelector } from 'ducks/uploads'

import Uploader from 'containers/Uploader'
import { File, UploadingFile } from 'components/File'
import Loader from 'components/Loader'
import Card from 'components/Card'

const SortableList = SortableContainer(({ items, dispatch }) => {
  return (
    <div>
      {items.map((file, index) => (
        <SortableItem
          key={file.file_id}
          index={index}
          file={file}
          dispatch={dispatch}
          position={index}
        />
      ))}
    </div>
  )
})

const SortableItem = SortableElement(({ file, position, dispatch }) => {
  return (
    <File
      file={file}
      key={file.file_id}
      onClick={() => dispatch(unselectFile(file))}
      position={position}
      selected
    />
  )
})

class MultiSelect extends Component {
  render() {
    const { files, uploads, dispatch } = this.props
    if (files.loading) return <Loader />

    return (
      <Uploader>
        <Card
          highlighted
          header='Selected'
        >
          <SortableList
            items={files.selected}
            onSortEnd={({ oldIndex, newIndex }) => dispatch(onSortEnd(oldIndex, newIndex))}
            dispatch={dispatch}
            axis='xy'
            distance={5}
          />
        </Card>

        <Card
          header='Available'
          filters='filter?'
        >
          {files.selectable.map((file) => (
            <File
              file={file}
              key={file.file_id}
              onClick={() => dispatch(selectFile(file))}
              selected={false}
            />
          ))}
          {uploads.records.map((upload, index) => (
            <UploadingFile
              upload={upload}
              key={upload.id}
            />
          ))}
        </Card>
      </Uploader>
    )
  }
}

const mapStateToProps = (state) => ({
  files: filesSelector(state),
  uploads: uploadsSelector(state),
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(MultiSelect)
