// Based on Sky3D by Cory Petkovsek and Contributors
// Copyright (c) 2023-2025 Cory Petkovsek and Contributors
// Copyright (c) 2021 J. Cuellar

shader_type sky;
render_mode use_debanding;

group_uniforms general;
uniform vec2 color_correction = vec2(0.0, 1.0);
uniform float horizon_offset = 0.0;
uniform float pixel_size : hint_range(0.0, 0.05, 0.001) = 0.01;

group_uniforms atmosphere;
uniform float atm_darkness = 0.5;
uniform float atm_sun_intensity = 18.0;
uniform vec4 atm_day_tint: source_color = vec4(0.808, 0.91, 1.0, 1.0);
uniform vec4 atm_horizon_light_tint: source_color = vec4(0.98, 0.635, 0.463, 1.0);
uniform vec4 atm_night_tint: source_color = vec4(0.041, 0.049, 0.061, 0.245);
uniform vec3 atm_level_params = vec3(1.0, 0.0, 0.0);
uniform float atm_thickness = 0.7;
uniform vec3 atm_beta_ray = vec3(0.00001, 0.00001, 0.00003);
uniform vec3 atm_beta_mie = vec3(0.00000003038);

group_uniforms sun_disk;
uniform vec4 sun_disk_color: source_color = vec4(0.996, 0.541, 0.14, 1.0);
uniform float sun_disk_intensity = 2.0;
uniform float sun_disk_size = 0.015;

group_uniforms sun_mie;
uniform vec4 atm_sun_mie_tint: source_color = vec4(1.0);
uniform float atm_sun_mie_intensity = 1.0;
uniform vec3 atm_sun_partial_mie_phase = vec3(0.36, 1.64, 1.6);

group_uniforms moon;
uniform vec4 moon_color: source_color = vec4(1.0);
uniform float moon_size = 0.07;

group_uniforms moon_mie;
uniform vec4 atm_moon_mie_tint: source_color = vec4(0.137, 0.184, 0.292, 1.0);
uniform float atm_moon_mie_intensity = 0.17152;
uniform vec3 atm_moon_partial_mie_phase = vec3(0.36, 1.64, 1.6);

group_uniforms stars;
uniform float stars_intensity = 1.0;
uniform float stars_scintillation = 0.75;
uniform float stars_scintillation_speed = 1.0;

group_uniforms clouds;
uniform vec4 clouds_night_color: source_color = vec4(0.09, 0.094, 0.129, 1.0);
uniform vec4 sun_light_color: source_color = vec4(1.0);

group_uniforms cumulus_clouds;
uniform bool cumulus_visible = true;
uniform float cumulus_intensity = 0.6;
uniform float cumulus_coverage = 0.55;
uniform float cumulus_thickness = 0.0243;
uniform float cumulus_absorption = 2.0;
uniform float cumulus_noise_freq = 2.7;
uniform float cumulus_sky_tint_fade = 0.0;
uniform float cumulus_size = 0.5;
uniform vec2 cumulus_position = vec2(0.0);
uniform sampler2D cumulus_texture;
uniform vec3 cumulus_partial_mie_phase = vec3(0.95756, 1.04244, 0.412);
uniform float cumulus_mie_intensity = 1.0;

group_uniforms transform_matrices;
uniform mat3 moon_matrix;

#include "Common.gdshaderinc"

// Simple hash for procedural stars
vec3 hash33(vec3 p) {
	p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
			  dot(p, vec3(269.5, 183.3, 246.1)),
			  dot(p, vec3(113.5, 271.9, 124.6)));
	return fract(sin(p) * 43758.5453123);
}

vec3 voronoi(vec3 x) {
	vec3 p = floor(x);
	vec3 f = fract(x);
	float id = 0.0;
	vec2 res = vec2(100.0);
	for (int k = -1; k <= 1; k++)
	for (int j = -1; j <= 1; j++)
	for (int i = -1; i <= 1; i++) {
		vec3 b = vec3(float(i), float(j), float(k));
		vec3 r = b - f + hash33(p + b);
		float d = dot(r, r);
		if (d < res.x) {
			id = dot(p + b, vec3(1.0, 57.0, 113.0));
			res = vec2(d, res.x);
		} else if (d < res.y) {
			res.y = d;
		}
	}
	return vec3(sqrt(res), abs(id));
}

float calc_disk_mask(vec3 norm, vec3 coords, lowp float size) {
	float dist = length(norm - coords);
	return 1.0 - step(size, dist);
}

float simple_sphere_intersect(vec3 ray_dir, vec3 sphere_pos, float radius) {
	vec3 oc = -sphere_pos;
	float b = dot(oc, ray_dir);
	float c = dot(oc, oc) - radius * radius;
	float h = b * b - c;
	float valid = step(0.0, h);
	h = sqrt(max(h, 0.0));
	return mix(-1.0, -b - h, valid);
}

float map_range(float value, float from_min, float from_max, float to_min, float to_max) {
	return to_min + (value - from_min) * (to_max - to_min) / (from_max - from_min);
}

bool ray_sphere_intersect(float r, vec3 origin, vec3 dir, out float t, out vec3 nrm) {
	origin += vec3(0.0, 450.0, 0.0);
	float a = dot(dir, dir);
	float b = 2.0 * dot(origin, dir);
	float c = dot(origin, origin) - r * r;
	float d = b * b - 4.0 * a * c;
	float valid = step(0.0, d);
	d = sqrt(max(d, 0.0));
	a *= 2.0;
	float t1 = 0.5 * (-b + d);
	float t2 = 0.5 * (-b - d);
	float t_min = min(t1, t2);
	t = mix(t2, t1, step(t2, t1) * step(0.0, t1));
	t = mix(0.0, t, step(0.0, t) * valid);
	nrm = mix(vec3(0.0), origin + t * dir, step(0.0, t) * valid);
	return bool(step(0.0, t) * valid);
}

vec3 calc_atmospheric_scatter(float sr, float sm, vec2 mu, vec3 mult) {
	vec3 beta_mie = atm_beta_mie;
	vec3 beta_ray = atm_beta_ray * atm_thickness;

	vec3 extc_factor = clamp_rgb_to_unit(exp(-(beta_ray * sr + beta_mie * sm)));

	float extc_ff = mix(clamp_to_unit(atm_thickness * 0.5), 1.0, mult.x);
	vec3 final_extc_factor = mix(1.0 - extc_factor, (1.0 - extc_factor) * extc_factor, extc_ff);
	float rayleigh_phase = calc_rayleigh_phase(mu.x);
	vec3 BRT = beta_ray * rayleigh_phase;
	vec3 BMT = beta_mie * calc_mie_phase(mu.x, atm_sun_partial_mie_phase);
	BMT *= atm_sun_mie_intensity * atm_sun_mie_tint.rgb;

	vec3 BRMT = (BRT + BMT) / (beta_ray + beta_mie);
	vec3 scatter = atm_sun_intensity * (BRMT * final_extc_factor) * atm_day_tint.rgb * mult.y;
	scatter = mix(scatter, scatter * (1.0 - extc_factor), atm_darkness);

	vec3 lcol = mix(atm_day_tint.rgb, atm_horizon_light_tint.rgb, mult.x);
	vec3 nscatter = (1.0 - extc_factor) * atm_night_tint.rgb;
	nscatter += calc_mie_phase(mu.y, atm_moon_partial_mie_phase) *
		atm_moon_mie_tint.rgb * atm_moon_mie_intensity * 0.005;

	return (scatter * lcol) + nscatter;
}

const int CUMULUS_STEP = 10;

float sample_cumulus_noise(vec3 p) {
	vec3 pos = vec3(p * 0.01);
	pos.z *= 256.0;
	vec2 offset = vec2(0.317, 0.123);
	vec4 uv = vec4(0.0);
	uv.xy = pos.xy + offset * floor(pos.z);
	uv.zw = uv.xy + offset;
	float x1 = textureLod(cumulus_texture, uv.xy, 0.0).r;
	float x2 = textureLod(cumulus_texture, uv.zw, 0.0).r;
	return mix(x1, x2, fract(pos.z));
}

float calc_cumulus_fbm(vec3 p, float l) {
	float ret;
	ret = 0.51749673 * sample_cumulus_noise(p);
	p *= l;
	ret += 0.25584929 * sample_cumulus_noise(p);
	p *= l;
	ret += 0.12527603 * sample_cumulus_noise(p);
	p *= l;
	ret += 0.06255931 * sample_cumulus_noise(p);
	return ret;
}

float calc_cumulus_density(vec3 p, vec3 wind_offset, float t) {
	vec3 pos = p * 0.0212242 - wind_offset;
	float dens = calc_cumulus_fbm(pos, cumulus_noise_freq);
	dens += dens;
	float cov = 1.0 - cumulus_coverage;
	cov = smoothstep(0.00, (cov * 3.5) + t, dens);
	dens *= cov;
	dens = map_range(dens, 1.0 - cov, 1.0, 0.0, 1.0);
	return clamp_to_unit(dens);
}

vec4 render_cumulus_clouds(vec3 ro, vec3 rd, float am, vec3 sun_pos, vec3 moon_pos) {
	vec4 ret = vec4(0.0);
	vec3 wind = -vec3(cumulus_position.x, 0.0, cumulus_position.y);
	float a = 0.0;

	vec3 n; float tt;
	if (ray_sphere_intersect(500.0, ro, rd, tt, n)) {
		float march_step = float(CUMULUS_STEP) * cumulus_thickness;
		vec3 dir_step = rd / rd.y * march_step;
		vec3 pos = n * cumulus_size;

		vec2 mu = vec2(dot(sun_pos, rd), dot(moon_pos, rd));
		vec3 mph = ((calc_mie_phase(mu.x, cumulus_partial_mie_phase) * atm_sun_mie_tint.rgb) +
			calc_mie_phase(mu.y, cumulus_partial_mie_phase) * am);

		vec4 t = vec4(1.0);
		t.rgb += (mph.rgb * cumulus_mie_intensity);

		for (int i = 0; i < CUMULUS_STEP; i++) {
			float h = float(i) * 0.1;
			float density = calc_cumulus_density(pos, wind, h);
			float sh = clamp_to_unit(exp(-cumulus_absorption * density * march_step));
			t *= sh;
			ret += (t * (exp(h) * 0.571428571) * density * march_step);
			a += (1.0 - sh) * (1.0 - a);
			pos += dir_step;
		}
		return vec4(ret.rgb * cumulus_intensity, a);
	}
	return vec4(ret.rgb * cumulus_intensity, a);
}

vec3 render_sky(vec3 world_pos, vec3 raw_dir, vec3 clouds_pos, vec3 sun_pos, vec3 moon_pos, float p_time) {
	vec3 col = vec3(0.0);

	vec4 angle_mult;
	angle_mult.x = clamp_to_unit(1.0 - sun_pos.y);
	angle_mult.y = clamp_to_unit(sun_pos.y + 0.45);
	angle_mult.z = clamp_to_unit(-sun_pos.y + 0.30);
	angle_mult.w = clamp_to_unit(-sun_pos.y + 0.60);

	// Use raw (non-pixelated) direction for Mie/sun/moon to avoid bright seam artifacts
	vec2 mu = vec2(dot(sun_pos, raw_dir), dot(moon_pos, raw_dir));
	float sr, sm;
	calc_simple_optical_depth(world_pos.y + atm_level_params.z - horizon_offset, sr, sm, atm_level_params.xy);

	world_pos.y -= horizon_offset;
	float horizonBlend = clamp_to_unit((world_pos.y - 0.03) * 3.0);
	float horizonBlendCumulus = clamp_to_unit((world_pos.y + 0.01) * 50.0);

	// Atmospheric scattering
	vec3 scatter = calc_atmospheric_scatter(sr, sm, mu.xy, angle_mult.xyz);
	col.rgb += scatter.rgb;

	// Sun disk (use raw_dir for smooth circular disk)
	vec3 sun_disk = calc_disk_mask(raw_dir, sun_pos, sun_disk_size) * sun_disk_color.rgb * scatter.rgb;
	sun_disk *= sun_disk_intensity;

	// Moon disk (use raw_dir for smooth sphere intersection)
	float moon_intersect = simple_sphere_intersect(raw_dir, moon_pos, moon_size);
	float moon_mask = moon_intersect > (-1.0 + sqrt(moon_size)) ? 1.0 : 0.0;
	vec3 moon_normal = normalize(raw_dir * moon_intersect - moon_pos);
	float moon_ndotl = clamp(dot(moon_normal, sun_pos), 0.0, 1.0);
	vec3 moon_output = moon_mask * moon_ndotl * exp2(1.0) * moon_color.rgb;
	float moonMask = (1.0 - moon_mask);

	// Procedural stars (voronoi-based, keep pixelated for aesthetic)
	vec3 deep_space = moon_output;
	if (stars_intensity > 0.0) {
		vec2 stars = voronoi(world_pos * 30.0).xz;
		float scintillation = mix(1.0, 0.5 + 0.5 * sin(p_time * stars_scintillation_speed + stars.y * 10.0), stars_scintillation);
		float star_mask = smoothstep(0.025 + 0.03 * (0.5 + 0.5 * sin(p_time * 0.5 + stars.y)), 0.0, stars.x);
		deep_space.rgb += star_mask * stars_intensity * scintillation * moonMask;
	}
	deep_space.rgb *= angle_mult.z;
	col.rgb += sun_disk.rgb + deep_space.rgb * horizonBlend;

	// Cumulus clouds
	if (cumulus_visible) {
		vec4 cumulus_clouds = render_cumulus_clouds(vec3(0.0), clouds_pos, angle_mult.z, sun_pos, moon_pos);
		cumulus_clouds.a = clamp_to_unit(cumulus_clouds.a);
		vec3 cloud_tint = sun_light_color.rgb;
		cloud_tint = mix(cloud_tint, clouds_night_color.rgb, angle_mult.w);
		cumulus_clouds.rgb *= cloud_tint * cumulus_intensity;
		cumulus_clouds.a = mix(0.0, cumulus_clouds.a, horizonBlend);
		col.rgb = mix(col.rgb, cumulus_clouds.rgb + mix(vec3(0.0), scatter, cumulus_sky_tint_fade), cumulus_clouds.a);
	}

	// Below horizon: mirror atmosphere color instead of flat ground
	float below_horizon = clamp_to_unit((-world_pos.y - atm_level_params.z) * 100.0);
	vec3 mirrored_pos = vec3(world_pos.x, abs(world_pos.y), world_pos.z);
	vec3 mirrored_raw = vec3(raw_dir.x, abs(raw_dir.y), raw_dir.z);
	vec2 mirror_mu = vec2(dot(sun_pos, mirrored_raw), dot(moon_pos, mirrored_raw));
	float mirror_sr, mirror_sm;
	calc_simple_optical_depth(mirrored_pos.y + atm_level_params.z, mirror_sr, mirror_sm, atm_level_params.xy);
	vec3 ground_scatter = calc_atmospheric_scatter(mirror_sr, mirror_sm, mirror_mu, angle_mult.xyz);
	col.rgb = mix(col.rgb, ground_scatter, below_horizon);

	// Tonemapping
	col.rgb = apply_photo_tonemap(col.rgb, color_correction.y, color_correction.x);

	return col;
}

vec3 pixelate_direction(vec3 dir, float size) {
	if (size <= 0.0) return dir;
	float theta = acos(dir.y);
	float phi = atan(dir.x, dir.z);
	theta = floor(theta / size) * size + size * 0.5;
	phi = floor(phi / size) * size + size * 0.5;
	float sin_t = sin(theta);
	return vec3(sin_t * sin(phi), cos(theta), sin_t * cos(phi));
}

void sky() {
	vec3 col = vec3(0.0);
	vec3 world_pos = pixelate_direction(EYEDIR, pixel_size);
	vec3 clouds_pos = pixelate_direction(EYEDIR, pixel_size);
	vec3 sun_pos = LIGHT0_DIRECTION;
	vec3 moon_pos = -sun_pos;

	col = render_sky(world_pos, EYEDIR, clouds_pos, sun_pos, moon_pos, TIME);
	COLOR = col.rgb;
}
