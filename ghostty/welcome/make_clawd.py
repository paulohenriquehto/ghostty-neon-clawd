# Gera os quadros do Clawd (mascote do Claude Code) em pixel art com meio-blocos ▀▄.
# Saída:
#   clawd-logo.txt   → primeiro quadro, usado como logo do fastfetch
#   clawd-frames.bin → quadros prontos para desenhar por cima do logo (separados por \x1e)
import math, os

OUT = os.path.dirname(os.path.abspath(__file__))
W, H = 46, 34            # tela em "pixels": 46 colunas x 34 meias-linhas (= 17 linhas)
TOP_PAD = 4              # linhas vazias acima do Clawd (centraliza ao lado das caixas)
ROW0, COL0 = 1 + TOP_PAD, 3   # onde o logo começa no terminal (1-based), padding esquerdo = 2
FRAMES = 40
PX, PY = 2, 4            # cada pixel do logo vira 2x4 (no logo original o pixel é alto)

ORANGE = (217, 119, 87)
LIGHT  = (234, 145, 112)
DARK   = (186, 92, 62)
LEG    = (170, 82, 55)
EYE    = (35, 22, 18)
SHADOW = (58, 63, 75)
SPARK  = [(246, 211, 101), (224, 93, 140), (217, 119, 87), (46, 196, 182)]

def frame(f):
    px = [[None] * W for _ in range(H)]
    def rect(x0, y0, w, h, color):
        for y in range(y0, y0 + h):
            for x in range(x0, x0 + w):
                if 0 <= x < W and 0 <= y < H:
                    px[y][x] = color

    ph = 2 * math.pi * f / FRAMES
    sway = round(2 * math.sin(ph))
    bob = round(1.4 * math.sin(2 * ph))            # sobe e desce 2x por ciclo
    ox, oy = 4 + sway, 10 - bob
    ground = 10 + 5 * PY                             # base fixa dos pés

    # sombra no chão (encolhe quando ele sobe)
    sw = 22 - 3 * bob
    rect(4 + 18 - sw // 2 + sway, ground + 1, sw, 1, SHADOW)

    # pernas: andam no lugar (pares alternados levantam)
    lift_a = max(0, round(3 * math.sin(ph)))
    lift_b = max(0, round(-3 * math.sin(ph)))
    body_bottom = oy + 4 * PY
    for col, lift in ((4, lift_a), (6, lift_b), (11, lift_a), (13, lift_b)):
        foot = ground - lift
        rect(ox + col * PX, body_bottom, PX, foot - body_bottom, LEG)

    # corpo
    bx, bw = ox + 3 * PX, 12 * PX
    rect(bx, oy, bw, 4 * PY, ORANGE)
    rect(bx, oy, bw, 2, LIGHT)
    rect(bx, oy + 4 * PY - 2, bw, 2, DARK)

    # braços: balançam; no fim do ciclo o direito acena
    arm_l = round(2 * math.sin(2 * ph + 1))
    if f >= 24:
        arm_r = -11 + round(2.5 * math.sin((f - 24) * 1.6))
    else:
        arm_r = round(2 * math.sin(2 * ph + 1 + math.pi))
    rect(ox + 1 * PX, oy + 2 * PY + arm_l, 2 * PX, PY, ORANGE)
    rect(ox + 15 * PX, oy + 2 * PY + arm_r, 2 * PX, PY, ORANGE)

    # olhos: olham para o lado do balanço e piscam
    look = 1 if sway > 0 else (-1 if sway < 0 else 0)
    blink = f in (8, 9, 31)
    for col in (5, 12):
        ex, ey = ox + col * PX + look, oy + PY
        if blink:
            rect(ex, ey + 3, PX, 1, EYE)
        else:
            rect(ex, ey, PX, PY, EYE)
    return px

SPARKS = [(2, 1, "✦"), (40, 0, "✧"), (44, 3, "⋆"), (0, 8, "·"), (34, 1, "·")]

def render(px, f):
    rows = []
    for r in range(H // 2):
        out, last = [], None
        for x in range(W):
            t, b = px[2 * r][x], px[2 * r + 1][x]
            spark = next((s for s in SPARKS if s[0] == x and s[1] == r), None)
            if t is None and b is None:
                if spark and (f // 5 + SPARKS.index(spark)) % 3:
                    c = SPARK[(f // 5 + SPARKS.index(spark)) % len(SPARK)]
                    out.append("\x1b[0;38;2;%d;%d;%dm" % c + spark[2]); last = None
                    continue
                code, ch = "\x1b[0m", " "
            elif t == b:
                code, ch = "\x1b[0;38;2;%d;%d;%dm" % t, "█"
            elif b is None:
                code, ch = "\x1b[0;38;2;%d;%d;%dm" % t, "▀"
            elif t is None:
                code, ch = "\x1b[0;38;2;%d;%d;%dm" % b, "▄"
            else:
                code, ch = "\x1b[0;38;2;%d;%d;%d;48;2;%d;%d;%dm" % (t + b), "▀"
            if code != last:
                out.append(code); last = code
            out.append(ch)
        out.append("\x1b[0m")
        rows.append("".join(out))
    return rows

def main():
    frames = [render(frame(f), f) for f in range(FRAMES)]

    with open(os.path.join(OUT, "clawd-logo.txt"), "w", encoding="utf-8") as fh:
        fh.write("\n" * TOP_PAD + "\n".join(frames[0]) + "\n")

    payloads = []
    for rows in frames:
        # sincronizado (modo 2026) para o Ghostty desenhar o quadro inteiro de uma vez
        p = "\x1b[?2026h\x1b7" + "".join("\x1b[%d;%dH%s" % (ROW0 + i, COL0, row) for i, row in enumerate(rows))
        payloads.append(p + "\x1b8\x1b[?2026l")
    with open(os.path.join(OUT, "clawd-frames.bin"), "w", encoding="utf-8") as fh:
        fh.write("\x1e".join(payloads))

if __name__ == "__main__":
    main()
