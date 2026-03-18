import os
import google.generativeai as genai

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

# Adjust model string based on defaults in Spring application.yaml
GEMINI_MODEL_TXT = os.getenv("GEMINI_MODEL", "gemini-2.0-flash")

def analyze_transcript_with_gemini(transcript: str, duration_seconds: int):
    """
    Passes the Whisper transcript to Gemini for coaching feedback.
    Returns a dictionary of scores and an AI comment.
    """
    if not GEMINI_API_KEY:
        # Fallback if no key is present during dev
        return {
            "overall_score": 70.0,
            "grammar_score": 75.0,
            "clarity_score": 65.0,
            "confidence_score": 70.0,
            "pace_score": 80.0,
            "ai_comments": "Gemini API key missing. This is a mockup report. Provide a valid GEMINI_API_KEY to receive real AI coaching."
        }
        
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
        # Failure fallback
        return {
            "overall_score": 0.0, "grammar_score": 0.0, "clarity_score": 0.0, 
            "confidence_score": 0.0, "pace_score": 0.0, 
            "ai_comments": "AI analysis failed temporarily. Please try again."
        }
