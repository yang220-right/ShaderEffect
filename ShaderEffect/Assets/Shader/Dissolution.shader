Shader "YYCustom/Dissolution"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _TintColor("TintColor",Color) = (1,1,1,1)
        _Dissolution("Dissolution",Vector) = (1,1,1,1)
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

            struct a2v
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD1;
            };

            float random(float2 st)
            {
                //dot 先放大  sin曲滑  frac映射到0-1
                return frac(sin(dot(st.xy,float2(53,43.5))) * 2312); 
            }
            //柏林噪声
            float noise(in float2 st)
            {
                //整数部分
                float2 i = floor(st);
                //小数部分
                float2 f = frac(st);
                //四个角的随机数
                float a = random(i);
                float b = random(i + float2(1.0,0.0));
                float c = random(i + float2(0.0,1.0));
                float d = random(i + float2(1.0,1.0));
                //三次平滑曲线函数  就是smoothstep的方法
                // float2 u = f*f*(3.0 - 2.0 * f);
                float2 u =smoothstep(0,1,f);
                //根据平滑曲线来进行插值
                return lerp(a,b,u.x) +//计算当前点的噪声值
                        (c - a) * (1 - u.x) * u.y +//加权
                        (d - b) * u.x * u.y;//加权
            }
            //分形布朗运动
            float noise2D(float2 uv){
                //相当于分为8个格子
                float c = noise(uv * 8.0);
                //16格子 乘以 权重0.5
                c += noise(uv * 16.0) * 0.5;
                //32格子 乘以 权重0.25
                c += noise(uv * 32.0) * 0.25;
                //64格子 乘以 权重0.125
                c += noise(uv * 64.0) * 0.125;
                // 1 + 0.5 + 0.25 + 0.125 近似 2 
                c / 2.0;
                return c;
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
                float2 st = i.uv * _Dissolution.x;
                float value = noise(st);
                clip(value - _Dissolution.y);
                return lerp(_Color,_TintColor,smoothstep(_Dissolution.y + _Dissolution.z,_Dissolution.y,value));
            }
            ENDHLSL
        }
    }
}

