import React from 'react'
import { Input } from 'reactstrap'
import TextareaAutosize from 'react-autosize-textarea'

import RichTextEditor from 'components/RichTextEditor'
import DateInput from 'components/DateInput'
import UrlInput from 'components/UrlInput'

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

    case 'color':
      return { type: 'color' }

    default:
      return { type: 'text' }
  }
}

export default function AtomInput ({ field, atom, index, onChange, onValueChange, characterCounter }) {
  const { structure } = atom.record.meta
  const key = field
  const type = structure[key].type
  const defaultValue = atom.record.data[key]

  React.useEffect(() => {
    if (type === 'collection') {
      const { collection } = structure[key]
      if (collection && collection.indexOf(null) === -1 && !defaultValue) {
        onValueChange(index, collection[0][1], key)
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
        scrollTarget='.f-c-atom-form-toolbar-fix-parent'
      />
    )
  }

  if (type === 'url') {
    return (
      <UrlInput
        name={key}
        defaultValue={defaultValue}
        onValueChange={(url) => onValueChange(index, url, key)}
        onChange={(e) => onChange(e, index, key)}
        onKeyPress={preventEnterSubmit}
        invalid={Boolean(atom.errors[key])}
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
        {structure[key].collection.map((ary) => (
          <option key={ary[1] || ''} value={ary[1] || ''}>{ary[0]}</option>
        ))}
      </Input>
    )
  }

  if (type === 'text' || type === 'code') {
    const classNames = ['form-control']

    if (type === 'code') {
      classNames.push('text-monospace')
    }

    if (atom.errors[key]) {
      classNames.push('is-invalid')
    }

    if (characterCounter) {
      classNames.push('text')
      classNames.push('f-input')
      classNames.push('f-input--character-counter')
    }

    return (
      <TextareaAutosize
        name={key}
        defaultValue={defaultValue}
        onChange={(e) => onValueChange(index, e.currentTarget.value, key)}
        type={type}
        className={classNames.join(' ')}
        rows={2}
        data-controller={characterCounter ? 'f-input-character-counter' : undefined}
        data-action={characterCounter ? 'f-input-character-counter#onInput' : undefined}
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
