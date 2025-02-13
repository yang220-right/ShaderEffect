Shader "YYCustom/WaterUV"
{
    Properties
    {
        _MainTex("MainTex",2D) = "White"{}
        _TintColor("Tint",Color) = (1,1,1,1)
        _Value("Value",Vector) = (0,0,0,0)
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
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _TintColor;
            float4 _Value;

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

            float2 random2(float2 st)
            {
                st = float2(dot(st, float2(127.1, 311.7)), dot(st, float2(269.5, 183.3)));
                return -1.0 + 2.0 * frac(sin(st) * 43758.5453123);
            }

            //渐变噪声（http://en.wikipedia.org/wiki/Gradient_noise），不要与之混淆
            //值噪声，而不是柏林噪声（这是梯度噪声的一种形式）
            //可能是生成噪声（随机平滑信号）最方便的方法
            //大部分能量在低频)适合程序纹理/着色，
            //建模和动画。
            //它比值噪声产生更平滑和更高的质量，但它当然稍微多一点昂贵。
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

            float Remap(float Val, float iMin, float iMax, float oMin, float oMax)
            {
                return (oMin + ((Val - iMin) * (oMax - oMin)) / (iMax - iMin));
            }

            v2f vert(a2v v)
            {
                v2f o;
                //抬高z轴方向以达到波浪效果 用法线确定方向
                float3 value = noise((_Time.y*_Value.x   + v.uv)* _Value.y )* v.normal + v.vertex;
                VertexPositionInputs posIN = GetVertexPositionInputs(float4(value, 1));
                o.pos = posIN.positionCS;
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return tex2D(_MainTex, i.uv) * _TintColor;
            }
            ENDHLSL
        }
    }
}