# WallaMarvel iOS Technical Test Implementation

## Features Implemented

1. **Hero Detail View**
   - When a user taps on a superhero in the list, the app navigates to a detail screen showing:
     - Hero name
     - Hero description
     - Hero image (low-res -> high-res swap with smooth fade-in)
     - Comics count
     - Series count
     - Stories count
     - Events count
     - Lists of comics, series, stories, and events (with "show more" toggle)

2. **Pagination**
   - When reaching the bottom of the superhero list, additional heroes are loaded automatically.
   - Spinner is shown at the bottom during pagination.
   - Minimum display time for loading indicators to improve UX.

3. **Search Functionality**
   - Search bar allows filtering heroes by name.
   - Search requests are **debounced** in the store for efficiency.
   - Cancelling search resets the list.

4. **Modern Concurrency**
   - Refactored the codebase to use Swift Concurrency (async/await) for handling asynchronous operations.
   - Retry with exponential backoff for transient network errors.
   - Cancellable in-flight requests for better search and refresh UX.

5. **Error Handling**
   - Improved error handling throughout the app with user-friendly error messages.
   - Displays retry option when initial load fails.
   - Clears previous errors upon successful load.

6. **Logging**
   - Added structured logging with injectable service provider.
   - Logs include app metadata and error context.

7. **Improved UI**
   - Smooth image transitions in hero detail screen.
   - Pagination spinner footer.
   - Compact top overlay loader for background searches.
   - Accessibility labels and identifiers for UI tests.

## Architecture Improvements

- Refactored to use **async/await** throughout the data layer.
- Improved error handling with proper error types and retry logic.
- Flattened repository/data source into API client for simplicity.
- Enhanced data models to include more information from the Marvel API.
- Introduced **ListHeroesUIStore** for state management and search debounce.
- MVP pattern with SwiftUI UI layer.
- Dependency injection via `Factory` library.
- Cancelable background tasks for search, refresh, and pagination.

## Files Modified

### Core Implementation Files
- `ListHeroesModule.swift` – Complete integration of API, presenter, store, SwiftUI views, and DI in a single cohesive module.
- `HeroDetailScreen.swift` – Detailed hero view with hi-res image fade-in and expandable lists.

### New / Updated Functionality
- Integrated **search debounce** inside `ListHeroesUIStore`.
- Added **retry/backoff** logic to `APIClient`.
- Added **structured logging**.
- Improved pagination UX with minimum spinner visibility.

## Setup Instructions

1. Ensure all Swift files are added to your Xcode project.
2. Project uses SwiftUI and Factory for DI. Add `Factory` via Swift Package Manager.
3. Marvel API keys are configured via `Info.plist`:
   - `MARVEL_PUBLIC_KEY`
   - `MARVEL_PRIVATE_KEY`

## Known Limitations

- Requires manual addition of any missing Swift files to the Xcode project.
- Kingfisher is no longer required — now uses SwiftUI's `AsyncImage`.

## Usage Notes

- App automatically loads heroes when launched.
- Scroll to the bottom to load more heroes (pagination).
- Use the search bar to filter heroes by name (debounced).
- Tap on any hero to view details (low-res image swaps to high-res with smooth transition).

## Marvel API Notes

If you encounter issues with the Marvel API:
- Ensure API keys are configured in `Info.plist`.
- API client retries transient errors automatically.
- Error handling shows user-friendly messages with retry option.

## Final Notes

This implementation demonstrates modern iOS development practices including:
- Swift Concurrency (async/await)
- MVP with SwiftUI state store
- Proper error handling and retry logic
- Pagination and search with debounce
- Responsive, accessible UI
- Dependency injection with `Factory`
- Image loading with smooth transitions
- Structured logging for better observability
