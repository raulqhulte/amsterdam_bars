# Amsterdam Bars app

This is a Flutter app for tracking bars in Amsterdam.

## Structure
- pages/ contains screens
- models/ contains data models
- db/ contains DAOs
- services/ contains session and helper services

## Rules
- Keep Material 3 styling
- Preserve the current architecture unless explicitly asked to refactor
- Prefer minimal edits
- Do not rename files unless necessary
- When changing UI, keep navigation intact
- When changing models or DAOs, update all affected files consistently
- Do not touch Firebase config unless explicitly asked

## Verification
After making changes, always run:
- flutter pub get
- dart format .
- flutter analyze

If tests exist, also run:
- flutter test