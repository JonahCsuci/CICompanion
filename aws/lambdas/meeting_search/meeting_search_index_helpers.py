import base64
import json


def decode_meeting_scheduler(body):
    try:
        decoded = base64.b64decode(body, validate=True).decode("utf-8")
        payload = json.loads(decoded)
    except Exception:
        return None

    required_fields = {"id", "conversationID", "title", "daysAllowed", "startTime", "endTime"}
    if not required_fields.issubset(payload.keys()):
        return None

    title = str(payload.get("title") or "").strip()
    if not title:
        return None

    return {
        "id": str(payload.get("id")),
        "title": title,
    }


def sync_meeting_search_index(cursor, message_id, conversation_id, body):
    meeting = decode_meeting_scheduler(body)

    if meeting is None:
        cursor.execute(
            "DELETE FROM meeting_search_index WHERE message_id = %s",
            (message_id,),
        )
        return

    cursor.execute(
        """
        INSERT INTO meeting_search_index (
          message_id,
          conversation_id,
          meeting_scheduler_id,
          title
        )
        VALUES (%s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE
          conversation_id = VALUES(conversation_id),
          meeting_scheduler_id = VALUES(meeting_scheduler_id),
          title = VALUES(title)
        """,
        (message_id, conversation_id, meeting["id"], meeting["title"]),
    )
