Shader "YYCustom/Outline"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        _FresnelLine("Fresnel",float) = 2
        _FresnelScale ("Fresnel Scale", Range(0, 1)) = 0.1
        _FilterFresnelDir("FilterFresnelDir",float) = 0.5
        _Dir("light dir",Vector) = (1,1,1,1)
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "Queue"="Geometry"
        }
        Pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }//向前渲染模式

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            float4 _Color;
            float _FresnelLine; 
            float _FresnelScale; //菲涅尔
            float _FilterFresnelDir; //菲涅尔
            float4 _Dir;
            samplerCUBE _Cubemap;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldViewDir : TEXCOORD2;
                float3 worldRefl : TEXCOORD3; //菲涅尔
            };

            v2f vert(a2v v)
            {
                v2f o;
                VertexPositionInputs posIN = GetVertexPositionInputs(v.vertex);
                VertexNormalInputs norIN = GetVertexNormalInputs(v.normal);
                o.pos = posIN.positionCS;
                o.worldNormal = norIN.normalWS; //世界坐标下的法线
                o.worldPos = posIN.positionWS; //世界坐标的顶点
                o.worldViewDir = normalize(_WorldSpaceCameraPos - o.worldPos); //视角方向
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float3 worldNormal = normalize(i.worldNormal);
                float3 worldViewDir = normalize(i.worldViewDir); //视角方向
                float value = step(_FilterFresnelDir,dot(worldNormal,_Dir));
                //菲涅尔求边缘
                float fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1 - dot(worldViewDir, worldNormal), _FresnelLine);
                return float4(fresnel,fresnel,fresnel, 1.0) * _Color * value;
            }
            ENDHLSL
        }
    }
}