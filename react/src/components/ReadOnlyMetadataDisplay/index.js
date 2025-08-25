import React from 'react'

export default ({ file }) => {
  // Read-only metadata display as unified Folio-styled table

  const renderSectionHeader = (title, icon = 'info') => (
    <tr className='table-secondary'>
      <td colSpan='2' className='fw-bold text-uppercase small py-2'>
        <i className={`fas fa-${icon} me-2`}></i>
        {title}
      </td>
    </tr>
  )

  const renderMetadataRow = (field) => {
    let value = file.attributes[field.key]
    
    // Skip empty values
    if (!value || value === '' || (Array.isArray(value) && value.length === 0)) {
      return null
    }
    
    // Format different value types
    if (Array.isArray(value)) {
      value = value.join(', ')
    } else if (field.type === 'date' && value) {
      value = new Date(value).toLocaleDateString('cs-CZ', { 
        year: 'numeric', 
        month: '2-digit', 
        day: '2-digit',
        ...(field.includeTime ? { hour: '2-digit', minute: '2-digit' } : {})
      })
    } else if (field.type === 'number' && value) {
      value = parseFloat(value).toFixed(field.decimals || 0)
    } else if (field.type === 'filesize' && value) {
      value = `${(value / 1024 / 1024).toFixed(1)} MB`
    }

    return (
      <tr key={field.key}>
        <td className='text-muted fw-medium' style={{ width: '30%' }}>
          {field.label}
        </td>
        <td className='text-break'>
          {value}
        </td>
      </tr>
    )
  }

  // Descriptive Metadata Fields
  const descriptiveFields = [
    { key: 'headline_from_metadata', label: window.FolioConsole.translations['file/metadata/headline'] || 'Headline', type: 'text' },
    { key: 'creator', label: window.FolioConsole.translations['file/metadata/creator'] || 'Creator(s)', type: 'array' },
    { key: 'caption_writer', label: window.FolioConsole.translations['file/metadata/caption_writer'] || 'Caption Writer', type: 'text' },
    { key: 'credit_line', label: window.FolioConsole.translations['file/metadata/credit_line'] || 'Credit Line', type: 'text' },
    { key: 'source_from_metadata', label: window.FolioConsole.translations['file/metadata/source'] || 'Source', type: 'text' },
    { key: 'keywords_from_metadata', label: window.FolioConsole.translations['file/metadata/keywords'] || 'Keywords', type: 'array' },
    { key: 'intellectual_genre', label: window.FolioConsole.translations['file/metadata/intellectual_genre'] || 'Intellectual Genre', type: 'text' },
    { key: 'subject_codes', label: window.FolioConsole.translations['file/metadata/subject_codes'] || 'Subject Codes', type: 'array' },
    { key: 'event', label: window.FolioConsole.translations['file/metadata/event'] || 'Event', type: 'text' },
    { key: 'category', label: window.FolioConsole.translations['file/metadata/category'] || 'Category', type: 'text' },
    { key: 'persons_shown_from_metadata', label: window.FolioConsole.translations['file/metadata/persons_shown'] || 'Persons Shown', type: 'array' },
    { key: 'organizations_shown_from_metadata', label: window.FolioConsole.translations['file/metadata/organizations_shown'] || 'Organizations Shown', type: 'array' }
  ]

  // Technical Metadata Fields
  const technicalFields = [
    { key: 'camera_make', label: window.FolioConsole.translations['file/metadata/camera_make'] || 'Camera Make', type: 'text' },
    { key: 'camera_model', label: window.FolioConsole.translations['file/metadata/camera_model'] || 'Camera Model', type: 'text' },
    { key: 'lens_info', label: window.FolioConsole.translations['file/metadata/lens_info'] || 'Lens Info', type: 'text' },
    { key: 'capture_date', label: window.FolioConsole.translations['file/metadata/capture_date'] || 'Capture Date', type: 'date', includeTime: true },
    { key: 'gps_latitude', label: window.FolioConsole.translations['file/metadata/gps_latitude'] || 'GPS Latitude', type: 'number', decimals: 6 },
    { key: 'gps_longitude', label: window.FolioConsole.translations['file/metadata/gps_longitude'] || 'GPS Longitude', type: 'number', decimals: 6 },
    { key: 'file_width', label: 'Šířka', type: 'text' },
    { key: 'file_height', label: 'Výška', type: 'text' },
    { key: 'file_size', label: 'Velikost souboru', type: 'filesize' },
    { key: 'orientation', label: window.FolioConsole.translations['file/metadata/orientation'] || 'Orientation', type: 'text' },
    { key: 'focal_length', label: window.FolioConsole.translations['file/metadata/focal_length'] || 'Focal Length', type: 'text' },
    { key: 'aperture', label: window.FolioConsole.translations['file/metadata/aperture'] || 'Aperture', type: 'text' },
    { key: 'shutter_speed', label: window.FolioConsole.translations['file/metadata/shutter_speed'] || 'Shutter Speed', type: 'text' },
    { key: 'iso_speed', label: window.FolioConsole.translations['file/metadata/iso_speed'] || 'ISO Speed', type: 'text' },
    { key: 'flash', label: window.FolioConsole.translations['file/metadata/flash'] || 'Flash', type: 'text' },
    { key: 'white_balance', label: window.FolioConsole.translations['file/metadata/white_balance'] || 'White Balance', type: 'text' },
    { key: 'metering_mode', label: window.FolioConsole.translations['file/metadata/metering_mode'] || 'Metering Mode', type: 'text' },
    { key: 'exposure_mode', label: window.FolioConsole.translations['file/metadata/exposure_mode'] || 'Exposure Mode', type: 'text' },
    { key: 'exposure_compensation', label: window.FolioConsole.translations['file/metadata/exposure_compensation'] || 'Exposure Compensation', type: 'text' }
  ]

  // Rights Metadata Fields
  const rightsFields = [
    { key: 'copyright_notice', label: window.FolioConsole.translations['file/metadata/copyright_notice'] || 'Copyright Notice', type: 'text' },
    { key: 'copyright_marked', label: window.FolioConsole.translations['file/metadata/copyright_marked'] || 'Copyright Marked', type: 'text' },
    { key: 'rights_usage_terms', label: window.FolioConsole.translations['file/metadata/usage_terms'] || 'Usage Terms', type: 'text' },
    { key: 'rights_url', label: window.FolioConsole.translations['file/metadata/rights_url'] || 'Rights URL', type: 'text' }
  ]

  // Location Metadata Fields
  const locationFields = [
    { key: 'location_created', label: window.FolioConsole.translations['file/metadata/location_created'] || 'Location Created', type: 'text' },
    { key: 'location_shown', label: window.FolioConsole.translations['file/metadata/location_shown'] || 'Location Shown', type: 'text' },
    { key: 'city', label: window.FolioConsole.translations['file/metadata/city'] || 'City', type: 'text' },
    { key: 'state_province', label: window.FolioConsole.translations['file/metadata/state_province'] || 'State/Province', type: 'text' },
    { key: 'country', label: window.FolioConsole.translations['file/metadata/country'] || 'Country', type: 'text' },
    { key: 'country_code', label: window.FolioConsole.translations['file/metadata/country_code'] || 'Country Code', type: 'text' },
    { key: 'sublocation', label: window.FolioConsole.translations['file/metadata/sublocation'] || 'Sublocation', type: 'text' }
  ]

  // Filter sections with data
  const sectionsWithData = [
    { title: window.FolioConsole.translations['file/descriptive_metadata'] || 'Descriptive Information', fields: descriptiveFields, icon: 'file-alt' },
    { title: window.FolioConsole.translations['file/technical_metadata'] || 'Technical Information', fields: technicalFields, icon: 'camera' },
    { title: window.FolioConsole.translations['file/rights_metadata'] || 'Rights & Attribution', fields: rightsFields, icon: 'copyright' },
    { title: window.FolioConsole.translations['file/location_metadata'] || 'Location Information', fields: locationFields, icon: 'map-marker-alt' }
  ].filter(section => {
    return section.fields.some(field => {
      const value = file.attributes[field.key]
      return value && value !== '' && (!Array.isArray(value) || value.length > 0)
    })
  })

  if (sectionsWithData.length === 0) {
    return (
      <div className='text-center text-muted py-4'>
        <i className='fas fa-info-circle fa-2x mb-2'></i>
        <p className='mb-0'>
          {window.FolioConsole.translations['file/no_metadata_description'] || 'Try extracting metadata to populate these fields.'}
        </p>
      </div>
    )
  }

  return (
    <div className='folio-console-metadata-table'>
      <h6 className='mb-3 text-secondary'>
        <i className='fas fa-database me-2'></i>
        Advanced Metadata
      </h6>

      <div className='table-responsive'>
        <table className='table table-striped table-hover'>
          <tbody>
            {sectionsWithData.map((section, sectionIndex) => (
              <React.Fragment key={`section-${sectionIndex}`}>
                {renderSectionHeader(section.title, section.icon)}
                {section.fields.map(field => renderMetadataRow(field))}
              </React.Fragment>
            ))}
          </tbody>
        </table>
      </div>


    </div>
  )
}