// DONT TOUCH ++++++++++++
#define PC
#define IS_VERTEX_SHADER 1
#define IS_PIXEL_SHADER 0
#include <shader_vars.h>
// DONT TOUCH ++++++++++++

struct VertexInput
{
	float4 position : POSITION;
    float4 normal   : NORMAL;
	float4 color 	: COLOR0;
    float4 tc       : TEXCOORD0;
};

struct PixelInput
{
	float4 position     : POSITION;
    float3 tc           : TEXCOORD0;
    float4 tc1          : TEXCOORD1;
    float3 worldPos     : TEXCOORD2;
    float3 worldNormal  : TEXCOORD3;
    float3 tc6          : TEXCOORD6;
};

PixelInput vs_main( const VertexInput vertex ) 
{

    // I´ve recreated this one out of shader assembly ripped from cod4
    // It does the same, but looks kinda .. you´ll see :p

	PixelInput pixel;
  
    float  shadowmapConst = 0.0009765625;
    float  oneQuarter     = 0.25;
    float  chunks         = 0.0078125; // 8.0 / 1024
    float  maxFLT         = 3.05175781e-005;
    float  noise          = 0.03125;
    float4 c99            = float4( 0.00787401572, 0.00392156886, -1, 0.752941191 );



    float4 setup;
    setup = float4( shadowmapConst * vertex.tc.zx, maxFLT * vertex.tc.zx);
    setup = float4( vertex.tc.wy * oneQuarter, vertex.tc.wy * chunks ) + setup;

    float4 fraction;
    fraction = frac(setup);

    float4 idk;
    idk = float4( fraction.xy * -noise + fraction.zw, setup.zw + -fraction.zw );

    float2 uv1;
    float2 uv2;
    float2 uv3;
    float2 uv4;

    uv1 = float2( idk.xy * 32.0 + -15.0 );
    uv2 = float2( idk.zw * -2.0 + 1.0 );

    uv3 = float2( uv2 * fraction.xy + uv2 );
    uv4 = pow(2, uv1);

    pixel.tc.xy = float2( uv3 * uv4 ); 
    pixel.tc.z = 1.0;

    // ############################ TEXCOORDS END ####################################
    // ############################ POSITION BEGIN ###################################

    pixel.position = mul( float4( vertex.position.xyz, 1.0f ), worldMatrix );
    pixel.position = mul( pixel.position, viewProjectionMatrix ); 

    float4 normal1;
    normal1 = float4( vertex.normal.xyz * c99.x, vertex.normal.w * c99.y) + c99.zzzw;

    float3 normal2;
    normal2.xyz = normal1.w * normal1.xyz;
    
    pixel.tc1 = float4( mul( normal2.xyz, worldMatrix ).xyz, 1.0f);
    pixel.tc6 = baseLightingCoords;

    pixel.worldPos = vertex.position.xyz; 
    pixel.worldNormal = normal2.xyz;

	return pixel;
}
