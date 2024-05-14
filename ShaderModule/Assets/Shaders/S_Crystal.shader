Shader "Custom/S_Crystal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (0, 0, 0, 0)
        _OutColor ("Out Color", Color) = (0,0,0,1)
        _OutEdgeValue ("Out Edge Value", Range(0,1)) = 0.2
        _OutValue ("Out Value", Range(0,1)) = 0.25
        _OutAlpha ("Out Alpha", Range(0,1)) = 1
        _Distortion ("Distortion Amount", Float) = 3
        _HasTime ("Use time", Range(0,1)) = 1
    }
    SubShader
    {
        LOD 100

        GrabPass { }

        Pass
        {

            Tags{ "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}

            ZWrite On

            Blend SrcAlpha OneMinusDstAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 normal : NORMAL0;
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 grabPos : TEXCOORD1;
                float3 wPos : TEXCOORD2;
                float3 normal : NORMAL0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;

            fixed4 _OutColor;
            float _OutEdgeValue;
            float _OutValue;
            float _OutAlpha;
            float _Distortion;
            float _HasTime;

            sampler2D _GrabTexture;
             
            v2f vert (appdata v)
            {
                v2f o;

                _OutValue = max(_OutEdgeValue, _OutValue);

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.vertex = UnityObjectToClipPos(v.vertex);

                float xPos = sin(tan(v.vertex.x) * (_HasTime == 1 ? _Time.y : 1));

                float4 clipPos = UnityObjectToClipPos(v.vertex + fixed4(xPos * _Distortion,0,0,0));
                
		        o.grabPos = ComputeGrabScreenPos(clipPos);
                o.wPos = mul (unity_ObjectToWorld, v.vertex).xyz;

                o.normal = UnityObjectToWorldNormal(v.normal); 

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // fixed4 c = tex2D (_MainTex, i.uv) * _Color;
                fixed4 c = _Color;

                fixed3 dir = normalize(_WorldSpaceCameraPos - i.wPos);

                float dotP = dot(i.normal, dir);

                float stepDotP = dotP < _OutEdgeValue || step(_OutValue, dotP);

                i.grabPos = UNITY_PROJ_COORD(i.grabPos);

                fixed4 f = tex2Dproj(_GrabTexture, i.grabPos);

                fixed4 finalC = stepDotP ? f.rgba * c.rgba : _OutColor;

                float finalAlpha = stepDotP ? c.a : _OutAlpha;

                return fixed4(finalC.rgb, finalAlpha);
            }
            ENDCG
        }
    }
}
