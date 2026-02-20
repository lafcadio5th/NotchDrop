//
//  LiquidShader.metal
//  NotchDrop
//
//  Created by Kelvin Tan on 2026/2/20.
//

#include <metal_stdlib>
using namespace metal;

struct LiquidUniforms {
    float progress;
    float time;
    float2 viewSize;
    float2 notchSize;
    float2 expandedSize;
    float cornerRadius;
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

// Full-screen quad vertex shader
vertex VertexOut vertexShader(uint vertexID [[vertex_id]]) {
    float2 positions[4] = {
        float2(-1, -1), float2(1, -1),
        float2(-1, 1), float2(1, 1)
    };

    VertexOut out;
    out.position = float4(positions[vertexID], 0, 1);
    out.uv = (positions[vertexID] + 1.0) * 0.5;
    out.uv.y = 1.0 - out.uv.y; // Flip Y for screen coords
    return out;
}

// Signed distance function for rounded rectangle
float sdRoundedRect(float2 p, float2 size, float radius) {
    float2 d = abs(p) - size + radius;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - radius;
}

// Spring-like easing with slight overshoot for organic feel
float springEase(float t) {
    float c4 = (2.0 * M_PI_F) / 3.0;
    if (t <= 0.0) return 0.0;
    if (t >= 1.0) return 1.0;
    return pow(2.0, -10.0 * t) * sin((t * 10.0 - 0.75) * c4) + 1.0;
}

fragment float4 liquidFragment(VertexOut in [[stage_in]],
                                constant LiquidUniforms &uniforms [[buffer(0)]]) {
    float2 uv = in.uv;
    float2 pixelPos = uv * uniforms.viewSize;

    // Center coordinates (origin at top-center of view)
    float2 center = float2(uniforms.viewSize.x * 0.5, 0);
    float2 pos = pixelPos - center;

    // Apply spring easing to progress
    float p = springEase(uniforms.progress);

    // Interpolate size from notch to expanded
    float currentWidth = mix(uniforms.notchSize.x, uniforms.expandedSize.x, p);
    float currentHeight = mix(uniforms.notchSize.y, uniforms.expandedSize.y, p);

    // Liquid organic wobble -- subtle sine displacement based on y position and time
    float wobbleAmount = sin(uniforms.progress * M_PI_F) * 3.0; // Max wobble at mid-animation
    float wobble = sin(pos.y * 0.05 + uniforms.time * 8.0) * wobbleAmount;
    pos.x += wobble;

    // Corner radius: square at top (connected to notch), rounded at bottom
    float topRadius = 0.0; // Square top corners
    float bottomRadius = mix(uniforms.cornerRadius * 0.5, uniforms.cornerRadius, p);

    // SDF for the shape -- offset pos to start from top
    float2 rectCenter = float2(0, currentHeight * 0.5);
    float2 rectPos = pos - rectCenter;

    // Use different radii for top vs bottom
    float radius = rectPos.y < 0 ? topRadius : bottomRadius;
    float dist = sdRoundedRect(rectPos, float2(currentWidth * 0.5, currentHeight * 0.5), radius);

    // Anti-aliased edge
    float alpha = 1.0 - smoothstep(-1.0, 1.0, dist);

    // Dark fill color with subtle gradient
    float3 baseColor = float3(0.04, 0.04, 0.047);

    // Subtle shimmer effect on the surface
    float shimmer = sin(pos.x * 0.02 + pos.y * 0.015 + uniforms.time * 2.0) * 0.5 + 0.5;
    shimmer *= sin(uniforms.progress * M_PI_F) * 0.03; // Only during animation
    float3 color = baseColor + shimmer;

    // Edge highlight (subtle glass-like refraction)
    float edgeDist = abs(dist);
    float edgeGlow = exp(-edgeDist * 0.8) * 0.15 * p;
    color += float3(0.2, 0.4, 0.8) * edgeGlow; // Blue-ish edge glow

    return float4(color, alpha * 0.97);
}
