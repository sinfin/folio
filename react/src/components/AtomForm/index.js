import React from 'react'
import { FormGroup, Input } from 'reactstrap'
import { debounce } from 'lodash'

import RichTextEditor from 'components/RichTextEditor'

class AtomForm extends React.Component {
  constructor (props) {
    super(props)
    this.debouncedOnChange = debounce(this.onChange, 1000)
  }

  onChangeRaw (e, key) {
    e.persist()
    this.debouncedOnChange(e, key, 1000)
  }

  onChange (e, key) {
    this.props.onChange({
      rootKey: this.props.rootKey,
      index: this.props.index,
      key: key,
      value: e.target.value
    })
  }

  onTypeChange = (e) => {
    this.props.onTypeChange({
      rootKey: this.props.rootKey,
      index: this.props.index,
      newType: e.target.value
    })
  }

  shouldComponentUpdate (nextProps) {
    return Boolean(nextProps.atom.destroyed) || (nextProps.index !== this.props.index) || (nextProps.atom.type !== this.props.atom.type)
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
    const { data, destroyed, id, meta, type } = this.props.atom
    const prefix = `${this.props.namespace}[${this.props.index + 1}]`

    return (
      <div className='card' hidden={destroyed}>
        <div className='card-body mb-n3'>
          {id && <Input type='hidden' name={`${prefix}[id]`} value={id} />}
          {destroyed && <Input type='hidden' name={`${prefix}[_destroy]`} value='1' />}
          <Input type='hidden' name={`${prefix}[position]`} value={this.props.index + 1} />

          {!destroyed && <React.Fragment>
            <FormGroup>
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
            </FormGroup>

            {Object.keys(meta.structure).map((key) => (
              <FormGroup key={key}>
                {/* <Label>{meta.structure[key].label}</Label> */}
                {
                  meta.structure[key].type === 'richtext' ? (
                    <RichTextEditor
                      name={`${prefix}[${key}]`}
                      defaultValue={data[key]}
                      onChange={(e) => this.onChangeRaw(e, key)}
                      placeholder={meta.structure[key].label}
                    />
                  ) : (
                    <Input
                      type={this.inputType(meta.structure[key].type)}
                      name={`${prefix}[${key}]`}
                      defaultValue={data[key]}
                      onChange={(e) => this.onChangeRaw(e, key)}
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
          </React.Fragment>}
        </div>
      </div>
    )
  }
}

export default AtomForm
