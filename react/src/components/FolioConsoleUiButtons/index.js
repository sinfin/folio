import React from 'react'

export default function FolioConsoleUiButtons (props) {
  return <div className={`f-c-ui-buttons ${props.className || ''} ${props.nowrap ? 'f-c-ui-buttons--nowrap' : ''}`}>{props.children}</div>
}
