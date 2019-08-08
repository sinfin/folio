import React from 'react'
import { Input } from 'reactstrap'
import TextareaAutosize from 'react-autosize-textarea'

import RichTextEditor from 'components/RichTextEditor'
import ColorInput from 'components/ColorInput'
import DateInput from 'components/DateInput'

import preventEnterSubmit from 'utils/preventEnterSubmit'

function inputProps (type) {
  switch (type) {
    case 'float':
      return { type: 'number', step: '0.01' }

    case 'integer':
      return { type: 'number', step: '1' }

    default:
      return { type: 'text' }
  }
}

export default function AtomInput ({ field, form, onChange, onValueChange }) {
  const { structure } = form.atom.meta
  const key = field

  if (structure[key].type === 'richtext') {
    return (
      <RichTextEditor
        name={key}
        defaultValue={form.atom.data[key]}
        onChange={(html) => onValueChange(html, key)}
        invalid={Boolean(form.errors[key])}
      />
    )
  }

  if (structure[key].type === 'color') {
    return (
      <ColorInput
        name={key}
        defaultValue={form.atom.data[key]}
        onChange={(colorString) => onValueChange(colorString, key)}
        invalid={Boolean(form.errors[key])}
        type={structure[key].type}
      />
    )
  }

  if (structure[key].type === 'date' || structure[key].type === 'datetime') {
    return (
      <DateInput
        name={key}
        defaultValue={form.atom.data[key]}
        onChange={(e) => onChange(e, key)}
        invalid={Boolean(form.errors[key])}
        type={structure[key].type}
      />
    )
  }

  if (structure[key].type === 'text' || structure[key].type === 'code') {
    const classNames = ['form-control']

    if (form.errors[key]) {
      classNames.push('is-invalid')
    }

    return (
      <TextareaAutosize
        name={key}
        defaultValue={form.atom.data[key]}
        onChange={(e) => onValueChange(e.currentTarget.value, key)}
        type={structure[key].type}
        className={classNames.join(' ')}
        rows={2}
      />
    )
  }

  return (
    <Input
      {...inputProps(structure[key].type)}
      name={key}
      defaultValue={form.atom.data[key]}
      onChange={(e) => onChange(e, key)}
      onKeyPress={preventEnterSubmit}
      invalid={Boolean(form.errors[key])}
    />
  )
}
