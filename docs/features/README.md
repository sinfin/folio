# Folio Features Documentation

This directory contains detailed specifications and documentation for advanced Folio features.

## Image Metadata

### Core Documentation
- [**Image Metadata Extraction**](image_metadata_extraction.md) 🎯 **Main Specification**  
  Complete specification for automatic EXIF/IPTC metadata extraction and mapping to database fields

### Implementation Guides

- [**IPTC Migration with Aliases**](image_metadata/iptc_migration_with_aliases.md) ⭐  
  Complete migration guide with backward compatibility:
  - Safe database migration preserving existing data
  - Read/write aliases for legacy field names
  - Zero breaking changes for existing applications
  - Async metadata extraction after upload
  - Bulk migration tools for existing files

- [**IPTC Metadata Mapping**](image_metadata/iptc_metadata_mapping.md)  
  Ready-to-use Ruby implementation following international standards:
  - Complete XMP/IPTC-IIM/EXIF field mappings
  - Namespace precedence handling
  - Complex field processors (GPS, arrays, locations)
  - Lang Alt support for multilingual metadata
  - Testing examples and command-line tools

- [**Performance & Testing**](image_metadata/iptc_performance_testing.md)  
  Production-ready optimizations and comprehensive test suite:
  - ExifTool stay-open mode for bulk processing
  - Lang Alt resolution tests
  - JSONB array handling
  - GPS and timezone normalization
  - Integration tests with overwrite protection

- [**Developer Experience**](image_metadata/image_metadata_developer_experience.md)  
  Tools and utilities for developers:
  - Rails generators for custom extractors
  - Event hooks and callbacks system
  - Testing helpers and matchers
  - Performance benchmarking tools
  - Console commands for debugging

## Implementation Status

| Feature | Status | Documentation |
|---------|--------|--------------|
| Basic metadata extraction | ✅ Implemented | [files.md](../files.md) |
| IPTC standard mapping | ✅ Ready | [iptc_metadata_mapping.md](image_metadata/iptc_metadata_mapping.md) |
| Database migration with aliases | ✅ Ready | [iptc_migration_with_aliases.md](image_metadata/iptc_migration_with_aliases.md) |
| Backward compatibility | ✅ Ready | [iptc_migration_with_aliases.md](image_metadata/iptc_migration_with_aliases.md) |
| Performance optimization | ✅ Ready | [iptc_performance_testing.md](image_metadata/iptc_performance_testing.md) |
| Developer tools | ✅ Ready | [image_metadata_developer_experience.md](image_metadata/image_metadata_developer_experience.md) |

## Implementation Priority

1. **Phase 1: Migration** *(Ready to implement)*
   - Run database migration with aliases
   - Deploy model changes with backward compatibility
   - Test with existing applications

2. **Phase 2: Extraction** *(Ready to implement)*
   - Enable async metadata extraction on upload
   - Run bulk extraction for existing files
   - Monitor performance

3. **Phase 3: Optimization** *(Optional)*
   - Implement stay-open mode for large batches
   - Add admin UI for metadata management
   - Generate developer tools

## Quick Links

- [← Back to Main Documentation](../README.md)
- [Files & Media Overview](../files.md)
- [Configuration Guide](../configuration.md)

---

*These specifications are living documents and will be updated as features are developed.*
