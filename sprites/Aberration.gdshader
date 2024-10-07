shader_type canvas_item;

uniform float spread : hint_range(0, 5) = 0;

vec3 chromatic_slice(float t){
	vec3 res = vec3(1.0 - t, 1.0 - abs(t - 1.0), t - 1.0);
	return max(res, 0.0);
}

void fragment(){
	vec3 sum = vec3(0);
	COLOR.rgb = vec3(0);
	vec2 offset = (UV - vec2(0.5)) / vec2(100, -75);
	for(int i = 0; i < 3; i++){
		float t = 2.0 * float(i) / float(3 - 1);
		vec3 slice = chromatic_slice(t);
		slice = max(slice, 0.0);
		sum += slice;
		vec2 slice_offset = (t - 1.0) * spread * offset;
		COLOR.rgb += slice * texture(SCREEN_TEXTURE, SCREEN_UV + slice_offset).rgb;
	}
	COLOR.rgb /= sum;
}