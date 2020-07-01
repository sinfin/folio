import React from 'react'
import { FormText } from 'reactstrap'

export default function EmptyFormText ({ hasErrors, structure }) {
  if (hasErrors) return null
  if (structure.hint) return null
  if (!structure.character_counter && structure.type !== 'richtext') return null

  return <FormText>&nbsp;</FormText>
}
