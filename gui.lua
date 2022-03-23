local gui = {}

local HelpMarker = function(desc)
  -- used as imgui.SameLine(); HelpMarker("whatever you want");
  imgui.TextDisabled("(?)");
  if (imgui.IsItemHovered()) then
      imgui.BeginTooltip();
      imgui.PushTextWrapPos(imgui.GetFontSize() * 35.0);
      imgui.TextUnformatted(desc);
      imgui.PopTextWrapPos();
      imgui.EndTooltip();
  end
end

local function loadImage(path) 
  local file = io.open(path, "rb")
  local data = file:read("*a")
  file:close(file)

  local content = love.filesystem.newFileData(data, "data")
  local image = love.graphics.newImage(love.image.newImageData(content))
  image:setWrap( "repeat", "repeat" )
  return image
end

gui.savePath = ""

gui.windows = {
  Toolbar = {
  },
  BackgroundPreview = {
    previewScale = 1
  },
  BackgroundManger = {

  },
  Help = {
    properties = {
      open = false
    },
    scripting = {
      open = false
    }
  },
  Export = {
    Gif = {
      open = false,
      recording = false
    }
  }
}

filters = ffi.new("char const * [?]", 3 , "*.dbg","*.lua")
imgfilters = ffi.new("char const * [?]", 2 , "*.png","*.jpg")--,"*.jpeg","*.bmp","*.tga")
gifFilter = ffi.new("char const * [?]", 3 , "*.gif","*.lua")

print(imgfilters[0][5])

gui.windows.Toolbar.show = function(background)
  
  if love.keyboard.isDown("lctrl") and love.keyboard.isDown("o") then
    local filepath = tinyfile.tinyfd_openFileDialog("Open File","",1,filters,"*.dbg",0 )
    if filepath == nil then
      print("hmm no files found")
    else
      print(ffi.string(filepath))
      
      local file = io.open(ffi.string(filepath),"rb");
      local jsonData = file:read("*a");
      background:loadJson(json.decode( love.data.decompress( "string", "zlib", jsonData )))

      file:close();
      gui.savePath = ffi.string(filepath)
    end
  end

  function love.filedropped(filedat)
    print(filedat:getFilename())
      
      local file = io.open(filedat:getFilename(),"rb");
      local jsonData = file:read("*a");
      background:loadJson(json.decode( love.data.decompress( "string", "zlib", jsonData )))

      file:close();
      gui.savePath = filedat:getFilename()
  end

  if love.keyboard.isDown("lctrl") and love.keyboard.isDown("s") then
    if gui.savePath == "" then
      local filepath = tinyfile.tinyfd_saveFileDialog("Save File","Background",1,filters,"*.dbg" )
      if filepath == nil then
        print("file write invalid")
      else
        print(ffi.string(filepath))

        local file = io.open(ffi.string(filepath),"wb");
        local jsonData = json.encode(background.data)
        file:write(love.data.compress( "string", "zlib", jsonData,9));
        file:close();
        gui.savePath = ffi.string(filepath)
      end
    else
      --print("save")
      local file = io.open(gui.savePath,"wb");
      local jsonData = json.encode(background.data)
      file:write(love.data.compress( "string", "zlib", jsonData,9));
      file:close();
    end
  end

  imgui.NewFrame()

  if imgui.BeginMainMenuBar() then
      if imgui.BeginMenu("File") then
          if imgui.MenuItem("Open","Ctrl+O") then

            local filepath = tinyfile.tinyfd_openFileDialog("Open File","",1,filters,"*.dbg",0 )
            if filepath == nil then
              print("hmm no files found")
            else
              print(ffi.string(filepath))
              local file = io.open(ffi.string(filepath),"rb");
              local jsonData = file:read("*a");
              background:loadJson(json.decode( love.data.decompress( "string", "zlib", jsonData )))

              file:close();
              gui.savePath = ffi.string(filepath)
            end

            --img = loadImage(ffi.string(filepath))

          end
          if imgui.MenuItem("Save","Ctrl+S") then

            local filepath = tinyfile.tinyfd_saveFileDialog("Save File","Background",1,filters,"*.dbg" )
            if filepath == nil then
              print("file write invalid")
            else
              print(ffi.string(filepath))

              local file = io.open(ffi.string(filepath),"wb");
              local jsonData = json.encode(background.data)
              file:write(love.data.compress( "string", "zlib", jsonData,9));
              file:close();
            end

          end
          imgui.Separator()
          if imgui.MenuItem("Export GIF","") and gui.windows.Export.Gif.recording == false then
            local filepath = tinyfile.tinyfd_saveFileDialog("Export Gif","Background",1,gifFilter,"*.gif" )
            
            if filepath == nil then
              print("file write invalid")
            else
              GifProperties = {
                dim = {background.swap_textures.final:getWidth(), background.swap_textures.final:getHeight()},
                path = ffi.string(filepath)
              }
              os.execute('rd /s/q "img"')
              os.execute( "mkdir img" )

              jsonFile = io.open( "img/img.json", "w" )
              jsonFile:write( json.encode(GifProperties) )
              jsonFile:close()

              gui.windows.Export.Gif.open = true
              gui.windows.Export.Gif.data = GifProperties

              gui.windows.Export.Gif.frames = 0
              gui.windows.Export.Gif.recording = false
              love.timer.sleep(1)
            end
            
            

            --imgui.PopStyleColor(3);

            

            --imgui.PopID();

            --imgui.EndPopup();
            --imgui.PopID();
            
          end
          imgui.Separator()
          if imgui.MenuItem("Exit","Ctrl+Q") then
            love.quit()
          end
          imgui.EndMenu()
      end

      if imgui.BeginMenu("Help") then
          if imgui.MenuItem("Background properties",nil, gui.windows.Help.properties.open) then
            gui.windows.Help.properties.open = not gui.windows.Help.properties.open 
          end
          if imgui.MenuItem("Lua scripting",nil, gui.windows.Help.scripting.open) then
            gui.windows.Help.scripting.open = not gui.windows.Help.scripting.open 
          end
          imgui.EndMenu()
      end
      if imgui.BeginMenu("Style") then
        if imgui.MenuItem("Classic") then
          imgui.StyleColorsClassic()
        end
        if imgui.MenuItem("Dark") then
          imgui.StyleColorsDark()
        end
        if imgui.MenuItem("Light") then
          imgui.StyleColorsLight()
        end
        imgui.EndMenu()
      end

      imgui.EndMainMenuBar()
  end

  
end

local dtcGIF = 0

gui.windows.Export.Gif.show = function(background, dt)
  if gui.windows.Export.Gif.open then
    imgui.SetNextWindowSize(350, 140, "ImGuiCond_FirstUseEver");
    gui.windows.Export.Gif.open = imgui.Begin("Export GIF", nil, {"ImGuiWindowFlags_NoResize","ImGuiWindowFlags_NoCollapse","ImGuiWindowFlags_AlwaysAutoResize"})

    imgui.TextWrapped(gui.windows.Export.Gif.data.path.."\n\nFrames : "..gui.windows.Export.Gif.frames.."\n\nRecording : "..(gui.windows.Export.Gif.recording and "Yes" or "No") );

    imgui.Separator();

    if not gui.windows.Export.Gif.recording then
      if (imgui.Button("Record", 150, 0)) then 
        gui.windows.Export.Gif.recording = true
      end
      imgui.SetItemDefaultFocus();
      imgui.SameLine();
      if (imgui.Button("Cancel", 150, 0)) then gui.windows.Export.Gif.open = false end

    else
      

      dtcGIF = dtcGIF+dt
      --print(dtcGIF)
      if dtcGIF > 6/100 then
        --print("cap")
      
      gui.windows.Export.Gif.frames = gui.windows.Export.Gif.frames+1
      local dat = background.swap_textures.final:newImageData( )

      local filedata = dat:encode("png")
      local file = io.open("img/img"..gui.windows.Export.Gif.frames..".png", "wb")
      file:write(filedata:getString( ))
      file:close(file)
      dat = nil
      filedata = nil
      file = nil

      
      dtcGIF = 0
      end

      if (imgui.Button("Stop and save", 308, 0)) then 
        love.timer.sleep( 1 )
        collectgarbage("collect") 
        --os.execute("GifExport" )
        io.popen("GifExport")
        gui.windows.Export.Gif.recording = false
        gui.windows.Export.Gif.open = false
      end

    end
    
    imgui.End()
  end
end

local vec4i = {0,0}
local fps = 0

local function drawLayer(background,i,v)
  if v == nil then
    return
  end
  if background.content[v.id] ~= nil then
    --imgui.PushStyleVar("ImGuiStyleVar_ItemSpacing", 0,-9);
    --imgui.PushStyleVar("ImGuiStyleVar_FramePadding", 0, 0);
    local winsize = 11
    local vis = v.visible and 1 or 0.5
    local boarderr = v.visible and .5 or 1
    local boardergb = v.visible and .5 or 0

    local contentsize = math.min(winsize/background.content[v.id]:getWidth(), winsize/background.content[v.id]:getHeight())

    imgui.Image(background.content[v.id],
    background.content[v.id]:getWidth()*contentsize,
    background.content[v.id]:getHeight()*contentsize, 0,0,1,1 ,1,1,1,vis,boarderr,boardergb,boardergb,1)
    if imgui.IsItemHovered() then
      local contentsize = math.min(1,200/background.content[v.id]:getWidth(), 200/background.content[v.id]:getHeight())
      imgui.BeginTooltip();
      imgui.Image(background.content[v.id],
      background.content[v.id]:getWidth()*contentsize,
      background.content[v.id]:getHeight()*contentsize, 0,0,1,1 ,1,1,1,1,boarderr,boardergb,boardergb,1)
      imgui.EndTooltip();
    end
    imgui.SameLine()
    --imgui.PopStyleVar(2);
  end 
  
  imgui.PushID(0);
  if imgui.Selectable(v.title, background.uiProperties[v.id].selected) then
    background.uiProperties[v.id].selected = not background.uiProperties[v.id].selected
  end

  if imgui.BeginPopupContextItem("item context menu"..v.id) then
    background.uiProperties[v.id].selected = false
    if i == 1 then
      imgui.PushStyleVar("ImGuiStyleVar_Alpha",  0.5);
      imgui.Button("^ Move up  ")
      imgui.PopStyleVar();
    else
      if (imgui.Button("^ Move up  ")) then 
        local temp = background.data.layers[i-1]
        background.data.layers[i-1] = background.data.layers[i]
        background.data.layers[i] = temp
      end
    end

    if i == #background.data.layers then
      imgui.PushStyleVar("ImGuiStyleVar_Alpha",  0.5);
      imgui.Button("v Move down")
      imgui.PopStyleVar();
    else
      if (imgui.Button("v Move down")) then 
        local temp = background.data.layers[i+1]
        background.data.layers[i+1] = background.data.layers[i]
        background.data.layers[i] = temp
      end
    end

    v.title = imgui.InputText("", v.title, 30);

    imgui.PushStyleColor("ImGuiCol_Button", 0.6, 0.1, 0.1, 1);
    imgui.PushStyleColor("ImGuiCol_ButtonHovered", 0.7, 0.1, 0.1, 1);
    imgui.PushStyleColor("ImGuiCol_ButtonActive", 0.8, 0.1, 0.1, 1);

    imgui.PushID(0);

    if imgui.Button("Delete Layer") then
      imgui.OpenPopup("Delete Layer");
    end
    imgui.PopStyleColor(3);

    imgui.SetNextWindowPos(love.graphics.getWidth()/2, love.graphics.getHeight()/2, "ImGuiCond_Appearing", 0.5, 0.5);

    if (imgui.BeginPopupModal("Delete Layer", nil, ImGuiWindowFlags_AlwaysAutoResize)) then

      imgui.Text("Are you sure you want to get rid of '"..v.title.."'?\nThere's absolutely no going back or undoing!\n\n");
      imgui.Separator();

        imgui.PushStyleVar("ImGuiStyleVar_FramePadding", 0, 0);
        imgui.PopStyleVar();

        if (imgui.Button("Delete", 120, 0)) then 
          table.remove(background.data.layers,i)
          imgui.CloseCurrentPopup(); 
        end
        imgui.SetItemDefaultFocus();
        imgui.SameLine();
        if (imgui.Button("Cancel", 120, 0)) then imgui.CloseCurrentPopup(); end
        imgui.EndPopup();
    end

    imgui.PopID();

    imgui.EndPopup();
    imgui.PopID();
  end
  imgui.Separator();
end

gui.windows.BackgroundManger.show = function(background)

  imgui.SetNextWindowPos(love.graphics.getWidth()-19, 19*2, "ImGuiCond_FirstUseEver", 1, 0);
  imgui.SetNextWindowSize(400, 720-19*3, "ImGuiCond_FirstUseEver");
  imgui.Begin("Background manager",nil)

  if imgui.CollapsingHeader("Properties", "ImGuiTreeNodeFlags_DefaultOpen" ) then
    background.data.dimensions.x, background.data.dimensions.y = imgui.DragInt2("Resolution", background.data.dimensions.x, background.data.dimensions.y, 1, 32, 1920 ); imgui.SameLine(); HelpMarker("Width then Height.")
    --background.data.framerate = imgui.DragInt("Framerate Target", background.data.framerate, 1, 1, 120);

    background.data.dimensions.x = math.max(32,math.min(background.data.dimensions.x,1920 ))
    background.data.dimensions.y = math.max(32,math.min(background.data.dimensions.y,1920 ))
    --background.data.framerate = math.max(1,math.min(background.data.framerate,120))

    if background.swap_textures.final:getWidth() ~= background.data.dimensions.x or background.swap_textures.final:getHeight() ~= background.data.dimensions.y then
      background.swap_textures.quad = love.graphics.newQuad(0, 0, background.data.dimensions.x, background.data.dimensions.y, 1, 1) -- sw sh are 1 to cheat and use int coords :P
      background.swap_textures.temp = love.graphics.newCanvas(background.data.dimensions.x,background.data.dimensions.y) -- we render a quad to this.
      background.swap_textures.final = love.graphics.newCanvas(background.data.dimensions.x,background.data.dimensions.y)
    end

  end
  if imgui.CollapsingHeader("Layers", "ImGuiTreeNodeFlags_DefaultOpen") then

    if (imgui.Button("New Layer")) then 
      background:addLayer()
    end

    for i, v in ipairs(background.data.layers) do
      drawLayer(background,i,v)
      if background.uiProperties[v.id].selected then
        imgui.SetNextWindowSize(470, 500, "ImGuiCond_FirstUseEver");

        background.uiProperties[v.id].selected = imgui.Begin(v.title.."##"..v.id, true)

        if imgui.CollapsingHeader("Properties", "ImGuiTreeNodeFlags_DefaultOpen" ) then

          imgui.Text("Texture")

          if imgui.Button("Import Texture") then
            local filepath = tinyfile.tinyfd_openFileDialog("Open File","",1,imgfilters,"*.png",0)
            if filepath == nil then
              print("hmm no files found")
            else
              background.content[v.id] = loadImage(ffi.string(filepath));
              local file = io.open(ffi.string(filepath), "rb")
              local data = file:read("*a")
              file:close(file)
              v.back_data = love.data.encode("string","base64",data,0)--ffi.string(filepath)
            end
          end
          imgui.SameLine()
          v.visible = imgui.Checkbox("Visible",v.visible)

          if background.content[v.id] ~= nil then
            local winsize = imgui.GetWindowWidth()*0.65
            local contentsize = math.min(1, winsize/background.content[v.id]:getWidth(), winsize/background.content[v.id]:getHeight())

            imgui.Image(background.content[v.id],
            background.content[v.id]:getWidth()*contentsize,
            background.content[v.id]:getHeight()*contentsize, 0,0,1,1)
          end

          imgui.Separator();
          imgui.Text("Palette")

          if imgui.Button("Import Palette") then
            local filepath = tinyfile.tinyfd_openFileDialog("Open File","",1,imgfilters,"*.png",0)
            if filepath == nil then
              print("hmm no files found")
            else
              background.palettes[v.id] = loadImage(ffi.string(filepath));
              local file = io.open(ffi.string(filepath), "rb")
              local data = file:read("*a")
              file:close(file)
              v.pal_data = love.data.encode("string","base64",data,0)--ffi.string(filepath)
            end
          end
          imgui.SameLine()
          v.pal_used = imgui.Checkbox("Uses Palette",v.pal_used)
          if background.palettes[v.id] ~= nil then
  
            imgui.Image(background.palettes[v.id],
            background.palettes[v.id]:getWidth(),
            background.palettes[v.id]:getHeight()*2, 0,0,1,1)
          end
          if v.pal_used then
            
            if imgui.RadioButton("Indexed", v.pal_mode == "Indexed") then
              v.pal_mode="Indexed"
            end 
            imgui.SameLine();
            if imgui.RadioButton("Cycling", v.pal_mode == "Cycling") then
              v.pal_mode = "Cycling"
            end
            --v.pal_index = imgui.DragInt("Palette Index", v.pal_index, 1, 0, 255);
            v.pal_index = imgui.DragInt("Palette "..(v.pal_mode == "Indexed" and "Index" or "Speed"), v.pal_index, 1);
            if v.pal_mode == "Cycling" then
              imgui.SameLine(); HelpMarker("How many times the palette is cycled per second.")
            else
              imgui.SameLine(); HelpMarker("What palette indexed is used.")
            end
          end

          imgui.Separator();

          imgui.Text("Blending")

          v.blend_mode = imgui.Combo("Blend Mode", v.blend_mode, { "Normal", "Add", "Subtract", "Screen" }, 4);
          v.opacity = imgui.DragFloat("Opacity", v.opacity, 0.005, 0, 1);

          imgui.Separator();

          imgui.Text("Background Position")

          if imgui.RadioButton("Static", v.offset_mode == "Static") then
            v.offset_mode = "Static"
          end
          imgui.SameLine();
          if imgui.RadioButton("Scrolling", v.offset_mode == "Scrolling") then
            v.offset_mode = "Scrolling"
          end
          v.offset.x, v.offset.y = imgui.DragInt2((v.offset_mode == "Static" and "Offset" or "Speed"), v.offset.x, v.offset.y, 1);
          if v.offset_mode == "Static" then
            imgui.SameLine(); HelpMarker("How many pixels the image is offset.")
          else
            imgui.SameLine(); HelpMarker("Scrolling speed in pixels moved per second.")
          end
        end

        if imgui.CollapsingHeader("Distortions", "ImGuiTreeNodeFlags_DefaultOpen" ) then

          imgui.Text("Axis Distortion"); imgui.SameLine(); HelpMarker("The first column is X and the second is Y.")

          imgui.PushItemWidth(imgui.GetWindowWidth()/3.15);
          v.distortion.x = imgui.Combo("", v.distortion.x, { "Oscillation", "Interlaced", "Compression", "Linear Scaling" }, 3);  imgui.SameLine();
          v.distortion.y = imgui.Combo("Distortion", v.distortion.y, { "Oscillation", "Interlaced", "Compression", "Linear Scaling" }, 3);
          imgui.PopItemWidth();
          v.frequency.x, v.frequency.y = imgui.DragInt2("Frequency", v.frequency.x, v.frequency.y, 1);
          --v.shift_offset.x, v.shift_offset.y = imgui.DragInt2("Speed", v.shift_offset.x, v.shift_offset.y, 1); imgui.SameLine(); HelpMarker("Offsets the angle in frequency to 'scroll' the wave")
          v.amplitude.x, v.amplitude.y = imgui.DragInt2("Amplitude", v.amplitude.x, v.amplitude.y, 1);

          imgui.PushID(0);
          if imgui.RadioButton("Static", v.shift_mode == "Static") then
            v.shift_mode = "Static"
          end
          imgui.SameLine();
          if imgui.RadioButton("Scrolling", v.shift_mode == "Scrolling") then
            v.shift_mode = "Scrolling"
          end
          --v.offset.x, v.offset.y = imgui.DragInt2((v.offset_mode == "Static" and "Offset" or "Speed"), v.offset.x, v.offset.y, 1);
          v.shift_offset.x, v.shift_offset.y = imgui.DragInt2((v.shift_mode == "Static" and "Offset" or "Speed"), v.shift_offset.x, v.shift_offset.y, 1)
          if v.shift_mode == "Static" then
            imgui.SameLine(); HelpMarker("How much frequency is offset")
          else
            imgui.SameLine(); HelpMarker("Scrolling speed in frequency changed per second.")
          end
          imgui.PopID()



          imgui.Separator();

          imgui.Text("Planar Distortion");
          imgui.PushID(0)
          v.plane_distort = imgui.Combo("Distortion", v.plane_distort, { "Fishbowl", "Kaleidoscope"}, 1);
          imgui.PopID()
          v.plane_amplitude = imgui.DragFloat("Amplitude", v.plane_amplitude, 0.005, 0.0, 0.0);
        end

        if imgui.CollapsingHeader("Scripting", "ImGuiTreeNodeFlags_DefaultOpen" ) then
          if imgui.Button("Compile") then
            local err = background:Compile(i)
            if err ~= nil then background.scripts[v.id] = nil end
          end imgui.SameLine();
          v.script_enabled = imgui.Checkbox("Script enabled",v.script_enabled)
          imgui.PushID(0)
          
          v.script_string = imgui.InputTextMultiline("", v.script_string, 65537, imgui.GetWindowWidth()/1.54, imgui.GetTextLineHeight()*16, {"ImGuiInputTextFlags_AllowTabInput"});
          imgui.PopID()
          imgui.Text("Total Chrs : "..string.len(v.script_string).."/65536\nCompiled   : "..(background.scripts[v.id] and "TRUE" or "FALSE") )
        end

        imgui.End()

      end
    end

  end

  imgui.End()
end

gui.windows.BackgroundPreview.show = function(canvas)
  

  imgui.SetNextWindowPos(19, 19*2, "ImGuiCond_FirstUseEver");
  imgui.SetNextWindowSize(-1, -1, "ImGuiCond_FirstUseEver");

  imgui.Begin("Background preview",nil,{"ImGuiWindowFlags_NoResize","ImGuiWindowFlags_NoCollapse","ImGuiWindowFlags_AlwaysAutoResize"})

  gui.windows.BackgroundPreview.previewScale = imgui.SliderInt("Preview scaling", gui.windows.BackgroundPreview.previewScale, 1, 8);
  imgui.PushStyleVar("ImGuiStyleVar_Alpha",  1.0);
  imgui.Image(canvas,
  canvas:getWidth()*gui.windows.BackgroundPreview.previewScale,
  canvas:getHeight()*gui.windows.BackgroundPreview.previewScale, 0,0,1,1)

  imgui.PopStyleVar();
  imgui.End()
end

gui.windows.Help.properties.show = function()
  if gui.windows.Help.properties.open then

    local texex = love.graphics.newImage("extex.png")
    local texexpal = love.graphics.newImage("pal.png")

    imgui.SetNextWindowSize(400, 500, "ImGuiCond_FirstUseEver");
    gui.windows.Help.properties.open = imgui.Begin("Background properties documentation", true)

    imgui.TextWrapped("Welcome to dieback. Below you will find information on all the sliders, buttons and whatnot. If you need help or want to share art join the Dieback discord.")

    if (imgui.Button("Discord")) then 
      love.system.openURL("https://discord.gg/BsGckhgWPS")
    end

    if imgui.CollapsingHeader("Background manager") then
      imgui.TextWrapped("This panel is where you can see all your layers and some properties.")
      imgui.Separator();
      imgui.TextWrapped("The first is Resolution it is the resolution of your background. you can type numbers into it.")
      imgui.Separator();
      imgui.TextWrapped("Next up is layers. If you just opened Dieback you'll see Layer1. Right clicking will open up another window with all it's properties. Left clicking will give you buttons to sort, a name input box and a button to delete the layer. Right click on the name box to enter your own or edit it.")
    end

    if imgui.CollapsingHeader("Texture") then

      imgui.TextWrapped("This button allows you to upload any .png file and use it as a background! However if you want to use a palette you'll need to upload the indexed image generated by PCXtool. It may look almost black but is actually red! The red channel maps to the palette horizontally.")

      imgui.Image(texex,
      texex:getWidth()*2,
      texex:getHeight()*2, 0,0,1,1)

      imgui.TextWrapped("Here is an example of an indexed background with a very high brightness for clarity. The Visible checkmark will toggle the layers visiblity.")
    end

    if imgui.CollapsingHeader("Palette") then

      imgui.TextWrapped("The button will allow you to import a palette. These images can be generated by PCXtool.")
      imgui.Separator();
      imgui.TextWrapped("To use palettes make sure you are using an indexed texture the black and red one. If you drag in the palette you will notice there isn't much to do with it.Thats because this palette only has one row (A row being a 1 pixel tall, 256 pixel long strip of colors). If you want fancy palette animations open it in aseprite and increase the height. You can then drag colors around and edit it.")

      imgui.Image(texexpal,
      texexpal:getWidth()*2,
      texexpal:getHeight()*2, 0,0,1,1)

      imgui.TextWrapped("Here is an example of what a palette might look like very zoomed in and cropped. The yellow line shows the current row.")

      imgui.Separator();
      imgui.TextWrapped("Make sure if you have a palette imported that you check 'Uses palette' this opens options such as Indexed and Cycling, Indexed allows you to manually choose the palette index, Cycling will automatically scroll at the selected speed.")
    end

    if imgui.CollapsingHeader("Hotkeys") then
      imgui.TextWrapped("Save - [CTRL+S]")
      imgui.Separator();
      imgui.TextWrapped("Load - [CTRL+O] (You can also drag a .dbi file onto the window to open it)")
      imgui.Separator();
      imgui.TextWrapped("Quit - [CTRL+Q] (Will not ask you to save! Immediately quits.)")
    end

    if imgui.CollapsingHeader("Exports") then
      imgui.TextWrapped("Gif exports are pretty simple. All the raw png frames to make the gif are stored within the img folder.")
    end

    if imgui.CollapsingHeader("PCXtool") then
      imgui.TextWrapped("This tool came with dieback and is often needed for creation of palettes. To generate a palette drag a .pcx file onto it (DON'T DOUBLE CLICK, drag the literal file onto the .exe icon). The file should only use 256 colors (Aseprite supports this natively), The tool sometimes shows errors but most likely still worked. Just check if it made indexed.png and palette.png")
    end

    imgui.Separator();
    imgui.TextWrapped("I've decided to not document the rest of the sliders as they are self explanitory.")

    
    
    imgui.End()
  end
end

gui.windows.Help.scripting.show = function()
  if gui.windows.Help.scripting.open then
    imgui.SetNextWindowSize(500, 600, "ImGuiCond_FirstUseEver");
    gui.windows.Help.scripting.open = imgui.Begin("Lua scripting documentation", true)
    imgui.TextWrapped("You can script each individual layer. Scripts have no limits technically however it is best to not to add new variables to layer or make globals. TLDR: just use local variables.\n\n");
    imgui.TextWrapped("Scripts can overwrite any variable that can be set with sliders. They can even change distortion modes. Scripts can not however load images for palette or texture.\n\n");
    imgui.TextWrapped("Here is a list of values provided to you to adjust the background.")
    imgui.TextWrapped("! prefix means the program can crash if set incorrectly.")
    if imgui.CollapsingHeader("time", "ImGuiTreeNodeFlags_DefaultOpen" ) then
      imgui.TextWrapped("The time in seconds. Given as a decimal, accurate to the microsecond.")
    end
    if imgui.CollapsingHeader("layer", "ImGuiTreeNodeFlags_DefaultOpen" ) then

      imgui.TextWrapped("  layer.visible | true or false")
      imgui.Separator();
      imgui.TextWrapped("  layer.pal_used | true or false")
      imgui.TextWrapped("! layer.pal_mode | can be set to 'Indexed' or 'Cycling'.")
      imgui.TextWrapped("  layer.pal_index | integer value")
      imgui.Separator();
      imgui.TextWrapped("  layer.blend_mode | integer value of 1 through 4")
      imgui.TextWrapped("  layer.opacity | float value of 0 through 1")
      imgui.Separator();
      imgui.TextWrapped("! layer.offset_mode | set to 'Static' or 'Scrolling'")
      imgui.TextWrapped("  layer.offset.x or .y | integer values")
      imgui.Separator();
      imgui.TextWrapped("  layer.distortion.x or .y | integer values of 1 through 4")
      imgui.TextWrapped("  layer.frequency.x or .y | unsure")
      imgui.TextWrapped("  layer.amplitude.x or .y | integer values")
      imgui.TextWrapped("! layer.shift_mode | set to 'Static' or 'Scrolling'")
      imgui.TextWrapped("  layer.shift_offset.x or .y | integer values")
      imgui.Separator();
      imgui.TextWrapped("  layer.plane_distort | integer value of 1 or 2")
      imgui.TextWrapped("  layer.plane_amplitude | float value")
    end
    
    imgui.End()
  end
end

gui.draw = function()
  imgui.Render();
end

gui.clean = function()
  imgui.ShutDown();
  love.filesystem.remove("imgui.ini")
end

return gui
