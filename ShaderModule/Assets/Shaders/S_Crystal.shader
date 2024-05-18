Shader "Custom/S_Crystal"
{
    Properties
    {
        [Header(Main Color)] [Space(12)]
        _Color ("Color", Color) = (0.45, 0.95, 1, 1)
        [Header(Rim Light)] [Space(12)]
        [Toggle] _UseCartoonishRimLight("Use Cartoonish Rim Light", Range(0,1)) = 0
        _RimColor ("Rim Light Color", Color) = (0,0,0,1)
        _RimIntensity ("Rim Light Intensity", Range(0,1)) = 0.2
        _RimDiffusionValue ("Rim Light Diffusion Value", Range(0,.5)) = 0.5
        _RimValue ("Rim Light Definition [Not Cartoon]", Range(0,1)) = 0.5
        [Header(Distortions)][Space(12)]
        [Toggle] _UseNormal("Use Normal Distortion", Range(0,1)) = 0
        _NormalDistortion ("Normal Distortion Amount", Range(-3,3)) = 0.5
        _CustomDistortion ("Custom Distortion Amount", Range(0,1)) = 0.5
        [Header(Time)][Space(12)]
        [Toggle] _UseTime("Use Time", Range(0,1)) = 0
        _DistortionTime ("Time speed", Range(0,20)) = 2
        _RimLightTime ("Rim Light Time speed", Range(0,10)) = 10
    }
    SubShader
    {
        LOD 200

        Tags{ "Queue" = "Transparent" "RenderType"="Transparent"} 

        GrabPass { }

        Pass
        {

            Blend SrcAlpha OneMinusSrcAlpha

            Cull Front

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

            float _UseCartoonishRimLight;
            fixed4 _RimColor;
            float _RimDiffusionValue;
            float _RimIntensity;
            float _RimLightTime;
            float _UseTime;

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex * (_UseCartoonishRimLight ? (1 + _RimDiffusionValue / 5) : 1));

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                if(_UseTime) _RimIntensity += (sin(_Time.y * _RimLightTime/2))/10;

                return _UseCartoonishRimLight ? fixed4(_RimColor.rgb, _RimIntensity) : fixed4(1,1,1,0);
            }
            ENDCG
        }

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

            // rimlight
            float _UseCartoonishRimLight;
            fixed4 _RimColor;
            float _RimDiffusionValue;
            float _RimValue;
            float _RimIntensity;
            //distortion
            float _CustomDistortion;
            float _NormalDistortion;
            float _UseNormal;
            // time
            float _UseTime;
            float _DistortionTime;
            float _RimLightTime;

            sampler2D _GrabTexture;

            float4 customDistortion(float4 pos)
            {
                return float4(
                    pos.x + sin((pos.y) * _CustomDistortion * 10 + (_UseTime ? _Time.y * _DistortionTime : 0))/20,
                    pos.y + sin(pos.y * _CustomDistortion / 2)/10,
                    pos.z,
                    pos.a
                    );
            }

            float3 distortedPos(fixed3 pos, fixed3 normal)
            {
                float multiplier = _UseTime ? sin(_Time.y * _DistortionTime)/5 : 0.7;

                return pos + normal * (_NormalDistortion * multiplier / 5);
            }
             
            v2f vert (appdata v)
            {
                v2f o;

                _RimValue -= 0.5;

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

                float stepDotP = _UseCartoonishRimLight
                    ? 0
                    : dotP < _RimDiffusionValue && dotP > -_RimValue;

                i.grabPos = _UseNormal ? i.grabPos : customDistortion(i.grabPos);

                i.grabPos = UNITY_PROJ_COORD(i.grabPos);

                fixed4 f = tex2Dproj(_GrabTexture, i.grabPos);

                float finalAlpha = stepDotP ? lerp(_RimColor.a, c.a, abs(dotP)) : 1;

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
