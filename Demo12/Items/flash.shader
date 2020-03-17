shader_type canvas_item;

void fragment(){
	vec2 uv = UV - vec2(0.5);
	float y = uv.y;
	float x = uv.x;
	
	float blur = 0.05;
	float speed = 0.75;
	float animation = abs(fract(TIME * speed)) * 2.0 - 1.0;
	animation *= 1.5;
	float left = -0.15 - animation;
	float right = 0.15 - animation;
	float value = smoothstep(left - blur, left, x + 0.5 * y);
	value -= smoothstep(right, right + blur, x + 0.5 * y);
	
	vec4 color = texture(TEXTURE, UV);
	COLOR = color + value * 0.15;
	COLOR.a = color.a;
}




