// Animações por tecla para o Ghostty.
// O shader só enxerga o cursor, então descobre a tecla pelo movimento dele:
//   Enter  → cursor desce de linha     → feixe roxo→azul na linha + anel no novo cursor
//   Apagar → cursor volta 1 casa       → a letra se desintegra em faíscas vermelhas/laranja
//   Espaço → avança 1 casa e fica vazio → ondulação verde-água no espaço
//   Letra  → avança 1 casa com texto   → brilho rosa suave no cursor
//   Salto  → cursor pula longe         → rastro rosa

const float DUR_ENTER  = 0.45;
const float DUR_DELETE = 0.40;
const float DUR_SPACE  = 0.40;
const float DUR_TYPE   = 0.18;
const float DUR_JUMP   = 0.30;

const vec3 PURPLE = vec3(0.776, 0.471, 0.867);
const vec3 BLUE   = vec3(0.357, 0.608, 1.000);
const vec3 RED    = vec3(1.000, 0.420, 0.420);
const vec3 ORANGE = vec3(0.953, 0.612, 0.420);
const vec3 TEAL   = vec3(0.180, 0.769, 0.714);
const vec3 GREEN  = vec3(0.659, 0.878, 0.388);
const vec3 PINK   = vec3(0.878, 0.365, 0.549);

float hash(float n) { return fract(sin(n * 12.9898) * 43758.5453); }

float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

// cursor: xy = canto superior esquerdo, zw = largura/altura (y cresce para cima)
vec2 cellCenter(vec4 c) { return c.xy + vec2(c.z, -c.w) * 0.5; }

// a casa está vazia se todos os pontos dela têm a mesma cor do canto (fundo)
bool cellIsBlank(vec4 c) {
    vec3 ref = texture(iChannel0, (c.xy + vec2(1.0, -1.0)) / iResolution.xy).rgb;
    float maxd = 0.0;
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 3; j++) {
            vec2 p = c.xy + vec2(c.z * (0.2 + 0.3 * float(j)), -c.w * (0.15 + 0.233 * float(i)));
            maxd = max(maxd, distance(texture(iChannel0, p / iResolution.xy).rgb, ref));
        }
    }
    return maxd < 0.06;
}

vec3 enterFx(vec2 fc, vec4 pc, vec2 cur, float h, float el) {
    float t = clamp(el / DUR_ENTER, 0.0, 1.0);
    float e = 1.0 - pow(1.0 - t, 3.0);
    float fade = 1.0 - t;
    // feixe que se abre para os lados a partir de onde o Enter foi apertado
    float rowY = pc.y - pc.w;
    float span = e * iResolution.x * 0.65;
    float dx = abs(fc.x - (pc.x + pc.z * 0.5));
    float beam = exp(-abs(fc.y - rowY) / (h * 0.07)) * smoothstep(span, span * 0.5, dx);
    vec3 beamCol = mix(PURPLE, BLUE, clamp(fc.x / iResolution.x, 0.0, 1.0));
    // anel que nasce no cursor da linha nova
    float r = e * h * 1.6;
    float ring = exp(-abs(length(fc - cur) - r) / (h * 0.07));
    return (beamCol * beam * 1.1 + PURPLE * ring * 0.8) * fade;
}

vec3 deleteFx(vec2 fc, vec2 c, float w, float h, float el) {
    float t = clamp(el / DUR_DELETE, 0.0, 1.0);
    float e = 1.0 - pow(1.0 - t, 2.0);
    float fade = 1.0 - t;
    // a casa apagada pisca em vermelho e encolhe
    vec2 q = abs(fc - c) / max(vec2(w, h) * 0.5 * fade, vec2(0.001));
    vec3 acc = RED * 0.35 * fade * step(max(q.x, q.y), 1.0);
    // faíscas saindo da letra apagada e caindo
    float seedBase = floor(iTimeCursorChange * 60.0);
    for (int i = 0; i < 14; i++) {
        float seed = float(i) + seedBase;
        float ang = hash(seed) * 6.2832;
        float sp = (0.5 + hash(seed + 3.1)) * h * 1.8;
        vec2 p = c + vec2(cos(ang), sin(ang)) * sp * e - vec2(0.0, h * 1.2 * t * t);
        float r = h * 0.09 * fade + 0.5;
        float d = length(fc - p);
        float s = smoothstep(r, r * 0.3, d) + exp(-d / (h * 0.12)) * 0.25;
        acc += mix(RED, ORANGE, hash(seed + 5.0)) * s * fade;
    }
    return acc;
}

vec3 spaceFx(vec2 fc, vec4 pc, float w, float h, float el) {
    float t = clamp(el / DUR_SPACE, 0.0, 1.0);
    float e = 1.0 - pow(1.0 - t, 3.0);
    float fade = 1.0 - t;
    vec2 c = cellCenter(pc);
    vec2 rel = fc - c;
    // duas ondas achatadas, como uma gota caindo na água
    float l = length(rel / vec2(1.6, 1.0));
    float ring = exp(-abs(l - e * h * 1.4) / (h * 0.06)) + 0.6 * exp(-abs(l - e * h * 0.8) / (h * 0.05));
    vec3 ringCol = mix(TEAL, GREEN, 0.5 + 0.5 * sin(atan(rel.y, rel.x) * 3.0 + t * 6.0));
    // linha brilhante embaixo do espaço que se estica
    float ul = exp(-abs(fc.y - (pc.y - pc.w)) / (h * 0.06)) * step(abs(fc.x - c.x), w * 0.5 + e * w * 1.5);
    return (ringCol * ring + TEAL * ul * 0.8) * fade;
}

vec3 typeFx(vec2 fc, vec2 cur, float h, float el) {
    float t = clamp(el / DUR_TYPE, 0.0, 1.0);
    return PINK * exp(-length(fc - cur) / (h * 0.45)) * 0.25 * (1.0 - t);
}

vec3 jumpFx(vec2 fc, vec2 prev, vec2 cur, float h, float el) {
    float t = clamp(el / DUR_JUMP, 0.0, 1.0);
    float fade = (1.0 - t) * (1.0 - t);
    float d = sdSegment(fc, mix(prev, cur, t), cur);
    float w = h * 0.35;
    float core = 1.0 - smoothstep(w * 0.5, w, d);
    return PINK * (core * 0.55 + exp(-d / (w * 1.5)) * 0.35) * fade;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 base = texture(iChannel0, fragCoord / iResolution.xy);
    fragColor = base;

    float el = iTime - iTimeCursorChange;
    if (el > 0.5 || iFocus == 0) return;

    vec4 cc = iCurrentCursor, pc = iPreviousCursor;
    vec2 cur = cellCenter(cc), prev = cellCenter(pc);
    float w = cc.z, h = cc.w;
    vec2 d = cur - prev;
    bool sameRow = abs(d.y) < 0.5 * h;

    vec3 fx = vec3(0.0);
    if (d.y < -0.5 * h) {
        fx = enterFx(fragCoord, pc, cur, h, el);
    } else if (sameRow && d.x < -0.5 * w && d.x > -2.5 * w) {
        fx = deleteFx(fragCoord, cur, w, h, el);
    } else if (sameRow && d.x > 0.5 * w && d.x < 1.5 * w) {
        fx = cellIsBlank(pc) ? spaceFx(fragCoord, pc, w, h, el) : typeFx(fragCoord, cur, h, el);
    } else if (length(d) > 1.5 * w) {
        fx = jumpFx(fragCoord, prev, cur, h, el);
    }

    vec3 col = clamp(base.rgb + fx, 0.0, 1.0);
    fragColor = vec4(col, max(base.a, clamp(max(fx.r, max(fx.g, fx.b)), 0.0, 1.0)));
}
