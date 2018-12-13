import React, { Fragment } from 'react'
import { connect } from 'react-redux'

import MultiSelect from 'containers/MultiSelect'
import ModalScroll from 'components/ModalScroll';
import { setOriginalPlacements, filePlacementsSelector } from 'ducks/filePlacements'
import numberToHumanSize from 'utils/numberToHumanSize'

import ModalSelect from '../';
import getPlacementField from './utils/getPlacementField';
import hiddenFieldHtml from './utils/hiddenFieldHtml';

class ModalMultiSelect extends ModalSelect {
  save = () => {
    const $ = window.jQuery
    const $el = $(this.state.el)
    const $wrap = $el.closest('.folio-console-react-picker').find('.folio-console-react-picker__files')

    const name = this.inputName($el)
    const placementKey = $wrap.data('placement-key')
    const date = Date.now()
    let i = 0

    const selected = this.props.filePlacements.selected.map((placement) => {
      i++
      const prefix = `${name}[${placementKey}_attributes][${date + i}]`
      return this.htmlForPlacement(placement, prefix, i)
    })

    const deleted = this.props.filePlacements.deleted.map((placement, i) => {
      i++
      const prefix = `${name}[${placementKey}_attributes][${date + i}]`

      return `
        ${hiddenFieldHtml(prefix, 'id', placement.id)}
        ${hiddenFieldHtml(prefix, '_destroy', 1)}
      `
    })

    $wrap.html(this.htmlForPlacements(selected, deleted))

    this.close()
  }

  htmlForPlacement = (placement, prefix, i) => {
    const hiddenFields = [
      hiddenFieldHtml(prefix, 'id', placement.id),
      hiddenFieldHtml(prefix, 'alt', placement.alt),
      hiddenFieldHtml(prefix, 'title', placement.title),
      hiddenFieldHtml(prefix, 'file_id', placement.file_id),
      hiddenFieldHtml(prefix, 'position', i),
      hiddenFieldHtml(prefix, '_destroy', 0),
    ].join('')

    if (this.selectingDocument()) {
      return `
        <div class="folio-console-file-table__tr">
          <div class="folio-console-file-table__td folio-console-file-table__td--main">${placement.title || placement.file.file_name}</div>
          <div class="folio-console-file-table__td folio-console-file-table__td--size">${numberToHumanSize(placement.file.file_size)}</div>
          <div class="folio-console-file-table__td folio-console-file-table__td--extension">${placement.file.extension}</div>
          ${hiddenFields}
        </div>
      `
    } else {
      return `
        <div class="folio-console-file-list__file">
          <div class="folio-console-file-list__img-wrap">
            <img class="folio-console-thumbnail__img folio-console-file-list__img" src="${window.encodeURI(placement.file.thumb)}">
          </div>
          ${hiddenFields}
        </div>
      `
    }
  }

  htmlForPlacements = (selected, deleted) => {
    if (this.selectingDocument()) {
      return `
        <div class="folio-console-file-table-wrap">
          <div class="folio-console-file-table folio-console-file-table--document">
            <div class="folio-console-file-table__tbody">
              ${selected.join('')}
              ${deleted.join('')}
            </div>
          </div>
        </div>
      `
    } else {
      return `
        <div class="folio-console-file-list">
          ${selected.join('')}
          ${deleted.join('')}
        </div>
      `
    }
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

    $wrap.find('.folio-console-file-list__file, .folio-console-file-table__tr').each((_i, el) => {
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
    const key = this.selectingDocument() ? 'documentsManagement' : 'galleryManagement'
    return <h4 className='modal-title'>{window.FolioConsole.translations[key]}</h4>
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
