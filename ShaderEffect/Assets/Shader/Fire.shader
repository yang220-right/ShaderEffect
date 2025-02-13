Shader "YYCustom/Fire"
{
    Properties
    {
        _TintColor1("Tint1",Color) = (1,1,1,1)
        _TintColor2("Tint2",Color) = (1,1,1,1)
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
                float2 st = i.uv + float2(0, -_Time.y);
                float cells1;
                float cells2;
                float grid1;
                float grid2;
                Voronoi(st, _Time.y, 5, cells1, grid1);
                Voronoi(st, _Time.y * 5, 3, cells2, grid2);
                //混合
                float blendValue = BlendOverlay(cells1, cells2, 1);
                //距离
                float dis = distance(i.uv, float2(0.5, 0.2));
                clip(0.55 - dis);
                //内焰
                float re1 = Remap(dis, 0, 0.64, 1, 0.1);
                //外焰
                float re2 = Remap(dis, 0, 0.7, 1, -0.2);
                //变亮
                float c1 = clamp(pow(re1, 3), 0, 1);
                float c2 = clamp(pow(re2, 7), 0, 1);
                //颜色
                float4 b1 = (blendValue * re1 + c1) * _TintColor1;
                float4 b2 = (blendValue * re2 + c2) * _TintColor2;

                float4 finalColor = b1 + b2;
                clip(finalColor.a - 0.4f);
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