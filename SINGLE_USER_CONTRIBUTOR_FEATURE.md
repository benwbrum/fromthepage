# Single User Contributor Time Feature

## Overview

This feature allows collection owners to view contribution time and activity details for a specific user within a selected date range, addressing the need to get individual user statistics without downloading a full spreadsheet.

## How to Use

1. **Navigate to Contributors Page**: Go to your collection and click on the "Collaborators" tab
2. **Select Date Range**: Use the start date and end date fields to specify the time period (defaults to last week)
3. **Select User (Optional)**: 
   - Use the "Select User" dropdown to search for a specific contributor
   - The dropdown searches users who have activity on your collection
   - Leave blank to see all contributors (existing functionality)
4. **View Results**: Click "Update" to see the filtered results

## What You'll See

### For a Specific User:
- **Total Time**: Hours and minutes the user spent on the project (from activity tracking)
- **Activity Details**: Chronological list of the user's contributions including:
  - Date and time of each activity
  - Type of activity (transcription, editing, review, etc.)
  - Links to the specific pages or works they contributed to
  - Limited to most recent 50 activities for performance

### For All Users (Default):
- Overview statistics for all contributors
- List of active contributors with their time contributions
- Export options for detailed reports

## Technical Notes

- **Data Sources**: 
  - Time data comes from `ahoy_activity_summary` table
  - Activity details come from the `deeds` table
- **User Search**: Only shows users who have actual activity on the collection
- **Performance**: Activity list is limited to 50 most recent items to ensure fast loading
- **Error Handling**: Invalid user selections gracefully fall back to showing all users

## Use Cases

- **Individual Performance Review**: Track a specific volunteer's contributions
- **Recognition**: Identify top contributors for acknowledgment
- **Quality Assurance**: Review specific user's work for training purposes
- **Reporting**: Generate focused reports for stakeholders about individual contributors

This feature eliminates the need to download and filter large spreadsheets to find information about a single contributor.