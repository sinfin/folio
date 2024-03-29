import React from 'react'

import FolioUiIcon from 'components/FolioUiIcon'

function FolioConsoleUiButtonContents (props) {
  return (
    <React.Fragment>
      {props.icon && (
        <FolioUiIcon name={props.icon} class='f-c-ui-button__icon' height={props.iconHeight} />
      )}

      {props.label && (
        <span className='f-c-ui-button__label'>{props.label}</span>
      )}

      {props.rightIcon && (
        <FolioUiIcon name={props.rightIcon} class='f-c-ui-button__right-icon' height={props.iconHeight} />
      )}
    </React.Fragment>
  )
}

export default function FolioConsoleUiButton (props) {
  let className = `f-c-ui-button btn btn-${props.variant || 'primary'}`
  if (props.class) className += ` ${props.class}`
  if (props.size) className += ` btn-${props.size}`

  if (props.href) {
    return (
      <a
        title={props.title}
        className={className}
        href={props.href}
        onClick={props.onClick}
        target={props.target}
        download={props.download}
        rel={props.rel}
        data-action={props.dataAction}
      >
        <FolioConsoleUiButtonContents
          icon={props.icon}
          label={props.label}
          rightIcon={props.rightIcon}
          iconHeight={props.iconHeight}
        />
      </a>
    )
  } else if (props.tag === 'span') {
    return (
      <span
        title={props.title}
        className={className}
        onClick={props.onClick}
        disabled={props.disabled}
        data-action={props.dataAction}
      >
        <FolioConsoleUiButtonContents
          icon={props.icon}
          label={props.label}
          rightIcon={props.rightIcon}
          iconHeight={props.iconHeight}
        />
        {props.children ? <span className='f-c-ui-button__label'>{props.children}</span> : null}
      </span>
    )
  } else {
    return (
      <button
        title={props.title}
        className={className}
        type={props.type || 'button'}
        onClick={props.onClick}
        disabled={props.disabled}
        data-action={props.dataAction}
      >
        <FolioConsoleUiButtonContents
          icon={props.icon}
          label={props.label}
          rightIcon={props.rightIcon}
          iconHeight={props.iconHeight}
        />
        {props.children ? <span className='f-c-ui-button__label'>{props.children}</span> : null}
      </button>
    )
  }
}
