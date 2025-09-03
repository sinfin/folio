# frozen_string_literal: true

Rails.application.config.tap do |config|
  # Enable/disable metadata extraction globally
  config.folio_image_metadata_extraction_enabled = true # default: true

  # Use IPTC-compliant field mappings (recommended)
  config.folio_image_metadata_use_iptc_standard = true # default: true

  # Standard IPTC field mappings with namespace precedence
  # XMP > IPTC-IIM > EXIF precedence (Note: ExifTool uses case-sensitive tag names)
  config.folio_image_metadata_standard_mappings = {
    # Core descriptive fields
    headline: ["XMP-photoshop:Headline", "Headline"],
    description: ["XMP-dc:Description", "Caption-Abstract", "ImageDescription"],
    creator: ["XMP-dc:Creator", "By-line", "Artist"],  # Store as JSONB array
    caption_writer: ["XMP-photoshop:CaptionWriter"],
    credit_line: ["XMP-iptcCore:CreditLine", "XMP-photoshop:Credit", "Credit"],
    source: ["XMP-iptcCore:Source", "XMP-photoshop:Source", "Source"],

    # Rights management
    copyright_notice: ["XMP-photoshop:Copyright", "XMP-dc:Rights"],
    copyright_marked: ["XMP-xmpRights:Marked"],  # Boolean
    usage_terms: ["XMP-xmpRights:UsageTerms"],
    rights_usage_info: ["XMP-xmpRights:WebStatement"],  # URL

    # Classification (JSONB arrays)
    keywords: ["XMP-dc:Subject"],  # Store as JSONB array
    intellectual_genre: ["XMP-iptcCore:IntellectualGenre"],
    subject_codes: ["XMP-iptcCore:SubjectCode"],  # JSONB array
    scene_codes: ["XMP-iptcCore:Scene"],  # JSONB array
    event: ["XMP-iptcCore:Event"],  # Single string

    # Legacy fields (deprecated)
    category: ["XMP-photoshop:Category", "Category"],
    urgency: ["XMP-photoshop:Urgency", "Urgency"],

    # People and objects (JSONB arrays)
    persons_shown: ["XMP-iptcExt:PersonInImage"],
    persons_shown_details: ["XMP-iptcExt:PersonInImageWDetails"],
    organizations_shown: ["XMP-iptcExt:OrganisationInImageName"],

    # Location data
    location_created: ["XMP-iptcExt:LocationCreated"],  # JSONB array of structs
    location_shown: ["XMP-iptcExt:LocationShown"],  # JSONB array of structs
    sublocation: ["XMP-iptcCore:Location"],  # Neighborhood/venue
    city: ["XMP-photoshop:City", "City"],
    state_province: ["XMP-photoshop:State", "Province-State"],
    country: ["XMP-iptcCore:CountryName", "Country-PrimaryLocationName", "Country"],
    country_code: ["XMP-iptcCore:CountryCode", "Country-PrimaryLocationCode"],  # 2 chars

    # Technical metadata from EXIF
    camera_make: ["Make"],
    camera_model: ["Model"],
    lens_info: ["LensModel", "LensInfo"],
    capture_date: ["DateTimeOriginal", "XMP-photoshop:DateCreated", "XMP-xmp:CreateDate", "CreateDate"],
    gps_latitude: ["GPSLatitude"],
    gps_longitude: ["GPSLongitude"],
    orientation: ["Orientation"],

    # Existing folio fields compatibility
    author: ["XMP-dc:Creator", "By-line", "Artist"],
    alt: ["XMP-dc:Description", "Caption-Abstract", "ImageDescription"]
  }

  # Custom field mappings (extends IPTC standard)
  config.folio_image_metadata_field_mappings = {}

  # Custom field processors (custom formatting and business logic with I18n support)
  config.folio_image_metadata_field_processors = {}

  # Fields to skip during extraction
  config.folio_image_metadata_skip_fields = []

  # Industry standard validation (optional)
  config.folio_image_metadata_require_agency_fields = false # default: false
  config.folio_image_metadata_required_fields = [
    # :creator, :credit_line, :copyright_notice, :source
  ] # IPTC recommended fields for professional use

  # Extract metadata to placements (TEMPORARILY DISABLED - functionality removed, will be reimplemented later)
  config.folio_image_metadata_copy_to_placements = false # default: true

  # Merge extracted keywords into image tag_list
  config.folio_image_metadata_merge_keywords_to_tags = true # default: true

  # ExifTool command options
  # Force UTF-8 pro IPTC (většina moderních souborů má UTF-8 data i když 1:90 auto-detect nefunguje)
  config.folio_image_metadata_exiftool_options = ["-G1", "-struct", "-n", "-charset", "iptc=utf8"] # default
  # When IPTC encoding is wrong or not declared, try these ExifTool IPTC charset fallbacks (order matters)
  config.folio_image_metadata_iptc_charset_candidates = %w[utf8 cp1250 iso-8859-2 cp1252 iso-8859-1 macroman]

  # Language priority for Lang Alt fields (dc:description, dc:rights, etc.)
  config.folio_image_metadata_locale_priority = [:en, "x-default"] # English first

  # Known photo providers for heuristic source detection when Credit/Source is missing
  # Host app can override/extend this list
  config.folio_image_metadata_known_providers = [
    { name: "Getty Images", patterns: [/\bgetty\b/i, /\bgetty images\b/i] },
    { name: "iStock", patterns: [/\bistock\b/i] },
    { name: "Shutterstock", patterns: [/\bshutterstock\b/i] },
    { name: "Westend61", patterns: [/\bwestend61\b/i] },
    { name: "Reuters", patterns: [/\breuters\b/i] },
    { name: "AP", patterns: [/\bassociated press\b/i, /\b\bAP\b/i] },
    { name: "Profimedia", patterns: [/\bprofimedia\b/i] },
    { name: "ČTK", patterns: [/\bctk\b/i, /\bčtk\b/i] },
    { name: "Unsplash", patterns: [/\bunsplash\b/i] },
    { name: "Pexels", patterns: [/\bpexels\b/i] }
  ]
end
