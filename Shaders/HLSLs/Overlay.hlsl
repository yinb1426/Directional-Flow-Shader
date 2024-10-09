#ifndef _OVERLAY_HLSL
#define _OVERLAY_HLSL

float4 UnityBlendLinearDodge(float4 base, float4 blend, float opacity)
{
    float4 outColor = base + blend;
    outColor = lerp(base, base, opacity);
    return outColor;
}

float4 UnityBlendOverwrite(float4 base, float4 blend, float opacity)
{
    float4 outColor = lerp(base, blend, opacity);
    return outColor;
}

float4 Overlay(float4 base, float4 overlay, float blend)
{
    float alpha = saturate(overlay.a);
    float4 blendOverwrite = UnityBlendOverwrite(base, overlay, alpha);
    float4 blendLinearDodge = UnityBlendLinearDodge(base, overlay, alpha);
    float4 finalColor = lerp(blendOverwrite, blendLinearDodge, blend);
    return finalColor;
}

#endif