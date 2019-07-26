import React from 'react'
import { FormGroup, Input, Label } from 'reactstrap'
import { isEqual } from 'lodash'

import RichTextEditor from 'components/RichTextEditor'

class AtomForm extends React.PureComponent {
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

  render () {
    const { data, meta, type } = this.props.atom
    const prefix = `${this.props.namespace}[${this.props.index + 1}]`

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
              Hotovo
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

        {Object.keys(meta.structure).map((key) => (
          <FormGroup key={key}>
            {<Label>{meta.structure[key].label}</Label>}
            {
              meta.structure[key].type === 'richtext' ? (
                <RichTextEditor
                  name={`${prefix}[${key}]`}
                  defaultValue={data[key]}
                  onChange={this.onChange}
                  placeholder={meta.structure[key].label}
                />
              ) : (
                <Input
                  type={this.inputType(meta.structure[key].type)}
                  name={`${prefix}[${key}]`}
                  defaultValue={data[key]}
                  onChange={(e) => this.onChange(e, key)}
                  placeholder={meta.structure[key].label}
                >
                  {(meta.structure[key].collection || []).map((record) => (
                    <option key={record[1]} value={record[1]}>{record[0]}</option>
                  ))}
                </Input>
              )
            }
          </FormGroup>
        ))}
      </React.Fragment>
    )
  }
}

export default AtomForm
