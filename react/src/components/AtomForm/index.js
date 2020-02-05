import React from 'react'
import { Button, Input } from 'reactstrap'
import { isEqual } from 'lodash'

import NestedModelControls from 'components/NestedModelControls'

import Associations from './Associations'
import Fields from './Fields'
import MultiAttachments from './MultiAttachments'
import SingleAttachments from './SingleAttachments'

import AtomFormWrap from './styled/AtomFormWrap'
import AtomFormHint from './styled/AtomFormHint'
import AtomFormCardOuter from './styled/AtomFormCardOuter'

class AtomForm extends React.PureComponent {
  state = { focusedIndex: null }

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
    if (this.autofocusRef.current) {
      setTimeout(() => { this.autofocusRef.current.focus() }, 0)
    }
  }

  componentWillMount () {
    window.jQuery('.f-c-simple-form-with-atoms').on('submit', this.handleGlobalFormSubmission)
  }

  componentWillUnmount () {
    window.jQuery('.f-c-simple-form-with-atoms').off('submit', this.handleGlobalFormSubmission)
  }

  handleGlobalFormSubmission = (e) => {
    e.preventDefault()
    e.stopPropagation()
    this.props.validateAndSubmitGlobalForm()
  }

  renderHint (text, molecule) {
    return (
      <AtomFormHint molecule={molecule}>
        <span className='mi'>info</span>
        {text.split(/\n/).map((part, i) => <p key={i}>{part}</p>)}
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

    return (
      <AtomFormWrap>
        <div className='f-c-atoms-settings-header'>
          <div className='f-c-atoms-settings-header__title'>
            <Input
              type='select'
              value={this.props.form.atoms[0].record.type}
              name={`${prefix}[type]`}
              onChange={this.onTypeChange}
              className='folio-console-atom-type-select'
            >
              {this.props.atomTypes.map(({ key, title }) => (
                <option key={key} value={key}>{title}</option>
              ))}
            </Input>
          </div>

          <div className='f-c-atoms-settings-header__controls'>
            <button
              type='button'
              className='btn btn-outline f-c-atoms-settings-header__button'
              onClick={this.props.saveFormAtoms}
            >
              {window.FolioConsole.translations.done}
            </button>

            <button
              type='button'
              className='f-c-atoms-settings-header__close mi'
              onClick={this.props.closeFormAtom}
            >
              close
            </button>
          </div>
        </div>

        <div className='f-c-simple-form-with-atoms__overlay-scroll f-c-atom-form-toolbar-fix-parent'>
          {this.props.form.atoms.map((atom, index) => {
            const asMolecule = molecule && !atom.record.meta.molecule_singleton
            if (asMolecule) { nonSingletonIndex++ }

            const singleAttachments = (
              <SingleAttachments
                attachments={atom.record.meta.attachments}
                atom={atom.record}
                index={index}
                remove={this.props.removeFormAtomAttachment}
              />
            )

            const inputs = (
              <React.Fragment>
                <Fields
                  atom={atom}
                  onChange={this.onChange}
                  onValueChange={this.onValueChange}
                  index={index}
                />

                <Associations
                  atom={atom}
                  asyncData={asMolecule ? asyncData : undefined}
                  onChange={this.onAssociationChange}
                  onBlur={() => { this.setState({ focusedIndex: null }) }}
                  onFocus={() => { this.setState({ focusedIndex: index }) }}
                  index={index}
                />
              </React.Fragment>
            )

            let renderAsFlex = false
            if (Object.keys(atom.record.meta.attachments).length === 1) {
              if (!atom.record.meta.attachments[0].plural) {
                if (Object.keys(atom.record.meta.structure).length <= 3) {
                  renderAsFlex = true
                }
              }
            }

            return (
              <AtomFormCardOuter
                key={atom.record.id || atom.record.timestamp}
                className={asMolecule ? 'card-outer' : undefined}
                focused={index === this.state.focusedIndex}
              >
                <div className={asMolecule ? 'card' : undefined}>
                  <div className={asMolecule ? 'card-body mb-n3' : undefined}>
                    {atom.messages.length > 0 && (
                      <div className='my-3 alert alert-danger'>
                        <div className='font-weight-bold'>{window.FolioConsole.translations.errorNotification}</div>

                        <ul>
                          {atom.messages.map((message) => (
                            <li className='mt-2' key={message}>{message}</li>
                          ))}
                        </ul>
                      </div>
                    )}

                    {renderAsFlex ? (
                      <div className='d-flex position-relative z-index-2'>
                        {singleAttachments}
                        <div className='flex-grow-1'>
                          {inputs}
                        </div>
                      </div>
                    ) : (
                      <div className='position-relative z-index-2'>
                        {singleAttachments}
                        {inputs}
                      </div>
                    )}

                    <MultiAttachments atom={atom} index={index} />

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
              <i className='fa fa-plus' />
              {type.title}
            </Button>
          ))}
        </div>
      </AtomFormWrap>
    )
  }
}

export default AtomForm
