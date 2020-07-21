import React from 'react'
import { connect } from 'react-redux'
import { FormGroup, Input } from 'reactstrap';
import TextareaAutosize from 'react-autosize-textarea'

import {
  setUploadAttributes,
  makeUploadsSelector,
  closeTagger
} from 'ducks/uploads'

import TagsInput from 'components/TagsInput'

class UploadTagger extends React.PureComponent {
  state = {
    tags: [],
    author: null,
    description: null,
  }

  constructor (props) {
    super(props)
    this.state = props.uploads.uploadAttributes
  }

  onTagsChange = (tags) => {
    this.setState({ ...this.state, tags })
  }

  onAuthorChange = (e) => {
    this.setState({ ...this.state, author: e.currentTarget.value })
  }

  onInputChange = (e) => {
    this.setState({ ...this.state, [e.currentTarget.name]: e.currentTarget.value })
  }

  setUploadAttributes = () => {
    this.props.dispatch(setUploadAttributes(this.props.fileType, this.state))
  }

  close = () => {
    this.props.dispatch(closeTagger(this.props.fileType))
  }

  render () {
    if (!this.props.uploads.showTagger) return null

    return (
      <div className='alert alert-primary mb-3 p-3'>
        <p>{window.FolioConsole.translations.newFilesAttributes}</p>
        <div className="row">
          <FormGroup className="col-md-6 pr-md-2">
            <Input
              value={this.state.author || ''}
              name='author'
              onChange={this.onInputChange}
              placeholder={window.FolioConsole.translations.fileAuthor}
              autoFocus
            />
          </FormGroup>

          <FormGroup className="col-md-6 pl-md-2">
            <TagsInput
              value={this.state.tags}
              onTagsChange={this.onTagsChange}
              closeMenuOnSelect={false}
              placeholder={window.FolioConsole.translations.tagsLabel}
              noAutofocus
            />
          </FormGroup>
        </div>

        <FormGroup>
          <TextareaAutosize
            value={this.state.description || ''}
            name='description'
            onChange={this.onInputChange}
            className='form-control'
            rows={2}
            placeholder={window.FolioConsole.translations.fileDescription}
            async
          />
        </FormGroup>

        <div className="d-flex">
          <button
            className='btn btn-success mr-2'
            type='button'
            onClick={this.setUploadAttributes}
          >
            {window.FolioConsole.translations.save}
          </button>

          <button
            className='btn btn-secondary'
            type='button'
            onClick={this.close}
          >
            {window.FolioConsole.translations.close}
          </button>
        </div>
      </div>
    )
  }
}

const mapStateToProps = (state, props) => ({
  uploads: makeUploadsSelector(props.fileType)(state)
})

function mapDispatchToProps (dispatch) {
  return { dispatch }
}

export default connect(mapStateToProps, mapDispatchToProps)(UploadTagger)
