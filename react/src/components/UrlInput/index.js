import React from 'react'
import { Input } from 'reactstrap'

export default function UrlInput (props) {
  return (
    <Input
      name={props.key}
      defaultValue={props.defaultValue}
      onChange={props.onChange}
      onKeyPress={props.onKeyPress}
      invalid={props.invalid}
      data-controller='f-c-input-url'
    />
  )
}
