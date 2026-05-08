from dataclasses import dataclass
from typing import List, Dict, Any, Optional
import os
import requests

@dataclass
class RedditSourceConfig:
    subreddit: str
    query: str
    since_utc: int
    until_utc: int

class RedditClient:
    """
    -Reddit's API wrapper

    it can be unit tested with a fake HTTP client.
    """

    def __init__(
        self,
        http: Optional[requests.Session] = None,
        token: Optional=str(None),
        base_url: Optional[str] = None,
    ):
        self._http = http or requests.Session()
        self._token = token or os.getenv("REDDIT_TOKEN", "")
        self._base_url = base_url or os.getenv("REDDIT_API_BASE_URL", "https://oauth.reddit.com")

    def fetch_posts(self, cfg: RedditSourceConfig) -> List[Dict[str, Any]]:
        """
        Fetch posts for a given source config.

        V1: simple listing search per subreddit.

        NOTE: In production you'll want to respect official API docs and rate limits.
        For tests, we use a DummyHTTP that returns a stable JSON structure.
        """
        url = f"{self._base_url}/r/{cfg.subreddit}/search"
        headers = {}
        if self._token:
            headers["Authorization"] = f"Bearer {self._token}"
        params = {
            "q": cfg.query,
            "restrict_sr": "on",
            "sort": "new",
            "limit": 100,
        }

        resp = self._http.get(url, headers=headers, params=params, timeout=10)
        if hasattr(resp, "raise_for_status"):
            resp.raise_for_status()

        payload = resp.json()
        children = payload.get("data", {}).get("children", [])
        posts: List[Dict[str, Any]] = []

        for child in children:
            data = child.get("data", {})
            posts.append(
                {
                    "id": data.get("id"),
                    "title": data.get("title", ""),
                    "body": data.get("selftext", ""),
                    "score": data.get("score", 0),
                    "num_comments": data.get("num_comments", 0),
                    "subreddit": data.get("subreddit", cfg.subreddit),
                    "created_utc": data.get("created_utc"),
                }
            )

        return posts