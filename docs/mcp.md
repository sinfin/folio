# Folio MCP Server

Folio includes an integrated MCP (Model Context Protocol) server that allows AI agents to interact with your CMS content.

## Quick Start

### 1. Install MCP

Run the generator:

```bash
rails generate folio:mcp:install
rails db:migrate
```

### 2. Configure Resources

Edit `config/initializers/folio_mcp.rb`:

```ruby
Folio::Mcp.configure do |config|
  config.resources = {
    pages: {
      model: "Folio::Page",
      fields: %i[title slug perex meta_title meta_description published locale],
      tiptap_fields: %i[tiptap_content],
      cover_field: :cover,
      versioned: true  # Enable version history tools
    },
    # Add your custom resources here
    articles: {
      model: "YourApp::Article",
      fields: %i[title subtitle slug published],
      tiptap_fields: %i[tiptap_content]
    },
    files: {
      model: "Folio::File::Image",
      searchable: true,
      uploadable: true
    }
  }

  config.locales = %i[cs en]
end
```

> **Note:** To enable `versioned: true`, you must also enable Folio page auditing:
> ```ruby
> # config/initializers/folio.rb
> Rails.application.config.folio_pages_audited = true
> ```

### 3. Generate API Token

```bash
rails folio:mcp:generate_token[admin@example.com]
```

> **Note:** Folio::User with the given email must exist.

Save the generated token - it won't be shown again!

### 4. Configure Cursor

Copy the sample configuration:

```bash
cp .cursor/mcp.json.sample .cursor/mcp.json
```

Edit `.cursor/mcp.json` and add your token:

```json
{
  "mcpServers": {
    "folio-local": {
      "type": "http",
      "url": "http://localhost:3000/folio/api/mcp",
      "headers": {
        "Authorization": "Bearer mcp_live_your_token_here"
      }
    }
  }
}
```

## Available Tools

### Content CRUD

- `get_page(id)` - Get page by ID
- `list_pages(limit, offset, locale, published)` - List pages with filters
- `create_page(title, slug, ...)` - Create new page
- `update_page(id, title, ...)` - Update existing page

Same tools are available for all configured resources (articles, projects, etc.).

### Translation

- `extract_translatable_texts(tiptap)` - Extract text fields for translation
- `apply_translations(original_tiptap, translations)` - Apply translated texts back

### Files

- `upload_file(url, alt, title, tags)` - Upload file from URL

### Version History

When `versioned: true` is set for a resource, these tools become available:

- `list_page_versions(id, limit, offset)` - List all versions with timestamps, authors, and preview URLs
- `get_page_version(id, version)` - Get specific historical version content with preview URL
- `restore_page_version(id, version)` - Restore record to a previous version

Same tools are available for all versioned resources (e.g., `list_project_versions`, etc.).

**Example workflow:**
```
1. list_page_versions(id: 123)
   → Returns versions with preview_url for each

2. Open preview_url in browser to review old version visually

3. get_page_version(id: 123, version: 5)
   → Returns full content at version 5 for comparison

4. restore_page_version(id: 123, version: 5)
   → Restores content, creates new version in history
```

## Available Resources

Resources can be read via the MCP resources protocol:

- `folio://pages` - List of pages
- `folio://pages/{id}` - Single page detail
- `folio://files?query=search` - Search files
- `folio://tiptap/schema` - Tiptap nodes schema

## Available Prompts

- `translate_page(page_id, source_locale, target_locale)` - Translation workflow guide
- `create_content(content_type)` - Content creation guide
- `edit_metadata(resource_type, id)` - Metadata editing guide

## Working with Tiptap Content

Tiptap is the rich text editor used in Folio. When creating or updating content via MCP, you need to understand the JSON structure.

### Basic Structure

You can pass tiptap content in two formats. The MCP server automatically wraps the simple format:

**Simple format (recommended for MCP):**
```json
{
  "type": "doc",
  "content": [
    { "type": "paragraph", "content": [{ "type": "text", "text": "Hello" }] },
    { "type": "folioTiptapNode", "attrs": { ... } }
  ]
}
```

**Full wrapper format (as stored in database):**
```json
{
  "tiptap_content": {
    "type": "doc",
    "content": [
      { "type": "paragraph", "content": [{ "type": "text", "text": "Hello" }] },
      { "type": "folioTiptapNode", "attrs": { ... } }
    ]
  }
}
```

> **Note:** The simple format is automatically wrapped by MCP before saving. Both formats are accepted.

### Folio Custom Nodes

Custom nodes use the `folioTiptapNode` wrapper:

```json
{
  "type": "folioTiptapNode",
  "attrs": {
    "type": "SinfinDigital::Tiptap::Node::Cards::Large",
    "version": 1,
    "data": {
      "title": "Card Title",
      "content": "{\"type\":\"doc\",\"content\":[...]}",
      "cover_placement_attributes": { "file_id": 123 }
    }
  }
}
```

### Image Attachment Naming Convention

**This is critical!** The attribute name depends on whether it's a single image or multiple:

| Node Definition | Attribute Name | Example |
|-----------------|----------------|---------|
| `cover: :image` | `cover_placement_attributes` | `{ "file_id": 123 }` |
| `images: :images` | `image_placements_attributes` | `[{ "file_id": 123 }, { "file_id": 124 }]` |

**Rule:** Singularize the key name, then append:
- `_placement_attributes` for single image (Hash)
- `_placements_attributes` for multiple images (Array)

**Common mistake:**
```json
// WRONG - will silently fail validation
"images_placement_attributes": [{ "file_id": 123 }]

// CORRECT
"image_placements_attributes": [{ "file_id": 123 }]
```

### Example: Gallery with Multiple Images

```json
{
  "type": "folioTiptapNode",
  "attrs": {
    "type": "SinfinDigital::Tiptap::Node::Images::MasonryGallery",
    "version": 1,
    "data": {
      "title": "Photo Gallery",
      "subtitle": "Our work",
      "image_placements_attributes": [
        { "file_id": 209 },
        { "file_id": 210 },
        { "file_id": 211 }
      ]
    }
  }
}
```

### Example: Card with Single Cover Image

```json
{
  "type": "folioTiptapNode",
  "attrs": {
    "type": "SinfinDigital::Tiptap::Node::Cards::Large",
    "version": 1,
    "data": {
      "title": "Featured Article",
      "content": "{\"type\":\"doc\",\"content\":[{\"type\":\"paragraph\",\"content\":[{\"type\":\"text\",\"text\":\"Description here.\"}]}]}",
      "button_url": "/read-more",
      "button_label": "Read More",
      "cover_placement_attributes": { "file_id": 207 }
    }
  }
}
```

### Rich Text Fields

Some node attributes contain nested tiptap content as a JSON string:

```json
{
  "content": "{\"type\":\"doc\",\"content\":[{\"type\":\"paragraph\",\"content\":[{\"type\":\"text\",\"text\":\"Nested content\"}]}]}"
}
```

### Columns Layout

```json
{
  "type": "folioTiptapColumns",
  "content": [
    {
      "type": "folioTiptapColumn",
      "content": [
        { "type": "folioTiptapNode", "attrs": { ... } }
      ]
    },
    {
      "type": "folioTiptapColumn", 
      "content": [
        { "type": "folioTiptapNode", "attrs": { ... } }
      ]
    }
  ]
}
```

### Discovering Available Nodes

Use the `folio://tiptap/schema` resource to see all available node types and their required attributes for your application.

### Validation

MCP validates tiptap nodes before saving. If a node is invalid (e.g., missing required images), you'll receive an error like:

```
Invalid tiptap content: Node #1 (MasonryGallery): Images can't be blank
```

## Security

### Token Management

Tokens are hashed using BCrypt before storage. The plain token is only shown once when generated.

Rake tasks:
- `rails folio:mcp:generate_token[email]` - Generate new token
- `rails folio:mcp:list_enabled` - List users with MCP enabled
- `rails folio:mcp:disable[email]` - Disable MCP for user

### Authorization

MCP uses the same authorization rules as Folio Console:

- Uses `Folio::Ability` for permission checks
- Respects site boundaries (users only see their site's content)
- Same ActiveRecord validations apply

### Rate Limiting

Configure rate limiting in the initializer:

```ruby
config.rate_limit = 100 # requests per minute
```

### Audit Logging

Enable audit logging:

```ruby
config.audit_logger = ->(event) {
  Rails.logger.tagged("MCP") { Rails.logger.info(event.to_json) }
  # Or save to database:
  # YourApp::McpAuditLog.create!(event)
}
```

## Testing

Test the connection:

```bash
curl -X POST http://localhost:3000/folio/api/mcp \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"ping"}'
```

## Troubleshooting

### 404 Not Found

MCP endpoint is not accessible. Check:
- MCP pack is enabled in `Folio.enabled_packs`
- Routes are properly mounted
- Rails server was restarted after configuration change

### 401 Unauthorized

Token issue:
- Check token is correct
- User has `mcp_enabled: true`
- Token hasn't been regenerated

### Validation Errors

MCP uses the same validations as Console. Check model validations and ensure all required fields are provided.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│  AI Agent (Cursor/Claude Desktop)                                   │
│                                                                     │
│  .cursor/mcp.json → Bearer token auth                               │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                │ Streamable HTTP (JSON-RPC 2.0)
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│  Folio Rails App                                                    │
│                                                                     │
│  POST /folio/api/mcp                                                │
│    ↓                                                                │
│  Folio::Api::McpController                                          │
│    - Token authentication                                           │
│    - Rate limiting                                                  │
│    - Audit logging                                                  │
│    ↓                                                                │
│  Folio::Mcp::ServerFactory                                          │
│    - Builds MCP::Server instance                                    │
│    - Registers tools, resources, prompts                            │
│    ↓                                                                │
│  MCP Tools / Resources                                              │
│    - Same authorization as Console (Folio::Ability)                 │
│    - Same validations (ActiveRecord)                                │
│    - Same callbacks (before_save, after_save, etc.)                 │
└─────────────────────────────────────────────────────────────────────┘
```
