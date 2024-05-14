Shader "Custom/S_Crystal_1"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _OutColor ("Out Color", Color) = (0,0,0,1)
        _OutEdgeValue ("Out Edge Value", Range(0,1)) = 0.2
        _OutValue ("Out Value", Range(0,1)) = 0.25
        _Distortion ("Distortion Amount", Float) = 3
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType"="Transparent"}
        LOD 200
        ZWrite On

        Blend SrcAlpha OneMinusSrcAlpha

        GrabPass { }

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        // #pragma surface surf Standard fullforwardshadows alpha:transparent
        #pragma surface surf Standard fullforwardshadows vertex:vert

        #pragma debug

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 viewDir;
            float3 worldPos;
            fixed4 grabPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        fixed4 _OutColor;
        float _OutEdgeValue;
        float _OutValue;
        float _Distortion;

        sampler2D _GrabTexture;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void vert(inout appdata_full v, out Input o) {
		    UNITY_INITIALIZE_OUTPUT(Input, o);

		    float4 clipPos = UnityObjectToClipPos(v.vertex + fixed4(sin(tan(v.vertex.x)) * _Distortion,0,0,0));
		    o.grabPos = ComputeGrabScreenPos(clipPos);
	    }


        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            _OutValue = max(_OutEdgeValue, _OutValue);
            
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;

            float dotP = dot(o.Normal, IN.viewDir);

            float stepDotP = dotP < _OutEdgeValue || step(_OutValue, dotP);

            fixed4 f = tex2Dproj(_GrabTexture, UNITY_PROJ_COORD(IN.grabPos));  

            o.Albedo = stepDotP ? (f.rgb + float3(0.2,0.2,0.2)) * c.rgb : _OutColor;

            o.Alpha = 1;
            
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
