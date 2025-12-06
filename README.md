# notepadmacOS

Windows XP–style Notepad rebuilt for macOS in C++ using Cocoa with an MVC layout.

## Build & run
- Prereqs: macOS with Xcode command-line tools (clang and Cocoa are default).
- Compile: `make`
- Run: `./notepadxp`

## Features
- Plain-text editor with XP-like window chrome, menus, status bar, and word wrap toggle.
- File commands: New, Open, Save, Save As, Page Setup, Print (via system print panel).
- Edit commands: Undo/Redo, Cut/Copy/Paste/Delete, Find/Find Next, Go To Line, Time/Date insert.
- Format/View: Word Wrap, Font chooser, Status Bar toggle.
- About dialog styled for XP Notepad homage.

## Architecture (MVC)
- Model: `src/DocumentModel.*` — text buffer, path, dirty tracking.
- View: `src/EditorView.*` — Cocoa window, text view, status bar, layout toggles.
- Controller: `src/AppController.*` — menu wiring, file I/O, prompts, status updates, commands.
- Menu construction is modularized in `src/MenuBuilder.*`.

Every class stays under 500 lines and includes a brief responsibility comment.
