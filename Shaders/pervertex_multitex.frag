#version 120

varying vec4 f_color;
varying vec2 f_texCoord;

uniform sampler2D texture0;
uniform sampler2D texture1;

uniform float uCloudOffset; // The offset of the cloud texture

void main() {
	vec4 texColor_0;
	vec4 texColor_1;
	vec4 texColor_Tot;

	//gl_FragColor = vec4(1.0);
	vec2 f_texCoord_1 = vec2(f_texCoord[0]+uCloudOffset,f_texCoord[1]);	/*koord mugitu S ren norabide beran uCloudOffset-en funtzean*/


	texColor_0 = texture2D(texture0, f_texCoord);	
	texColor_1 = texture2D(texture1, f_texCoord_1);	

	// The final color must be a linear combination of both
	// textures with a factor of 0.5, e.g:
	//
	//color = 0.5 * color_of_texture0 + 0.5 * color_of_texture1;
	texColor_Tot = 0.5*texColor_0 + 0.5*texColor_1;	

	gl_FragColor = texColor_Tot * f_color;
}
