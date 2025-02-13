Shader "YYCustom/Water2UV"
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
          float3 mod289(float3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
            float2 mod289(float2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
            float3 permute(float3 x) { return mod289(((x * 34.0) + 1.0) * x); }

            // Description : GLSL 2D simplex noise function
            //      Author : Ian McEwan, Ashima Arts
            //  Maintainer : ijm
            //     Lastmod : 20110822 (ijm)
            //     License :
            //  Copyright (C) 2011 Ashima Arts. All rights reserved.
            //  Distributed under the MIT License. See LICENSE file.
            //  https://github.com/ashima/webgl-noise

            float noise(float2 v)
            {
                const float4 C = float4(0.211324865405187, // (3.0-sqrt(3.0))/6.0
                                    0.366025403784439, // 0.5*(sqrt(3.0)-1.0)
                                    -0.577350269189626, // -1.0 + 2.0 * C.x
                                    0.024390243902439); // 1.0 / 41.0
                float2 i = floor(v + dot(v, C.yy));
                float2 x0 = v - i + dot(i, C.xx);
                float2 i1;
                i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
                float4 x12 = x0.xyxy + C.xxzz;
                x12.xy -= i1;
                i = mod289(i); // 避免排列中的截断效应
                float3 p = permute(permute(i.y + float3(0.0, i1.y, 1.0))
                    + i.x + float3(0.0, i1.x, 1.0));

                float3 m = max(0.5 - float3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
                m = m * m;
                m = m * m;
                float3 x = 2.0 * frac(p * C.www) - 1.0;
                float3 h = abs(x) - 0.5;
                float3 ox = floor(x + 0.5);
                float3 a0 = x - ox;
                m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
                float3 g;
                g.x = a0.x * x0.x + h.x * x0.y;
                g.yz = a0.yz * x12.xz + h.yz * x12.yw;
                return 130.0 * dot(m, g);
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
                //画圆
                float2 re = i.uv * 2 - 1;
                clip( _Value.z - re.x* re.x - re.y*re.y);
                //噪声产生水波纹
                float stNoise = noise((i.uv + float2(_Time.y , 0)) * _Value.y) / 25 + _Value.x;
                //重新隐射到-1,2
                float edge = Remap(i.uv.y,0,1,0,2);
                //将值进行对比
                float filteValue = step(edge,stNoise);
                return lerp(tex2D(_MainTex, i.uv),_TintColor,filteValue);
            }
            ENDHLSL
        }
    }
}