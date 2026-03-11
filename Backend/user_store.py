import os
import sqlite3
from typing import Iterable, List, Optional, Sequence, Tuple


def _ensure_db(base_path: str) -> str:
    """
    Ensure the user store database exists inside base_path and return its path.
    """
    if not base_path:
        raise ValueError("Storage path is not configured.")
    os.makedirs(base_path, exist_ok=True)
    db_path = os.path.join(base_path, "users.db")

    with sqlite3.connect(db_path) as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS users (
                username TEXT PRIMARY KEY,
                password TEXT NOT NULL
            )
            """
        )
        connection.commit()

    return db_path


def list_users(base_path: str) -> List[str]:
    db_path = _ensure_db(base_path)
    with sqlite3.connect(db_path) as connection:
        cursor = connection.cursor()
        cursor.execute("SELECT username FROM users ORDER BY username COLLATE NOCASE")
        return [row[0] for row in cursor.fetchall()]


def get_user_password(base_path: str, username: str) -> Optional[str]:
    db_path = _ensure_db(base_path)
    with sqlite3.connect(db_path) as connection:
        cursor = connection.cursor()
        cursor.execute("SELECT password FROM users WHERE username = ?", (username,))
        row = cursor.fetchone()
        return row[0] if row else None


def add_user(base_path: str, username: str, password: str) -> None:
    db_path = _ensure_db(base_path)
    with sqlite3.connect(db_path) as connection:
        cursor = connection.cursor()
        cursor.execute(
            "INSERT INTO users (username, password) VALUES (?, ?)",
            (username, password),
        )
        connection.commit()


def remove_user(base_path: str, username: str) -> None:
    db_path = _ensure_db(base_path)
    with sqlite3.connect(db_path) as connection:
        cursor = connection.cursor()
        cursor.execute("DELETE FROM users WHERE username = ?", (username,))
        connection.commit()


def seed_legacy_users(
    base_path: str, entries: Sequence[Tuple[str, str]]
) -> None:
    """
    Populate the user store with legacy entries (if they do not already exist).
    """
    if not entries:
        return
    db_path = _ensure_db(base_path)
    with sqlite3.connect(db_path) as connection:
        cursor = connection.cursor()
        cursor.executemany(
            "INSERT OR IGNORE INTO users (username, password) VALUES (?, ?)",
            entries,
        )
        connection.commit()

