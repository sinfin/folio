import React from 'react'
import { FormGroup, FormText, Input, Label } from 'reactstrap'
import { isEqual } from 'lodash'

import MultiSelect from 'containers/MultiSelect'
import RichTextEditor from 'components/RichTextEditor'
import SingleSelectTrigger from 'components/SingleSelectTrigger'
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

  onRichTextChange (html, key) {
    this.props.updateFormAtomValue(key, html)
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
          onChange={(html) => this.onRichTextChange(html, key)}
          placeholder={meta.structure[key].label}
          invalid={Boolean(this.props.form.errors[key])}
          ref={autofocusRef()}
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
        <div className='row mb-4'>
          <div className='col-6'>
            <Input
              type='select'
              defaultValue={type}
              name={`${prefix}[type]`}
              onChange={this.onTypeChange}
              className='folio-console-atom-type-select'
            >
              {this.props.atomTypes.map(({ key, title }) => (
                <option key={key} value={key}>{title}</option>
              ))}
            </Input>
          </div>

          <div className='col-6 d-flex align-items-center justify-content-end'>
            <button
              type='button'
              className='btn btn-outline f-c-atoms-settings-header__button'
              onClick={this.props.saveFormAtom}
            >
              {window.FolioConsole.translations.done}
            </button>

            <button
              type='button'
              className='f-c-atoms-settings-header__close mi ml-g'
              onClick={this.props.closeFormAtom}
            >
              close
            </button>
          </div>
        </div>

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
          <FormGroup key={key} className={errors[key] ? 'form-group-invalid' : 'form-group-valid'}>
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

        {validating && <span className='folio-loader' />}
      </AtomFormWrap>
    )
  }
}

export default AtomForm
