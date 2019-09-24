import React from 'react'
import { Input, Label } from 'reactstrap'
import { makeConfirmed } from 'utils/confirmed'

import MenuItemWrap from './styled/MenuItemWrap'

function MenuItem ({ node, path, onChange, options, remove }) {
  return (
    <MenuItemWrap className='form-inline'>
      <Label className='mr-h'>{window.FolioConsole.translations.title}:</Label>

      <Input
        className='mr-g'
        value={node.title || ''}
        onChange={(e) => onChange(path, { ...node, title: e.target.value })}
      />

      <Label className='mr-h'>{window.FolioConsole.translations.link}:</Label>

      <Input
        className='mr-g'
        type='select'
        value={node.rails_path || ''}
        onChange={(e) => onChange(path, { ...node, rails_path: e.target.value })}
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
