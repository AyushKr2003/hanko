#!/usr/bin/env python3
# hanko-sounds · Oto 音 (docs/kaze, mockup 13): synthesise Kaze's six sounds
# into assets/sounds/*.ogg. Stand-ins until recordings replace them: a sheath
# click, hyoshigi clappers, paper, a small bell, a brush, a temple bell.
# Pure Python (wave, math, random) plus ffmpeg for the Opus encode.
#   python3 scripts/hanko-sounds.py
import math, os, random, struct, subprocess, tempfile, wave

RATE = 48000
PEAK = 10 ** (-16 / 20)   # every sound peaks at -16 dBFS: quiet beside anything else
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sounds")
rnd = random.Random(7)

def render(seconds, f):
    n = int(seconds * RATE)
    xs = [f(i / RATE) for i in range(n)]
    # a 15% fade at the end so nothing clicks off
    for i in range(int(n * 0.85), n):
        xs[i] *= (n - i) / (n * 0.15)
    top = max(1e-9, max(abs(x) for x in xs))
    return [x / top * PEAK for x in xs]

def lowpass(xs, cutoff):
    a = math.exp(-2 * math.pi * cutoff / RATE); y = 0; out = []
    for x in xs:
        y = (1 - a) * x + a * y; out.append(y)
    return out

def highpass(xs, cutoff):
    lo = lowpass(xs, cutoff)
    return [x - l for x, l in zip(xs, lo)]

def noise(seconds):
    return [rnd.uniform(-1, 1) for _ in range(int(seconds * RATE))]

S = math.sin; P = 2 * math.pi
sounds = {}

# 納 sheath: a soft slide, then one bright click
slide = lowpass(noise(0.13), 3000)
sounds["noto"] = render(0.13, lambda t: 0.25 * slide[int(t * RATE)] * math.exp(-((t - 0.05) / 0.03) ** 2)
                        + (0.6 * (S(P * 3200 * t) + 0.5 * S(P * 5100 * t)) * math.exp(-(t - 0.085) * 60) if t >= 0.085 else 0))
# 拍子木 hyoshigi: one strike of two hardwood blocks
knock = noise(0.09)
sounds["hyoshigi"] = render(0.09, lambda t: (S(P * 1100 * t) + 0.6 * S(P * 2300 * t) + 0.4 * knock[int(t * RATE)]) * math.exp(-t * 90))
# 紙 paper: a strip of washi unrolling
paper = highpass(lowpass(noise(0.22), 7000), 1800)
sounds["kami"] = render(0.22, lambda t: paper[int(t * RATE)] * S(math.pi * t / 0.22) ** 2)
# 鈴 suzu: a small bell, struck once
sounds["suzu"] = render(0.24, lambda t: (S(P * 1870 * t) + 0.7 * S(P * 4420 * t) + 0.4 * S(P * 6230 * t)) * math.exp(-t * 14) * (1 - math.exp(-t * 400)))
# 墨 ink: a wet brush touching paper
brush = highpass(lowpass(noise(0.16), 1600), 200)
sounds["sumi"] = render(0.16, lambda t: brush[int(t * RATE)] * S(math.pi * t / 0.16) * math.exp(-t * 6))
# 鐘 bell: a distant temple bell, already fading in
f0 = 196
sounds["kane"] = render(1.2, lambda t: (S(P * f0 * t) + 0.6 * S(P * f0 * 2.01 * t) + 0.35 * S(P * f0 * 2.76 * t) + 0.2 * S(P * f0 * 5.4 * t))
                        * math.exp(-t * 2.6) * (1 - math.exp(-t * 30)))

os.makedirs(OUT, exist_ok=True)
for name, xs in sounds.items():
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        path = tmp.name
    with wave.open(path, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, x)) * 32767)) for x in xs))
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", path, "-c:a", "libopus", "-b:a", "64k", os.path.join(OUT, name + ".ogg")], check=True)
    os.unlink(path)
    print(name, "%.2fs" % (len(xs) / RATE))
