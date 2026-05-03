# Meeting Scheduler Search AWS Notes

This folder contains the deployable pieces for meeting-title search.

1. Run `create_meeting_search_index.sql` against the `CIApp` database.
2. Create Lambda `ciapp-search-student-meetings` with file `lambda_search_student_meetings.py` and handler `lambda_search_student_meetings.lambda_handler`.
3. Match the existing messaging Lambdas for runtime, VPC, security group, role permissions, and `DB_HOST`, `DB_USER`, `DB_PASSWORD` environment variables.
4. Add API Gateway route `GET /student/{studentId}/meetings/search` to the new Lambda.
5. Copy `meeting_search_index_helpers.py` logic into `ciapp-send-message` and `ciapp-edit-message`.

The send/edit Lambdas should call `sync_meeting_search_index(cursor, message_id, conversation_id, body)` inside the same transaction after the `messages` row is inserted or updated. Non-MeetingScheduler bodies delete any stale index row for that message.
