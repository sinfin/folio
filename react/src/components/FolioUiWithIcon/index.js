import React from 'react'

import FolioUiIcon from 'components/FolioUiIcon'

export default function FolioUiWithIcon (props) {
  return (
    <div
      className={`f-c-ui-with-icon ${props.class}`}
      onClick={props.onClick}
    >
      <FolioUiIcon name={props.icon} height={props.iconHeight} />
      {props.children}
    </div>
  )
}
