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
vec3 directional_specularra(int i){
	vec3 n=normalize(modelToCameraMatrix * vec4(v_normal, 0)).xyz;
	vec3 v = normalize(-(modelToCameraMatrix * (vec4(v_position,1)))).xyz; /*erpinetik camera doan vec3 mod=1*/
	vec3 l = normalize(-theLights[i].position).xyz;
	vec3 r = 2*dot(l,n)*n - l;
	float angle = max(0,dot(n,l));
	//barreiatua
	vec3 idiff = theMaterial.diffuse * theLights[i].diffuse; //gero 0 a aldatu i-ra
	//spekularra
	vec3 ispec = pow(max(0, dot(r,v)),theMaterial.shininess)*theMaterial.specular * theLights[i].specular;
	return angle*(idiff+ispec);
}
vec3 directional_barreiatua(int i){
	vec3 n=normalize(modelToCameraMatrix * vec4(v_normal, 0)).xyz;
	vec3 v = normalize(-(modelToCameraMatrix * (vec4(v_position,1)))).xyz; /*erpinetik camera doan vec3 mod=1*/
	vec3 l = normalize(-theLights[i].position).xyz;
	vec3 r = 2*dot(l,n)*n - l;
	float angle = max(0,dot(n,l));
	//barreiatua
	vec3 idiff = theMaterial.diffuse * theLights[i].diffuse; //gero 0 a aldatu i-ra
	//spekularra
	vec3 ispec = pow(max(0, dot(r,v)),theMaterial.shininess)*theMaterial.specular * theLights[i].specular;
	return angle*idiff;
}
//Argi lokalak (local)
vec3 local_ahuldurekin(int i){
	vec3 n=normalize(modelToCameraMatrix * vec4(v_normal, 0)).xyz;
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
	float Sc = theLights[i].attenuation[0];
	float Sl = theLights[i].attenuation[1];
	float Sq = theLights[i].attenuation[2];
	d=d/(Sc+Sl*length(Spos_p)+Sq*pow(length(Spos_p),2));
	return d * angle*(idiff+ispec);
}

//Spotlight argiak
vec3 spotlight(int i){
	vec3 n=normalize(modelToCameraMatrix * vec4(v_normal, 0)).xyz;
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
	
	float cos_alpha=dot(-1*l,theLights[i].spotDir);
	//spotlight
	float C_spot = max((cos_alpha),0);
	
	if (cos_alpha<theLights[i].cosCutOff){	
		C_spot=0;
	}

	return pow(C_spot,theLights[i].exponent)*angle*(idiff+ispec);
}


void main() {
	vec3 i_tot=vec3(0,0,0);
	if(active_lights_n==0){
		i_tot= vec3(scene_ambient);
	}
	for (int i=0; i<active_lights_n; i++){	
		if (theLights[i].position[3]==0){	/*argi direkzionala erabili*/
			i_tot += vec3(directional_specularra(i));
		}else if(theLights[i].cosCutOff>0 && theLights[i].cosCutOff<90){ /*Spotlight erabiltzen ari gara*/
			i_tot += vec3(spotlight(i));
		}else{
			i_tot += vec3(local_ahuldurekin(i));/*argi lokala erabiltzen ari gara.*/
		}
	}
	i_tot+=scene_ambient;


	f_color=vec4(i_tot,1);
	f_texCoord = v_texCoord;
	gl_Position = modelToClipMatrix * vec4(v_position, 1);
}
