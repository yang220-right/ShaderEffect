Shader "YYCustom/CloseDissolution"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _TintColor("TintColor",Color) = (1,1,1,1)
        //x噪声大小 y颜色间隔 z离目标点距离 w起始距离
        _Dissolution("Dissolution",Vector) = (50,0.02,1,0.94)
        _Pos("Pos",Vector) = (0,0,0,0)
        _Speed("Speed",Float) = 0.35
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

            float4 _Color;
            float4 _TintColor;
            float4 _Dissolution;
            float4 _Pos;
            float _Speed;

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD1;
                float3 worldPos:TEXCOORD2;
            };

            inline float SimpleNoiseRandomValue(float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
            }

            inline float SimpleNnoiseInterpolate(float a, float b, float t)
            {
                return (1.0 - t) * a + (t * b);
            }

            inline float SimpleNoiseValueNoise(float2 uv)
            {
                float2 i = floor(uv);
                float2 f = frac(uv);
                f = f * f * (3.0 - 2.0 * f);

                float2 c0 = i + float2(0.0, 0.0);
                float2 c1 = i + float2(1.0, 0.0);
                float2 c2 = i + float2(0.0, 1.0);
                float2 c3 = i + float2(1.0, 1.0);
                float r0 = SimpleNoiseRandomValue(c0);
                float r1 = SimpleNoiseRandomValue(c1);
                float r2 = SimpleNoiseRandomValue(c2);
                float r3 = SimpleNoiseRandomValue(c3);

                float bottomOfGrid = SimpleNnoiseInterpolate(r0, r1, f.x);
                float topOfGrid = SimpleNnoiseInterpolate(r2, r3, f.x);
                float t = SimpleNnoiseInterpolate(bottomOfGrid, topOfGrid, f.y);
                return t;
            }

            float SimpleNoise(float2 UV, float Scale)
            {
                float t = 0.0;
                float freq = pow(2.0, float(0));
                float amp = pow(0.5, float(3 - 0));
                t += SimpleNoiseValueNoise(float2(UV.x * Scale / freq, UV.y * Scale / freq)) * amp;
                freq = pow(2.0, float(1));
                amp = pow(0.5, float(3 - 1));
                t += SimpleNoiseValueNoise(float2(UV.x * Scale / freq, UV.y * Scale / freq)) * amp;
                freq = pow(2.0, float(2));
                amp = pow(0.5, float(3 - 2));
                t += SimpleNoiseValueNoise(float2(UV.x * Scale / freq, UV.y * Scale / freq)) * amp;
                return t;
            }

            v2f vert(a2v v)
            {
                v2f o;
                VertexPositionInputs posIN = GetVertexPositionInputs(v.vertex);
                o.pos = posIN.positionCS;
                o.worldPos = posIN.positionWS;
                o.uv = v.uv;
                return o;
            }

            float Remap(float Val, float iMin, float iMax, float oMin, float oMax)
            {
                return (oMin + ((Val - iMin) * (oMax - oMin)) / (iMax - iMin));
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 st = i.uv;
                float dis = Remap(distance(i.worldPos, _Pos), 0, 1, 1, 0);
                float value = dis * SimpleNoise(st + _Time.y * _Speed, _Dissolution.x);
                float stepValue1 = step(_Dissolution.w - _Dissolution.z, value);
                float stepValue2 = step(_Dissolution.w + _Dissolution.y - _Dissolution.z, value);
                clip(1 - stepValue2 - 0.01);
                return lerp(_TintColor, _Color, stepValue1);
            }
            ENDHLSL
        }
    }
}