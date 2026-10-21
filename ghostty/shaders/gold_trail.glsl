// Rastro dourado do cursor — aparece quando o cursor pula e some em ~0.3s
const vec3 GOLD = vec3(0.878, 0.365, 0.549); // rosa do prompt
const float DURATION = 0.30;

float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 base = texture(iChannel0, fragCoord / iResolution.xy);
    vec2 cur  = iCurrentCursor.xy  + vec2(iCurrentCursor.z,  -iCurrentCursor.w)  * 0.5;
    vec2 prev = iPreviousCursor.xy + vec2(iPreviousCursor.z, -iPreviousCursor.w) * 0.5;

    float t = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
    float fade = (1.0 - t) * (1.0 - t);

    // ignora movimentos curtos (digitação normal) para não poluir
    if (length(cur - prev) < iCurrentCursor.z * 1.5 || fade <= 0.0) {
        fragColor = base;
        return;
    }

    vec2 tail = mix(prev, cur, t);
    float d = sdSegment(fragCoord, tail, cur);
    float w = iCurrentCursor.w * 0.35;
    float core = 1.0 - smoothstep(w * 0.5, w, d);
    float glow = exp(-d / (w * 1.5)) * 0.35;
    float a = clamp((core * 0.55 + glow) * fade, 0.0, 1.0);
    fragColor = vec4(mix(base.rgb, GOLD, a), base.a);
}
