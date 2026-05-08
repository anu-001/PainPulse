# ingestion/reddit_client.py

from dataclasses import dataclass
from typing import List, Dict, Any
import requests


@dataclass
class RedditSourceConfig:
    subreddit: str
    query: str
    since_utc: int
    until_utc: int


class RedditClient:
    """
    Thin wrapper around Reddit's API.

    Airflow DAGs call into this class; it has no Airflow dependencies
    and can be unit tested in isolation.
    """

    def __init__(self, http: requests.Session, token: str):
        self._http = http
        self._token = token

    def fetch_posts(self, cfg: RedditSourceConfig) -> List[Dict[str, Any]]:
        """
        Fetch posts for a given source config. Implementation will be added later.

        For now, raise NotImplementedError to force tests to drive the design.
        """
        raise NotImplementedError("fetch_posts not implemented yet")