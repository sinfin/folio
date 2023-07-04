import React from 'react'

import FolioUiIcon from 'components/FolioUiIcon'

function FolioConsoleUiButtonContents (props) {
  return (
    <React.Fragment>
      {props.icon && (
        <FolioUiIcon name={props.icon} class='f-c-ui-button__icon' />
      )}

      {props.label && (
        <span class='f-c-ui-button__label'>{props.label}</span>
      )}

      {props.rightIcon && (
        <FolioUiIcon name={props.rightIcon} class='f-c-ui-button__right-icon' />
      )}
    </React.Fragment>
  )
}

export default function FolioConsoleUiButton (props) {
  let className = `f-c-ui-button btn btn-${props.variant || 'primary'}`
  if (props.class) className += ` ${props.class}`

  if (props.href) {
    return (
      <a className={className} href={props.href} onClick={props.onClick}>
        <FolioConsoleUiButtonContents
          icon={props.icon}
          label={props.label}
          rightIcon={props.rightIcon}
        />
      </a>
    )
  } else {
    return (
      <button className={className} type={props.type || 'button'} onClick={props.onClick}>
        <FolioConsoleUiButtonContents
          icon={props.icon}
          label={props.label}
          rightIcon={props.rightIcon}
        />
      </button>
    )
  }
}
