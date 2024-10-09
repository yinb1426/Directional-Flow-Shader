Shader "Unlit/DirectionalFlowDynamicShader"
{
    Properties
    {
        [Header(Textures)]
        _DisplacementMap ("Displacement Map", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "white" {}
        _NormalStrength ("Normal Strength", Float) = 0.5

        [Header(FlowMap And WaterHeight)]
        _FlowMapBefore ("Flow Map (Before)", 2D) = "white" {}
        _FlowMapAfter ("Flow Map (After)", 2D) = "white" {}
        _WaterHeightTextureBefore ("Water Height Texture (Before)", 2D) = "white" {}
        _WaterHeightTextureAfter ("Water Height Texture (After)", 2D) = "white" {}
        _TimeStep ("Time Step", Float) = 0.0

        [Header(Water Color)]
        _WaterShallowColor ("Water Shallow Color", Color) = (0, 0, 0, 0)
        _WaterDeepColor ("Water Deep Color", Color) = (0, 0, 0, 0)
        _DepthDensity ("Depth Density", Float) = 1

        [Header(Wave A)]
        _GridResolution_A ("Grid Resolution A", Float) = 40
        _WavePeriod_A ("Wave Period A", Float) = 1.578
        _FlowVelocityStrength_A ("Flow Velocity Strength A", Float) = 5
        _HeightEdge_A ("Flow Velocity Strength A", Range(0, 1)) = 0.232

        [Header(Wave B)]
        _GridResolution_B ("Grid Resolution B", Float) = 60
        _WavePeriod_B ("Wave Period B", Float) = 1.36
        _FlowVelocityStrength_B ("Flow Velocity Strength B", Float) = 3.5
        _HeightEdge_B ("Flow Velocity Strength B", Range(0, 1)) = 0.227

        [Header(Wave C)]
        _GridResolution_C ("Grid Resolution C", Float) = 70
        _WavePeriod_C ("Wave Period C", Float) = 1.66
        _FlowVelocityStrength_C ("Flow Velocity Strength C", Float) = 2.2
        _HeightEdge_C ("Flow Velocity Strength C", Range(0, 1)) = 0.243

        [Header(Wave D)]
        _GridResolution_D ("Grid Resolution D", Float) = 50
        _WavePeriod_D ("Wave Period D", Float) = 2.54
        _FlowVelocityStrength_D ("Flow Velocity Strength D", Float) = 4.2
        _HeightEdge_D ("Flow Velocity Strength D", Range(0, 1)) = 0.265

        [Header(Foam)]
        _FoamTexture ("Foam Texture", 2D) = "white" {}
        _FoamMinEdge ("Foam Min Edge", Range(0, 1)) = 0.3
        _FoamMaxEdge ("Foam Max Edge", Range(0, 1)) = 0.6
        _FoamBlend ("Foam Blend", Range(0, 1)) = 0.6
    }
    SubShader
    {
        Tags {
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "RenderPipeline"="UniversalPipeline"
        }
        LOD 200
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            #include "HLSLs/Overlay.hlsl"
            #include "HLSLs/FlowCell.hlsl"
            #include "HLSLs/Utils.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 tangentWS : TEXCOORD3;
                float3 bitangentWS : TEXCOORD4;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _DisplacementMap_ST;
                float4 _NormalMap_ST;
                float4 _FlowMapBefore_ST;
                float4 _FlowMapAfter_ST;
                float4 _WaterHeightTextureBefore_ST;
                float4 _WaterHeightTextureAfter_ST;
                float4 _FoamTexture_ST;

                float _NormalStrength;
                float _TimeStep;

                float4 _WaterShallowColor;
                float4 _WaterDeepColor;
                float _DepthDensity;

                // Wave A
                float _GridResolution_A;
                float _WavePeriod_A;
                float _FlowVelocityStrength_A;
                float _HeightEdge_A;

                // Wave B
                float _GridResolution_B;
                float _WavePeriod_B;
                float _FlowVelocityStrength_B;
                float _HeightEdge_B;

                // Wave C
                float _GridResolution_C;
                float _WavePeriod_C;
                float _FlowVelocityStrength_C;
                float _HeightEdge_C;

                // Wave D
                float _GridResolution_D;
                float _WavePeriod_D;
                float _FlowVelocityStrength_D;
                float _HeightEdge_D;

                // Foam
                float _FoamMinEdge;
                float _FoamMaxEdge;
                float _FoamBlend;
            CBUFFER_END
            
            TEXTURE2D(_DisplacementMap);            SAMPLER(sampler_DisplacementMap);
            TEXTURE2D(_NormalMap);                  SAMPLER(sampler_NormalMap);
            TEXTURE2D(_FlowMapBefore);              SAMPLER(sampler_FlowMapBefore);
            TEXTURE2D(_FlowMapAfter);               SAMPLER(sampler_FlowMapAfter);
            TEXTURE2D(_WaterHeightTextureBefore);   SAMPLER(sampler_WaterHeightTextureBefore);
            TEXTURE2D(_WaterHeightTextureAfter);    SAMPLER(sampler_WaterHeightTextureAfter);
            TEXTURE2D(_FoamTexture);            SAMPLER(sampler_FoamTexture);

            Varyings vert (Attributes input)
            {
                Varyings output = (Varyings)0;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.uv = TRANSFORM_TEX(input.uv, _DisplacementMap);
                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                output.normalWS = normalize(normalInputs.normalWS);
                output.tangentWS = normalize(normalInputs.tangentWS);
                output.bitangentWS = normalize(normalInputs.bitangentWS);
                return output;
            }
        

            float4 frag(Varyings input) : SV_Target
            {
                float3 curNormal;
                float3 finalNormal;
                float curDisplacement;
                float finalDisplacement;

                FlowCell(_FlowMapBefore, sampler_FlowMapBefore, _FlowMapAfter, sampler_FlowMapAfter, _NormalMap, sampler_NormalMap, _DisplacementMap, sampler_DisplacementMap, _TimeStep, input.uv, _GridResolution_A, _FlowVelocityStrength_A, _WavePeriod_A, curNormal, curDisplacement);
                finalNormal = curNormal;
                finalDisplacement = smoothstep(_HeightEdge_A, 1.0, curDisplacement);

                FlowCell(_FlowMapBefore, sampler_FlowMapBefore, _FlowMapAfter, sampler_FlowMapAfter, _NormalMap, sampler_NormalMap, _DisplacementMap, sampler_DisplacementMap, _TimeStep, input.uv, _GridResolution_B, _FlowVelocityStrength_B, _WavePeriod_B, curNormal, curDisplacement);
                finalNormal += curNormal;
                finalDisplacement += smoothstep(_HeightEdge_B, 1.0, curDisplacement);

                FlowCell(_FlowMapBefore, sampler_FlowMapBefore, _FlowMapAfter, sampler_FlowMapAfter, _NormalMap, sampler_NormalMap, _DisplacementMap, sampler_DisplacementMap, _TimeStep, input.uv, _GridResolution_C, _FlowVelocityStrength_C, _WavePeriod_C, curNormal, curDisplacement);
                finalNormal += curNormal;
                finalDisplacement += smoothstep(_HeightEdge_C, 1.0, curDisplacement);

                FlowCell(_FlowMapBefore, sampler_FlowMapBefore, _FlowMapAfter, sampler_FlowMapAfter, _NormalMap, sampler_NormalMap, _DisplacementMap, sampler_DisplacementMap, _TimeStep, input.uv, _GridResolution_D, _FlowVelocityStrength_D, _WavePeriod_D, curNormal, curDisplacement);
                finalNormal += curNormal;
                finalDisplacement += smoothstep(_HeightEdge_D, 1.0, curDisplacement);

                finalNormal = normalize(finalNormal);
                finalNormal = NormalStrength(finalNormal, _NormalStrength);
                finalDisplacement /= 4.0;

                // 深浅水颜色
                float waterHeightBefore = SAMPLE_TEXTURE2D(_WaterHeightTextureBefore, sampler_WaterHeightTextureBefore, input.uv);
                float waterHeightAfter = SAMPLE_TEXTURE2D(_WaterHeightTextureAfter, sampler_WaterHeightTextureAfter, input.uv);
                float waterHeight = lerp(waterHeightBefore, waterHeightAfter, _TimeStep);
                waterHeight /= _DepthDensity;
                waterHeight = saturate(waterHeight);
                float4 waterColor = lerp(_WaterShallowColor, _WaterDeepColor, waterHeight);
                float alpha = waterColor.a;

                // 法线
                float3x3 tbnMatrix = float3x3(input.tangentWS, input.bitangentWS, input.normalWS);
                float3 normalWS = mul(finalNormal, tbnMatrix);

                // Blinn-Phong光照
                Light mainLight = GetMainLight();
                float3 lightDirWS = normalize(mainLight.direction);
                float4 lightColor = float4(mainLight.color, 1.0);
                
                float NdotL = dot(normalWS, lightDirWS);
                float halfLambert = 0.5 * NdotL + 0.5;
                float4 diffuseColor = waterColor * lightColor * halfLambert;

                float4 finalColor = diffuseColor;

                // // 浪尖泡沫
                float foamValue = SAMPLE_TEXTURE2D(_FoamTexture, sampler_FoamTexture, input.uv * _FoamTexture_ST.xy).r;
                foamValue = Remap(foamValue, float2(0, 1), float2(0.2, 1));
                foamValue = foamValue * smoothstep(_FoamMinEdge, _FoamMaxEdge, finalDisplacement);
                float4 foamColor = float4(foamValue, foamValue, foamValue, foamValue);

                finalColor = Overlay(finalColor, foamColor, _FoamBlend);
                return float4(finalColor.rgb, alpha);
            }

            ENDHLSL
        }
    }
}
