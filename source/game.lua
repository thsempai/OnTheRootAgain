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
    self:setZIndex(0)
    self.mapPos = { 0, 0 }
end

function ScreenAnimatedSprite:update()

    if (self.screen == nill or self.screen.active) then
        ScreenAnimatedSprite.super.update(self)
    end
end

function ScreenAnimatedSprite:moveTo(x, y)
    self.mapPos = { x, y }
    ScreenAnimatedSprite.super.moveTo(self, mapDecal[1] + (x - 1) * tileSize[1], mapDecal[2] + (y - 1) * tileSize[2])
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

class("Root").extends(ScreenAnimatedSprite)

function Root:init(x, y, state, index)
    Root.super.init(self, "root", x, y)
    self:addState("left", 1, 7, { tickStep = 5, nextAnimation = "left-fixe" })
    self:addState("left-fixe", 7, 7, { tickStep = 5 })

    self:addState("up", 8, 14, { tickStep = 5, nextAnimation = "up-fixe" })
    self:addState("up-fixe", 14, 14, { tickStep = 5 })

    self:addState("right", 15, 21, { tickStep = 5, nextAnimation = "right-fixe" })
    self:addState("right-fixe", 21, 21, { tickStep = 5 })

    self:addState("down", 22, 28, { tickStep = 5, nextAnimation = "down-fixe" })
    self:addState("down-fixe", 28, 28, { tickStep = 5 })

    self:changeState(state, true)
    self:setCenter(0, 0)
    self:moveTo(x, y)
    self:setZIndex(-5)

    self.index = index
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

    self.roots = {}


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

    if self.battleMap[hx][hy] ~= "I" and self.battleMap[hx][hy] ~= "O" then

        state = nil
        if dy == 1 then state = "up"
        elseif dy == -1 then state = "down"
        elseif dx == 1 then state = "left"
        elseif dx == -1 then state = "right"
        end

        index = #self.roots + 1
        root = Root(hx, hy, state, index)
        table.insert(self.roots, index, root)
        self:add(root)
    end

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
