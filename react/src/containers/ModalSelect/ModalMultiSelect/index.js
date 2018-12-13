import React, { Fragment } from 'react'
import { connect } from 'react-redux'

import MultiSelect from 'containers/MultiSelect'
import ModalScroll from 'components/ModalScroll';
import { setOriginalPlacements } from 'ducks/filePlacements'

import ModalSelect from '../';
import getPlacementField from './utils/getPlacementField';

class ModalMultiSelect extends ModalSelect {
  save = () => {


    this.close()
  }

  close = () => {
    this.jQueryModal().modal('hide')
  }

  selector () {
    return this.selectingDocument() ? '.folio-console-add-documents' : '.folio-console-add-images'
  }

  jQueryModal () {
    const $ = window.jQuery
    return $('.folio-console-react-modal')
      .filter(`[data-klass="${this.props.fileType}"]`)
      .filter('[data-multi="true"]')
  }

  onOpen (el) {
    const $ = window.jQuery
    const $wrap = $(el).closest('.folio-console-react-picker')

    let placements = []

    $wrap.find('.folio-console-file-list__file').each((i, el) => {
      const $fields = $(el).find('input[type="hidden"]')
      placements.push({
        id: Number(getPlacementField($fields, 'id')),
        file_id: Number(getPlacementField($fields, 'file_id')),
        alt: getPlacementField($fields, 'alt'),
        title: getPlacementField($fields, 'title'),
        position: getPlacementField($fields, 'position'),
      })
    })

    this.props.dispatch(setOriginalPlacements(placements))
  }

  renderHeader () {
    return <h4 className='modal-title'>{window.FolioConsole.translations.galleryManagement}</h4>
  }

  renderFooter () {
    return (
      <Fragment>
        <button className='btn btn-secondary' type="button" onClick={this.close}>
          {window.FolioConsole.translations.cancel}
        </button>
        <button className='btn btn-primary' type="button" onClick={this.save}>
          {window.FolioConsole.translations.save}
        </button>
      </Fragment>
    )
  }

  render () {
    return (
      <ModalScroll
        header={this.renderHeader()}
        footer={this.renderFooter()}
      >
        <MultiSelect />
      </ModalScroll>
    )
  }
}

const mapStateToProps = (state) => ({
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(ModalMultiSelect)
