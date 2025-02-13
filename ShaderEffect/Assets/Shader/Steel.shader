Shader "YYCustom/Steel"
{
     Properties
    {
        _Color("Color",Color) = (0.5,0.5,0.5,1)
        _SnowColor("SnowColor",Color) = (1,1,1,1)
        _SnowDir("SnowDir",Vector) = (1,1,1,1)
        //x 控制雪顶高度 y 渐变噪声放大倍数 z 渐变纹理阈值
        _ControlValue("ControlValue",Vector) = (0,0,0,0)
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

            float4 _SnowColor; 
            float4 _Color; 
            float4 _SnowDir; 
            float4 _ControlValue; 

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 wNormal : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            float2 random2(float2 st)
            {
                st = float2(dot(st, float2(127.1, 311.7)), dot(st, float2(269.5, 183.3)));
                return -1.0 + 2.0 * frac(sin(st) * 43758.5453123);
            }
            //渐变噪声
            float noise(float2 st)
            {
                float2 i = floor(st);
                float2 f = frac(st);
                float2 u = f * f * (3.0 - 2.0 * f);
                return lerp(lerp(dot(random2(i + float2(0.0, 0.0)), f - float2(0.0, 0.0)),
                                 dot(random2(i + float2(1.0, 0.0)), f - float2(1.0, 0.0)),
                                 u.x),
                            lerp(dot(random2(i + float2(0.0, 1.0)), f - float2(0.0, 1.0)),
                                 dot(random2(i + float2(1.0, 1.0)), f - float2(1.0, 1.0)),
                                 u.x),
                            u.y);
            }

            v2f vert(a2v v)
            {
                v2f o;
                VertexPositionInputs posIN = GetVertexPositionInputs(v.vertex);
                VertexNormalInputs norIN = GetVertexNormalInputs(v.normal);
                o.pos = posIN.positionCS;
                o.uv = v.uv;
                o.wNormal = norIN.normalWS;
                
                float3 binormal = cross( normalize(v.normal), normalize(v.tangent.xyz) ) * v.tangent.w; 
                float3x3 rotation = float3x3( v.tangent.xyz, binormal, v.normal );
                o.viewDir = mul(rotation, GetObjectSpaceNormalizeViewDir(v.vertex)).xyz;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 st = (i.uv + i.viewDir)* _ControlValue.y;
                float noiseValue = noise(st);
                return lerp(_Color,_Color * smoothstep(0.9f,noiseValue,0.75f),noiseValue) ;
            }
            ENDHLSL
        }
    }
}


