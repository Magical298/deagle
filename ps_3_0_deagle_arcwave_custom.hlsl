// DONT TOUCH ++++++++++++
#define PC
#define IS_VERTEX_SHADER 0
#define IS_PIXEL_SHADER 1
#include <shader_vars.h>
// DONT TOUCH ++++++++++++

#define SCROLLMAP_SIZE      10.0    // default : 10.0; scales the scrolltexture
#define SCROLLMAP_BLEND1    0.2     // default : 0.2; scale to blend Side/Top/Front Scrolltextures
#define SCROLLMAP_BLEND2    1.8     // default : 1.8; scale to blend Side/Top/Front Scrolltextures

#define SCROLLMAP_SCROLLX   + (gameTime.w * 0.0)    // + / - defines the direction; gameTime.w the velocity
#define SCROLLMAP_SCROLLY   + (gameTime.w * 0.0)    // + / - defines the direction; gameTime.w the velocity
#define SCROLLMAP_SCROLLZ   + (gameTime.w * 0.8)    // + / - defines the direction; gameTime.w the velocity

#define USE_SPECULAR        true    // use specular; if set to false -> comment (//) specularMapSampler & colorMapSampler1 in raw\techniques
#define SPECMAP_SIZE        1.0     // default : 1.0; 
#define SPECMAP_CONTRAST    2.0     // default : 2.0;
#define SPECMAP_BRIGHTNESS  0.0     // default : 0.0; -1 to decrease; 1 to increase 
#define SPECMAP_BLEND1      0.2     // default : 0.2; scale to blend Side/Top/Front Specmaptextures
#define SPECMAP_BLEND2      1.8     // default : 1.8; scale to blend Side/Top/Front Specmaptextures

struct PixelInput
{
	float4 position     : POSITION;
	float3 tc           : TEXCOORD0;
    float4 modelNormal  : TEXCOORD1;
    float3 worldPos     : TEXCOORD2;
    float3 worldNormal  : TEXCOORD3;
    float3 tc6          : TEXCOORD6;
};

struct PixelOutput
{
	float4 color        : COLOR;
};

PixelOutput ps_main( const PixelInput pixel )
{
    PixelOutput fragment;

    float3 normal;
    float  majorNormal;
    float  reciprocalNormal;

    float3 lightLookup;
    float  sunDir;

    float3 lightSamplerUVS;
    float4 modelLightSample;
    float3 modelLightMultiplier;
    float3 modelLight;
    float3 modelLightFinal;

    float4 modelTexture;

    normal              = normalize( pixel.modelNormal );
    majorNormal         = max( abs(normal.x), max(abs(normal.y), abs(normal.z)) );
    reciprocalNormal    = 1.0 / majorNormal;

    lightLookup = float3( normal * lightingLookupScale.xyz );
    sunDir      = saturate( (sunPosition.x * normal.x) + (sunPosition.y * normal.y) + (sunPosition.z * normal.z) );

    lightSamplerUVS         = float3( lightLookup * reciprocalNormal ) + pixel.tc6.xyz;
    modelLightSample        = tex3D( modelLightingSampler, lightSamplerUVS );
    modelLightMultiplier    = float3( modelLightSample.xyz * 2.0 );
    modelLight              = float3( sunDir * sunDiffuse.xyz );
    modelLightFinal         = float3( modelLightSample.w * modelLight ) + modelLightMultiplier;

    modelTexture = tex2D( colorMapSampler, pixel.tc );

    // ---- SCROLLMAP UP / SIDE / DOWN TEXTURING USING WORLD POSITIONS ----------------------------------- 

    float3 tpUVS; 
    float3 tpBlend;
    float4 tpSample;
    float3 modelTexLitFog;

    tpUVS = float3( pixel.worldPos.x SCROLLMAP_SCROLLX, 
                    pixel.worldPos.y SCROLLMAP_SCROLLY, 
                    pixel.worldPos.z SCROLLMAP_SCROLLZ) / SCROLLMAP_SIZE;

    tpBlend = saturate(abs(pixel.worldNormal.xyz) - SCROLLMAP_BLEND1);
    tpBlend =  pow(tpBlend, SCROLLMAP_BLEND2);
    tpBlend /= dot(tpBlend, float3(1.0, 1.0, 1.0));

    tpSample = tpBlend.x * tex2D(colorMapSampler2, tpUVS.yz);
    tpSample = tpBlend.y * tex2D(colorMapSampler2, tpUVS.xz) + tpSample;
    tpSample = tpBlend.z * tex2D(colorMapSampler2, tpUVS.xy) + tpSample;

    // COLOR FUN ::
    //tpSample.x = tpSample.x * clamp( sin( gameTime.w * 0.5 ), 0.5, 1.5 );
    //tpSample.y = tpSample.y * clamp( sin( gameTime.w * 1.5 ), 0.5, 1.5 );

    modelTexLitFog = float3( modelTexture.xyz * modelLightFinal.xyz ) + ( - fogColor.xyz );
    modelTexLitFog = float3( pixel.modelNormal.w * modelTexLitFog.xyz ) + fogColor.xyz;

    // ALPHA BLENDING ::
    fragment.color.xyz = lerp( tpSample.xyz, modelTexLitFog, modelTexture.w );
    fragment.color.w = 1.0;

    // ---- SPECMAP UP / SIDE / DOWN TEXTURING -----------------------------------
    if( USE_SPECULAR )
    {
        float4 specMap;
        float  specAlpha;
        float3 specUVS;
        float4 specMapSample;

        specMap = tex2D( specularMapSampler, pixel.tc );

        // EDIT CONTRAST :: SPECULARMAP-ALPHA-CHANNEL
        specAlpha = ((specMap.w - 0.5f) * (SPECMAP_CONTRAST + (1.0 - sunSpecular.x)) ) + 0.5f;

        // EDIT BRIGHTNESS :: SPECULARMAP-ALPHA-CHANNEL
        specAlpha += SPECMAP_BRIGHTNESS;

        specUVS = float3( pixel.tc.xyz ) / SPECMAP_SIZE;

        tpBlend =  saturate(abs( pixel.tc.xyz ) - SPECMAP_BLEND1);
        tpBlend =  pow(tpBlend, SPECMAP_BLEND2);
        tpBlend /= dot(tpBlend, float3(1.0, 1.0, 1.0));

        specMapSample = tpBlend.x * tex2D(colorMapSampler1, specUVS.yz);
        specMapSample = tpBlend.y * tex2D(colorMapSampler1, specUVS.xz) + specMapSample;
        specMapSample = tpBlend.z * tex2D(colorMapSampler1, specUVS.xy) + specMapSample;

        // ALPHA BLENDING ::
        fragment.color.xyz = lerp( fragment.color.xyz, specMapSample.xyz, specAlpha );
    }
    // ARCWAVE BLUE ENERGY TEST
    float energyPulse;
    energyPulse = 0.5 + 0.5 * sin(gameTime.w * 4.0);

    fragment.color.xyz += float3(0.0, 0.15, 0.8) * energyPulse * 0.35;

    return fragment;
}
