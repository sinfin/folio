import React from 'react'
import { Input } from 'reactstrap'
import TextareaAutosize from 'react-autosize-textarea'

import RichTextEditor from 'components/RichTextEditor'
import ColorInput from 'components/ColorInput'
import DateInput from 'components/DateInput'

import preventEnterSubmit from 'utils/preventEnterSubmit'

function inputProps (type, defaultValue) {
  switch (type) {
    case 'float':
      return { type: 'number', step: '0.01' }

    case 'integer':
      return { type: 'number', step: '1' }

    case 'boolean':
      return { type: 'checkbox', defaultChecked: defaultValue }

    case 'collection':
      return { type: 'select' }

    default:
      return { type: 'text' }
  }
}

export default function AtomInput ({ field, atom, index, onChange, onValueChange }) {
  const { structure } = atom.record.meta
  const key = field
  const type = structure[key].type
  const defaultValue = atom.record.data[key]

  React.useEffect(() => {
    if (type === 'collection') {
      const { collection } = structure[key]
      if (collection && !defaultValue && defaultValue !== collection[0]) {
        onValueChange(index, collection[0], key)
      }
    }
  }, [type, onValueChange, defaultValue, key, structure, index])

  if (type === 'richtext') {
    return (
      <RichTextEditor
        name={key}
        defaultValue={defaultValue}
        onChange={(html) => onValueChange(index, html, key)}
        invalid={Boolean(atom.errors[key])}
      />
    )
  }

  if (type === 'color') {
    return (
      <ColorInput
        name={key}
        defaultValue={defaultValue}
        onChange={(colorString) => onValueChange(index, colorString, key)}
        invalid={Boolean(atom.errors[key])}
        type={type}
      />
    )
  }

  if (type === 'date' || type === 'datetime') {
    return (
      <DateInput
        name={key}
        defaultValue={defaultValue}
        onChange={(date) => onValueChange(index, date, key)}
        invalid={Boolean(atom.errors[key])}
        type={type}
      />
    )
  }

  if (type === 'collection') {
    return (
      <Input
        {...inputProps(type, atom.record.data[key])}
        name={key}
        defaultValue={defaultValue}
        onChange={(e) => onChange(e, index, key)}
        onKeyPress={preventEnterSubmit}
        invalid={Boolean(atom.errors[key])}
      >
        {structure[key].collection.map((value) => (
          <option key={value} value={value}>{value}</option>
        ))}
      </Input>
    )
  }

  if (type === 'text' || type === 'code') {
    const classNames = ['form-control']

    if (atom.errors[key]) {
      classNames.push('is-invalid')
    }

    return (
      <TextareaAutosize
        name={key}
        defaultValue={defaultValue}
        onChange={(e) => onValueChange(index, e.currentTarget.value, key)}
        type={type}
        className={classNames.join(' ')}
        rows={2}
        async
      />
    )
  }

  return (
    <Input
      {...inputProps(type, atom.record.data[key])}
      name={key}
      defaultValue={defaultValue}
      onChange={(e) => onChange(e, index, key)}
      onKeyPress={preventEnterSubmit}
      invalid={Boolean(atom.errors[key])}
    />
  )
}
