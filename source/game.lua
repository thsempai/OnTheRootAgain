import "CoreLibs/sprites"
import "CoreLibs/string"

import "AnimatedSprite"

local gfx <const> = playdate.graphics
local pd <const> = playdate

local mapSize = { 11, 6 }
local mapDecal = { 24, 24 }
local tileSize = { 32, 32 }

local tileset = gfx.imagetable.new("sprites/tileset")
local heartset = gfx.imagetable.new("sprites/heart")
local dropset = gfx.imagetable.new("sprites/drop")

class("Game").extends()

function Game:init()

    battleScreen = BattleScreen(self)
    gameOver = GameOver(self)

    flower = FlowerScreen(self)

    self.screens = { battle = battleScreen, gameOver = gameOver, flower = flower }

    self:changeCurrentScreen("battle")

end

function Game:changeCurrentScreen(newScreen)
    print("current screen: " .. newScreen)
    if self.current == "battle" and newScreen ~= "battle" then
        self.screens["battle"] = BattleScreen(self)
    end

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
    self.circle = nil
    self.circleRadius = 400
    self.circleSpeed = -5
    image = gfx.image.new(400, 240, gfx.kColorClear)
    self.circleSprite = ScreenSprite(image)
    self.circleSprite:setCenter(0, 0)
    self.circleSprite:moveTo(0, 0)
    self.circleSprite:setZIndex(500)
    self:add(self.circleSprite)

    self.circleFunction = nil
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

function Screen:circleOut(x, y, fct)
    self.circle = { x, y }
    self.circleSpeed = -10
    self.circleRadius = 400
    self.circleFunction = fct
end

function Screen:circleIn(x, y, fct)
    self.circle = { x, y }
    self.circleSpeed = 10
    self.circleRadius = 0
    self.circleFunction = fct
end

function Screen:update()
    if self.circle ~= nil then
        image = gfx.image.new(400, 240, gfx.kColorClear)
        gfx.pushContext(image)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(0, 0, 400, 240)
        gfx.setColor(gfx.kColorClear)
        gfx.fillCircleAtPoint(x, y, self.circleRadius)
        gfx.popContext()
        self.circleSprite:setImage(image)
        if self.circleRadius <= 0 and self.circleSpeed < 0 or
            self.circleSprite.x + self.circleRadius >= 510 and self.circleSpeed > 0 then
            self.circle = nil
            if self.circleFunction ~= nil then
                self.circleFunction()
            end
        end
        self.circleRadius += self.circleSpeed
    end
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
class("GUIValue").extends(ScreenSprite)

function GUIValue:init(x, y, imagetable)
    self.imagetable = imagetable
    image = imagetable:getImage(2, 1)
    GUIValue.super.init(self, image)
    self:moveTo(x, y)
    self:setCenter(0.5, 1)
    self:setZIndex(150)
end

function GUIValue:fill(ok)
    if ok == true then
        image = self.imagetable:getImage(2, 1)
    else
        image = self.imagetable:getImage(1, 1)
    end
    self:setImage(image)

end

class("Mana").extends(ScreenAnimatedSprite)

function Mana:init(x, y)
    Mana.super.init(self, "mana")
    self:addState("drop", 1, 11, { tickStep = 5 }).asDefault()
    self:changeState("drop", true)
    self.mapPos = { x, y }
    self:setCenter(0, 0)
    self:moveTo(x, y)
end

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

    self.heroLife = 10
    self.heroMana = 0

    self.hearts = {}
    self.drops = {}

    for index = 1, 10, 1 do
        y = 215 - (index - 1) * 12
        heart = GUIValue(19, y, heartset)
        table.insert(self.hearts, index, heart)
        if index > self.heroLife then
            heart:fill(false)
        end
        self:add(heart)
    end

    for index = 1, 10, 1 do
        y = 215 - (index - 1) * 12
        drop = GUIValue(383, y, dropset)
        table.insert(self.drops, index, drop)
        if index > self.heroMana then
            drop:fill(false)
        end
        self:add(drop)
    end

    self.battleTiles = {}
    self.battleMap = {}

    self.roots = {}
    self.manas = {}


    self:CreateMap()
    self:InitializeField()

end

function BattleScreen:ChangeHeroLife(life)
    self.heroLife = life

    if self.heroLife <= 0 then
        self.game:changeCurrentScreen("gameOver")
        return
    end
    for index = 1, #self.hearts, 1 do
        self.hearts[index]:fill(index <= self.heroLife)
    end
end

function BattleScreen:ChangeHeroMana(mana)
    self.heroMana = mana
    self.heroMana = math.min(self.heroMana, 10)

    for index = 1, #self.drops, 1 do
        self.drops[index]:fill(index <= self.heroMana)
    end
end

function BattleScreen:CreateMap()
    for x = 1, mapSize[1], 1 do
        table.insert(self.battleMap, x, {})
        for y = 1, mapSize[2], 1 do
            table.insert(self.battleMap[x], y, ".")
        end
    end

    -- in
    inY = math.random(1, mapSize[2])
    inX = 1
    self.battleMap[inX][inY] = "I"
    self.hero:moveTo(inX, inY)
    cx = (self.hero.mapPos[1] - 1) * tileSize[1] + tileSize[1] / 2 + mapDecal[1]
    cy = (self.hero.mapPos[2] - 1) * tileSize[2] + tileSize[2] / 2 + mapDecal[2]
    self:circleIn(cx, cy)

    -- out
    outY = math.random(1, mapSize[2])
    outX = mapSize[1]
    self.battleMap[outX][outY] = "O"

    y = inY
    x = inX

    doY = true

    while x ~= outX or y ~= outY do

        if y ~= outY and x ~= outX then
            doY = not doY
        end

        if (doY == true and y > outY) then
            y -= 1
        elseif doY == true and y < outY then
            y += 1
        elseif doY == true and y == outY and (outX - x) > 1 then
            y += math.random(-1, 1)
        elseif x > outX then
            x -= 1
        elseif x < outX then
            x += 1
        end

        if self.battleMap[x][y] ~= "O" then
            self.battleMap[x][y] = "P"
        end
    end


    -- mana
    manaNumber = 4

    while manaNumber > 0 do
        x = math.random(1, mapSize[1])
        y = math.random(1, mapSize[2])
        if self.battleMap[x][y] == "." then
            manaNumber -= 1
            self.battleMap[x][y] = 'M'
        end
    end

    for x = 1, mapSize[1], 1 do
        for y = 1, mapSize[2], 1 do
            if self.battleMap[x][y] == "." and math.random(1, 2) == 1 then
                self.battleMap[x][y] = "X"
            end
        end
    end


end

function BattleScreen:InitializeField()

    tilesDic = { X = { 1, 1 }, I = { 2, 1 }, O = { 3, 1 }, P = { 4, 1 } }

    for x = 1, mapSize[1], 1 do
        for y = 1, mapSize[2], 1 do

            if self.battleMap[x][y] == "M" then
                mana = Mana(x, y)
                self:add(mana)
                table.insert(self.manas, mana)
                table.insert(self.battleTiles, mana)
            else
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

end

function BattleScreen:leave()
    x = (self.hero.mapPos[1] - 1) * tileSize[1] + tileSize[1] / 2 + mapDecal[1]
    y = (self.hero.mapPos[2] - 1) * tileSize[2] + tileSize[2] / 2 + mapDecal[2]
    self:circleOut(x, y, function()
        self.game:changeCurrentScreen("flower")
    end)
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

    if self.battleMap[nx][ny] == "X" then
        return
    end

    self.hero:moveTo(nx, ny)
    if self.battleMap[nx][ny] == "O" then
        self:leave()
    elseif self.battleMap[nx][ny] == "M" then
        self:manaCollection(nx, ny)
    end

    if self.battleMap[nx][ny] == "-" then
        self:rootCollision(nx, ny)
    elseif self.battleMap[hx][hy] ~= "I" and self.battleMap[hx][hy] ~= "O" then

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
        self.battleMap[hx][hy] = "-"
    end

end

function BattleScreen:manaCollection(x, y)
    for index, mana in ipairs(self.manas) do
        if mana.mapPos[1] == x and mana.mapPos[2] == y then
            table.remove(self.manas, index)
            self:remove(mana)
            break
        end
    end
    self:ChangeHeroMana(self.heroMana + 1)
    self.battleMap[x][y] = '.'
end

function BattleScreen:rootCollision(x, y)

    found = false
    lifeLost = #self.roots

    newRoots = {}
    for index, root in ipairs(self.roots) do
        if found == false and root.mapPos[1] == x and root.mapPos[2] == y then
            found = true
        end

        if found == true then
            self:remove(root)
            self.battleMap[root.mapPos[1]][root.mapPos[2]] = "."
        else
            table.insert(newRoots, root)
        end

    end

    self.roots = newRoots
    lifeLost -= #self.roots
    lifeLost = math.ceil(lifeLost / 2)

    self:ChangeHeroLife(self.heroLife - lifeLost)

end

function BattleScreen:update()

    if self.circle == nil then

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

    BattleScreen.super.update(self)

end

class("GameOver").extends(Screen)

function GameOver:init(game)
    GameOver.super.init(self, game)

    bg = ScreenSprite("gameOver")
    bg:setCenter(0, 0)
    self:add(bg)
end

function GameOver:update()
    GameOver.super.update(self)
    if pd.buttonJustPressed(pd.kButtonA) then
        self.game:changeCurrentScreen("battle")
    end
end

class("FlowerScreen").extends(Screen)

function FlowerScreen:init(game)
    FlowerScreen.super.init(self, game)
end
