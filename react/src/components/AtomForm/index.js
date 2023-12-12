import React from 'react'
import { Button, Input } from 'reactstrap'
import { isEqual } from 'lodash'
import ReactModal from 'react-modal'

import NestedModelControls from 'components/NestedModelControls'
import FolioConsoleUiButton from 'components/FolioConsoleUiButton'
import FolioUiIcon from 'components/FolioUiIcon'

import splitAtomValueToParts from './utils/splitAtomValueToParts'

import Associations from './Associations'
import Fields from './Fields'
import Field from './Field'
import MultiAttachments from './MultiAttachments'
import SingleAttachments from './SingleAttachments'
import SplittableModal from './SplittableModal'

import AtomFormWrap from './styled/AtomFormWrap'
import AtomFormHint from './styled/AtomFormHint'
import AtomFormCardOuter from './styled/AtomFormCardOuter'
import AtomFormCardRows from './styled/AtomFormCardRows'
import AtomFormCardRow from './styled/AtomFormCardRow'
import AtomFormCardColumns from './styled/AtomFormCardColumns'
import AtomFormCardColumn from './styled/AtomFormCardColumn'

ReactModal.setAppElement('body')

class AtomForm extends React.PureComponent {
  state = { focusedIndex: null, splittable: null }

  constructor (props) {
    super(props)
    this.autofocusRef = React.createRef()
  }

  onTypeChange = (e) => {
    const { form, structures } = this.props
    const newType = e.target.value
    const newStructure = structures[newType].structure
    const oldAtom = form.atoms[0].record
    const oldStructure = oldAtom.meta.structure
    const values = {}
    Object.keys(newStructure).forEach((key) => {
      if (isEqual(newStructure[key], oldStructure[key])) {
        values[key] = oldAtom.data[key]
      }
    })
    this.props.updateFormAtomType(newType, values)
  }

  onChange = (e, index, key) => {
    if (e.target.type === 'checkbox') {
      this.props.updateFormAtomValue(index, key, e.target.checked)
    } else {
      this.props.updateFormAtomValue(index, key, e.target.value)
    }
  }

  onAssociationChange = (record, index, key) => {
    this.props.updateFormAtomAssociation(index, key, record)
  }

  onValueChange = (index, value, key) => {
    this.props.updateFormAtomValue(index, key, value)
  }

  componentDidMount () {
    window.jQuery('.f-c-simple-form-with-atoms').on('submit', this.handleGlobalFormSubmission)
    window.jQuery(document).on('keydown.fcAtomForm', this.onKeydown)

    if (this.autofocusRef.current) {
      setTimeout(() => { this.autofocusRef.current.focus() }, 0)
    }
  }

  componentWillUnmount () {
    window.jQuery('.f-c-simple-form-with-atoms').off('submit', this.handleGlobalFormSubmission)
    window.jQuery(document).off('keydown.fcAtomForm', this.onKeydown)
  }

  handleGlobalFormSubmission = (e) => {
    e.preventDefault()
    e.stopPropagation()
    this.props.validateAndSubmitGlobalForm()
  }

  saveFormAtoms = () => {
    window.folioConsoleRedactorHardsyncAll()
    this.props.saveFormAtoms()
  }

  onKeydown = (e) => {
    if (e.keyCode === 13 && e.ctrlKey) {
      e.preventDefault()
      this.saveFormAtoms()
      return false
    }
  }

  startSplittingAtom = (atom, field) => {
    const value = atom.record.data[field]
    let parts

    if (atom.record.meta.structure[field].type === 'richtext') {
      parts = splitAtomValueToParts({ value, isRichText: true })
    } else if (atom.record.meta.structure[field].type === 'text') {
      parts = splitAtomValueToParts({ value, isRichText: false })
    } else {
      return
    }

    this.setState({ ...this.state, splittable: { atom, field, parts } })
  }

  splittableSave = (splitIndices) => {
    if (splitIndices && splitIndices.length > 0) {
      const parts = []
      let currentPart = ''

      this.state.splittable.parts.forEach((part, partIndex) => {
        if (splitIndices.indexOf(partIndex) !== -1) {
          parts.push(currentPart)
          currentPart = ''
        }

        currentPart += part
      })

      if (currentPart !== '') {
        parts.push(currentPart)
      }

      this.props.splitFormAtom(this.state.splittable.field, parts)
      this.props.saveFormAtomsWithoutValidation()
    }

    this.splittableCancel()
  }

  splittableCancel = () => {
    this.setState({ ...this.state, splittable: null })
  }

  renderHint (text, molecule) {
    return (
      <AtomFormHint molecule={molecule}>
        <FolioUiIcon name='info' />
        {text.split(/\n/).map((part, i) => <p key={i} dangerouslySetInnerHTML={{ __html: part }} />)}
      </AtomFormHint>
    )
  }

  render () {
    const prefix = `${this.props.namespace}[${this.props.index + 1}]`
    const molecule = this.props.form.atoms[0].record.meta.molecule
    const addButtons = []
    let nonSingletonIndex = 0

    const asyncData = {}

    this.props.form.atoms.forEach((atom) => {
      if (atom.record.meta.molecule_singleton) {
        Object.keys(atom.record.associations).forEach((key) => {
          if (atom.record.associations[key]) {
            asyncData[key] = atom.record.associations[key].id
          }
        })
      }
    })

    if (molecule) {
      Object.keys(this.props.structures).forEach((type) => {
        if (this.props.structures[type].molecule === molecule) {
          let shouldAdd = true

          if (this.props.structures[type].molecule_singleton) {
            const exists = this.props.form.atoms.filter((atom) => atom.record.type === type).length > 0
            shouldAdd = !exists
          }

          if (shouldAdd) {
            addButtons.push({ type, title: this.props.structures[type].title })
          }
        }
      })
    }

    const usedTypes = this.props.form.atoms.map((atom) => atom.record.type)
    const typeForValue = this.props.atomTypes.find(({ key }) => usedTypes.indexOf(key) !== -1)
    const typeValue = typeForValue ? typeForValue.key : undefined

    return (
      <AtomFormWrap>
        <div className='f-c-r-atoms-settings-header'>
          <div className='f-c-r-atoms-settings-header__title'>
            <Input
              type='select'
              value={typeValue}
              name={`${prefix}[type]`}
              onChange={this.onTypeChange}
              className='folio-console-atom-type-select select'
            >
              {this.props.atomTypes.map(({ key, title }) => (
                <option key={key} value={key}>{title}</option>
              ))}
            </Input>
          </div>

          <div className='f-c-r-atoms-settings-header__controls'>
            <FolioConsoleUiButton
              type='button'
              variant='primary'
              className='f-c-r-atoms-settings-header__button'
              onClick={this.saveFormAtoms}
              label={window.FolioConsole.translations.done}
            />

            <button
              type='button'
              className='f-c-r-atoms-settings-header__close'
              onClick={this.props.closeFormAtom}
            >
              <FolioUiIcon name='close' />
            </button>
          </div>
        </div>

        <div className='f-c-simple-form-with-atoms__overlay-scroll f-c-atom-form-toolbar-fix-parent'>
          {this.props.form.atoms.map((atom, index) => {
            const asMolecule = molecule && !atom.record.meta.molecule_singleton
            if (asMolecule) { nonSingletonIndex++ }

            const fillOutput = (input) => {
              let zIndex = 100
              const makeStyle = () => ({ position: 'relative', zIndex: (zIndex -= 1) })

              if (typeof input === 'object') {
                if (input.rows) {
                  zIndex -= 1
                  return (
                    <AtomFormCardRows data-debug='rows' style={makeStyle()}>
                      {input.rows.map((row) => {
                        zIndex -= 1

                        return (
                          <AtomFormCardRow data-debug='row' key={JSON.stringify(row)} style={makeStyle()}>
                            {fillOutput(row)}
                          </AtomFormCardRow>
                        )
                      })}
                    </AtomFormCardRows>
                  )
                } else if (input.columns) {
                  zIndex -= 1

                  return (
                    <AtomFormCardColumns data-debug='columns' style={makeStyle()}>
                      {input.columns.map((column) => (
                        <AtomFormCardColumn data-debug='column' key={JSON.stringify(column)}>
                          {fillOutput(column)}
                        </AtomFormCardColumn>
                      ))}
                    </AtomFormCardColumns>
                  )
                } else {
                  input.map((item) => fillOutput(item))
                }
              } else {
                zIndex -= 1

                if (input === 'aside_attachments') {
                  return (
                    <AtomFormCardColumns data-debug='columns' style={makeStyle()}>
                      <AtomFormCardColumn data-debug='column' dontGrow>
                        {fillOutput('ATTACHMENTS')}
                      </AtomFormCardColumn>
                      <AtomFormCardColumn data-debug='column'>
                        <AtomFormCardRows data-debug='rows' style={makeStyle()}>
                          <AtomFormCardRow data-debug='row' style={makeStyle()}>
                            {fillOutput('ASSOCIATIONS')}
                          </AtomFormCardRow>
                          <AtomFormCardRow data-debug='row' style={makeStyle()}>
                            {fillOutput('STRUCTURE')}
                          </AtomFormCardRow>
                        </AtomFormCardRows>
                      </AtomFormCardColumn>
                    </AtomFormCardColumns>
                  )
                } else if (input === 'ASSOCIATIONS') {
                  return (
                    <Associations
                      atom={atom}
                      key={input}
                      asyncData={asMolecule ? asyncData : undefined}
                      onChange={this.onAssociationChange}
                      onBlur={() => { this.setState({ focusedIndex: null }) }}
                      onFocus={() => { this.setState({ focusedIndex: index }) }}
                      index={index}
                      style={makeStyle()}
                      addAtomSettings
                    />
                  )
                } else if (input === 'STRUCTURE') {
                  return (
                    <Fields
                      key={input}
                      atom={atom}
                      onChange={this.onChange}
                      onValueChange={this.onValueChange}
                      index={index}
                      style={makeStyle()}
                      startSplittingAtom={this.startSplittingAtom}
                    />
                  )
                } else if (input === 'ATTACHMENTS') {
                  return (
                    <SingleAttachments
                      key={input}
                      attachments={atom.record.meta.attachments}
                      atom={atom.record}
                      index={index}
                      updateFormAtomAttachment={this.props.updateFormAtomAttachment}
                      removeFormAtomAttachment={this.props.removeFormAtomAttachment}
                      style={makeStyle()}
                    />
                  )
                } else if (input.indexOf('STRUCTURE/') !== -1) {
                  return (
                    <Field
                      key={input}
                      atom={atom}
                      field={input.replace('STRUCTURE/', '')}
                      onChange={this.onChange}
                      onValueChange={this.onValueChange}
                      style={makeStyle()}
                      index={index}
                      startSplittingAtom={this.startSplittingAtom}
                    />
                  )
                }
              }
            }

            const output = fillOutput(atom.record.meta.form_layout)

            return (
              <AtomFormCardOuter
                key={atom.record.id || atom.record.lodashId}
                asMolecule={asMolecule}
                focused={index === this.state.focusedIndex || atom.record.meta.molecule_singleton}
              >
                <div className={asMolecule ? 'card' : undefined}>
                  <div className={asMolecule ? 'card-body mb-n3' : undefined}>
                    {atom.messages.length > 0 && (
                      <div className={`${asMolecule ? 'mt-0 mb-g' : 'my-g'} alert alert-danger`}>
                        <div className='fw-bold'>{window.FolioConsole.translations.errorNotification}</div>

                        <ul>
                          {atom.messages.map((message) => (
                            <li className='mt-2' key={message}>{message}</li>
                          ))}
                        </ul>
                      </div>
                    )}

                    {output}

                    <MultiAttachments
                      atom={atom}
                      index={index}
                      openFileModal={this.props.openFileModal}
                    />

                    {atom.record.meta.hint && this.renderHint(atom.record.meta.hint, molecule)}

                    {atom.validating && <span className='folio-loader' />}
                  </div>
                </div>

                {asMolecule && (
                  <NestedModelControls
                    moveUp={nonSingletonIndex > 1 ? () => { this.props.moveFormAtom(index, index - 1) } : null}
                    moveDown={(index + 1 !== this.props.form.atoms.length) ? () => { this.props.moveFormAtom(index, index + 1) } : null}
                    remove={this.props.form.atoms.length > 1 ? () => { this.props.removeFormAtom(index) } : null}
                    vertical
                  />
                )}
              </AtomFormCardOuter>
            )
          })}

          {addButtons.map((type) => (
            <Button color='success' type='button' className='mr-2' onClick={() => { this.props.addAtom(type.type) }} key={type.type}>
              <FolioUiIcon name='plus' />
              {type.title}
            </Button>
          ))}
        </div>

        <ReactModal
          isOpen={!!this.state.splittable}
          onRequestClose={this.splittableCancel}
          className='ReactModal ReactModal--AtomFormSplittable'
        >
          {this.state.splittable ? (
            <SplittableModal
              splittable={this.state.splittable}
              save={this.splittableSave}
              cancel={this.splittableCancel}
            />
          ) : null}
        </ReactModal>
      </AtomFormWrap>
    )
  }
}

export default AtomForm
