# Development Guidelines for AI Assistants

## Code Formatting and Linting

After editing any code files, automatically format and lint them using the appropriate tools for that language.

### JavaScript
- Format: `npm run format:file <file_path>`
- Lint: `npx eslint --fix <file_path>`
- Note: This overrides the standard JavaScript formatting/linting from the root AGENTS.md. Use eslint and prettier instead of `npx standard --fix`.

### TypeScript
- Format: `npm run format:file <file_path>`
- Lint: `npx eslint --fix <file_path>`
- Type Check: `npm run build:check` - Verify TypeScript compilation after making changes

## Project Structure Notes

- This is a TipTap-based rich text editor built with React + TypeScript + Vite
- Uses SCSS for styling with BEM-like naming conventions
- Follow existing patterns for component structure and naming
- All components should be properly typed with TypeScript interfaces

## Code Standards

- Use existing utility functions and follow established patterns
- Maintain consistent import organization (external libs first, then internal)
- Follow the existing SCSS variable and mixin conventions
- Prefer early returns over nested if statements for better readability
- Never commit without running the full command sequence above
