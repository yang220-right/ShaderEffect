Shader "YYCustom/Lighting"
{
    Properties
    {
        _TintColor1("Tint1",Color) = (1,1,1,1)
        // x闪电宽度 y亮度
        _ControlValue("Value",Vector) = (0,0,0,0)
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
            float4 _TintColor1;
            float4 _ControlValue;

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                v2f o;
                VertexPositionInputs posIN = GetVertexPositionInputs(v.vertex);
                o.pos = posIN.positionCS;
                o.uv = v.uv;
                return o;
            }

            //旋转
            float2 Twirl(float2 UV, float2 Center, float Strength, float2 Offset)
            {
                float2 delta = UV - Center;
                float angle = Strength * length(delta);
                float x = cos(angle) * delta.x - sin(angle) * delta.y;
                float y = sin(angle) * delta.x + cos(angle) * delta.y;
                return float2(x + Center.x + Offset.x, y + Center.y + Offset.y);
            }

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

            //极坐标
            float2 PolarCoordinates(float2 UV, float2 Center, float RadialScale, float LengthScale)
            {
                float2 delta = UV - Center;
                float radius = length(delta) * 2 * RadialScale;
                float angle = atan2(delta.x, delta.y) * 1.0 / 6.28 * LengthScale;
                return float2(radius, angle);
            }

            float Remap(float Val, float iMin, float iMax, float oMin, float oMax)
            {
                return (oMin + ((Val - iMin) * (oMax - oMin)) / (iMax - iMin));
            }

            //生成一个矩形 中心为0.5,0.5
            float Rectangle(float2 UV, float Width, float Height)
            {
                float2 d = abs(UV * 2 - 1) - float2(Width, Height);
                //fwidth领域像素的近似导数值 fwidth(d) = abs(ddx(d)) + abs(ddy(d))
                // ddx(d) 是 d 在屏幕空间 x 方向上的导数。
                // ddy(d) 是 d 在屏幕空间 y 方向上的导数。
                d = 1 - d / fwidth(d); //平滑边缘
                return saturate(min(d.x, d.y));
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 st = i.uv;
                float noiseValue1 = SimpleNoise(st + float2(0, 2 * _Time.y), 8);
                float noiseValue2 = SimpleNoise(st + float2(0, -2 * _Time.y), 10);
                //混合两个噪声
                float blendValue = Remap(pow(noiseValue1 + noiseValue2, 2), 0, 1, -10, 10);
                //生成线段
                float rectValue = Rectangle(blendValue, _ControlValue.x, 1);
                //极坐标
                float circleValue = saturate(1 - pow(PolarCoordinates(st, float2(0.5, 0.5), 1, 1).x,_ControlValue.y));
                float4 finalColor = rectValue * circleValue * _TintColor1;
                return finalColor;
            }
            ENDHLSL
        }
    }
}