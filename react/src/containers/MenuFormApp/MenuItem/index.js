import React from 'react'
import { Input, Label } from 'reactstrap'

import MenuItemWrap from './styled/MenuItemWrap'

function MenuItem ({ node, path, onChange, options }) {
  return (
    <MenuItemWrap className='form-inline'>
      <Label className='mr-h'>{window.FolioConsole.translations.link}:</Label>

      <Input
        type='select'
        value={node.rails_path || ''}
        onChange={(e) => onChange(path, { ...node, rails_path: e.target.value })}
        className='mr-g'
      >
        <option value='' />
        {options}
      </Input>

      <Label className='mr-h'>{window.FolioConsole.translations.title}:</Label>
      <Input
        value={node.title || ''}
        onChange={(e) => onChange(path, { ...node, title: e.target.value })}
      />
    </MenuItemWrap>
  )
}

export default MenuItem
