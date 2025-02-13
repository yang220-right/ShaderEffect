Shader "YYCustom/HoloGraphic"
{
    Properties
    {
        _TintColor1("Tint1",Color) = (1,1,1,1)
        // x内横线速度 y外速度 z线条间隔
        _ControlValue("Value",Vector) = (0,0,0,0)
        //菲涅尔
        _FresnelLine("Fresnel",float) = 2
        _FresnelScale ("Fresnel Scale", Range(0, 1)) = 0.1//
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

            float _FresnelLine;
            float _FresnelScale; //菲涅尔

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
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
                float3 worldNormal = normalize(i.worldNormal);
                float3 worldViewDir = normalize(i.worldViewDir); //视角方向
                //菲涅尔求边缘
                float fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1 - dot(worldViewDir, worldNormal), _FresnelLine);
                //菲涅尔求反
                float fresnelResult = pow(1 - fresnel,10);
                //分割
                float3 objPos = mul(unity_WorldToObject,i.worldPos);
                //顶点位移
                float st = step(frac((objPos.y + _Time.y * _ControlValue.x) * _ControlValue.z),0.5) * 0.6 * fresnelResult + fresnel;
                float finalColor = frac(( objPos.y + _Time.y * _ControlValue.y) * 0.74) * 0.6 + st ;
                
                return finalColor * _TintColor1;
            }
            ENDHLSL
        }
    }
}