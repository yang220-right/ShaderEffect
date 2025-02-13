// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "YYCustom/Toon Shading" {
	Properties {
		_Color ("Color", Color) = (1, 1, 1, 1)
		_GradientColor1("Gradient1",Color) = (0,0,0,0)
		_GradientColor2("Gradient2",Color) = (1,1,1,1)
		_Outline ("Outline", Range(0, 1)) = 0.1//轮廓线宽度
		_OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)//轮廓线颜色
	}
    SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}
		
		Pass {
			NAME "OUTLINE"
			//代表这个pass只渲染背面的三角面片
			Cull Front
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			float _Outline;
			fixed4 _OutlineColor;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			}; 
			struct v2f {
			    float4 pos : SV_POSITION;
			};
			
			v2f vert (a2v v) {
				v2f o;
				
				float4 pos = mul(UNITY_MATRIX_MV, v.vertex); //获取视角空间坐标信息
				float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);//视角空间法线信息
				//将拓展后的背面更加扁平化 降低遮挡正面面片的可能性 
				normal.z = -0.5;//将z轴统一为一个定值
				//将顶点位置沿法线方向偏移 以达到膨胀几何体的目的
				pos = pos + float4(normalize(normal), 0) * _Outline;
				o.pos = mul(UNITY_MATRIX_P, pos);//从视角空间变换到裁剪空间
				
				return o;
			}
			
			float4 frag(v2f i) : SV_Target { 
				return float4(_OutlineColor.rgb, 1);               
			}
			
			ENDCG
		}
		
		Pass {
			Tags { "LightMode"="UniversalForward" }
			Cull Back
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			
			fixed4 _Color;
			fixed4 _GradientColor1;
			fixed4 _GradientColor2;
		
			struct a2v {
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			}; 
			struct v2f {
				float4 pos : POSITION;
				float2 uv : TEXCOORD0;
			};
			
			v2f vert (a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			float4 frag(v2f i) : SV_Target {
				return _Color * lerp(_GradientColor1,_GradientColor2,smoothstep(0,1,i.uv.y));
			}
			ENDCG
		}
	}
}


