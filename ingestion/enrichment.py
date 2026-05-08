from typing import Iterable, List
import re

from nltk.sentiment.vader import SentimentIntensityAnalyzer


def matches_patterns(text: str, patterns: Iterable[str]) -> bool:
    """
    Return True if any configured regex pattern matches the text, case-insensitive.
    """
    if not text:
        return False

    lowered = text.lower()
    for pat in patterns:
        if re.search(pat.lower(), lowered):
            return True
    return False


_sia = SentimentIntensityAnalyzer()


def compute_sentiment(text: str) -> float:
    """
    Compute a simple sentiment score using VADER compound score.
    Returns value in [-1.0, 1.0].
    """
    if not text:
        return 0.0
    scores = _sia.polarity_scores(text)
    return float(scores.get("compound", 0.0))


def compute_engagement(score: int, num_comments: int) -> float:
    """
    Simple engagement heuristic: weighted sum of score and num_comments.
    You can refine this later.
    """
    return float(score) + 2.0 * float(num_comments)