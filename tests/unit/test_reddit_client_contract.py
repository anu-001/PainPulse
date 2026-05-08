# tests/unit/test_reddit_client_contract.py

from ingestion.reddit_client import RedditClient, RedditSourceConfig


class DummyResponse:
    def __init__(self, data, status_code=200):
        self._data = data
        self.status_code = status_code

    def json(self):
        return self._data

    def raise_for_status(self):
        if not (200 <= self.status_code < 300):
            raise Exception(f"HTTP {self.status_code}")


class DummyHTTP:
    def __init__(self, response_data, status_code=200):
        self._response_data = response_data
        self._status_code = status_code
        self.get_calls = []

    def get(self, url, headers=None, params=None, timeout=None):
        self.get_calls.append((url, params))
        return DummyResponse(self._response_data, self._status_code)


def test_fetch_posts_flattens_reddit_listing_response():
    api_payload = {
        "data": {
            "children": [
                {
                    "data": {
                        "id": "abc123",
                        "title": "I wish there was a tool for invoices",
                        "selftext": "Reconciling invoices sucks",
                        "score": 42,
                        "num_comments": 7,
                        "subreddit": "smallbusiness",
                        "created_utc": 1715123456,
                    }
                }
            ]
        }
    }

    http = DummyHTTP(api_payload)
    client = RedditClient(http=http, token="dummy-token")
    cfg = RedditSourceConfig(
        subreddit="smallbusiness", query="tool", since_utc=1715100000, until_utc=1715200000
    )

    posts = client.fetch_posts(cfg)

    assert len(posts) == 1
    p = posts[0]
    assert p["id"] == "abc123"
    assert p["title"].startswith("I wish there was a tool")
    assert p["body"] == "Reconciling invoices sucks"
    assert p["score"] == 42
    assert p["num_comments"] == 7
    assert p["subreddit"] == "smallbusiness"
    assert p["created_utc"] == 1715123456