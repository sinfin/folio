import React, { useState } from 'react'
import { FormGroup, Label, Badge } from 'reactstrap'
import TextareaAutosize from 'react-autosize-textarea'

import AutocompleteInput from 'components/AutocompleteInput'
import FolioConsoleUiButton from 'components/FolioConsoleUiButton'
import TagsInput from 'components/TagsInput'

import { fileFieldAutocompleteUrl } from 'constants/urls'

export default ({ formState, onValueChange, extractMetadata, readOnly, isExtracting }) => {
  const [showAdvanced, setShowAdvanced] = useState(false)
  const [showTechnical, setShowTechnical] = useState(false)

  // Essential metadata fields (for all files)
  const essentialFields = [
    { key: 'headline', type: 'input', label: 'Title/Headline', group: 'basic', priority: 'high' },
    { key: 'description', type: 'textarea', label: 'Description', group: 'basic', priority: 'high' },
    { key: 'keywords', type: 'tags', label: 'Keywords', group: 'basic', priority: 'high' }
  ]

  // Rights and attribution (universal)
  const rightsFields = [
    { key: 'creator', type: 'tags', label: 'Creator(s)', group: 'rights', priority: 'medium' },
    { key: 'copyright_notice', type: 'textarea', label: 'Copyright Notice', group: 'rights', priority: 'medium' },
    { key: 'credit_line', type: 'input', label: 'Credit Line', group: 'rights', priority: 'medium' },
    { key: 'source', type: 'input', label: 'Source', group: 'rights', priority: 'low' },
    { key: 'rights_usage_terms', type: 'textarea', label: 'Usage Terms', group: 'rights', priority: 'low' }
  ]

  // Advanced descriptive fields 
  const descriptiveFields = [
    { key: 'caption_writer', type: 'input', label: 'Caption Writer', group: 'descriptive', priority: 'low' },
    { key: 'intellectual_genre', type: 'input', label: 'Genre', group: 'descriptive', priority: 'low' },
    { key: 'subject_codes', type: 'tags', label: 'Subject Codes', group: 'descriptive', priority: 'low' },
    { key: 'persons_shown', type: 'tags', label: 'Persons Shown', group: 'descriptive', priority: 'low' }
  ]

  // Location fields (for images)
  const locationFields = [
    { key: 'city', type: 'input', label: 'City', group: 'location', priority: 'medium' },
    { key: 'state_province', type: 'input', label: 'State/Province', group: 'location', priority: 'medium' },
    { key: 'country', type: 'input', label: 'Country', group: 'location', priority: 'medium' },
    { key: 'country_code', type: 'input', label: 'Country Code (2 chars)', group: 'location', priority: 'low' }
  ]

  // Technical metadata (images only, read-only)
  const technicalFields = [
    { key: 'capture_date', type: 'readonly', label: 'Capture Date', group: 'technical', priority: 'medium' },
    { key: 'gps_latitude', type: 'readonly', label: 'GPS Latitude', group: 'technical', priority: 'low' },
    { key: 'gps_longitude', type: 'readonly', label: 'GPS Longitude', group: 'technical', priority: 'low' },
    { key: 'gps_altitude', type: 'readonly', label: 'GPS Altitude', group: 'technical', priority: 'low' }
  ]

  const hasExtractedMetadata = formState.file_metadata_extracted_at
  const allFields = [...essentialFields, ...rightsFields, ...descriptiveFields, ...locationFields, ...technicalFields]
  const hasAnyMetadata = allFields.some(field => formState[field.key])
  
  // Helper to check if we have location/GPS data
  const hasLocationData = locationFields.some(field => formState[field.key]) || 
                         formState.gps_latitude || formState.gps_longitude

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
          <div className='form-control-static'>
            {value ? (
              <span className='text-dark'>{value}</span>
            ) : (
              <span className='text-muted font-italic'>Not available</span>
            )}
          </div>
        )
      default:
        return (
          <AutocompleteInput
            value={value}
            onChange={(e) => onValueChange(field.key, e.currentTarget.value)}
            name={field.key}
            url={fileFieldAutocompleteUrl(field.key)}
            disabled={readOnly}
            className='form-control'
          />
        )
    }
  }

  const renderFieldGroup = (fields, title, icon = null, collapsible = false) => {
    const groupHasData = fields.some(field => formState[field.key])
    
    return (
      <div className='metadata-field-group mb-4'>
        <div className='d-flex align-items-center mb-3'>
          {icon && <i className={`fas fa-${icon} mr-2 text-muted`}></i>}
          <h6 className='mb-0 text-secondary font-weight-bold'>{title}</h6>
          {groupHasData && <Badge color='light' className='ml-2 small'>has data</Badge>}
        </div>
        
        <div className='row'>
          {fields.map((field) => {
            const hasValue = formState[field.key] && (
              Array.isArray(formState[field.key]) ? formState[field.key].length > 0 : formState[field.key].toString().length > 0
            )
            
            return (
              <div key={field.key} className={field.priority === 'high' ? 'col-12 mb-3' : 'col-lg-6 mb-3'}>
                <FormGroup className='mb-0'>
                  <Label className={`form-label small ${hasValue ? 'font-weight-bold' : ''}`}>
                    {window.FolioConsole.translations[`metadata/${field.key}`] || field.label}
                    {field.priority === 'high' && <span className='text-danger ml-1'>*</span>}
                  </Label>
                  {readOnly && !hasValue ? (
                    <div className='text-muted font-italic small'>Not filled</div>
                  ) : (
                    renderField(field)
                  )}
                </FormGroup>
              </div>
            )
          })}
        </div>
      </div>
    )
  }

  return (
    <div className='metadata-extraction-section mt-4'>
      {/* Header with extraction controls */}
      <div className='d-flex align-items-center justify-content-between mb-4'>
        <div>
          <h5 className='mb-1'>Metadata</h5>
          {hasExtractedMetadata && (
            <small className='text-muted'>
              Auto-extracted {new Date(hasExtractedMetadata).toLocaleDateString()}
            </small>
          )}
        </div>
        
        {!readOnly && (
          <FolioConsoleUiButton
            onClick={extractMetadata}
            disabled={isExtracting}
            variant='primary'
            size='sm'
            icon='reload'
            label={isExtracting ? 'Extracting...' : 'Extract Metadata'}
          />
        )}
      </div>

      {!hasAnyMetadata && !readOnly && (
        <div className='alert alert-light border mb-4'>
          <i className='fas fa-info-circle text-info mr-2'></i>
          <strong>No metadata found.</strong> Click "Extract Metadata" to automatically extract IPTC/EXIF data from this file.
        </div>
      )}

      {/* Essential fields - always visible */}
      {renderFieldGroup(essentialFields, 'Essential Information', 'file-alt')}
      
      {/* Rights & Attribution - always visible */}  
      {renderFieldGroup(rightsFields, 'Rights & Attribution', 'copyright')}

      {/* Location fields - for images with location data */}
      {hasLocationData && renderFieldGroup(locationFields, 'Location', 'map-marker-alt')}

      {/* Advanced fields toggle */}
      <div className='mb-3 pb-3 border-bottom'>
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
          {/* Descriptive fields */}
          {renderFieldGroup(descriptiveFields, 'Descriptive', 'tags')}

          {/* Technical metadata toggle - only for images */}
          <div className='mb-3'>
            <FolioConsoleUiButton
              onClick={() => setShowTechnical(!showTechnical)}
              variant='link'
              size='sm'
              icon={showTechnical ? 'arrow_up' : 'arrow_down'}
              label={showTechnical ? 'Hide Technical Data' : 'Show Technical Data'}
            />
          </div>

          {showTechnical && renderFieldGroup(technicalFields, 'Technical Metadata (Read-only)', 'camera')}
        </>
      )}

      {/* Extraction info footer */}
      {hasExtractedMetadata && (
        <div className='mt-4 pt-3 border-top'>
          <small className='text-muted'>
            <i className='fas fa-robot mr-1'></i>
            Metadata automatically extracted on {new Date(hasExtractedMetadata).toLocaleString()}.
            Only blank fields are populated during extraction to preserve manual edits.
          </small>
        </div>
      )}
    </div>
  )
}
