Shader "YYCustom/UV"
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
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

                      float random21(float2 st) {
                //连续随机 所以后面的12 78 43758可以是任何值 合理就行了
                return frac(sin(dot(st.xy, float2(12.9898, 78.233))) * 43758.5453);
            }

            float noise(float2 st) {
                //取整数
                float2 i = floor(st);
                //取小数
                float2 f = frac(st);
                //获取左下角值
                float a = random21(i);
                //获取右下角值
                float b = random21(i + float2(1.0, 0.0));
                //获取左上值
                float c = random21(i + float2(0.0, 1.0));
                //获取右上值
                float d = random21(i + float2(1.0, 1.0));
                //随机一个函数得到U值
                float2 u = f * f * (3.0 - 2.0 * f);
                //插值更平滑
                return lerp(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
            }

            float Remap(float Val, float iMin, float iMax, float oMin, float oMax)
            {
                return (oMin + ((Val - iMin) * (oMax - oMin)) / (iMax - iMin));
            }

            v2f vert(a2v v)
            {
                v2f o;
                VertexPositionInputs posIN = GetVertexPositionInputs(v.vertex);
                o.pos = posIN.positionCS;
                o.uv = v.uv;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 st = i.uv;
                //跟y做关联
                float noiseValue = noise((st.y + _Time.y) * _Value.x);
                noiseValue = Remap(noiseValue,0,1,0,0.04);
                return tex2D(_MainTex, float2(noiseValue + st.x, st.y)) * _TintColor;
            }
            ENDHLSL
        }
    }
}