shader_type spatial;
render_mode unshaded;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_disable;
uniform sampler2D texture_flow : hint_normal,filter_linear_mipmap,repeat_disable;
uniform int particles_anim_h_frames;
uniform int particles_anim_v_frames;
uniform bool particles_anim_loop;
uniform bool smoothing = false;
uniform float flow_strength = 0.015;

varying vec2 next_UV;
varying float timer;

void vertex() {
	mat4 mat_world = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]) ,normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]);
	mat_world = mat_world * mat4(vec4(cos(INSTANCE_CUSTOM.x), -sin(INSTANCE_CUSTOM.x), 0.0, 0.0), vec4(sin(INSTANCE_CUSTOM.x), cos(INSTANCE_CUSTOM.x), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	float h_frames = float(particles_anim_h_frames);
	float v_frames = float(particles_anim_v_frames);
	float particle_total_frames = float(particles_anim_h_frames * particles_anim_v_frames);
	float particle_frame = floor(INSTANCE_CUSTOM.z * float(particle_total_frames));
	if (!particles_anim_loop) {
		particle_frame = clamp(particle_frame, 0.0, particle_total_frames - 1.0);
	} else {
		particle_frame = mod(particle_frame, particle_total_frames);
	}
	UV /= vec2(h_frames, v_frames);
	next_UV = UV;
	UV += vec2(mod(particle_frame, h_frames) / h_frames, floor((particle_frame + 0.5) / h_frames) / v_frames);
	next_UV += vec2(mod(particle_frame + 1.0, h_frames) / h_frames, floor((particle_frame + 1.0 + 0.5) / h_frames) / v_frames);
	timer = fract(INSTANCE_CUSTOM.y * h_frames * v_frames);
}

void fragment() {
	vec4 albedo_tex;
	if (smoothing) {
		vec2 flow_tex = texture(texture_flow, UV).rg;
		flow_tex -= 0.5;
		flow_tex *= 2.0;
		vec2 flow_uv = UV + flow_tex * timer * -flow_strength;
		vec2 reverse_flow_uv = next_UV + flow_tex * (1.0 - timer) * flow_strength;
		albedo_tex = mix(texture(texture_albedo, flow_uv), texture(texture_albedo, reverse_flow_uv), timer);
	} else {
		albedo_tex = texture(texture_albedo, UV);
	}
	albedo_tex *= COLOR;
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	ALPHA *= albedo.a * albedo_tex.a;
}