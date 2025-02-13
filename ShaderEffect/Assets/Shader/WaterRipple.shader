Shader "YYCustom/WaterRipple"
{
    Properties
    {
        _MainTex("MainTex",2D) = "White"{}
        _TintColor("Tint",Color) = (1,1,1,1)
        //x速度 y波浪大小 z远近波浪控制
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
                //水波纹
                float len = length(st - 0.5);
                float2 water = sin(len * 30 + _Value.x * _Time.y);
                // normalize(st - 0.5) 方向向量不变 所以此代码是为了从近到远进行非等比例缩放
                float2 c = normalize(st - 0.5) * _Value.y * pow(saturate(1 - len / 2)/*取反*/,_Value.z);
                return tex2D(_MainTex,water * c * st);
            }
            ENDHLSL
        }
    }
}