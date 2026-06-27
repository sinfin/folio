import React from 'react'
import renderer from 'react-test-renderer'

import 'folioTestSetup'

import FileUploadProgress from '../'

describe('FileUploadProgress', () => {
  it('renders upload state modifier and text', () => {
    const component = renderer.create(
      <FileUploadProgress
        progress={100}
        progressText='Selhalo'
        uploadState='failed'
      />
    )

    const tree = component.toJSON()

    expect(tree.props.className).toEqual('f-c-r-file-upload-progress f-c-r-file-upload-progress--failed')
    expect(tree.children[1].children).toEqual(['Selhalo'])
  })

  it('does not render without progress', () => {
    const component = renderer.create(<FileUploadProgress />)

    expect(component.toJSON()).toEqual(null)
  })
})
