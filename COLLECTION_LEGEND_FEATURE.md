# Collection Legend Feature

## Overview

The Collection Legend feature allows collection owners to add a legend field to their collections that provides context or guidance for understanding the content. The legend is displayed on each page's transcription display view to help transcribers and readers understand symbols, conventions, or formatting used in the documents.

## Implementation

### Database Changes
- Added `legend` text field to the `collections` table
- Field supports HTML content with a maximum length of 65,535 characters

### User Interface Changes
- **Collection Edit Form**: New legend field in the collection edit form under the "General" settings
- **Page Display View**: Legend appears in a styled section between the transcription content and the page notes
- **Conditional Display**: Legend section only appears when legend content is present

### Key Features
- **HTML Support**: Legend field accepts and validates HTML content
- **Rich Text**: Supports formatted text including emphasis, lists, and basic HTML elements
- **Responsive Design**: Legend displays consistently with existing page layout
- **User-Friendly**: Easy to add and edit through the collection settings interface

### Technical Details
- **Model**: Collection model includes legend field with HTML validation
- **Controller**: Collection controller permits legend parameter for form submissions
- **Views**: Display page view conditionally shows legend when present
- **Styling**: Custom CSS provides consistent appearance with page notes section
- **Internationalization**: English translations provided for form labels and display text

### Usage Example
Collection owners can add legends such as:
- Symbol guides explaining transcription conventions
- Formatting notes for understanding document structure  
- Editorial guidelines for interpreting historical content
- Reference information about abbreviations or terminology

### Files Modified
- `app/models/collection.rb` - Added legend field and validation
- `app/controllers/collection_controller.rb` - Added legend to permitted parameters
- `app/views/collection/_edit_form.html.slim` - Added legend input field
- `app/views/display/display_page.html.slim` - Added legend display section
- `app/assets/stylesheets/sections/page.scss` - Added legend styling
- `config/locales/collection/collection-en.yml` - Added legend form translations
- `config/locales/display/display-en.yml` - Added legend display translation
- `db/migrate/20250915142600_add_legend_to_collections.rb` - Database migration

### Tests Added
- Model validation tests for HTML syntax validation
- Controller tests for parameter handling
- Feature tests for legend display functionality

This feature enhances the user experience by providing contextual information directly where transcribers need it most - on the page display view where they can see both the original document and the transcribed content alongside helpful guidance.