#ifndef _FLOW_CELL_HLSL
#define _FLOW_CELL_HLSL

float2 GetFlowDirection(Texture2D flowMapBefore, SamplerState samplerFlowMapBefore, Texture2D flowMapAfter, SamplerState samplerFlowMapAfter,
                        float lerpValue, float2 uv, float2 offset, float gridResolution)
{
    uv *= gridResolution;
    float2 offset1 = offset * 0.5;
    float2 offset2 = (1.0 - offset) * 0.5;
    uv = floor(uv + offset1);
    uv += offset2;
    uv /= gridResolution;
    float2 directionBefore = SAMPLE_TEXTURE2D(flowMapBefore, samplerFlowMapBefore, uv).rg;
    float2 directionAfter = SAMPLE_TEXTURE2D(flowMapAfter, samplerFlowMapAfter, uv).rg;
    float2 direction = lerp(directionBefore, directionAfter, lerpValue);
    direction = (direction * 2) - 1;
    return direction;
}

float2 RotateUV(float2 direction, float2 uv, float gridResolution, float flowVelocityStrength, float wavePeriod)
{
    float2 unitDir = normalize(direction);
    float2x2 rotationMatrix = float2x2(unitDir.y, -unitDir.x, unitDir.x, unitDir.y); 
    float2 newUV = mul(rotationMatrix, uv);

    float dirLength = length(direction);
    dirLength *= flowVelocityStrength;
    float strength = _Time.y * dirLength;

    newUV = newUV * (gridResolution * wavePeriod) - float2(0, strength);
    return newUV;
}

void FlowCell(Texture2D flowMapBefore, SamplerState samplerFlowMapBefore,
              Texture2D flowMapAfter, SamplerState samplerFlowMapAfter,
              Texture2D normalMap, SamplerState samplerNormalMap,
              Texture2D displacementMap, SamplerState samplerDisplacementMap,
              Texture2D heightNoiseMap, SamplerState samplerHeightNoiseMap,
              float lerpValue, float2 uv, float gridResolution, float flowVelocityStrength, float wavePeriod,
              out float3 finalNormal, out float finalDisplacement)
{
    float2 dir1 = GetFlowDirection(flowMapBefore, samplerFlowMapBefore, flowMapAfter, samplerFlowMapAfter, lerpValue, uv, float2(0.0, 0.0), gridResolution);
    float2 dir2 = GetFlowDirection(flowMapBefore, samplerFlowMapBefore, flowMapAfter, samplerFlowMapAfter, lerpValue, uv, float2(1.0, 0.0), gridResolution);
    float2 dir3 = GetFlowDirection(flowMapBefore, samplerFlowMapBefore, flowMapAfter, samplerFlowMapAfter, lerpValue, uv, float2(0.0, 1.0), gridResolution);
    float2 dir4 = GetFlowDirection(flowMapBefore, samplerFlowMapBefore, flowMapAfter, samplerFlowMapAfter, lerpValue, uv, float2(1.0, 1.0), gridResolution);

    float2 newUV1 = RotateUV(dir1, uv, gridResolution, flowVelocityStrength, wavePeriod);
    float2 newUV2 = RotateUV(dir2, uv, gridResolution, flowVelocityStrength, wavePeriod);
    float2 newUV3 = RotateUV(dir3, uv, gridResolution, flowVelocityStrength, wavePeriod);
    float2 newUV4 = RotateUV(dir4, uv, gridResolution, flowVelocityStrength, wavePeriod);

    float3 normal1 = SAMPLE_TEXTURE2D(normalMap, samplerNormalMap, newUV1).rgb * 2.0 - 1.0;
    float3 normal2 = SAMPLE_TEXTURE2D(normalMap, samplerNormalMap, newUV2).rgb * 2.0 - 1.0;
    float3 normal3 = SAMPLE_TEXTURE2D(normalMap, samplerNormalMap, newUV3).rgb * 2.0 - 1.0;
    float3 normal4 = SAMPLE_TEXTURE2D(normalMap, samplerNormalMap, newUV4).rgb * 2.0 - 1.0;

    float displacement1 = SAMPLE_TEXTURE2D(displacementMap, samplerDisplacementMap, newUV1).r;
    float displacement2 = SAMPLE_TEXTURE2D(displacementMap, samplerDisplacementMap, newUV2).r;
    float displacement3 = SAMPLE_TEXTURE2D(displacementMap, samplerDisplacementMap, newUV3).r;
    float displacement4 = SAMPLE_TEXTURE2D(displacementMap, samplerDisplacementMap, newUV4).r;

    float noise1 = SAMPLE_TEXTURE2D(heightNoiseMap, samplerHeightNoiseMap, newUV1).r;
    float noise2 = SAMPLE_TEXTURE2D(heightNoiseMap, samplerHeightNoiseMap, newUV2).r;
    float noise3 = SAMPLE_TEXTURE2D(heightNoiseMap, samplerHeightNoiseMap, newUV3).r;
    float noise4 = SAMPLE_TEXTURE2D(heightNoiseMap, samplerHeightNoiseMap, newUV4).r;

    displacement1 = (displacement1 + noise1) / 2.0;
    displacement2 = (displacement2 + noise2) / 2.0;
    displacement3 = (displacement3 + noise3) / 2.0;
    displacement4 = (displacement4 + noise4) / 2.0;
    
    float2 uvFrac = frac(uv * gridResolution);
    uvFrac *= 2 * PI;
    uvFrac = cos(uvFrac) * 0.5 + 0.5;

    float w1 = (1.0 - uvFrac.r) * (1.0 - uvFrac.g);
    float w2 = uvFrac.r * (1.0 - uvFrac.g);
    float w3 = (1.0 - uvFrac.r) * uvFrac.g;
    float w4 = uvFrac.r * uvFrac.g;

    finalNormal = normalize(w1 * normal1 + w2 * normal2 + w3 * normal3 + w4 * normal4);
    finalDisplacement = w1 * displacement1 + w2 * displacement2 + w3 * displacement3 + w4 * displacement4;
}

float2 GetFlowDirection(Texture2D flowMap, SamplerState samplerFlowMap, float2 uv, float2 offset, float gridResolution)
{
    uv *= gridResolution;
    float2 offset1 = offset * 0.5;
    float2 offset2 = (1.0 - offset) * 0.5;
    uv = floor(uv + offset1);
    uv += offset2;
    uv /= gridResolution;
    float2 direction = SAMPLE_TEXTURE2D(flowMap, samplerFlowMap, uv).rg;
    direction = (direction * 2) - 1;
    return direction;
}

void FlowCell(Texture2D flowMap, SamplerState samplerFlowMap,
              Texture2D normalMap, SamplerState samplerNormalMap,
              Texture2D displacementMap, SamplerState samplerDisplacementMap,
              float2 uv, float gridResolution, float flowVelocityStrength, float wavePeriod,
              out float3 finalNormal, out float finalDisplacement)
{
    float2 dir1 = GetFlowDirection(flowMap, samplerFlowMap, uv, float2(0.0, 0.0), gridResolution);
    float2 dir2 = GetFlowDirection(flowMap, samplerFlowMap, uv, float2(1.0, 0.0), gridResolution);
    float2 dir3 = GetFlowDirection(flowMap, samplerFlowMap, uv, float2(0.0, 1.0), gridResolution);
    float2 dir4 = GetFlowDirection(flowMap, samplerFlowMap, uv, float2(1.0, 1.0), gridResolution);

    float2 newUV1 = RotateUV(dir1, uv, gridResolution, flowVelocityStrength, wavePeriod);
    float2 newUV2 = RotateUV(dir2, uv, gridResolution, flowVelocityStrength, wavePeriod);
    float2 newUV3 = RotateUV(dir3, uv, gridResolution, flowVelocityStrength, wavePeriod);
    float2 newUV4 = RotateUV(dir4, uv, gridResolution, flowVelocityStrength, wavePeriod);

    float4 normal1 = SAMPLE_TEXTURE2D(normalMap, samplerNormalMap, newUV1);
    float4 normal2 = SAMPLE_TEXTURE2D(normalMap, samplerNormalMap, newUV2);
    float4 normal3 = SAMPLE_TEXTURE2D(normalMap, samplerNormalMap, newUV3);
    float4 normal4 = SAMPLE_TEXTURE2D(normalMap, samplerNormalMap, newUV4);

    float displacement1 = SAMPLE_TEXTURE2D(displacementMap, samplerDisplacementMap, newUV1).r;
    float displacement2 = SAMPLE_TEXTURE2D(displacementMap, samplerDisplacementMap, newUV2).r;
    float displacement3 = SAMPLE_TEXTURE2D(displacementMap, samplerDisplacementMap, newUV3).r;
    float displacement4 = SAMPLE_TEXTURE2D(displacementMap, samplerDisplacementMap, newUV4).r;

    float2 uvFrac = frac(uv * gridResolution);
    uvFrac *= 2 * PI;
    uvFrac = cos(uvFrac) * 0.5 + 0.5;

    float w1 = (1.0 - uvFrac.r) * (1.0 - uvFrac.g);
    float w2 = uvFrac.r * (1.0 - uvFrac.g);
    float w3 = (1.0 - uvFrac.r) * uvFrac.g;
    float w4 = uvFrac.r * uvFrac.g;

    float4 finalNormal0 = w1 * normal1 + w2 * normal2 + w3 * normal3 + w4 * normal4;
    finalNormal = UnpackNormal(finalNormal0).rgb;
    finalDisplacement = w1 * displacement1 + w2 * displacement2 + w3 * displacement3 + w4 * displacement4;
}

#endif