import React from 'react'
import { Button, Input } from 'reactstrap'
import { isEqual, find } from 'lodash'

import NestedModelControls from 'components/NestedModelControls'

import Associations from './Associations'
import Fields from './Fields'
import MultiAttachments from './MultiAttachments'
import SingleAttachments from './SingleAttachments'

import AtomFormWrap from './styled/AtomFormWrap'
import AtomFormHint from './styled/AtomFormHint'

class AtomForm extends React.PureComponent {
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

  onAssociationChange = (e, index, key) => {
    const { records } = this.props.form.atoms[index].record.meta.associations[key]
    const record = find(records, { value: e.target.value })
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

  renderHint (text) {
    return (
      <AtomFormHint>
        <span className='mi'>info</span>
        {text.split(/\n/).map((part, i) => <p key={i}>{part}</p>)}
      </AtomFormHint>
    )
  }

  render () {
    const prefix = `${this.props.namespace}[${this.props.index + 1}]`
    const molecule = Boolean(this.props.form.atoms[0].record.meta.molecule)

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
          {this.props.form.atoms.map((atom, index) => (
            <div key={atom.record.id || atom.record.timestamp} className={molecule ? 'card-outer' : undefined}>
              <div className={molecule ? 'card' : undefined}>
                <div className={molecule ? 'card-body mb-n3' : undefined}>
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

                  <SingleAttachments
                    attachments={atom.record.meta.attachments}
                    atom={atom.record}
                    index={index}
                    remove={this.props.removeFormAtomAttachment}
                  />

                  <Fields
                    atom={atom}
                    onChange={this.onChange}
                    onValueChange={this.onValueChange}
                    index={index}
                  />

                  <Associations
                    atom={atom}
                    onChange={this.onAssociationChange}
                    index={index}
                  />

                  <MultiAttachments atom={atom} />

                  {atom.record.meta.hint && this.renderHint(atom.record.meta.hint)}

                  {atom.validating && <span className='folio-loader' />}
                </div>
              </div>

              {molecule && (
                <NestedModelControls
                  moveUp={index !== 0 ? () => { this.props.moveFormAtom(index, index - 1) } : null}
                  moveDown={(index + 1 !== this.props.form.atoms.length) ? () => { this.props.moveFormAtom(index, index + 1) } : null}
                  remove={this.props.form.atoms.length > 1 ? () => { this.props.removeFormAtom(index) } : null}
                  vertical
                />
              )}
            </div>
          ))}

          {molecule && (
            <Button color='success' type='button' onClick={this.props.addAtom}>
              <i className='fa fa-plus' />
              {window.FolioConsole.translations.add}
            </Button>
          )}
        </div>
      </AtomFormWrap>
    )
  }
}

export default AtomForm
