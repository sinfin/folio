import React, { useState } from 'react'
import { FormGroup, Label, Badge } from 'reactstrap'
import TextareaAutosize from 'react-autosize-textarea'

import AutocompleteInput from 'components/AutocompleteInput'
import FolioConsoleUiButton from 'components/FolioConsoleUiButton'
import TagsInput from 'components/TagsInput'

import { fileFieldAutocompleteUrl } from 'constants/urls'

export default ({ formState, onValueChange, extractMetadata, readOnly, isExtracting }) => {
  const [showAdvanced, setShowAdvanced] = useState(false)

  // IPTC Core fields
  const coreFields = [
    { key: 'headline', type: 'input', label: 'Headline' },
    { key: 'creator', type: 'tags', label: 'Creator(s)' },
    { key: 'caption_writer', type: 'input', label: 'Caption Writer' },
    { key: 'credit_line', type: 'input', label: 'Credit Line' },
    { key: 'source', type: 'input', label: 'Source' },
    { key: 'copyright_notice', type: 'textarea', label: 'Copyright Notice' },
    { key: 'usage_terms', type: 'textarea', label: 'Usage Terms' },
    { key: 'rights_usage_info', type: 'input', label: 'Rights Usage Info (URL)' },
    { key: 'keywords', type: 'tags', label: 'Keywords' }
  ]

  // Advanced IPTC fields (show on demand)
  const advancedFields = [
    { key: 'intellectual_genre', type: 'input', label: 'Intellectual Genre' },
    { key: 'subject_codes', type: 'tags', label: 'Subject Codes' },
    { key: 'scene_codes', type: 'tags', label: 'Scene Codes' },
    { key: 'event', type: 'input', label: 'Event' },
    { key: 'persons_shown', type: 'tags', label: 'Persons Shown' },
    { key: 'organizations_shown', type: 'tags', label: 'Organizations Shown' },
    { key: 'sublocation', type: 'input', label: 'Sublocation' },
    { key: 'city', type: 'input', label: 'City' },
    { key: 'state_province', type: 'input', label: 'State/Province' },
    { key: 'country', type: 'input', label: 'Country' },
    { key: 'country_code', type: 'input', label: 'Country Code (2 chars)' }
  ]

  const technicalFields = [
    { key: 'camera_make', type: 'readonly', label: 'Camera Make' },
    { key: 'camera_model', type: 'readonly', label: 'Camera Model' },
    { key: 'lens_info', type: 'readonly', label: 'Lens Info' },
    { key: 'capture_date', type: 'readonly', label: 'Capture Date' },
    { key: 'gps_latitude', type: 'readonly', label: 'GPS Latitude' },
    { key: 'gps_longitude', type: 'readonly', label: 'GPS Longitude' }
  ]

  const hasExtractedMetadata = formState.file_metadata_extracted_at
  const hasAnyMetadata = coreFields.some(field => formState[field.key]) || 
                        advancedFields.some(field => formState[field.key]) ||
                        technicalFields.some(field => formState[field.key])

  const renderField = (field) => {
    const value = formState[field.key] || (field.type === 'tags' ? [] : '')
    
    switch (field.type) {
      case 'tags':
        return (
          <TagsInput
            value={Array.isArray(value) ? value : (value ? [value] : [])}
            onTagsChange={(tags) => onValueChange(field.key, tags)}
            disabled={readOnly}
            noAutofocus
          />
        )
      case 'textarea':
        return (
          <TextareaAutosize
            name={field.key}
            value={value}
            onChange={(e) => onValueChange(field.key, e.currentTarget.value)}
            className='form-control'
            rows={2}
            maxRows={5}
            disabled={readOnly}
            async
          />
        )
      case 'readonly':
        return (
          <p className='form-control-plaintext'>{value || <span className='text-muted'>Not available</span>}</p>
        )
      default:
        return (
          <AutocompleteInput
            value={value}
            onChange={(e) => onValueChange(field.key, e.currentTarget.value)}
            name={field.key}
            url={fileFieldAutocompleteUrl(field.key)}
            disabled={readOnly}
          />
        )
    }
  }

  return (
    <div className='metadata-extraction-section mt-4'>
      <div className='d-flex align-items-center justify-content-between mb-3'>
        <h5 className='mb-0'>
          IPTC Metadata
          {hasExtractedMetadata && (
            <Badge color='success' className='ml-2 small'>
              Auto-extracted {new Date(hasExtractedMetadata).toLocaleDateString()}
            </Badge>
          )}
        </h5>
        
        {!readOnly && (
          <FolioConsoleUiButton
            onClick={extractMetadata}
            disabled={isExtracting}
            variant='secondary'
            size='sm'
            icon='reload'
            label={isExtracting ? 'Extracting...' : 'Extract Metadata'}
          />
        )}
      </div>

      {!hasAnyMetadata && !readOnly && (
        <div className='alert alert-info'>
          <strong>No metadata found.</strong> Click "Extract Metadata" to automatically extract IPTC/EXIF data from this image.
        </div>
      )}

      {/* Core IPTC Fields */}
      <div className='row'>
        {coreFields.map((field) => (
          <div key={field.key} className='col-lg-6 mb-3'>
            <FormGroup>
              <Label className='form-label'>
                {window.FolioConsole.translations[`metadata/${field.key}`] || field.label}
              </Label>
              {readOnly && !formState[field.key] ? (
                <p className='m-0 text-muted'>{window.FolioConsole.translations.blank}</p>
              ) : (
                renderField(field)
              )}
            </FormGroup>
          </div>
        ))}
      </div>

      {/* Advanced Fields Toggle */}
      <div className='mb-3'>
        <FolioConsoleUiButton
          onClick={() => setShowAdvanced(!showAdvanced)}
          variant='link'
          size='sm'
          icon={showAdvanced ? 'arrow_up' : 'arrow_down'}
          label={showAdvanced ? 'Hide Advanced Fields' : 'Show Advanced Fields'}
        />
      </div>

      {showAdvanced && (
        <>
          <h6 className='mb-3'>Advanced IPTC Fields</h6>
          <div className='row'>
            {advancedFields.map((field) => (
              <div key={field.key} className='col-lg-6 mb-3'>
                <FormGroup>
                  <Label className='form-label'>
                    {window.FolioConsole.translations[`metadata/${field.key}`] || field.label}
                  </Label>
                  {readOnly && !formState[field.key] ? (
                    <p className='m-0 text-muted'>{window.FolioConsole.translations.blank}</p>
                  ) : (
                    renderField(field)
                  )}
                </FormGroup>
              </div>
            ))}
          </div>

          <h6 className='mb-3 mt-4'>Technical Metadata (Read-only)</h6>
          <div className='row'>
            {technicalFields.map((field) => (
              <div key={field.key} className='col-lg-6 mb-3'>
                <FormGroup>
                  <Label className='form-label'>
                    {window.FolioConsole.translations[`metadata/${field.key}`] || field.label}
                  </Label>
                  {renderField(field)}
                </FormGroup>
              </div>
            ))}
          </div>
        </>
      )}

      {hasExtractedMetadata && (
        <div className='mt-3'>
          <small className='text-muted'>
            Metadata automatically extracted on {new Date(hasExtractedMetadata).toLocaleString()}.
            Only blank fields are populated during extraction to preserve manual edits.
          </small>
        </div>
      )}
    </div>
  )
}
