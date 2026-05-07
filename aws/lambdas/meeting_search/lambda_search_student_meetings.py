import json
import os
import pymysql


def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, default=str),
    }


def parse_limit(query_parameters):
    raw_limit = (query_parameters or {}).get("limit")
    if raw_limit is None:
        return 20

    try:
        return min(max(int(raw_limit), 1), 50)
    except (TypeError, ValueError):
        return 20


def isoformat(value):
    if value is None:
        return None
    if hasattr(value, "isoformat"):
        return value.isoformat().replace("+00:00", "Z")
    return str(value)


def build_conversation(row, participants, student_id):
    participant_ids = [participant["id"] for participant in participants]
    other_participant = None

    if row["conversation_type"] == "direct":
        other_participant = next(
            (participant for participant in participants if participant["id"] != student_id),
            None,
        )

    return {
        "id": row["conversation_id"],
        "conversationType": row["conversation_type"],
        "participantIds": participant_ids,
        "otherParticipant": other_participant,
        "groupName": row.get("group_name"),
        "adminStudentId": row.get("admin_student_id"),
        "participants": participants,
        "unreadCount": 0,
        "lastMessagePreview": f"Scheduling a meeting: {row['title']}",
        "lastMessage": None,
        "lastMessageAt": isoformat(row.get("last_message_at")),
        "createdAt": isoformat(row.get("conversation_created_at")),
        "archivedAt": isoformat(row.get("archived_at")),
    }


def lambda_handler(event, context):
    path_parameters = event.get("pathParameters") or {}
    query_parameters = event.get("queryStringParameters") or {}

    student_id = path_parameters.get("studentId")
    query = (query_parameters.get("q") or "").strip()
    limit = parse_limit(query_parameters)

    if not student_id:
        return response(400, {"error": "Missing studentId path parameter"})

    if not query:
        return response(400, {"error": "Missing q query parameter"})

    if len(query) < 3:
        return response(400, {"error": "Search query must be at least 3 characters"})

    connection = pymysql.connect(
        host=os.environ["DB_HOST"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        database="CIApp",
        cursorclass=pymysql.cursors.DictCursor,
    )

    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT id FROM students WHERE id = %s", (student_id,))
            if cursor.fetchone() is None:
                return response(404, {"error": "Student not found"})

            cursor.execute(
                """
                SELECT
                  msi.message_id,
                  msi.conversation_id,
                  msi.meeting_scheduler_id,
                  msi.title,
                  msi.created_at AS meeting_created_at,
                  c.conversation_type,
                  c.group_name,
                  c.admin_student_id,
                  c.created_at AS conversation_created_at,
                  c.last_message_at,
                  c.archived_at,
                  MATCH(msi.title) AGAINST (%s IN NATURAL LANGUAGE MODE) AS relevance
                FROM meeting_search_index msi
                JOIN conversations c ON c.id = msi.conversation_id
                JOIN conversation_participants requester
                  ON requester.conversation_id = c.id
                 AND requester.student_id = %s
                WHERE c.archived_at IS NULL
                  AND MATCH(msi.title) AGAINST (%s IN NATURAL LANGUAGE MODE)
                ORDER BY relevance DESC, msi.created_at DESC, msi.message_id DESC
                LIMIT %s
                """,
                (query, student_id, query, limit),
            )
            rows = cursor.fetchall()

            if not rows:
                return response(200, [])

            conversation_ids = [row["conversation_id"] for row in rows]
            placeholders = ", ".join(["%s"] * len(conversation_ids))
            cursor.execute(
                f"""
                SELECT
                  cp.conversation_id,
                  s.id,
                  s.name,
                  s.email,
                  cp.joined_at
                FROM conversation_participants cp
                JOIN students s ON s.id = cp.student_id
                WHERE cp.conversation_id IN ({placeholders})
                ORDER BY cp.joined_at ASC, s.name ASC
                """,
                conversation_ids,
            )

            participants_by_conversation = {}
            for participant in cursor.fetchall():
                conversation_id = participant["conversation_id"]
                participants_by_conversation.setdefault(conversation_id, []).append({
                    "id": participant["id"],
                    "name": participant["name"],
                    "email": participant["email"],
                    "joinedAt": isoformat(participant.get("joined_at")),
                })

            results = []
            for row in rows:
                participants = participants_by_conversation.get(row["conversation_id"], [])
                results.append({
                    "messageId": row["message_id"],
                    "conversation": build_conversation(row, participants, student_id),
                    "meetingSchedulerId": row.get("meeting_scheduler_id"),
                    "title": row["title"],
                    "createdAt": isoformat(row.get("meeting_created_at")),
                })

            return response(200, results)

    except Exception as error:
        print(error)
        return response(500, {"error": "Unable to search meetings"})

    finally:
        connection.close()
