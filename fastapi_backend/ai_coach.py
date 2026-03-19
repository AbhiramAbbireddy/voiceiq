import os
import google.generativeai as genai
import re

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

# Adjust model string based on defaults in Spring application.yaml
GEMINI_MODEL_TXT = os.getenv("GEMINI_MODEL", "gemini-2.0-flash")


def _clamp(value: float, minimum: float = 0.0, maximum: float = 100.0) -> float:
    return max(minimum, min(maximum, value))


def _build_local_fallback_report(transcript: str, duration_seconds: int, reason: str):
    text = (transcript or "").strip()
    words = [word for word in re.findall(r"\b[\w']+\b", text)]
    word_count = len(words)
    duration = max(duration_seconds, 1)
    words_per_minute = int(round((word_count / duration) * 60))

    filler_matches = re.findall(r"\b(um|uh|like|you know|basically|actually)\b", text, flags=re.IGNORECASE)
    filler_count = len(filler_matches)

    sentences = [segment.strip() for segment in re.split(r"[.!?]+", text) if segment.strip()]
    avg_sentence_words = word_count / max(len(sentences), 1)

    pace_score = 82.0
    if words_per_minute < 90:
        pace_score = 62.0
    elif words_per_minute < 110:
        pace_score = 74.0
    elif words_per_minute > 175:
        pace_score = 64.0
    elif words_per_minute > 155:
        pace_score = 74.0

    clarity_score = 78.0
    if avg_sentence_words > 24:
        clarity_score -= 10.0
    if filler_count >= 4:
        clarity_score -= 8.0
    if word_count < 12:
        clarity_score -= 12.0

    confidence_score = 76.0
    tentative_matches = re.findall(r"\b(maybe|i think|kind of|sort of|probably)\b", text, flags=re.IGNORECASE)
    confidence_score -= len(tentative_matches) * 4.0
    confidence_score -= min(filler_count * 2.0, 10.0)

    grammar_score = 80.0
    if text and not re.search(r"[.!?]$", text):
        grammar_score -= 6.0
    if re.search(r"\bi\b", text) and not re.search(r"\bI\b", text):
        grammar_score -= 6.0
    if word_count < 10:
        grammar_score -= 8.0

    pace_score = _clamp(pace_score)
    clarity_score = _clamp(clarity_score)
    confidence_score = _clamp(confidence_score)
    grammar_score = _clamp(grammar_score)
    overall_score = round((pace_score + clarity_score + confidence_score + grammar_score) / 4.0, 1)

    comments = [
        f"Local fallback analysis was used because {reason}.",
        f"Your answer was about {word_count} words at roughly {words_per_minute} words per minute.",
    ]

    if filler_count > 0:
        comments.append(f"You used {filler_count} filler word{'s' if filler_count != 1 else ''}, so trimming those will make the answer sound sharper.")
    else:
        comments.append("You kept filler words low, which helps your response sound cleaner.")

    if words_per_minute < 90:
        comments.append("Try speaking a little faster and keeping your ideas moving.")
    elif words_per_minute > 175:
        comments.append("Slow down slightly so each point lands more clearly.")
    else:
        comments.append("Your speaking pace is in a reasonable range for interview answers.")

    if avg_sentence_words > 24:
        comments.append("Shorter sentences will make your thoughts easier to follow.")

    return {
        "overall_score": overall_score,
        "grammar_score": round(grammar_score, 1),
        "clarity_score": round(clarity_score, 1),
        "confidence_score": round(confidence_score, 1),
        "pace_score": round(pace_score, 1),
        "ai_comments": " ".join(comments),
    }

def analyze_transcript_with_gemini(transcript: str, duration_seconds: int):
    """
    Passes the Whisper transcript to Gemini for coaching feedback.
    Returns a dictionary of scores and an AI comment.
    """
    if not GEMINI_API_KEY:
        return _build_local_fallback_report(
            transcript,
            duration_seconds,
            "the Gemini API key is missing",
        )
        
    try:
        model = genai.GenerativeModel(GEMINI_MODEL_TXT)
        
        # System instructions asking it to act as an interviewer 
        prompt = f"""
        You are a professional communication coach. Analyze the following interview transcript. 
        The recording was {duration_seconds} seconds long.
        
        Evaluate the user on the following metrics (0-100 scale):
        1. Grammar & Vocabulary
        2. Clarity & Articulation
        3. Confidence
        4. Pace
        
        Also provide a single clear paragraph of constructive feedback (ai_comments).
        
        Return exactly and ONLY valid JSON matching this structure perfectly:
        {{
            "overall_score": 0.0,
            "grammar_score": 0.0,
            "clarity_score": 0.0,
            "confidence_score": 0.0,
            "pace_score": 0.0,
            "ai_comments": "string"
        }}
        
        Transcript: "{transcript}"
        """
        
        # Enforce JSON formatting heavily to prevent markdown blocks
        response = model.generate_content(
            prompt,
            generation_config={"response_mime_type": "application/json"}
        )
        
        import json
        return json.loads(response.text)
        
    except Exception as e:
        import logging
        logging.error(f"Gemini AI Coaching failed: {e}")
        return _build_local_fallback_report(
            transcript,
            duration_seconds,
            "the Gemini request failed",
        )
