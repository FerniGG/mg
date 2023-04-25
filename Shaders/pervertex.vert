#version 120

uniform mat4 modelToCameraMatrix;
uniform mat4 cameraToClipMatrix;
uniform mat4 modelToWorldMatrix;
uniform mat4 modelToClipMatrix;

uniform int active_lights_n; // Number of active lights (< MG_MAX_LIGHT)
uniform vec3 scene_ambient;  // rgb

uniform struct light_t {
	vec4 position;    // Camera space
	vec3 diffuse;     // rgb
	vec3 specular;    // rgb
	vec3 attenuation; // (constant, lineal, quadratic)
	vec3 spotDir;     // Camera space
	float cosCutOff;  // cutOff cosine
	float exponent;
} theLights[4];     // MG_MAX_LIGHTS

uniform struct material_t {
	vec3  diffuse;
	vec3  specular;
	float alpha;
	float shininess;
} theMaterial;

attribute vec3 v_position; // Model space
attribute vec3 v_normal;   // Model space
attribute vec2 v_texCoord;

varying vec4 f_color;
varying vec2 f_texCoord;

//Argi infinituak (directional)
vec3 directional(int i){
	vec3 n=normalize(nmodelToCameraMatrix * vec4(v_normal, 0)).xyz;
	vec3 v = normalize(-(modelToCameraMatrix * (vec4(v_position,1)))).xyz; /*erpinetik camera doan vec3 mod=1*/
	vec3 l = normalize(-theLights[i].position).xyz;
	vec3 r = 2*dot(l,n)*n - l;
	float angle = max(0,dot(n,l));
	//barreiatua
	vec3 idiff = theMaterial.diffuse * theLights[i].diffuse; //gero 0 a aldatu i-ra
	//spekularra
	vec3 ispec = pow(max(0, dot(r,v)),theMaterial.shininess)*theMaterial.specular * theLights[i].specular;
	return angle*(idiff+ispec);//Itot[i]
}

//Argi lokalak (local)
vec3 local(int i){
	vec3 n=normalize(nmodelToCameraMatrix * vec4(v_normal, 0)).xyz;
	vec3 v = normalize(-(modelToCameraMatrix * (vec4(v_position,1)))).xyz; /*erpinetik camera doan vec3 mod=1*/
	vec3 p = (modelToCameraMatrix * (vec4(v_position,1))).xyz;	/*erpinaren posizioa*/
	vec3 Spos_p = (theLights[i].position.xyz-p);	/*argiaren posizioa - P*/
	vec3 l = normalize(Spos_p);
	vec3 r = 2*dot(l,n)*n - l;
	float angle = max(0,dot(n,l));
	//barreiatua
	vec3 idiff = theMaterial.diffuse * theLights[i].diffuse; //gero 0 a aldatu i-ra
	//spekularra
	vec3 ispec = pow(max(0, dot(r,v)),theMaterial.shininess)*theMaterial.specular * theLights[i].specular;
	float d=1;
	return d * angle*(idiff+ispec);//Itot[i]
}
//Spotlight argiak



void main() {
	gl_Position = modelToClipMatrix * vec4(v_position, 1);
}
