Shader "Custom/S_Crystal"
{
    Properties
    {
        _Color ("Color", Color) = (0, 0, 0, 0)
        _RimColor ("Rim Light Color", Color) = (0,0,0,1)
        _RimDiffusionValue ("Rim Light Diffusion Value", Range(0,.5)) = 0.3
        _RimValue ("Rim Light Definition", Range(-0.5,0.5)) = 0.5
        _RimIntensity ("Rim Light Intensity", Range(0,1)) = 0.5
        [Toggle(USE_NORMAL)] _UseNormal("Use Normal Distortion", Range(0,1)) = 0
        _NormalDistortion ("Normal Distortion Amount", Range(-3,3)) = 0
        _CustomDistortion ("Custom Distortion Amount", Range(0,1)) = 0.2
        [Toggle(USE_TIME)] _UseTime("Use Time", Range(0,1)) = 1
        _DistortionTime ("Time speed", Range(0,20)) = 1
        _RimLightTime ("Rim Light Time speed", Range(0,10)) = 1
    }
    SubShader
    {
        LOD 200

        Tags{ "Queue" = "Transparent" "RenderType"="Transparent"} 

        GrabPass { }

        Pass
        {
            ZWrite On

            Blend SrcAlpha OneMinusSrcAlpha

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

            fixed4 _Color;

            fixed4 _RimColor;
            float _RimDiffusionValue;
            float _RimValue;
            float _RimIntensity;
            float _CustomDistortion;
            float _NormalDistortion;
            float _UseNormal;
            float _UseTime;
            float _DistortionTime;
            float _RimLightTime;

            sampler2D _GrabTexture;

            float4 customDistortion(float4 pos)
            {
                return float4(
                    pos.x + sin((pos.y) * _CustomDistortion * 10 + (_UseTime ? _Time.y * _DistortionTime : 0))/20,
                    pos.y + sin(pos.y)/10,
                    pos.z,
                    pos.a
                    );
            }

            float3 distortedPos(fixed3 pos, fixed3 normal)
            {
                float multiplier = _UseTime ? sin(_Time.y * _DistortionTime)/5 : 1;

                return pos + normal * (_NormalDistortion * multiplier / 5);
            }
             
            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal); 

                float4 clipPos = _UseNormal 
                    ? UnityObjectToClipPos(fixed4(distortedPos(v.vertex, o.normal),0)) 
                    : o.vertex;

		        o.grabPos = ComputeGrabScreenPos(clipPos);

                o.wPos = mul (unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 c = _Color;

                fixed3 dir = normalize(_WorldSpaceCameraPos - i.wPos);

                float dotP = dot(i.normal, dir);

                float stepDotP = dotP < _RimDiffusionValue && dotP > -_RimValue;

                i.grabPos = _UseNormal ? i.grabPos : customDistortion(i.grabPos);

                i.grabPos = UNITY_PROJ_COORD(i.grabPos);

                fixed4 f = tex2Dproj(_GrabTexture, i.grabPos);

                float finalAlpha = stepDotP ? _RimColor.a : 1;
                float4 notRim = c.rgba * f.rgba; 

                if(_UseTime) _RimIntensity += (sin(_Time.y * _RimLightTime/2))/10;

                fixed4 finalC = stepDotP 
                    ? lerp(notRim, _RimColor, pow(1 - saturate(dotP), (10 - _RimIntensity * 10)))
                    : lerp(float4(1,1,1,1), c.rgba, c.a) * f.rgba;

                return fixed4(finalC.rgb, finalAlpha);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
