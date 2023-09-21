import React from 'react'

import FolioUiIcon from 'components/FolioUiIcon'

class DueDate extends React.Component {
  constructor (props) {
    super(props)
    this.inputRef = React.createRef()
  }

  componentDidMount () {
    if (window.folioConsoleInitDatePicker) {
      window.folioConsoleInitDatePicker(this.inputRef.current, {
        widgetPositioning: {
          horizontal: 'right',
          vertical: 'bottom'
        }
      })

      window.jQuery(this.inputRef.current).on('folioCustomChange.DueDate', this.onChange)
    }
  }

  componentWillUnmount () {
    if (window.folioConsoleUnbindDatePicker) {
      window.folioConsoleUnbindDatePicker(this.inputRef.current)

      window.jQuery(this.inputRef.current).off('folioCustomChange.DueDate', this.onChange)
    }
  }

  defaultValue () {
    if (this.props.dueAt) {
      return this.props.dueAt.toISOString()
    }
  }

  onChange = (e) => {
    const strOrNull = this.inputRef.current.dataset.date
    let dueAt = null

    if (strOrNull && strOrNull !== 'null') {
      dueAt = new Date(Date.parse(strOrNull))
    }

    this.props.onChange(dueAt)
  }

  render () {
    return (
      <div className={`${this.props.className} f-c-r-notes-fields-app-table-due-date`}>
        <div className='f-c-r-notes-fields-app-table-due-date__button'>
          <FolioUiIcon name='calendar_range' height={18} />

          <input
            type='text'
            ref={this.inputRef}
            defaultValue={''}
            data-date={this.defaultValue()}
            className='f-c-r-notes-fields-app-table-due-date__input form-control'
          />
        </div>

        {(this.props.dueAt && window.strftime) ? (
          <div className='f-c-r-notes-fields-app-table-due-date__date small ms-2'>
            {window.strftime('%d. %m.', this.props.dueAt)}
          </div>
        ) : null}
      </div>
    )
  }
}

export default DueDate
