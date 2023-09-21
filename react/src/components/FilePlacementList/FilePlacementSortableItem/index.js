import React from 'react'
import { SortableElement } from 'react-sortable-hoc'

import NestedModelControls from 'components/NestedModelControls'
import FileHoverButtons from 'components/FileHoverButtons'
import Picture from 'components/Picture'

import HiddenInputs from './HiddenInputs'

const I18N = {
  cs: {
    alt: 'Alt',
    altMissing: 'Alt nevyplněn',
    description: 'Popis',
    descriptionMissing: 'Popis nevyplněn'
  },
  en: {
    alt: 'Alt',
    altMissing: 'Alt missing',
    description: 'Title',
    descriptionMissing: 'Title missing'
  }
}

class FilePlacement extends React.Component {
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
              style={{ background: filePlacement.file.attributes.dominant_color }}
              target='_blank'
              rel='noopener noreferrer'
              onClick={(e) => e.stopPropagation()}
            >
              <Picture file={filePlacement.file} imageClassName='f-c-file-placement__img' />
            </a>

            {<FileHoverButtons edit onEdit={onEdit} />}
          </div>
        )}

        <div className='f-c-file-placement__inputs' onClick={onEdit}>
          <div className='f-c-file-placement__description'>
            {filePlacement.file.attributes.description ? `${window.Folio.i18n(I18N, 'description')}: ${filePlacement.file.attributes.description}` : <span className='text-muted'>{window.Folio.i18n(I18N, 'descriptionMissing')}</span>}
          </div>

          {fileTypeIsImage && (
            <div className='f-c-file-placement__alt'>
              {filePlacement.file.attributes.alt ? `${window.Folio.i18n(I18N, 'alt')}: ${filePlacement.file.attributes.alt}` : <span className='text-danger'>{window.Folio.i18n(I18N, 'altMissing')}</span>}
            </div>
          )}
        </div>

        <NestedModelControls
          remove={this.unselect}
          moveUp={this.moveUp}
          moveDown={this.moveDown}
          edit={onEdit}
          handleClassName='f-c-file-placement__handle'
        />

        {!this.props.nested && (
          <HiddenInputs
            filePlacement={filePlacement}
            attachmentable={attachmentable}
            placementType={placementType}
            position={position}
          />
        )}
      </div>
    )
  }
}

const FilePlacementSortableItem = SortableElement((props) => <FilePlacement {...props} />)

export default FilePlacementSortableItem
