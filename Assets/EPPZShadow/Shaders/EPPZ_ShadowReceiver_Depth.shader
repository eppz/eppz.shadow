﻿Shader "eppz!/Shadow/Receiver (depth)"
{
	Properties
	{
		_MainColor ("Main Color", Color) = (1,1,1,1) 	
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_ShadowMap ("Shadow map (RGB)", 2D) = "white" {}	
	}
	
    SubShader
    {   
    
    
    	// Test shadow vertex projection depth against shadow map value.
        Pass
      	{
      		Lighting Off
      		
			GLSLPROGRAM
         	#include "Assets/EPPZShadow/Shaders/EPPZ_Shadow.glslinc"

         	uniform vec4 _MainColor; 
 			uniform sampler2D _MainTex;
 			varying vec4 v_textureCoordinates;
			
			#ifdef VERTEX
			
			void main()
			{
				// Screen projection for vertex output.
				gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
				v_textureCoordinates = gl_MultiTexCoord0;       	
				
				SHADOW_VERTEX;
			}
			
			#endif

			#ifdef FRAGMENT
					
			vec4 textureBlur2D(sampler2D texture_, vec2 uv, float blurSize, int kernelSize)
			{
				int iterations = 1 + 2 * kernelSize;
				float weight = 1.0 / float(iterations);
				vec4 sample = vec4(0.0, 0.0, 0.0, 0.0); // Start from black
				
				for (int index = -kernelSize; index <= kernelSize; index++)
				{
					sample += texture2D(texture_, vec2(uv.x + float(index) * blurSize, uv.y)) * weight;
				}
				
				return sample;
			}
			
			float shadowCoverageForShadowProjection_z(float shadowProjection_z, float bias, vec2 uv, float blurSize, int kernelSize)
			{
				int iterations = 1 + 2 * kernelSize;
				float weight = 1.0 / float(iterations) * 2.0;
				float coverage = 0.5;
				
				for (int index = -kernelSize; index <= kernelSize; index++)
				{
					vec4 shadowDepthSample = texture2D(_ShadowMap, vec2(uv.x + float(index) * blurSize, uv.y));
					float shadowDepth = shadowDepthSample.r;
					bool shadowed = (shadowDepth + bias > shadowProjection_z);
					if (shadowed)
					{
						coverage += weight;
					}
					else
					{
						coverage -= weight;
					}
					
				}
				
				return coverage;
			}
								
			void main()
			{
				vec4 outputColor; 
				float bias = 0.025;
				float blurSize = 0.02;
				
				vec4 unlitColor = vec4(0, 0, 0, 1);
				
				
				// Normalize shadow projection positions.
				vec4 shadowProjection_Position = v_shadowProjection_Position / v_shadowProjection_Position.w;
			
				// Get shadow depth sample for this fragment position.
				vec2 shadowMap_UV = vec2(
					(shadowProjection_Position.x + 1.0) * 0.5,
					(shadowProjection_Position.y + 1.0) * 0.5
					);
			
				vec4 shadowDepthSample = texture2D(_ShadowMap, shadowMap_UV);
				float shadowDepth = shadowDepthSample.r; // unpackFloatFromVec4(sceneDepthSample);
				
				// Get shadow camera fragment depth.
				float shadowProjection_z = normalizedDepth(v_shadowProjection_Position);
				
				// Shadow tests.
				bool shadowed = (shadowDepth + bias < shadowProjection_z);				
				float shadowDistance = shadowProjection_z - shadowDepth;
				
				
				float shadowCoverage = shadowCoverageForShadowProjection_z(shadowProjection_z, bias, shadowMap_UV, shadowDistance * blurSize, 14);
				shadowCoverage *= (1.0 - shadowDistance * 0.1);
				// vec4 blurShadowDepthSample = textureBlur2D(_ShadowMap, shadowMap_UV, shadowDistance * blurSize, 7);
				
				outputColor = colorFromFloat(shadowCoverage); // colorFromFloat(shadowDistance);
				
				
				
				
				
				// Lighting.
				vec4 lightColor;
				if (v_attenuation > 0.0)
				{
					 lightColor = vec4(0, 0, 0, 1);
				}
				else
				{
					float lightAttenution = v_attenuation * -1.0;
					lightColor = vec4(lightAttenution, lightAttenution, lightAttenution, 1.0);
				}
				
				// Blend.
				vec4 litColor = lightColor;
				// outputColor = (shadowed) ? unlitColor : litColor;
				
				
				
				
				
				
				
				// Unlit fragments outside shadow camera frustum.
				if (shadowProjection_Position.x > 1.0) outputColor = unlitColor;
				if (shadowProjection_Position.x < -1.0) outputColor = unlitColor;
				if (shadowProjection_Position.y > 1.0) outputColor = unlitColor;
				if (shadowProjection_Position.y < -1.0) outputColor = unlitColor;		
				
				// Output.
				gl_FragColor = outputColor;
			}
			
			#endif

			ENDGLSL
		}		
   }
}