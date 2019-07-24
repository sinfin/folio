import React from 'react'
import { FormGroup, Label, Input } from 'reactstrap'
import { debounce } from 'lodash'

class AtomForm extends React.PureComponent {
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

  render () {
    const { data, meta } = this.props.atom
    const prefix = `${this.props.namespace}[${this.props.index + 1}]`

    return (
      <div className='mb-3 border'>
        {Object.keys(meta.structure).map((key) => (
          <FormGroup key={key}>
            <Label>{key}</Label>
            <Input
              type='text'
              name={`${prefix}[${key}]`}
              defaultValue={data[key]}
              onChange={(e) => this.onChangeRaw(e, key)}
            />
          </FormGroup>
        ))}
      </div>
    )
  }
}

export default AtomForm
