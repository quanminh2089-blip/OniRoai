shader_type spatial;
render_mode cull_disabled;
uniform sampler2D body_color : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D body_normal : hint_normal, filter_linear_mipmap;
varying vec3 local_point;
void vertex() { local_point = VERTEX; }
void fragment() {
 // The imported scope has an opaque cap in the optical bore. Open that bore
 // in the actual mesh so the player can see the world through both apertures.
 if (length(local_point.xy - vec2(0.01444, 0.08805)) < 0.198) { discard; }
 ALBEDO = texture(body_color, UV).rgb;
 NORMAL_MAP = texture(body_normal, UV).rgb;
 NORMAL_MAP_DEPTH = 0.45;
 ROUGHNESS = 0.67;
 METALLIC = 0.4;
}
