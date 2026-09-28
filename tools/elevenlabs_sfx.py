"""Generate sound effects with ElevenLabs from a JSON list (127).

Usage: python3 tools/elevenlabs_sfx.py <list.json> <out_dir>

The list holds objects {"name", "text", "duration", "loop"?, "influence"?}.
Existing files are skipped, so a rerun only fills the gaps. The key comes
from $ELEVENLABS_API_KEY and is never printed. At most two requests run at
once (the account limit). Prints one line per effect with the credits read
from the character-cost header, then a CSV-ready summary.
"""

import json
import os
import sys
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor

URL = "https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128"
MODEL = "eleven_text_to_sound_v2"


def generate(effect: dict, out_dir: str) -> tuple[str, str, str]:
    path = os.path.join(out_dir, effect["name"] + ".mp3")
    if os.path.exists(path):
        return effect["name"], "skipped", ""
    body = {
        "text": effect["text"],
        "duration_seconds": effect["duration"],
        "prompt_influence": effect.get("influence", 0.5),
        "model_id": MODEL,
    }
    if effect.get("loop"):
        body["loop"] = True
    request = urllib.request.Request(URL, data=json.dumps(body).encode(), method="POST")
    request.add_header("xi-api-key", os.environ["ELEVENLABS_API_KEY"])
    request.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(request, timeout=300) as response:
            data = response.read()
            cost = response.headers.get("character-cost", "?")
    except urllib.error.HTTPError as error:
        return effect["name"], "error %d" % error.code, error.read().decode()[:200]
    with open(path, "wb") as file:
        file.write(data)
    return effect["name"], "ok", cost


def main() -> None:
    effects = json.load(open(sys.argv[1]))
    out_dir = sys.argv[2]
    os.makedirs(out_dir, exist_ok=True)
    total = 0
    with ThreadPoolExecutor(max_workers=2) as pool:
        for name, status, detail in pool.map(lambda effect: generate(effect, out_dir), effects):
            print(name, status, detail)
            if status == "ok" and detail.isdigit():
                total += int(detail)
    print("TOTAL credits", total)


if __name__ == "__main__":
    main()
