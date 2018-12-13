import React, { Fragment } from 'react'
import { connect } from 'react-redux'

import MultiSelect from 'containers/MultiSelect'
import ModalScroll from 'components/ModalScroll';
import { setOriginalPlacements, filePlacementsSelector } from 'ducks/filePlacements'

import ModalSelect from '../';
import getPlacementField from './utils/getPlacementField';
import hiddenFieldHtml from './utils/hiddenFieldHtml';

class ModalMultiSelect extends ModalSelect {
  save = () => {
    const $el = $(this.state.el)
    const $wrap = $el.closest('.folio-console-react-picker').find('.folio-console-react-picker__files')
    const $nestedInput = $el.closest('.nested-fields').find('input[type="hidden"]')

    let name
    if ($nestedInput.length) {
      name = $nestedInput.attr('name').match(/\w+\[\w+\]\[\w+\]/)
    } else {
      const $genericInput = $el.closest('form').find('.form-control[name*="["]').first()
      name = $genericInput.attr('name').split('[')[0]
    }

    const placementKey = $wrap.data('placement-key')
    const date = Date.now()
    let i = 0

    const selected = this.props.filePlacements.selected.map((placement) => {
      i++
      const prefix = `${name}[${placementKey}_attributes][${date + i}]`

      return `
        <div class="folio-console-file-list__file">
          <div class="folio-console-file-list__img-wrap">
            <img class="folio-console-thumbnail__img folio-console-file-list__img" src="${window.encodeURI(placement.file.thumb)}">
          </div>

          ${hiddenFieldHtml(prefix, 'id', placement.id)}
          ${hiddenFieldHtml(prefix, 'alt', placement.alt)}
          ${hiddenFieldHtml(prefix, 'title', placement.title)}
          ${hiddenFieldHtml(prefix, 'file_id', placement.file_id)}
          ${hiddenFieldHtml(prefix, 'position', i)}
          ${hiddenFieldHtml(prefix, '_destroy', 0)}
        </div>
      `
    })

    const deleted = this.props.filePlacements.deleted.map((placement, i) => {
      i++
      const prefix = `${name}[${placementKey}_attributes][${date + i}]`

      return `
        ${hiddenFieldHtml(prefix, 'id', placement.id)}
        ${hiddenFieldHtml(prefix, '_destroy', 1)}
      `
    })

    $wrap.html(`
      <div class="folio-console-file-list">
        ${selected.join('')}
        ${deleted.join('')}
      </div>
    `)

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
  filePlacements: filePlacementsSelector(state),
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(ModalMultiSelect)
