import React from 'react'
import { Badge } from 'reactstrap'
import FolioConsoleUiButton from 'components/FolioConsoleUiButton'

export default ({ formState, onValueChange, extractMetadata, readOnly, isExtracting, compact }) => {
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

  const allFields = [...essentialFields, ...rightsFields, ...descriptiveFields, ...locationFields, ...technicalFields]

  const hasExtractedMetadata = formState.file_metadata_extracted_at
  const hasAnyMetadata = allFields.some(field => formState[field.key])

  const renderField = (field) => {
    const value = formState[field.key]
    
    switch (field.type) {
      case 'tags': {
        const str = Array.isArray(value) ? value.join(', ') : (value || '')
        return (
          <input
            className='form-control'
            value={str}
            onChange={(e) => onValueChange(field.key, e.currentTarget.value.split(/[,;]/).map(s => s.trim()).filter(Boolean))}
          />
        )
      }
      case 'textarea':
        return (
          <textarea
            className='form-control'
            rows={2}
            value={value || ''}
            onChange={(e) => onValueChange(field.key, e.currentTarget.value)}
          />
        )
      case 'input':
        return (
          <input
            className='form-control'
            value={value || ''}
            onChange={(e) => onValueChange(field.key, e.currentTarget.value)}
          />
        )
      case 'readonly':
        return (
          <div className='form-control-static'>
            {value ? (
              <span className='text-dark'>{value}</span>
            ) : (
              <span className='text-muted font-italic'>{window.FolioConsole.translations['file/not_available']}</span>
            )}
          </div>
        )
      default:
        return (
          <input
            className='form-control'
            value={value || ''}
            onChange={(e) => onValueChange(field.key, e.currentTarget.value)}
          />
        )
    }
  }

  const renderFieldGroup = (fields, title, icon) => (
    <div className='mb-4'>
      {!compact && (
        <div className='d-flex align-items-center mb-3'>
          <i className={`fas fa-${icon} mr-2 text-muted`}></i>
          <h6 className='mb-0 text-secondary font-weight-bold'>{title}</h6>
          {fields.some(f => !!formState[f.key]) && <Badge color='light' className='ml-2 small'>{window.FolioConsole.translations['file/has_data'] || 'has data'}</Badge>}
        </div>
      )}
      <div className='row'>
        {fields.map((f) => (
          <div className='col-12 mb-3' key={f.key}>
            <div className='mb-0 form-group'>
              <label className='form-label'>
                {window.FolioConsole.translations[`file/metadata/${f.key}`]
                  || window.FolioConsole.translations[`metadata/${f.key}`]
                  || f.label}
              </label>
              {renderField(f)}
            </div>
          </div>
        ))}
      </div>
    </div>
  )

  return (
    <>
      {!compact && (
        <div className='d-flex align-items-center justify-content-between mb-4'>
          <div>
            <h5 className='mb-1'>Metadata</h5>
            {hasExtractedMetadata && (
              <small className='text-muted'>Auto-extracted {new Date(hasExtractedMetadata).toLocaleDateString()}</small>
            )}
          </div>
          {!readOnly && (
            <FolioConsoleUiButton
              onClick={extractMetadata}
              disabled={isExtracting}
              variant='warning'
              size='sm'
              icon='reload'
              label={isExtracting ? window.FolioConsole.translations['file/extracting'] : window.FolioConsole.translations['file/extract_metadata']}
            />
          )}
        </div>
      )}

      {!hasAnyMetadata && !readOnly && !compact && (
        <div className='alert alert-light border mb-4'>
          <i className='fas fa-info-circle text-info mr-2'></i>
          <strong>{window.FolioConsole.translations['file/no_metadata_found']}</strong> {window.FolioConsole.translations['file/no_metadata_description']}
        </div>
      )}

      {renderFieldGroup(essentialFields, window.FolioConsole.translations['file/essential_information'], 'file-alt')}
      {renderFieldGroup(rightsFields, window.FolioConsole.translations['file/rights_attribution'], 'copyright')}
      {renderFieldGroup(locationFields, window.FolioConsole.translations['file/location'], 'map-marker-alt')}
      {renderFieldGroup(descriptiveFields, 'Descriptive', 'tags')}
      {renderFieldGroup(technicalFields, window.FolioConsole.translations['file/technical_metadata_readonly'], 'camera')}

      {!compact && hasExtractedMetadata && (
        <div className='mt-4 pt-3 border-top'>
          <small className='text-muted'>
            <i className='fas fa-robot mr-1'></i>
            {window.FolioConsole.translations['file/metadata_extracted_at_prefix'] || 'Metadata automatically extracted on'} {new Date(hasExtractedMetadata).toLocaleString()}.
            {' '}
            {window.FolioConsole.translations['file/metadata_extracted_at_suffix'] || 'Only blank fields are populated during extraction to preserve manual edits.'}
          </small>
        </div>
      )}
    </>
  )
}
