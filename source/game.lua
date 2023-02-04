import "CoreLibs/sprites"
import "CoreLibs/string"

import "AnimatedSprite"

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
    if (not sprite:isa(ScreenSprite) and not sprite:isa(ScreenAnimatedSprite)) then
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
    self:moveTo(mapDecal[1] + tileSize[1] * (x - 1), mapDecal[2] + tileSize[2] * (y - 1))
    self:setZIndex(-10)

end

class("ScreenAnimatedSprite").extends(AnimatedSprite)

function ScreenAnimatedSprite:init(imageName)
    imagePath = "sprites/" .. imageName
    imagetable = gfx.imagetable.new(imagePath)
    ScreenAnimatedSprite.super.init(self, imagetable)
    ScreenAnimatedSprite.screen = nil

end

function ScreenAnimatedSprite:update()

    if (self.screen == nill or self.screen.active) then
        ScreenAnimatedSprite.super.update(self)
    end
end

-----------SPECIFICS------------------------

class("Hero").extends(ScreenAnimatedSprite)

function Hero:init(x, y)

    Hero.super.init(self, "hero")
    self:addState("pose", 11, 12, { tickStep = 5 }).asDefault()
    self:changeState("pose", true)
    self.mapPos = { x, y }
    self:setCenter(0, 0)
    self:moveTo(x, y)
end

function Hero:moveTo(x, y)
    self.mapPos = { x, y }
    Hero.super.moveTo(self, mapDecal[1] + (x - 1) * tileSize[1], mapDecal[2] + (y - 1) * tileSize[2])
end

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

    -- Hero
    self.hero = Hero(0, 0)
    self:add(self.hero)


    self.battleTiles = {}
    self.battleMap = {}


    self:CreateMap()
    self:InitializeField()

end

function BattleScreen:CreateMap()
    for x = 1, mapSize[1], 1 do
        table.insert(self.battleMap, x, {})
        for y = 1, mapSize[2], 1 do
            table.insert(self.battleMap[x], y, ".")
        end
    end

    -- in
    y = math.random(1, mapSize[2])
    self.battleMap[1][y] = "I"
    self.hero:moveTo(1, y)

    -- out
    y = math.random(1, mapSize[2])
    self.battleMap[mapSize[1]][y] = "O"

end

function BattleScreen:InitializeField()

    tilesDic = { X = { 1, 1 }, I = { 2, 1 }, O = { 3, 1 } }

    for x = 1, mapSize[1], 1 do
        for y = 1, mapSize[2], 1 do
            tileCoord = tilesDic[self.battleMap[x][y]]
            if tileCoord ~= nil then
                tx = tileCoord[1]
                ty = tileCoord[2]
                tile = Tile(tx, ty, x, y)
                self:add(tile)
                table.insert(self.battleTiles, tile)
            end

        end
    end

end

function BattleScreen:moveHero(dx, dy)
    hx = self.hero.mapPos[1]
    hy = self.hero.mapPos[2]

    nx = hx + dx
    ny = hy + dy

    if nx < 1 or nx > mapSize[1] then
        return
    end
    if ny < 1 or ny > mapSize[2] then
        return
    end

    self.hero:moveTo(nx, ny)

end

function BattleScreen:update()
    BattleScreen.super.update(self)

    if pd.buttonJustPressed(pd.kButtonUp) then
        self:moveHero(0, -1)
    elseif pd.buttonJustPressed(pd.kButtonDown) then
        self:moveHero(0, 1)
    elseif pd.buttonJustPressed(pd.kButtonLeft) then
        self:moveHero(-1, 0)
    elseif pd.buttonJustPressed(pd.kButtonRight) then
        self:moveHero(1, 0)

    end
end
