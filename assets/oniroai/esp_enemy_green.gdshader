shader_type spatial;
// Silhouette xanh lá phủ lên toàn bộ skin của NPC, cả khi đứng sau vật cản.
// GL Compatibility / Godot 4.5: lớp phủ nhẹ, không thay mesh hay animation.
render_mode unshaded, cull_disabled, depth_test_disabled, depth_draw_never, blend_mix, fog_disabled;
uniform vec4 esp_green : source_color = vec4(0.12, 1.0, 0.20, 0.87);
void fragment() {
    ALBEDO = esp_green.rgb;
    EMISSION = esp_green.rgb * 0.35;
    ALPHA = esp_green.a;
}
