local dieback = {}

dieback.Init = function() -- how it will work :P instead of loading a new background we will init and overwrite with load stuffs.
    math.randomseed(os.time())
    collection = {
        gtime = 0,
        gid = 0,
        total_layers = 0,
        swap_textures = {
            quad = love.graphics.newQuad(0, 0, 320, 180, 1, 1), -- sw sh are 1 to cheat and use int coords :P
            temp = love.graphics.newCanvas(320,180), -- we render a quad to this.
            final = love.graphics.newCanvas(320,180) -- we render temp to this and do blending + fisheye
        },
        data = {
            dimensions = {x=320,y=180},
            --framerate = 60,
            layers = {},
        },
        uiProperties = {

        },
        -- put here to not save with json
        content = {
            --gid - image
        },
        palettes = {
            --gid - image
        },
        scripts = {
            --gid - function
        }
    }

    

    collection.Compile = function(self,layerid)
        local func, err = load("return function(layer, time)\n"..self.data.layers[layerid].script_string.."\nend")
        
        if err == nil then
            local ok, runnable = pcall(func)
            --runnable()
            self.scripts[self.data.layers[layerid].id] = runnable
        end

        return err -- can be used in console i suppose
    end

    -- not needed in export module
    collection.getGID = function(self) -- gives us an always random nonrepeating number :)
        self.gid = self.gid+math.random(2,25)
        return self.gid
    end

    collection.loadJson = function(self,table)

        local function decodeImage(base64)
        local data = love.data.decode( "string", "base64", base64 )
        local content = love.filesystem.newFileData(data, "data")
        local image = love.graphics.newImage(love.image.newImageData(content))
        image:setWrap( "repeat", "repeat" )
        return image
        end

        self.data = table

        self.swap_textures.quad = love.graphics.newQuad(0, 0, self.data.dimensions.x, self.data.dimensions.y, 1, 1) -- sw sh are 1 to cheat and use int coords :P
        self.swap_textures.temp = love.graphics.newCanvas(self.data.dimensions.x,self.data.dimensions.y) -- we render a quad to this.
        self.swap_textures.final = love.graphics.newCanvas(self.data.dimensions.x,self.data.dimensions.y)

        self.total_layers = #table.layers
        for i,v in ipairs(table.layers) do
            if (v.back_data ~= "") then
                self.content[v.id] = decodeImage(v.back_data)
            end
            if (v.pal_data ~= "") then
                self.palettes[v.id] = decodeImage(v.pal_data)
            end

            self:Compile(i)

            self.uiProperties[v.id] = {
                selected = false
            }

            self.gid = v.id -- probably had possible issues :eyes:
        end
        
    end

    collection.addLayer = function(self) --settings are initialized to default.
        self.total_layers = self.total_layers+1
        local layer_count = #self.data.layers+1
        self.data.layers[layer_count] = {
            id = tostring(self:getGID()),
            title = "Layer"..tostring(self.total_layers),

            back_data = "",
            visible = true,

            pal_used = false,
            pal_data = "",
            pal_mode = "Indexed",
            pal_index = 0,

            blend_mode = 1,
            opacity = 1,
            
            offset_mode = "Static",
            offset = {x = 0, y = 0},

            distortion = {x = 1, y = 1},
            frequency = {x = 0, y = 0},
            shift_mode = "Static",
            shift_offset = {x = 0, y = 0},
            amplitude = {x = 0, y = 0},

            plane_distort = 1,
            plane_amplitude = 0,

            script_enabled = false,
            script_string = "-- You can write your code in this editor."
        }
        self.uiProperties[self.data.layers[layer_count].id] = {
            selected = false
        }
    end

    -- not needed in export module

    

    collection.Update = function(self,time) -- time input should be seconds
        self.gtime = time and time or love.timer.getTime()
        for i,v in ipairs(self.data.layers) do
            if self.scripts[v.id] and v.script_enabled then
                pcall(self.scripts[v.id],v,self.gtime)
            end
        end
    end

    collection.axis_distortion = love.graphics.newShader([[
    
        uniform ivec2 tex_size;
        uniform vec2 tex_offset;

        uniform bool palette_enabled;
        uniform sampler2D palette_texture;
        uniform float palette_index;

        uniform ivec2 axis_mode;
        uniform ivec2 axis_frequency;
        uniform ivec2 axis_amplitude;
        uniform vec2 axis_shift;

        #ifdef VERTEX
        vec4 position(mat4 transform_projection, vec4 vertex_position)
        {
            vec4 transformed = transform_projection * vertex_position;
            return transformed;
        }
        #endif

        #ifdef PIXEL

        #define PI 3.1415926538

        //x vec2 is X, Y
        //y vec2 is Y, X
        int distort(int d_mode, ivec2 f_position, int i_frequency, int i_amplitude, float i_shift)
        {
            int offset_pos = 0;
            if(d_mode == 0) { //oscillation
                offset_pos = int(i_amplitude * sin( ((1.0/i_frequency)*PI) * (f_position.y + i_shift) ));
            }
            if(d_mode == 1) { //interlaced
                if(mod(f_position.y,2) == 0) {
                    offset_pos = -int(i_amplitude * sin( ((1.0/i_frequency)*PI) * (f_position.y + i_shift) ));
                } else {
                    offset_pos = int(i_amplitude * sin( ((1.0/i_frequency)*PI) * (f_position.y + i_shift) ));
                }
            }
            if(d_mode == 2) { //compression
                offset_pos = int(i_amplitude * sin( ((1.0/i_frequency)*PI) * (f_position.x + i_shift) ));
            }
            if(d_mode == 3) { //linear scaling
                offset_pos = int( (f_position.x+i_shift)*float(float(i_amplitude)/float(i_frequency)) );
            }
            return offset_pos;
        }

        vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
        {
            ivec2 distortion = ivec2(
                distort(axis_mode.x, ivec2(texture_coords.x,texture_coords.y), axis_frequency.x, axis_amplitude.x,axis_shift.x),
                distort(axis_mode.y, ivec2(texture_coords.y,texture_coords.x), axis_frequency.y, axis_amplitude.y,axis_shift.y)
            );

            vec4 base_color = Texel(tex, ((texture_coords+tex_offset+distortion)/tex_size));

            if (palette_enabled) {
                base_color = Texel(palette_texture,vec2(base_color.r,palette_index));
            }

            return color * base_color;
        }
        #endif
    ]])

    collection.planar_distortion = love.graphics.newShader([[
        uniform ivec2 tex_size;
        uniform int planar_mode;
        uniform float planar_amplitude;

        #ifdef VERTEX
        vec4 position(mat4 transform_projection, vec4 vertex_position)
        {
            vec4 transformed = transform_projection * vertex_position;
            return transformed;
        }
        #endif

        #ifdef PIXEL

        #define PI 3.1415926538

        vec2 distort(int d_mode, vec2 f_position, float i_amplitude)
        {
            vec2 offset_pos = f_position;

            if (d_mode == 0) { // fishbowl
                vec2 p = f_position;

                float prop = 1.0; //screen proroption
            
                vec2 m = vec2(0.5, 0.5);//center coords
            
                vec2 d = p - m;//vector from center to current fragment
            
                float r = sqrt(dot(d, d)); // distance of pixel from center
        
                float power = ( 2.0 * PI / (2.0 * sqrt(dot(m, m))) ) * (i_amplitude);//amount of effect
        
                float bind;//radius of 1:1 effect
            
                if (power > 0.0) bind = sqrt(dot(m, m));//stick to corners
                else {if (prop < 1.0) bind = m.x; else bind = m.y;}//stick to borders
        
                //Weird formulas
                if (power > 0.0)//fisheye
                    offset_pos = m + normalize(d) * tan(r * power) * bind / tan( bind * power);
                else if (power < 0.0)//antifisheye
                    offset_pos = m + normalize(d) * atan(r * -power * 10.0) * bind / atan(-power * bind * 10.0);
                else offset_pos = p;//no effect for power = 1.0
            }
            if (d_mode == 1) { // fishbowl
                offset_pos = tex_size;
            }
            return offset_pos;
        }

        vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
        {
            vec2 distortion = distort(planar_mode,texture_coords,planar_amplitude);

            vec4 base_color = Texel(tex, distortion);
            return color * base_color;
        }
        #endif
    ]])

    collection.Render = function(self,target) -- renders our background

        local currentCanv = love.graphics.getCanvas()

        local time = self.gtime

        local blend_modes = {
            "alpha","add","subtract","screen"
        }

        local floor = math.floor

        local function wrap(x,x_min,x_max) -- used to stop any silly floating point errors :P lua uses doubles and glsl uses floats
            return x - (x_max - x_min) * floor( x / (x_max - x_min));
        end

        love.graphics.setCanvas(self.swap_textures.final)
        love.graphics.clear(0,0,0,1)

        for i = #self.data.layers, 1, -1 do v = self.data.layers[i]
            if self.content[v.id] and v.visible then
                love.graphics.setCanvas(self.swap_textures.temp)
                love.graphics.setBlendMode("replace")
                love.graphics.setColor( 1, 1, 1, 1)
                    love.graphics.setShader(self.axis_distortion)

                    self.axis_distortion:send("tex_size",{self.content[v.id]:getWidth(),self.content[v.id]:getHeight()})

                    local real_offset = {x=-v.offset.x,y=-v.offset.y}
                    if v.offset_mode == "Scrolling" then
                        real_offset.x, real_offset.y = time*-v.offset.x, time*-v.offset.y
                    end
                    self.axis_distortion:send("tex_offset",{
                        wrap(real_offset.x,0,self.content[v.id]:getWidth()),
                        wrap(real_offset.y,0,self.content[v.id]:getHeight())
                    })

                    self.axis_distortion:send("axis_mode",{
                        v.distortion.x-1,
                        v.distortion.y-1
                    })
                    self.axis_distortion:send("axis_frequency",{v.frequency.x,v.frequency.y})
                    self.axis_distortion:send("axis_amplitude",{v.amplitude.x,v.amplitude.y})

                    local real_shift = {x=-v.shift_offset.x,y=-v.shift_offset.y}
                    if v.shift_mode == "Scrolling" then
                        real_shift.x, real_shift.y = time*-v.shift_offset.x, time*-v.shift_offset.y
                    end
                    self.axis_distortion:send("axis_shift",{
                        wrap(real_shift.x,0,v.frequency.x*2),
                        wrap(real_shift.y,0,v.frequency.y*2)
                    })

                    self.axis_distortion:send("palette_enabled",v.pal_used)
                    if self.palettes[v.id] and v.pal_used then
                        self.axis_distortion:send("palette_texture",self.palettes[v.id])
                        local real_palette = v.pal_index
                        if v.pal_mode == "Cycling" then
                            real_palette =  time*v.pal_index
                        end
                        local index = wrap(real_palette, 0, self.palettes[v.id]:getHeight())/self.palettes[v.id]:getHeight()
                        self.axis_distortion:send("palette_index",index)
                    end
                    
                    love.graphics.draw( self.content[v.id], self.swap_textures.quad)

                    love.graphics.setCanvas(self.swap_textures.final)
                    love.graphics.setColor( 1, 1, 1, v.opacity )

                    love.graphics.setShader(self.planar_distortion)

                    self.planar_distortion:send("tex_size",{self.data.dimensions.x,self.data.dimensions.x})
                    self.planar_distortion:send("planar_mode",v.plane_distort-1)
                    self.planar_distortion:send("planar_amplitude",v.plane_amplitude)

                    love.graphics.setBlendMode(blend_modes[v.blend_mode])
                    love.graphics.draw(self.swap_textures.temp)


            end
        end

        love.graphics.setColor( 1, 1, 1, 1)
        love.graphics.setBlendMode("alpha")
        love.graphics.setShader()
        
        love.graphics.setCanvas(currentCanv)

    end

    collection.Draw = function(self,x,y) -- will draw out the background with love.graphics.draw and call :render
        love.graphics.push()
        love.graphics.origin()
        self:Render()
        love.graphics.pop()
        love.graphics.draw(self.swap_textures.final,x,y)
    end

    return collection

end

return dieback