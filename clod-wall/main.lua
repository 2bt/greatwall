require "greatwall"

local graphics = love.graphics

function wall.load()

	fx = graphics.newPixelEffect([[

extern float time;
extern vec2 res;

float f(vec3 o) {
    float a=(sin(o.x)+o.y*.25)*.35;
    o=vec3(cos(a)*o.x-sin(a)*o.y,sin(a)*o.x+cos(a)*o.y,o.z);
    return dot(cos(o)*cos(o),vec3(1))-1.2;
}

#if 1
//
// modified by iq:
//   removed the break inside the marching loop (GLSL compatibility)
//   replaced 10 step binary search by a linear interpolation
//
vec3 s(vec3 o,vec3 d) {
    float t=0.0;
    float dt = 0.5;
    float nh = 0.0;
    float lh = 0.0;
    for(int i=0;i<50;i++)
    {
        nh = f(o+d*t);
        if(nh>0.0) { lh=nh; t+=dt; }
    }

    if( nh>0.0 ) return vec3(.93,.94,.85);

    t = t - dt*nh/(nh-lh);

    vec3 e=vec3(.1,0.0,0.0);
    vec3 p=o+d*t;
    vec3 n=-normalize(vec3(f(p+e),f(p+e.yxy),f(p+e.yyx))+vec3((sin(p*75.)))*.01);

    return vec3( mix( ((max(-dot(n,vec3(.577)),0.) + 0.125*max(-dot(n,vec3(-.707,-.707,0)),0.)))*(mod

(length(p.xy)*20.,2.)<1.0?vec3(.71,.85,.25):vec3(.79,.93,.4))
                           ,vec3(.93,.94,.85), vec3(pow(t/9.,5.)) ) );
}
#else
//
// original marching
//
vec3 s(vec3 o,vec3 d) {
    float t=0.,a,b;
    for(int i=0;i<75;i++) {
        if(f(o+d*t)<0.0) {
            a=t-.125;b=t;
            for(int i=0; i<10;i++) {
                t=(a+b)*.5;
                if(f(o+d*t)<0.0) b=t;
                else a=t;
            }
            vec3 e=vec3(.1,0.0,0.0);
            vec3 p=o+d*t;
            vec3 n=-normalize(vec3(f(p+e),f(p+e.yxy),f(p+e.yyx))+vec3((sin(p*75.)))*.01);

            return vec3(mix(((max(-dot(n,vec3(.577)),0.) + 0.125*max(-dot(n,vec3(-.707,-.707,0)),0.)))*(mod(length(p.xy)*20.,2.)<1.0?vec3(.71,.85,.25):vec3(.79,.93,.4))
                           ,vec3(.93,.94,.85), vec3(pow(t/9.,5.)) ) );
        }
        t+=.125;
    }
    return vec3(.93,.94,.85);
}
#endif

vec4 effect(vec4 color, sampler2D tex, vec2 tex_coords, vec2 pos) {
    vec2 p = -1.0 + 2.0 * pos / res;
    return vec4(s(vec3(sin(time*1.5)*.5,cos(time)*.5,time), normalize(vec3(p.xy,1.0))),1.0);
}
]])

	print(fx:getWarnings())
	return "bender", 1350
end


time = 0

function wall.tick()
	canvas = canvas or graphics.newCanvas()
	time = time + 0.02

	flip = not flip
	if flip then return end

	graphics.setCanvas(canvas)
	fx:send("time", time)
	fx:send("res", { graphics.getWidth(), graphics.getHeight() })


	graphics.setPixelEffect(fx)
	graphics.rectangle("fill", 0, 0, graphics.getWidth(), graphics.getHeight())
	graphics.setPixelEffect()
	graphics.setCanvas()
	local data = canvas:getImageData()

	for y = 0, 23 do
		for x = 0, 23 do
			wall.pixel(x, y, data:getPixel(x * data:getWidth() / 24, y * data:getHeight() / 24))
		end
	end


end
