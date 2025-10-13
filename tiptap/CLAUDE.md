# Development Guidelines for AI Assistants

## Required Commands After Code Changes

When making any code changes to this project, ALWAYS run these commands in order:

1. **Lint Check**: `npm run lint` - Fix any linting errors before proceeding
2. **Format Code**: `npm run format` - Apply consistent code formatting  
3. **Type Check**: `npm run build:check` - Verify TypeScript compilation

## Project Structure Notes

- This is a TipTap-based rich text editor built with React + TypeScript + Vite
- Uses SCSS for styling with BEM-like naming conventions
- Follow existing patterns for component structure and naming
- All components should be properly typed with TypeScript interfaces

## Code Standards

- Use existing utility functions and follow established patterns
- Maintain consistent import organization (external libs first, then internal)
- Follow the existing SCSS variable and mixin conventions
- Never commit without running the full command sequence above