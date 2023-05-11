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


vec3 directional (int i){
	vec3 itot=vec3(0,0,0);
	vec4 n_4 =  modelToCameraMatrix * vec4(v_normal, 0);

	vec3 n = normalize(n_4).xyz; /*planoaren normala*/

	vec3 l = normalize(-theLights[i].position).xyz;	/*argiaren kontrako norabidea, normalizatua*/
	
	float angle = max(0,dot(l,n));	/*argia eta normalaren arteko angelua*/

	//barreiatua
	vec3 idiff = theMaterial.diffuse * theLights[i].diffuse;	/*materialeko faktore barreiatua bider argiren faktore barreiatua*/
	//espekularra
	vec3 v = normalize(-(modelToCameraMatrix * (vec4(v_position,1)))).xyz; /*erpinetik ikuslera doan bektore unitarioa*/
	vec3 r = 2*dot(l,n)*n - l;
	float angle_spec = pow(max(0, dot(r,v)),theMaterial.shininess);
	vec3 ispec = angle_spec * (theMaterial.specular * theLights[i].specular);	/*r eta v arteko angelua bider materialeko faktore espekularra bider rgiren faktore espekularra*/
	
	itot=angle * (idiff+ispec);
	return itot;

}

vec3 local (int i){
	vec3 itot=vec3(0,0,0);
	vec4 n_4 =  modelToCameraMatrix * vec4(v_normal, 0);

	vec3 n = normalize(n_4).xyz; /*planoaren normala*/

	vec3 l = normalize(-theLights[i].position).xyz;	/*argiaren kontrako norabidea, normalizatua*/
	
	float angle = max(0,dot(l,n));	/*argia eta normalaren arteko angelua*/

	//barreiatua
	vec3 idiff = theMaterial.diffuse * theLights[i].diffuse;	/*materialeko faktore barreiatua bider argiren faktore barreiatua*/
	//espekularra
	vec3 v = normalize(-(modelToCameraMatrix * (vec4(v_position,1)))).xyz; /*erpinetik ikuslera doan bektore unitarioa*/
	vec3 r = 2*dot(l,n)*n - l;
	float angle_spec = pow(max(0, dot(r,v)),theMaterial.shininess);
	vec3 ispec = angle_spec * (theMaterial.specular * theLights[i].specular);	/*r eta v arteko angelua bider materialeko faktore espekularra bider rgiren faktore espekularra*/
	
	vec3 P = (modelToCameraMatrix * (vec4(v_position,1))).xyz;	/*erpinaren posizioa*/
	vec3 Spos_p = (theLights[i].position.xyz-P);	/*argiaren posizioa - P*/
	vec3 li = normalize(Spos_p);	
	float angle_local = max(0,dot(n, li));	/*gainazalaren normala eta rpinetik argira doan bektore unitarioaren arteko angelua*/
	float d = 1.0/(theLights[i].attenuation[0]+theLights[i].attenuation[1]*length(Spos_p) + theLights[i].attenuation[2]*pow(length(Spos_p),2));
	itot=d*angle_local*(idiff+ispec);
	return itot;
}

vec3 spotlight (int i){
	vec3 itot=vec3(0,0,0);
	vec4 n_4 =  modelToCameraMatrix * vec4(v_normal, 0);

	vec3 n = normalize(n_4).xyz; /*planoaren normala*/

	vec3 l = normalize(-theLights[i].position).xyz;	/*argiaren kontrako norabidea, normalizatua*/
	
	float angle = max(0,dot(l,n));	/*argia eta normalaren arteko angelua*/

	//barreiatua
	vec3 idiff = theMaterial.diffuse * theLights[i].diffuse;	/*materialeko faktore barreiatua bider argiren faktore barreiatua*/
	//espekularra
	vec3 v = normalize(-(modelToCameraMatrix * (vec4(v_position,1)))).xyz; /*erpinetik ikuslera doan bektore unitarioa*/
	vec3 r = 2*dot(l,n)*n - l;
	float angle_spec = pow(max(0, dot(r,v)),theMaterial.shininess);
	vec3 ispec = angle_spec * (theMaterial.specular * theLights[i].specular);	/*r eta v arteko angelua bider materialeko faktore espekularra bider rgiren faktore espekularra*/
	

	vec3 P = (modelToCameraMatrix * (vec4(v_position,1))).xyz;	/*erpinaren posizioa*/
	vec3 Spos_p = (theLights[i].position.xyz-P);	/*argiaren posizioa - P*/
	vec3 li = normalize(Spos_p);	
	float angle_local = max(0,dot(n, li));	/*gainazalaren normala eta rpinetik argira doan bektore unitarioaren arteko angelua*/
	float angle_spot=dot(-li,theLights[i].spotDir);
	//spotlight
	float C_spot=0;	
	if (angle_spot>theLights[i].cosCutOff){	
		C_spot = max(angle_spot,0);
	}

	

	itot = pow(C_spot,theLights[i].exponent) * angle_local * (idiff+ispec);
	return itot;
}

void main() {
	vec3 itot = scene_ambient;
	for (int i=0; i<active_lights_n; i++){	/*piztutako argi kopuruaren arabera loop*/
		if (theLights[i].position[3]==0){	/*puntu bat izan beharrena bektore bat du (x,y,z,0). Bakarrik norabidea duenez, argi direkzionala erabili*/
			itot += vec3(directional(i));
		}else if(theLights[i].cosCutOff>0 && theLights[i].cosCutOff<90){ /*cosCutOff balio bat badu, spotlight argia erabiltzen ari gara*/
			itot += vec3(spotlight(i));
		}else{
			itot += vec3(local(i));
		}
	}
	f_color=vec4(itot,1);
	f_texCoord = v_texCoord;
	gl_Position = modelToClipMatrix * vec4(v_position, 1);
}