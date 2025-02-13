Shader "YYCustom/Twirl"
{
    Properties
    {
        _TintColor1("Tint1",Color) = (1,1,1,1)
        _TintColor2("Tint2",Color) = (1,1,1,1)
        // x内焰大小 y外焰大小 z裁剪值 
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
            float4 _TintColor2;
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

            float2 VoronoiRandomVector(float2 UV, float offset)
            {
                float2x2 m = float2x2(15.27, 47.63, 99.41, 89.98);
                UV = frac(sin(mul(UV, m)) * 46839.32);
                return float2(sin(UV.y * offset) * 0.5 + 0.5, cos(UV.x * offset) * 0.5 + 0.5);
            }

            void Voronoi(float2 UV, float AngleOffset, float cellScale, out float Out, out float Cells)
            {
                float2 g = floor(UV * cellScale);
                float2 f = frac(UV * cellScale);
                float3 res = float3(8.0, 0.0, 0.0);

                for (int y = -1; y <= 1; y++)
                {
                    for (int x = -1; x <= 1; x++)
                    {
                        float2 lattice = float2(x, y);
                        float2 offset = VoronoiRandomVector(lattice + g, AngleOffset);
                        float d = distance(lattice + offset, f);

                        if (d < res.x)
                        {
                            res = float3(d, offset.x, offset.y);
                            Out = res.x;
                            Cells = res.y;
                        }
                    }
                }
            }

            float Remap(float Val, float iMin, float iMax, float oMin, float oMax)
            {
                return (oMin + ((Val - iMin) * (oMax - oMin)) / (iMax - iMin));
            }

            // 混合两个细胞
            float BlendOverlay(float Base, float Blend, float Opacity)
            {
                float result1 = 1.0 - 2.0 * (1.0 - Base) * (1.0 - Blend); //
                float result2 = 2.0 * Base * Blend;
                float zeroOrOne = step(Base, 0.5);
                float Out = result2 * zeroOrOne + (1 - zeroOrOne) * result1;
                return lerp(Base, Out, Opacity);
            }

            float4 frag(v2f i) : SV_Target
            {
                float2 st = i.uv;

                float2 twirlUV = Twirl(st,float2(0.5,0.5),25,_Time.y*0.5);
                float voValue;
                float cellsValue;
                Voronoi(twirlUV,2,7,voValue,cellsValue);
                float reValue = 1 - Remap(voValue,0,1,-15,1);

                float dis = 1 - distance(st,float2(0.5,0.5));
                float dis1 = pow(dis,5) * _ControlValue.x;
                float dis2 = pow(dis,10) * _ControlValue.y;

                float4 coreTwirlColor = saturate(dis2 * reValue) * _TintColor2;
                float4 outerTwirlColor =  saturate(dis1 * reValue) * _TintColor1;
                float4 finalColor = coreTwirlColor + outerTwirlColor;
                clip(finalColor.a - _ControlValue.z);
                return finalColor;
                //胞体
                // return half4(blendValue, blendValue, blendValue, 1.0);
                //四边形格子
                // return half4(grid1, grid1, grid1, 1.0);
            }
            ENDHLSL
        }
    }
}