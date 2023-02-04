import "CoreLibs/sprites"
import "CoreLibs/string"

local gfx <const> = playdate.graphics
local pd <const> = playdate

local mapSize = { 11, 6 }
local mapDecal = { 24, 24 }
local tileSize = { 32, 32 }

local tileset = gfx.imagetable.new("sprites/tileset")

class("Game").extends()

function Game:init()


    battleScreen = BattleScreen(self)


    self.screens = { battle = battleScreen }

    self:changeCurrentScreen("battle")

end

function Game:changeCurrentScreen(newScreen)
    self.current = newScreen
    gfx.sprite:removeAll()

    for name, screen in pairs(self.screens) do
        if (name == newScreen) then
            gfx.setBackgroundColor(screen.bgColor)
            gfx.clear()
            screen:setActive(true)
        else
            screen:setActive(false)
        end
    end
end

function Game:update()
    self.screens[self.current]:update()
end

class("Screen").extends()

function Screen:init(game, color)
    if color == nil then
        self.bgColor = gfx.kColorClear
    else
        self.bgColor = color
    end
    self.game = game
    self.sprites = {}
    self:setActive(false)
end

function Screen:setActive(ok)
    self.active = ok
    if ok == true then
        for i, sprite in ipairs(self.sprites) do
            sprite:add()
        end
    end
end

function Screen:add(sprite)
    if (not sprite:isa(ScreenSprite)) then
        error("To add a sprite to the screen it must be a ScreenSprite")
    end
    table.insert(self.sprites, sprite)
    sprite.screen = self
end

function Screen:remove(sprite)
    table.remove(self.sprites, table.indexOfElement(sprite))
    sprite:remove()
    sprite.screen = nil
end

function Screen:update()

end

class("ScreenSprite").extends(gfx.sprite)

function ScreenSprite:init(imagePath)

    if pcall(function() imagePath = "sprites/" .. imagePath end) then
        image = gfx.image.new(imagePath)
    else
        image = imagePath
    end


    ScreenSprite.super.init(self)
    self:setImage(image)

    self.screen = nil

end

function ScreenSprite:update()

    if (self.screen == nill or self.screen.active) then
        ScreenSprite.super.update(self)
    end
end

class("Tile").extends(ScreenSprite)

function Tile:init(tileX, tileY, x, y)

    image = tileset:getImage(tileX, tileY)
    Tile.super.init(self, image)
    self.mapX = x
    self.mapY = y
    self:setCenter(0, 0)
    self:moveTo(mapDecal[1] + tileSize[1] * x, mapDecal[2] + tileSize[2] * y)
    print(x, y)
    self:setZIndex(10)

end

-----------SPECIFICS------------------------

class("BattleScreen").extends(Screen)

function BattleScreen:init(game)
    BattleScreen.super.init(self, game, gfx.kColorWhite)

    -- BG --

    bg = ScreenSprite("bg")
    bg:setCenter(0, 0)
    bg:moveTo(0, 0)
    bg:setZIndex(-100)
    self:add(bg)

    -- FG --
    fg = ScreenSprite("fg")
    fg:setCenter(0, 0)
    fg:moveTo(0, 0)
    fg:setZIndex(100)
    self:add(fg)

    self.battleTiles = {}
    self:InitializeField()

end

function BattleScreen:InitializeField()

    for x = 1, mapSize[1], 1 do
        for y = 1, mapSize[2], 1 do
            if math.random(10) == 1 then
                tile = Tile(1, 1, x, y)
                self:add(tile)
                table.insert(self.battleTiles, tile)
            end
        end
    end

end
