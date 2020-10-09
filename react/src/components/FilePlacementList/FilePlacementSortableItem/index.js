import React from 'react'
import { SortableElement } from 'react-sortable-hoc'
import { FormGroup, FormText } from 'reactstrap'
import TextareaAutosize from 'react-autosize-textarea'

import NestedModelControls from 'components/NestedModelControls'
import FileHoverButtons from 'components/FileHoverButtons'
import Picture from 'components/Picture'

import preventLineBreaks from 'utils/preventLineBreaks'

import filePlacementInputName from '../utils/filePlacementInputName'
import HiddenInputs from './HiddenInputs'

class FilePlacement extends React.Component {
  state = {
    alt: '',
    title: ''
  }

  constructor (props) {
    super(props)
    this.state = {
      alt: props.filePlacement.alt,
      title: props.filePlacement.title
    }
  }

  onTitleChange = (e) => {
    this.setState({ ...this.state, title: e.target.value })
  }

  onAltChange = (e) => {
    this.setState({ ...this.state, alt: e.target.value })
  }

  onTitleBlur = (e) => {
    this.props.onTitleChange(this.props.fileType, this.props.filePlacement, e.target.value)
  }

  onAltBlur = (e) => {
    this.props.onAltChange(this.props.fileType, this.props.filePlacement, e.target.value)
  }

  unselect = () => {
    this.props.unselectFilePlacement(this.props.fileType, this.props.filePlacement)
  }

  moveUp = () => {
    if (!this.props.isFirst) {
      this.props.move({
        oldIndex: this.props.position,
        newIndex: this.props.position - 1
      })
    }
  }

  moveDown = () => {
    if (!this.props.isLast) {
      this.props.move({
        oldIndex: this.props.position,
        newIndex: this.props.position + 1
      })
    }
  }

  render () {
    const {
      filePlacement,
      attachmentable,
      placementType,
      position,
      fileTypeIsImage,
      openFileModal
    } = this.props

    let className
    if (fileTypeIsImage) {
      className = 'f-c-file-placement f-c-file-placement--image'
    } else {
      className = 'f-c-file-placement f-c-file-placement--document'
    }

    const onEdit = () => { openFileModal(filePlacement.file) }

    return (
      <div className={className}>
        {fileTypeIsImage && (
          <div
            className='f-c-file-placement__img-wrap'
          >
            <a
              className='f-c-file-placement__img-a'
              href={filePlacement.file.attributes.source_url}
              target='_blank'
              rel='noopener noreferrer'
              onClick={(e) => e.stopPropagation()}
            >
              <Picture file={filePlacement.file} imageClassName='f-c-file-placement__img' />
            </a>

            {<FileHoverButtons edit onEdit={onEdit} />}
          </div>
        )}

        <div className='f-c-file-placement__inputs'>
          <div className='f-c-file-placement__title'>
            <FormGroup>
              <TextareaAutosize
                placeholder={filePlacement.file.attributes.file_name}
                value={this.state.title || ''}
                onChange={this.onTitleChange}
                onBlur={this.onTitleBlur}
                onKeyPress={preventLineBreaks}
                name={filePlacementInputName('title', filePlacement, attachmentable, placementType)}
                rows={1}
                className='form-control'
                async
              />

              <FormText>{window.FolioConsole.translations.fileTitleHint}</FormText>
            </FormGroup>
          </div>

          {fileTypeIsImage && (
            <div className='f-c-file-placement__alt'>
              <FormGroup>
                <TextareaAutosize
                  placeholder='alt'
                  value={this.state.alt || ''}
                  onChange={this.onAltChange}
                  onBlur={this.onAltBlur}
                  onKeyPress={preventLineBreaks}
                  name={filePlacementInputName('alt', filePlacement, attachmentable, placementType)}
                  rows={1}
                  className='form-control'
                  async
                />

                <FormText>{window.FolioConsole.translations.altHint}</FormText>
              </FormGroup>
            </div>
          )}
        </div>

        <NestedModelControls
          remove={this.unselect}
          moveUp={this.moveUp}
          moveDown={this.moveDown}
          edit={onEdit}
        />

        {!this.props.nested && (
          <HiddenInputs
            filePlacement={filePlacement}
            attachmentable={attachmentable}
            placementType={placementType}
            position={position}
          />
        )}

        <div className='f-c-file-placement__handle'>
          <i className='fa fa-arrows-alt' />
        </div>
      </div>
    )
  }
}

const FilePlacementSortableItem = SortableElement((props) => <FilePlacement {...props} />)

export default FilePlacementSortableItem
