import React from 'react'
import { connect } from 'react-redux'
import { FormGroup } from 'reactstrap'
import TextareaAutosize from 'react-autosize-textarea'

import {
  setUploadAttributes,
  makeUploadsSelector,
  closeTagger
} from 'ducks/uploads'

import AutocompleteInput from 'components/AutocompleteInput'
import TagsInput from 'components/TagsInput'
import FolioConsoleUiButtons from 'components/FolioConsoleUiButtons'
import FolioConsoleUiButton from 'components/FolioConsoleUiButton'

import { AUTHOR_AUTOCOMPLETE_URL } from 'constants/urls'

import Wrap from './styled/Wrap'

const DEFAULT_STATE = {
  tags: [],
  author: null,
  description: null
}

class UploadTagger extends React.PureComponent {
  state = { ...DEFAULT_STATE }

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
    this.setState({ ...DEFAULT_STATE })
  }

  close = () => {
    this.props.dispatch(closeTagger(this.props.fileType))
    this.setState({ ...DEFAULT_STATE })
  }

  render () {
    if (!this.props.uploads.showTagger) return null

    return (
      <Wrap className='my-g p-g'>
        <p>{window.FolioConsole.translations.newFilesAttributes}</p>
        <div className='row'>
          <FormGroup className={this.props.taggable ? 'col-md-6 pe-md-2' : 'col-12'}>
            <AutocompleteInput
              value={this.state.author}
              name='author'
              onChange={this.onInputChange}
              placeholder={window.FolioConsole.translations.fileAuthor}
              url={AUTHOR_AUTOCOMPLETE_URL}
              autoFocus
            />
          </FormGroup>

          {this.props.taggable && (
            <FormGroup className='col-md-6 ps-md-2'>
              <TagsInput
                value={this.state.tags}
                onTagsChange={this.onTagsChange}
                closeMenuOnSelect={false}
                placeholder={window.FolioConsole.translations.tagsLabel}
                noAutofocus
              />
            </FormGroup>
          )}
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

        <FolioConsoleUiButtons>
          <FolioConsoleUiButton
            onClick={this.setUploadAttributes}
            variant='success'
            label={window.FolioConsole.translations.save}
          />

          <FolioConsoleUiButton
            onClick={this.close}
            vairant='secondary'
            label={window.FolioConsole.translations.close}
          />
        </FolioConsoleUiButtons>
      </Wrap>
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
