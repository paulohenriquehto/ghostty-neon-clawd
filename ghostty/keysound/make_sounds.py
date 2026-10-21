# Sintetiza sons de teclado mecânico (sem baixar nada): clique + "thock" do gabinete + soltura da tecla
import math, random, struct, wave, os, sys
SR = 44100
out = sys.argv[1]

def bandpass(x, f, q):
    w = 2 * math.pi * f / SR; a = math.sin(w) / (2 * q); c = math.cos(w)
    b0, b2, a0, a1, a2 = a, -a, 1 + a, -2 * c, 1 - a
    y = []; x1 = x2 = y1 = y2 = 0.0
    for s in x:
        v = (b0 * s + b2 * x2 - a1 * y1 - a2 * y2) / a0
        x2, x1, y2, y1 = x1, s, y1, v; y.append(v)
    return y

def key(seed, click_f, thump_f, body, length=0.11, release=0.055, gain=1.0):
    rnd = random.Random(seed); n = int(SR * length)
    noise = [rnd.uniform(-1, 1) for _ in range(n)]
    click = bandpass(noise, click_f, 1.8)
    case = bandpass(noise, body, 1.2)
    sig = []
    for i in range(n):
        t = i / SR
        s = click[i] * 1.6 * math.exp(-t / 0.004)
        s += case[i] * 1.2 * math.exp(-t / 0.018)
        s += 0.55 * math.sin(2 * math.pi * thump_f * (1 - 0.3 * t / length) * t) * math.exp(-t / 0.022)
        tr = t - release
        if tr > 0:  # tecla voltando
            s += click[i] * 0.5 * math.exp(-tr / 0.003) + case[i] * 0.35 * math.exp(-tr / 0.010)
        sig.append(s)
    peak = max(abs(v) for v in sig)
    return [v / peak * 0.85 * gain for v in sig]

def save(name, sig):
    with wave.open(os.path.join(out, name), 'w') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, v)) * 32767)) for v in sig))

for i in range(4):
    save(f'key{i}.wav', key(i, 2600 + i * 180, 190 + i * 12, 900 + i * 60))
save('space.wav', key(10, 1700, 120, 520, length=0.14, release=0.07))
save('enter.wav', key(20, 1900, 135, 600, length=0.14, release=0.065))
save('back.wav', key(30, 3100, 230, 1100, gain=0.9))
