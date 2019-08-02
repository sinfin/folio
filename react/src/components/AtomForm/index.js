import React from 'react'
import { FormGroup, Input, Label } from 'reactstrap'
import { isEqual } from 'lodash'

import MultiSelect from 'containers/MultiSelect'
import RichTextEditor from 'components/RichTextEditor'
import SingleSelectTrigger from 'components/SingleSelectTrigger'

import fileTypeToKey from 'utils/fileTypeToKey'

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

  inputType (type) {
    switch (type) {
      case 'text':
        return 'textarea'

      case 'relation':
        return 'select'

      default:
        return 'text'
    }
  }

  componentDidMount () {
    if (this.autofocusRef.current) {
      setTimeout(() => { this.autofocusRef.current.focus() }, 0)
    }
  }

  render () {
    const { data, meta, type } = this.props.atom
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
      <React.Fragment>
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
          <FormGroup key={key}>
            {<Label>{meta.structure[key].label}</Label>}
            {
              meta.structure[key].type === 'richtext' ? (
                <RichTextEditor
                  name={key}
                  defaultValue={data[key]}
                  onChange={(html) => this.onRichTextChange(html, key)}
                  placeholder={meta.structure[key].label}
                  ref={autofocusRef()}
                />
              ) : (
                meta.structure[key].collection ? (
                  <Input
                    type={this.inputType(meta.structure[key].type)}
                    name={key}
                    defaultValue={data[key]}
                    onChange={(e) => this.onChange(e, key)}
                    placeholder={meta.structure[key].label}
                  >
                    {meta.structure[key].collection.map((record) => (
                      <option key={record[1]} value={record[1]}>{record[0]}</option>
                    ))}
                  </Input>
                ) : (
                  <Input
                    type={this.inputType(meta.structure[key].type)}
                    name={key}
                    defaultValue={data[key]}
                    onChange={(e) => this.onChange(e, key)}
                    placeholder={meta.structure[key].label}
                    innerRef={autofocusRef()}
                  />
                )
              )
            }
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
      </React.Fragment>
    )
  }
}

export default AtomForm
