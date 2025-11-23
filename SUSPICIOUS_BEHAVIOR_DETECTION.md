# Suspicious Behavior Detection Feature

## Overview
This feature implements a system to detect and flag suspicious transcription behavior, with the primary focus on detecting paste events that may indicate users are using AI assistance (like ChatGPT) instead of transcribing from the page image.

## Problem Statement
Several transcription projects have found that some users don't look at the page image, but instead:
1. Copy the image into ChatGPT
2. Ask the LLM to transcribe the text
3. Paste the text back into the FromThePage transcription editor

This behavior needs to be flagged for project owner intervention, while still allowing legitimate use cases like:
- Users typing into a Word document on a second monitor and then pasting into FromThePage
- Users copying their work to Notepad as a backup before saving
- Users using AI-Assist to copy-and-paste a word or phrase they're editing

## Implementation

### Database Schema

#### `suspicious_behaviors` table
- `user_id` - The user who performed the suspicious action
- `page_id` - The page where the action occurred (optional)
- `collection_id` - The collection the page belongs to
- `deed_id` - Associated deed if any (optional)
- `behavior_type` - Type of behavior: 'paste_detected', 'high_wpm', 'chatgpt_tell', 'low_backspace', 'no_image_adjustment'
- `metadata` - JSON field for additional data (text length, timestamp, etc.)
- `flagged_at` - When the behavior was detected
- `resolved_at` - When it was resolved (nullable)
- `resolved_by_user_id` - Who resolved it (nullable)
- `status` - 'pending', 'approved', or 'dismissed'

#### `users` table addition
- `approved_for_paste` - Boolean flag indicating user is approved for paste (default: false)

### User Flow

#### For Transcribers
1. User pastes text into the transcription editor
2. JavaScript detects the paste event
3. An AJAX request is sent to the server (silently, doesn't interrupt work)
4. If it's their first paste and they're not approved, a suspicious behavior record is created
5. The project owner receives an email notification

#### For Project Owners
1. Receive email on first paste by a user
2. Can view all suspicious behaviors in their dashboard
3. Can review the user's contributions
4. Can approve the user if their paste use is legitimate
5. Once approved, no further notifications for that user
6. Subsequent paste events by non-approved users appear in nightly activity report

#### For Administrators
1. Can view all suspicious behaviors site-wide
2. Can approve users globally
3. Can monitor patterns across projects

### JavaScript Implementation
The paste detection is implemented in `app/assets/javascripts/transcribe.js.erb`:
- Listens for paste events on CodeMirror editor
- Listens for paste events on regular textareas
- Listens for paste events on field-based transcription inputs
- Sends data to `/transcribe/detect_paste` endpoint
- Includes metadata: page_id, text_length, timestamp

### Backend Implementation

#### Controllers
- `TranscribeController#detect_paste` - Receives paste event data, creates suspicious behavior records
- `AdminController#suspicious_behaviors` - Admin interface to view all behaviors
- `AdminController#approve_user_for_paste` - Admin approval action
- `DashboardController#suspicious_behaviors` - Owner interface to view behaviors in their collections
- `DashboardController#approve_user_for_paste` - Owner approval action

#### Mailers
- `UserMailer#suspicious_paste_alert` - Sent on first paste detection to collection owner
- `AdminMailer::OwnerCollectionActivity` - Updated to include suspicious behaviors in nightly email

### Views
- `/admin/suspicious_behaviors` - Admin view of all behaviors
- `/dashboard/suspicious_behaviors` - Owner view of behaviors in their collections
- Email templates for paste alerts (HTML and text versions)

## Usage

### Running Migrations
```bash
bundle exec rails db:migrate
```

### Approving a User
From the admin or owner dashboard:
1. Navigate to "Suspicious Behaviors"
2. Find the user in the list
3. Click "Approve User" button
4. This will:
   - Set `approved_for_paste = true` on the user
   - Mark all pending behaviors as 'dismissed'
   - Prevent future notifications for that user

### Viewing User Contributions
From the suspicious behaviors list, click "View User Contributions" to see all their work in that collection.

## Testing

### Running Tests
```bash
bundle exec rspec spec/models/suspicious_behavior_spec.rb
bundle exec rspec spec/requests/transcribe_controller_spec.rb
bundle exec rspec spec/models/user_spec.rb
```

### Manual Testing
1. Log in as a transcriber
2. Navigate to a transcription page
3. Copy some text and paste it into the editor
4. Check that a suspicious behavior record was created
5. Check that the collection owner received an email
6. Log in as the collection owner
7. Navigate to dashboard → Suspicious Behaviors
8. Verify the user appears in the list
9. Click "Approve User"
10. Try pasting again as the transcriber
11. Verify no new suspicious behavior records are created

## Future Enhancements

The infrastructure supports detecting additional suspicious behaviors:
- **High WPM**: Calculate words per minute based on time between display and save
- **ChatGPT tells**: Detect patterns in text like "OCR TEXT" that indicate AI output
- **Low backspace count**: Real users will edit and second-guess themselves
- **No image adjustment**: Real users zoom and pan while transcribing

These can be implemented by:
1. Adding detection logic in the appropriate places
2. Creating `SuspiciousBehavior` records with the appropriate `behavior_type`
3. Following the same notification and resolution flow

## Configuration

### Email Notifications
Email notifications require `SMTP_ENABLED` to be true. Set this in your environment configuration.

### Nightly Reports
The nightly owner activity email is sent by the rake task:
```bash
bundle exec rake fromthepage:collection_stats_by_owner
```

This should be scheduled to run daily via cron or similar.

## Security Considerations

- Paste detection is done client-side but verified server-side
- User approval requires owner or admin privileges
- All suspicious behavior records are logged for audit purposes
- The system is designed to minimize false positives
- Users' work is never blocked, only flagged for review

## Database Indexes

The following indexes are created for performance:
- `suspicious_behaviors(user_id, behavior_type, flagged_at)`
- `suspicious_behaviors(collection_id, status)`
- `suspicious_behaviors(status)`
- `users(approved_for_paste)`

## API Endpoints

### POST `/transcribe/detect_paste`
Receives paste event data from JavaScript.

**Parameters:**
- `page_id` - ID of the page being transcribed
- `text_length` - Length of pasted text
- `timestamp` - ISO 8601 timestamp of the event

**Response:**
- `200 OK` - Paste event recorded (or user already approved)
- `401 Unauthorized` - User not logged in
- `404 Not Found` - Page not found

### POST `/admin/approve_user_for_paste`
Approves a user for paste (admin only).

**Parameters:**
- `user_id` - ID of user to approve

**Response:**
- Redirects to admin suspicious behaviors page with success message

### POST `/dashboard/approve_user_for_paste`
Approves a user for paste (collection owner only).

**Parameters:**
- `user_id` - ID of user to approve

**Response:**
- Redirects to dashboard suspicious behaviors page with success message

## Troubleshooting

### Paste events not being detected
- Check browser console for JavaScript errors
- Verify the CSRF token is present in the page
- Check that the `/transcribe/detect_paste` endpoint is accessible

### Emails not being sent
- Verify `SMTP_ENABLED` is true
- Check email configuration in your environment
- Look for errors in the Rails logs

### User still receiving notifications after approval
- Check that `approved_for_paste` is true in the database
- Verify there are no JavaScript caching issues

## Monitoring

### Useful Queries

Count paste events by user:
```ruby
SuspiciousBehavior.paste_events.group(:user_id).count
```

Find users with multiple paste events:
```ruby
SuspiciousBehavior.paste_events.group(:user_id).having('COUNT(*) > 5').count
```

List pending behaviors:
```ruby
SuspiciousBehavior.pending.includes(:user, :collection)
```

## Support

For questions or issues, contact the FromThePage development team.
