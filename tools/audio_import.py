"""Turn raw generated audio into game-ready Ogg Vorbis (57, 58, 59).

Usage: uv run --with imageio-ffmpeg python tools/audio_import.py <out_dir>
           [--peak -3] [--loudness -18] [--loop] [--keep-silence] <file.mp3> [...]

Each input becomes <out_dir>/<same name>.ogg: leading and trailing silence
cut (unless --loop or --keep-silence, since a loop must keep its length),
peak normalized to --peak dBFS, or with --loudness to that integrated
loudness in LUFS (voices, so every speaker sounds as loud). With --loop,
the Godot .import file is written with looping on, so the stream repeats
seamlessly.
"""

import argparse
import os
import re
import subprocess

import imageio_ffmpeg

FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
TRIM = (
    "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.02,"
    "areverse,silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.08,areverse"
)
IMPORT_TEMPLATE = """[remap]

importer="oggvorbisstr"
type="AudioStreamOggVorbis"

[params]

loop={loop}
loop_offset=0
bpm=0
beat_count=0
bar_beats=4
"""


def max_volume(path: str, filters: str) -> float:
    command = [FFMPEG, "-hide_banner", "-i", path, "-af", (filters + "," if filters else "") + "volumedetect", "-f", "null", "-"]
    output = subprocess.run(command, capture_output=True, text=True).stderr
    match = re.search(r"max_volume: (-?[\d.]+) dB", output)
    return float(match.group(1)) if match else 0.0


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("out_dir")
    parser.add_argument("files", nargs="+")
    parser.add_argument("--peak", type=float, default=-3.0)
    parser.add_argument("--loudness", type=float, default=None)
    parser.add_argument("--loop", action="store_true")
    parser.add_argument("--keep-silence", action="store_true")
    args = parser.parse_args()
    os.makedirs(args.out_dir, exist_ok=True)
    for path in args.files:
        filters = "" if args.loop or args.keep_silence else TRIM
        if args.loudness is not None:
            gain = 0.0
            chain = (filters + "," if filters else "") + "loudnorm=I=%.1f:TP=-1.5:LRA=11" % args.loudness
        else:
            gain = args.peak - max_volume(path, filters)
            chain = (filters + "," if filters else "") + "volume=%.2fdB" % gain
        out = os.path.join(args.out_dir, os.path.splitext(os.path.basename(path))[0] + ".ogg")
        # loudnorm resamples to 192 kHz: back to 44.1 kHz.
        subprocess.run([FFMPEG, "-hide_banner", "-loglevel", "error", "-y", "-i", path, "-af", chain,
                        "-ar", "44100", "-c:a", "libvorbis", "-q:a", "5", out], check=True)
        if args.loop:
            with open(out + ".import", "w") as file:
                file.write(IMPORT_TEMPLATE.format(loop="true"))
        print("%s gain %+.1f dB%s" % (out, gain, " loop" if args.loop else ""))


if __name__ == "__main__":
    main()
