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

  render () {
    const {
      filePlacement,
      attachmentable,
      placementType,
      position,
      unselectFilePlacement,
      fileTypeIsImage,
    } = this.props

    return (
      <div className='folio-console-file-placement'>
        {fileTypeIsImage && (
          <a
            className='folio-console-file-placement__img-wrap'
            href={filePlacement.file.source_image}
            target='_blank'
            rel='noopener noreferrer'
            onClick={(e) => e.stopPropagation()}
          >
            <img src={filePlacement.file.thumb} className='folio-console-file-placement__img' alt='' />
          </a>
        )}

        <div className='folio-console-file-placement__title'>
          <FormGroup
            placeholder={filePlacement.file.file_name}
            value={this.state.title}
            onChange={this.onTitleChange}
            name={filePlacementInputName('title', filePlacement, attachmentable, placementType)}
          />
        </div>

        {fileTypeIsImage && (
          <div className='folio-console-file-placement__alt'>
            <FormGroup
              placeholder='alt'
              value={this.state.alt}
              onChange={this.onAltChange}
              name={filePlacementInputName('alt', filePlacement, attachmentable, placementType)}
            />
          </div>
        )}

        <NestedModelControls
          remove={() => unselectFilePlacement(filePlacement)}
        />

        <HiddenInputs
          filePlacement={filePlacement}
          attachmentable={attachmentable}
          placementType={placementType}
          position={position}
        />
      </div>
    )
  }
}

const FilePlacementSortableItem = SortableElement((props) => <FilePlacement {...props} />)

export default FilePlacementSortableItem
