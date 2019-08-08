import React from 'react'
import { FormGroup, FormText, Input, Label } from 'reactstrap'
import { isEqual } from 'lodash'

import MultiSelect from 'containers/MultiSelect'
import RichTextEditor from 'components/RichTextEditor'
import SingleSelectTrigger from 'components/SingleSelectTrigger'
import ColorInput from 'components/ColorInput'
import DateInput from 'components/DateInput'

import fileTypeToKey from 'utils/fileTypeToKey'
import preventEnterSubmit from 'utils/preventEnterSubmit'

import AtomFormWrap from './styled/AtomFormWrap'

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

  onChange (e, key) {
    this.props.updateFormAtomValue(key, e.target.value)
  }

  onValueChange (value, key) {
    this.props.updateFormAtomValue(key, value)
  }

  inputProps (type) {
    switch (type) {
      case 'code':
      case 'text':
        return { type: 'textarea' }

      case 'float':
        return { type: 'number', step: '0.01' }

      case 'integer':
        return { type: 'number', step: '1' }

      default:
        return { type: 'text' }
    }
  }

  componentDidMount () {
    if (this.autofocusRef.current) {
      setTimeout(() => { this.autofocusRef.current.focus() }, 0)
    }
  }

  renderInput (key, meta, data, autofocusRef) {
    if (meta.structure[key].type === 'richtext') {
      return (
        <RichTextEditor
          name={key}
          defaultValue={data[key]}
          onChange={(html) => this.onValueChange(html, key)}
          placeholder={meta.structure[key].label}
          invalid={Boolean(this.props.form.errors[key])}
          ref={autofocusRef()}
        />
      )
    }

    if (meta.structure[key].type === 'color') {
      return (
        <ColorInput
          name={key}
          defaultValue={data[key]}
          onChange={(colorString) => this.onValueChange(colorString, key)}
          placeholder={meta.structure[key].label}
          invalid={Boolean(this.props.form.errors[key])}
          type={meta.structure[key].type}
        />
      )
    }

    if (meta.structure[key].type === 'date' || meta.structure[key].type === 'datetime') {
      return (
        <DateInput
          name={key}
          defaultValue={data[key]}
          onChange={(e) => this.onChange(e, key)}
          placeholder={meta.structure[key].label}
          invalid={Boolean(this.props.form.errors[key])}
          type={meta.structure[key].type}
        />
      )
    }

    if (meta.structure[key].collection) {
      return (
        <Input
          type='select'
          name={key}
          defaultValue={data[key]}
          onChange={(e) => this.onChange(e, key)}
          placeholder={meta.structure[key].label}
          invalid={Boolean(this.props.form.errors[key])}
        >
          {meta.structure[key].collection.map((record) => (
            <option key={record[1]} value={record[1]}>{record[0]}</option>
          ))}
        </Input>
      )
    }

    return (
      <Input
        {...this.inputProps(meta.structure[key].type)}
        name={key}
        defaultValue={data[key]}
        onChange={(e) => this.onChange(e, key)}
        onKeyPress={preventEnterSubmit}
        placeholder={meta.structure[key].label}
        innerRef={autofocusRef()}
        invalid={Boolean(this.props.form.errors[key])}
      />
    )
  }

  formGroupClassName (key, meta) {
    const classNames = []

    if (this.props.form.errors[key]) {
      classNames.push('form-group-invalid')
    } else {
      classNames.push('form-group-valid')
    }

    if (meta.structure[key].type === 'date') {
      classNames.push('date')
    } else if (meta.structure[key].type === 'datetime') {
      classNames.push('datetime')
    } else if (meta.structure[key].type === 'color') {
      classNames.push('color')
    }

    return classNames.join(' ')
  }

  render () {
    const { data, meta, type } = this.props.atom
    const { errors, messages, validating } = this.props.form
    const prefix = `${this.props.namespace}[${this.props.index + 1}]`
    let autofocused = false
    const autofocusRef = () => {
      if (autofocused) {
        return undefined
      } else {
        autofocused = true
        return this.autofocusRef
      }
    }

    return (
      <AtomFormWrap>
        <div className='f-c-atoms-settings-header'>
          <div className='f-c-atoms-settings-header__title'>
            <Input
              type='select'
              value={type}
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
              onClick={this.props.saveFormAtom}
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

        <div className='f-c-simple-form-with-atoms__form-scroll f-c-atom-form-toolbar-fix-parent'>
          <div>
            {messages.length > 0 && (
              <div className='my-3 alert alert-danger'>
                <div className='font-weight-bold'>{window.FolioConsole.translations.errorNotification}</div>

                <ul>
                  {messages.map((message) => (
                    <li className='mt-2' key={message}>{message}</li>
                  ))}
                </ul>
              </div>
            )}

            <div className='d-flex'>
              {meta.attachments.map((attachmentType) => (
                attachmentType.plural ? null : (
                  <SingleSelectTrigger
                    key={attachmentType.key}
                    attachmentType={attachmentType}
                    data={this.props.atom[attachmentType.key]}
                    remove={() => this.props.removeFormAtomAttachment(attachmentType.key)}
                  />
                )
              ))}
            </div>

            {Object.keys(meta.structure).map((key) => (
              <FormGroup key={key} className={this.formGroupClassName(key, meta)}>
                {<Label>{meta.structure[key].label}</Label>}
                {this.renderInput(key, meta, data, autofocusRef)}

                {errors[key] && (
                  <FormText className='invalid-feedback' color='danger'>{errors[key]}</FormText>
                )}
              </FormGroup>
            ))}

            {meta.attachments.map((attachmentType) => (
              attachmentType.plural ? (
                <div className='mt-4' key={attachmentType.key}>
                  <MultiSelect
                    filesKey={fileTypeToKey(attachmentType['file_type'])}
                    shouldLoadFiles
                  />
                </div>
              ) : null
            ))}

          </div>
        </div>
        {validating && <span className='folio-loader' />}
      </AtomFormWrap>
    )
  }
}

export default AtomForm
