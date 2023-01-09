local shaders = {}

shaders.model = love.graphics.newShader[[
	#ifdef VERTEX
		uniform mat4 modelMatrix;
		uniform mat4 viewMatrix;
		uniform mat4 projectionMatrix;
		uniform bool isCanvasEnabled; 
		vec4 position(mat4 transform_projection, vec4 vertex_position)
		{
			vec4 screenPosition = projectionMatrix * viewMatrix * modelMatrix * vertex_position;
			if (isCanvasEnabled) {
				screenPosition.y *= -1.0;
			}
			return screenPosition;
		}
	#endif
	#ifdef PIXEL
		vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) 
		{ 
			return color; 
		}
	#endif
]]

shaders.billboard = love.graphics.newShader[[
	#ifdef VERTEX
		uniform mat4 modelMatrix;
		uniform mat4 viewMatrix;
		uniform mat4 projectionMatrix;
		uniform bool isCanvasEnabled;
		vec4 position(mat4 transform_projection, vec4 vertexPosition)
		{
			mat4 modelView = viewMatrix * modelMatrix;
			modelView[0] = vec4(1, 0, 0, 0);
			modelView[1] = vec4(0, 1, 0, 0);
			modelView[2] = vec4(0, 0, 1, 0);
			vec4 screenPosition = projectionMatrix * modelView * vertexPosition;
			if (isCanvasEnabled) {
				screenPosition.y *= -1.0;
			}
			return screenPosition;
		}
	#endif
	#ifdef PIXEL
		vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) 
		{ 
			//vec4 texturecolor = Texel(tex, tc);
			//return texturecolor * color;
			return color; 
		}
	#endif
]]


return shaders

