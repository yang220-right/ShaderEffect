Shader "YYCustom/MaSaiKe"
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
            //将格子归到一块
            float2 mergerColor(float2 uv, float Steps)
            {
                return floor(uv / (1 / Steps)) * (1 / Steps);
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
                float2 st = mergerColor(i.uv,_Value.x);
                return tex2D(_MainTex, st) * _TintColor;
            }
            ENDHLSL
        }
    }
}
