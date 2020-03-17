shader_type canvas_item;

uniform vec4 tint_color : hint_color = vec4(1.0);
uniform vec4 replace_color : hint_color = vec4(1.0);

void fragment(){
	vec4 color = texture(TEXTURE, UV);
	if(distance(color, replace_color) <= 0.0001){
		color.rgb = tint_color.rgb;
	}
	COLOR = color;
}
