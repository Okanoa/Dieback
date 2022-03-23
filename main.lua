love.graphics.setDefaultFilter("nearest", "nearest", 0)
love.window.setTitle( "Dieback 1.0.4" )
love.window.setMode( 1280, 720, {vsync=0,resizable=true} ) --simple shizzle
local run = require "run" --essentially disables pausing between frames kinda silly for a tool 🥴

img = nil

imgui = require "imgui"
json = require "json"
ffi = require "ffi"
tinyfile = ffi.load('tinyfiledialogs64.dll')
ffi.cdef[[
void tinyfd_beep() ;

char const * tinyfd_saveFileDialog (
    char const * const aTitle , // NULL or ""
    char const * const aDefaultPathAndFile , // NULL or ""
    int const aNumOfFilterPatterns , // 0
    char const * const * const aFilterPatterns , // NULL | {"*.txt"}
    char const * const aSingleFilterDescription ) ; // NULL | "text files"
        // returns NULL on cancel

char const * tinyfd_openFileDialog (
    char const * const aTitle , // NULL or ""
    char const * const aDefaultPathAndFile , // NULL or ""
    int const aNumOfFilterPatterns , // 0
    char const * const * const aFilterPatterns , // NULL {"*.jpg","*.png"}
    char const * const aSingleFilterDescription , // NULL | "image files"
    int const aAllowMultipleSelects ) ; // 0
]]
local input = require "input"
local gui = require "gui"
local dieback = require "dieback"

local background = dieback.Init()

background:addLayer()

local canvas = love.graphics.newCanvas(background.data.dimensions.x, background.data.dimensions.y)

function love.load(args)
  
end

local count = 0

function love.update(dt)
  gui.windows.Toolbar.show(background)
  
  gui.windows.Export.Gif.show(background, dt)
  gui.windows.Help.properties.show()
  gui.windows.Help.scripting.show()
  gui.windows.BackgroundManger.show(background)
  --imgui.ShowDemoWindow(true)
  input.commands()
  background:Update()
  background:Render()
  gui.windows.BackgroundPreview.show(background.swap_textures.final)

  if love.keyboard.isDown("lctrl") and love.keyboard.isDown("s") then
    count = 2
  end

  if gui.savePath == "" then
    love.window.setTitle( "Dieback 1.0.4" )
  else
    love.window.setTitle( "Dieback 1.0.4 - "..gui.savePath)
  end
  
  count = count-dt
end

function love.draw()
  love.graphics.clear(.5,.5,.55,1)
  love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 1, 0, 1)
  love.graphics.setCanvas()
  gui.draw()
  if img ~= nil then
    love.graphics.draw(img)
  end
  if count > 0 then

  love.graphics.setBlendMode("alpha")
  love.graphics.setColor(1,1,1,count)
  love.graphics.print("Saved "..gui.savePath, 10, love.graphics.getHeight()-32)
  love.graphics.setColor(1,1,1,1)
  end
  

end

function love.quit()
gui.clean()
end
