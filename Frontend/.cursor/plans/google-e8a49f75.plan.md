<!-- e8a49f75-c5f2-4024-a05a-29da72c59387 10c1c8a4-4cd6-4a10-aff3-3fa3ce5b33ef -->
# Google Photos–Style UI Plan

## Current understanding (from code)

- Pages: `app/photos/page.js` (gallery by date), `app/albums/page.js`, `app/albums/[id]/page.js`, `app/favorites/page.js`, `app/page.js` (user selection/login modal), `app/layout.js`.
- Layout: `components/layout/MainLayout.js` sidebar + mobile header.
- Photos UI: `PhotoToolbar`, `DateSection`, `PhotoGrid`, `UploadModal`; dummy data in `data/photos.js`; localStorage for favorites and albums.
- Albums UI: `AlbumCard`, `CreateAlbumModal`; album detail uses `PhotoGrid`.

## Goals

- Deliver a Google Photos–like UI: fast grid, date clusters with sticky headers, multi-select, bulk actions, lightbox viewer, albums, favorites, uploads, search, and basic settings.

## Scope and phases

### Phase 1: Foundation and UX polish

- Improve grid responsiveness, hover/pressed states, and empty/loading UI.
- Add infinite scroll for large photo sets with date-group virtualization.
- Introduce a lightweight state store (Zustand) to centralize selection, favorites, albums.
- Normalize data model (photo, album) and replace ids with `string` UUIDs across UI.

### Phase 2: Selection and bulk actions

- Implement shift-click range selection, keyboard shortcuts (A, Esc, Delete), and drag-select box.
- Enhance `PhotoToolbar` with dynamic actions: download, delete, share, add to album, favorite.
- Per-date “Select all in section” refinement with indeterminate states.

### Phase 3: Lightbox viewer (single photo view)

- New `components/photos/Lightbox.js` with zoom, pan, swipe, arrow-key nav.
- Show sidebar metadata (time, dimensions, EXIF placeholder), actions (favorite, download, delete, add to album).
- Entry from clicking a photo; preserves selection state.

### Phase 4: Search and filters (local for now)

- `SearchBar` with query parsing; facet filters (type, favorites, date range) client-side.
- Hook search into photos index (title, tags) with debounced input.

### Phase 5: Albums and organization

- Album create/edit modal upgrade (title validation, cover selection, photo counts).
- Add album edit page for renaming, reordering cover, remove/add photos.
- Album share link stub and cover mosaic.

### Phase 6: Uploads

- Enhance `UploadModal` with progress per file and cancellation.
- Background queue manager; optimistic grid insertion in Today group.

### Phase 7: Performance & polish

- Virtualized grid + windowed date sections (e.g., `react-virtualized` or `react-window` + masonry-like layout).
- Preload next/prev images in lightbox; responsive `sizes` and `srcSet`.
- Skeletons, toasts, and accessible focus states.

## Key file changes/new files

- Update: `app/photos/page.js`, `components/photos/PhotoGrid.js`, `components/photos/PhotoToolbar.js`, `components/photos/DateSection.js`.
- New: `components/photos/Lightbox.js`, `components/photos/DragSelectOverlay.js`, `store/useGalleryStore.js`, `components/common/Toast.js`, `components/common/Skeletons.js`.
- Optional: `lib/images.ts` for helpers (srcset, preload), `lib/keyboardShortcuts.ts`.

## Data model (client-first)

- Photo: `{ id: string, url: string, title?: string, takenAt?: string, width?: number, height?: number, favorite?: boolean, tags?: string[] }`.
- Album: `{ id: string, title: string, description?: string, photoIds: string[], createdAt: string, coverPhotoId?: string }`.
- Persist in localStorage for now; abstract through `store/useGalleryStore.js`.

## Accessibility & theming

- Ensure keyboard navigation and focus rings; ARIA for dialogs, buttons, checkboxes.
- Maintain dark mode; add settings toggles for density and grid size.

## Risks/assumptions

- Operating in client-only mode until backend/API is confirmed.
- Large lists require virtualization to avoid performance issues.

## Minimal milestones (ship increments)

1) Grid polish + centralized store + favorites/albums wired to store.
2) Selection UX (shift, drag), toolbar actions; basic lightbox.
3) Virtualized infinite scroll; improved uploads.
4) Album edit/cover; search filters; performance polish.

### To-dos

- [ ] Add Zustand store for photos, albums, selection, favorites
- [ ] Polish PhotoGrid UI, add skeletons and empty states
- [ ] Implement shift-click and drag-select; keyboard shortcuts
- [ ] Create Lightbox with zoom, pan, next/prev, metadata
- [ ] Add windowed list for date groups and grid virtualization
- [ ] Enhance UploadModal with progress and background queue
- [ ] Add album edit page and cover selection
- [ ] Implement local search and facet filters
- [ ] Preload images, responsive sizes, toasts, a11y