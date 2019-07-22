import React from 'react'
import { SortableElement } from 'react-sortable-hoc'

import NestedModelControls from 'components/NestedModelControls'
import FormGroup from 'components/FormGroup';

import filePlacementInputName from '../utils/filePlacementInputName'
import HiddenInputs from './HiddenInputs';

class FilePlacement extends React.Component {
  state = {
    alt: '',
    title: '',
  }

  constructor (props) {
    super(props)
    this.state = {
      alt: props.filePlacement.alt,
      title: props.filePlacement.title,
    }
  }

  onTitleChange = (e) => {
    this.setState({ ...this.state, title: e.target.value })
  }

  onAltChange = (e) => {
    this.setState({ ...this.state, alt: e.target.value })
  }

  onTitleBlur = (e) => {
    this.props.onTitleChange(this.props.filePlacement, e.target.value)
  }

  onAltBlur = (e) => {
    this.props.onAltChange(this.props.filePlacement, e.target.value)
  }

  unselect = () => {
    this.props.unselectFilePlacement(this.props.filePlacement)
  }

  moveUp = () => {
    if (!this.props.isFirst) {
      this.props.move({
        oldIndex: this.props.position,
        newIndex: this.props.position - 1,
      })
    }
  }

  moveDown = () => {
    if (!this.props.isLast) {
      this.props.move({
        oldIndex: this.props.position,
        newIndex: this.props.position + 1,
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
    } = this.props

    let className
    if (fileTypeIsImage) {
      className = 'folio-console-file-placement folio-console-file-placement--image'
    } else {
      className = 'folio-console-file-placement folio-console-file-placement--document'
    }

    return (
      <div className={className}>
        {fileTypeIsImage && (
          <a
            className='folio-console-file-placement__img-wrap'
            href={filePlacement.file.attributes.source_image}
            target='_blank'
            rel='noopener noreferrer'
            onClick={(e) => e.stopPropagation()}
          >
            <img src={filePlacement.file.attributes.thumb} className='folio-console-file-placement__img' alt='' />
          </a>
        )}

        <div className='folio-console-file-placement__inputs'>
          <div className='folio-console-file-placement__title'>
            <FormGroup
              placeholder={filePlacement.file.attributes.file_name}
              value={this.state.title}
              onChange={this.onTitleChange}
              onBlur={this.onTitleBlur}
              name={filePlacementInputName('title', filePlacement, attachmentable, placementType)}
              hint={window.FolioConsole.translations.fileTitleHint}
            />
          </div>

          {fileTypeIsImage && (
            <div className='folio-console-file-placement__alt'>
              <FormGroup
                placeholder='alt'
                value={this.state.alt}
                onChange={this.onAltChange}
                onBlur={this.onAltBlur}
                name={filePlacementInputName('alt', filePlacement, attachmentable, placementType)}
                hint={window.FolioConsole.translations.altHint}
              />
            </div>
          )}
        </div>

        <NestedModelControls
          remove={this.unselect}
          moveUp={this.moveUp}
          moveDown={this.moveDown}
        />

        <HiddenInputs
          filePlacement={filePlacement}
          attachmentable={attachmentable}
          placementType={placementType}
          position={position}
        />

        <div className='folio-console-file-placement__handle'>
          <i className='fa fa-arrows-alt' />
        </div>
      </div>
    )
  }
}

const FilePlacementSortableItem = SortableElement((props) => <FilePlacement {...props} />)

export default FilePlacementSortableItem
