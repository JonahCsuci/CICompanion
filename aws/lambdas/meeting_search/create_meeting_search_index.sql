CREATE TABLE IF NOT EXISTS meeting_search_index (
  message_id BIGINT UNSIGNED NOT NULL,
  conversation_id BIGINT UNSIGNED NOT NULL,
  meeting_scheduler_id VARCHAR(36) DEFAULT NULL,
  title VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (message_id),
  KEY idx_meeting_search_conversation_created (conversation_id, created_at, message_id),
  FULLTEXT KEY ft_meeting_search_title (title),
  CONSTRAINT fk_meeting_search_message
    FOREIGN KEY (message_id) REFERENCES messages (id)
    ON DELETE CASCADE,
  CONSTRAINT fk_meeting_search_conversation
    FOREIGN KEY (conversation_id) REFERENCES conversations (id)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
