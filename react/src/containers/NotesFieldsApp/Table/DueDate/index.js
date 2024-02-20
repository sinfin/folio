import React from 'react'

import FolioUiIcon from 'components/FolioUiIcon'

class DueDate extends React.Component {
  constructor (props) {
    super(props)
    this.inputRef = React.createRef()
  }

  componentDidMount () {
    if (this.unbindInput) this.unbindInput()

    this.inputRef.current.addEventListener('change', this.onChange)

    this.unbindInput = () => {
      this.inputRef.current.removeEventListener('change', this.onChange)
      delete this.unbindInput
    }
  }

  componentWillUnmount () {
    if (this.unbindInput) this.unbindInput()
  }

  defaultValue () {
    if (this.props.dueAt) {
      return this.props.dueAt.toISOString()
    }
  }

  onChange = (e) => {
    try {
      this.props.onChange(e.target.folioInputTempusDominus.dates.picked[0])
    } catch (_e) {
      this.props.onChange(null)
    }
  }

  render () {
    return (
      <div className={`${this.props.className} f-c-r-notes-fields-app-table-due-date`}>
        <div className='f-c-r-notes-fields-app-table-due-date__button'>
          <FolioUiIcon name='calendar_range' height={18} />

          <input
            type='text'
            ref={this.inputRef}
            defaultValue=''
            data-date={this.defaultValue()}
            className='f-c-r-notes-fields-app-table-due-date__input form-control f-input f-input--date-time'
            data-controller='f-input-date-time'
          />
        </div>

        {(this.props.dueAt && window.strftime)
          ? (
            <div className='f-c-r-notes-fields-app-table-due-date__date small ms-2 me-1'>
              {window.strftime('%d. %m.', this.props.dueAt)}
            </div>
          )
          : null}
      </div>
    )
  }
}

export default DueDate
