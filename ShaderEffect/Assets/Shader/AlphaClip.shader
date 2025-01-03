Shader "YYCustom/AlphaClip"
{
    Properties
    {
        _ClipValue("ClipValue",float) = 1
        _Color("Color",Color) = (1,1,1,1)
        _MarginLight("MarginLight",float) = 0.03
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

            float _ClipValue; 
            float _MarginLight; 
            float4 _Color; 

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                v2f o;
                VertexPositionInputs posIN = GetVertexPositionInputs(v.vertex);
                o.pos = posIN.positionCS;
                o.worldPos = posIN.positionWS; //世界坐标的顶点
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                //float4(v.worldPos, 1.0f) 这行代码将 v.worldPos转换为 float4 类型，并且为 w 分量指定了 1.0f。这意味着我们认为这个坐标是一个 空间中的点，而不是一个方向向量。
                float4 selfPos = mul(unity_WorldToObject, float4(i.worldPos, 1.0f));
                //模型空间的坐标范围在-1,1 重建坐标
                selfPos = (selfPos + 1 )/ 2;
                clip(_ClipValue - selfPos.y);
                return lerp(float4(0.5f,0.5f,1,1),_Color,smoothstep(_ClipValue - _MarginLight,_ClipValue,selfPos.y));
            }
            ENDHLSL
        }
    }
}
