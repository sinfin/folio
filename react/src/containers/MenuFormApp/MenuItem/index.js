import React from 'react'
import { Input, Label } from 'reactstrap'
import { makeConfirmed } from 'utils/confirmed'

import MenuItemWrap from './styled/MenuItemWrap'

const makeOnChange = (path, node, onChange) => (e) => {
  const newNode = {
    ...node
  }

  if (e.target.value.indexOf(' -=- ') === -1) {
    newNode.rails_path = e.target.value
    newNode.target_id = null
    newNode.target_type = null
  } else {
    const [type, id] = e.target.value.split(' -=- ')
    newNode.target_id = id
    newNode.target_type = type
    newNode.rails_path = null
  }

  onChange(path, newNode)
}

function MenuItem ({ node, path, onChange, options, remove }) {
  let linkValue = node.rails_path
  if (!linkValue && node.target_type && node.target_id) {
    linkValue = `${node.target_type} -=- ${node.target_id}`
  }

  return (
    <MenuItemWrap className='form-inline'>
      <Label className='mr-h'>{window.FolioConsole.translations.title}:</Label>

      <Input
        className='mr-g'
        value={node.title || ''}
        onChange={(e) => onChange(path, { ...node, title: e.target.value })}
        autoFocus={node.id === null}
      />

      <Label className='mr-h'>{window.FolioConsole.translations.link}:</Label>

      <Input
        className='mr-g'
        type='select'
        value={linkValue || ''}
        onChange={makeOnChange(path, node, onChange)}
      >
        <option value=''>{window.FolioConsole.translations.menuNoLink}</option>
        {options}
      </Input>

      <button
        className='btn btn-danger fa fa-times'
        type='button'
        onClick={makeConfirmed(() => remove(path, node))}
      />
    </MenuItemWrap>
  )
}

export default MenuItem
