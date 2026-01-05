# Folio Tiptap

React + TypeScript + Vite app that provides Tiptap editor implementation for Folio. Built as a standalone app that integrates with the Rails application via iframes.

## Features

- Basic rich text editor with standard formatting
- Advanced block editor with custom nodes
- Integration with Folio's file system and components
- Real-time communication with parent Rails application

## Development

This is a Vite-based React application. To get started:

1. **Install dependencies:**

   ```bash
   npm install
   ```

2. **Start development server:**

   ```bash
   npm run dev
   ```

   This starts a development server at http://localhost:5173/

3. **For Folio integration testing:**
   Set `FOLIO_TIPTAP_DEV=1` when starting your Rails server:
   ```bash
   FOLIO_TIPTAP_DEV=1 rails server
   ```
   This configures the Rails app to use the local development server instead of built assets.

## Scripts

- `npm run dev` - Start development server with style copying
- `npm run build` - Build for production (outputs to `dist/assets/`)
- `npm run build:check` - Validate TypeScript without generating files
- `npm run lint` - Run ESLint
- `npm run lint:fix` - Run ESLint with auto-fix
- `npm run format` - Format all files with Prettier
- `npm run format:file [files]` - Format specific files with Prettier

## Build Output

The build process generates:

- `folio-tiptap.css` - Stylesheet for the editor
- `folio-tiptap.js` - JavaScript bundle

These files are placed in `dist/assets/` and consumed by the Rails application's asset pipeline.
