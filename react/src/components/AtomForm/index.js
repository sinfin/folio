import React from 'react'
import { Input } from 'reactstrap'
import { isEqual, find } from 'lodash'

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
    const { atom, structures } = this.props
    const newType = e.target.value
    const newStructure = structures[newType].structure
    const oldStructure = atom.meta.structure
    const values = {}
    Object.keys(newStructure).forEach((key) => {
      if (isEqual(newStructure[key], oldStructure[key])) {
        values[key] = atom.data[key]
      }
    })
    this.props.updateFormAtomType(newType, values)
  }

  onChange = (e, key) => {
    if (e.target.type === 'checkbox') {
      this.props.updateFormAtomValue(key, e.target.checked)
    } else {
      this.props.updateFormAtomValue(key, e.target.value)
    }
  }

  onAssociationChange (e, key) {
    const { records } = this.props.form.atom.meta.associations[key]
    const record = find(records, { value: e.target.value })
    this.props.updateFormAtomAssociation(key, record)
  }

  onValueChange = (value, key) => {
    this.props.updateFormAtomValue(key, value)
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
    // let autofocused = false
    // const autofocusRef = () => {
    //   if (autofocused) {
    //     return undefined
    //   } else {
    //     autofocused = true
    //     return this.autofocusRef
    //   }
    // }

    return (
      <AtomFormWrap>
        <div className='f-c-atoms-settings-header'>
          <div className='f-c-atoms-settings-header__title'>
            <Input
              type='select'
              value={this.props.form.atom.type}
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
          <div>
            {this.props.form.messages.length > 0 && (
              <div className='my-3 alert alert-danger'>
                <div className='font-weight-bold'>{window.FolioConsole.translations.errorNotification}</div>

                <ul>
                  {this.props.form.messages.map((message) => (
                    <li className='mt-2' key={message}>{message}</li>
                  ))}
                </ul>
              </div>
            )}

            <SingleAttachments
              attachments={this.props.form.atom.meta.attachments}
              atom={this.props.form.atom}
              remove={this.props.removeFormAtomAttachment}
            />

            <Fields
              form={this.props.form}
              onChange={this.onChange}
              onValueChange={this.onValueChange}
            />

            <Associations
              onChange={(e, key) => this.onAssociationChange(e, key)}
              form={this.props.form}
            />

            <MultiAttachments attachments={this.props.form.atom.meta.attachments} />
          </div>

          {this.props.form.atom.meta.hint && this.renderHint(this.props.form.atom.meta.hint)}
        </div>
        {this.props.form.validating && <span className='folio-loader' />}
      </AtomFormWrap>
    )
  }
}

export default AtomForm
