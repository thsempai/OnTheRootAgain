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

    self.life = 10
    self.mana = 0

    self.screens = {}
    self.screens.gameOver = GameOver(self)

    self.screens.victory = Victory(self)
    self.screens.flower = FlowerScreen(self)
    self.screens.battle = BattleScreen(self)

    self:changeCurrentScreen("flower")


end

function Game:changeCurrentScreen(newScreen)
    print("current screen: " .. newScreen)

    if self.current == "battle" and newScreen ~= "battle" then
        self.screens["battle"] = BattleScreen(self)
    end

    if self.current ~= "flower" and newScreen == "flower" then
        self.screens["flower"]:circleIn(200, 38)
    end

    if self.current ~= "gameOver" and newScreen == "gameOver" then
        self.mana = 0
        self.life = 10
        self.screens["flower"] = FlowerScreen(self)
        self.screens["battle"] = BattleScreen(self)
        self.screens[newScreen]:circleIn(200, 120)
    end

    if self.current ~= "victory" and newScreen == "victory" then
        self.mana = 0
        self.life = 10
        self.screens["flower"] = FlowerScreen(self)
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

function Screen:init(game, color, colorIn)
    if colorIn == nil then
        colorIn = gfx.kColorBlack
    end
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
    gfx.pushContext(image)
    gfx.setColor(colorIn)
    gfx.fillRect(0, 0, 400, 240)
    gfx.popContext()
    self.circleSprite = ScreenSprite(image)
    self.circleSprite:setCenter(0, 0)
    self.circleSprite:moveTo(0, 0)
    self.circleSprite:setZIndex(500)
    self:add(self.circleSprite)

    self.circleFunction = nil
    self.circleBorder = false
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

function Screen:circleOut(x, y, fct, border)
    if border == nil then
        border = false
    end
    self.circle = { x, y }
    self.circleSpeed = -10
    self.circleRadius = 400
    self.circleFunction = fct
end

function Screen:circleIn(x, y, fct, border)
    if border == nil then
        border = false
    end
    self.circleBorder = border
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
        x = self.circle[1]
        y = self.circle[2]
        gfx.fillCircleAtPoint(x, y, self.circleRadius)
        if self.circleBorder == true then
            gfx.setColor(gfx.kColorWhite)
            gfx.drawCircleAtPoint(x, y, self.circleRadius + 1)
        end
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

    self.hearts = {}
    self.drops = {}

    for index = 1, 10, 1 do
        y = 215 - (index - 1) * 12
        heart = GUIValue(19, y, heartset)
        table.insert(self.hearts, index, heart)
        if index > self.game.life then
            heart:fill(false)
        end
        self:add(heart)
    end

    for index = 1, 15, 1 do
        y = 215 - (index - 1) * 12
        drop = GUIValue(383, y, dropset)
        table.insert(self.drops, index, drop)
        if index > self.game.mana then
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
    self.game.life = life

    if self.game.life <= 0 then
        x = (self.hero.mapPos[1] - 1) * tileSize[1] + tileSize[1] / 2 + mapDecal[1]
        y = (self.hero.mapPos[2] - 1) * tileSize[2] + tileSize[2] / 2 + mapDecal[2]
        self:circleOut(x, y, function()
            self.game:changeCurrentScreen("gameOver")
        end)
        return
    end
    for index = 1, #self.hearts, 1 do
        self.hearts[index]:fill(index <= self.game.life)
    end
end

function BattleScreen:ChangeHeroMana(mana)
    self.game.mana = mana
    self.game.mana = math.min(self.game.mana, 15)

    for index = 1, #self.drops, 1 do
        self.drops[index]:fill(index <= self.game.mana)
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
            if math.random(self.game.screens["flower"].map.power, 10) == 10 then
                self.battleMap[x][y] = "X"
            else
                self.battleMap[x][y] = "P"
            end
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

    tilesDic = { X = { 1, 1 }, I = { 2, 1 }, O = { 3, 1 } }

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
    self.game.screens["flower"]:UpdateValues()
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


    self.hero:moveTo(nx, ny)
    if self.battleMap[nx][ny] == "O" then
        self:leave()
    elseif self.battleMap[nx][ny] == "M" then
        self:manaCollection(nx, ny)
    end

    if self.battleMap[nx][ny] == "X" then
        self:ChangeHeroLife(self.game.life - 2)
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
    self:ChangeHeroMana(self.game.mana + 1)
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
    lifeLost = math.floor(lifeLost / 2)
    if lifeLost < 1 then
        lifeLost = 1
    end

    self:ChangeHeroLife(self.game.life - lifeLost)

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
        self.game:changeCurrentScreen("flower")
    end
end

class("Victory").extends(Screen)

function Victory:init(game)
    Victory.super.init(self, game)

    bg = ScreenSprite("victory")
    bg:setCenter(0, 0)
    self:add(bg)

    self:circleIn(200, 120)
end

function Victory:update()
    Victory.super.update(self)
    if pd.buttonJustPressed(pd.kButtonA) then
        self.game:changeCurrentScreen("flower")
    end
end

class("FlowerScreen").extends(Screen)

function FlowerScreen:init(game)
    FlowerScreen.super.init(self, game, gfx.kColorWhite)


    bg = ScreenSprite("bgflower")
    bg:setCenter(0, 0)
    bg:moveTo(0, 0)
    bg:setZIndex(-100)
    self:add(bg)

    self.map = RootsMap()
    self:add(self.map)

    self.flower = FlowerSprite(200, 59)
    self:add(self.flower)

    self.hearts = {}
    self.drops = {}

    for index = 1, 10, 1 do
        x = 8 + (index - 1) * 10
        heart = GUIValue(x, 13, heartset)
        table.insert(self.hearts, index, heart)
        if index > self.game.life then
            heart:fill(false)
        end
        self:add(heart)
    end

    for index = 1, 15, 1 do
        x = 252 + (index - 1) * 10
        drop = GUIValue(x, 13, dropset)
        table.insert(self.drops, index, drop)
        if index > self.game.mana then
            drop:fill(false)
        end
        self:add(drop)
    end

end

function FlowerScreen:UpdateValues()
    -- if self.game.mana >= 10 then
    --     self.game.mana = 0
    --     self.flower:UpdatePower(self.map.power)
    --     self.map.dry = 150

    -- end
    for index = 1, #self.hearts, 1 do
        self.hearts[index]:fill(index <= self.game.life)
    end

    for index = 1, #self.drops, 1 do
        self.drops[index]:fill(index <= self.game.mana)
    end
end

class("RootsMap").extends(ScreenSprite)

function RootsMap:init()

    image = gfx.image.new(400, 240, gfx.kColorClear)


    RootsMap.super.init(self, image)
    self:setCenter(0, 0)
    self:moveTo(0, 0)
    self:setZIndex(0)

    self.roots = {}
    self.save = nil

    self.origin = RootPixel(self, 0, 0)
    self.current = self.origin
    self.power = math.floor(self.current.y / 30)
    self.step = 0
    self.dry = 150
end

function RootsMap:update()

    RootsMap.super.update(self)

    image = gfx.image.new(400, 240, gfx.kColorClear)
    gfx.pushContext(image)
    gfx.setColor(gfx.kColorWhite)
    for index, root in ipairs(self.roots) do
        gfx.drawPixel(root.x + 200, root.y + 60)
        if root.battle == true then
            gfx.drawCircleAtPoint(root.x + 200, root.y + 60, 2)
        end
    end
    gfx.fillRect(132, 3, self.dry/1.5, 11)
    gfx.popContext()

    self:setImage(image)

    if self.screen.circle ~= nil then
        return
    end
    if pd.buttonIsPressed(pd.kButtonDown) then
        if self.current.y < 180 then
            self.current:next()
            self.step += 1
            self.dry -= 1
            if self.dry <= 0 then
                self.screen:circleOut(200, 59 - 22, function()
                    self.screen.game:changeCurrentScreen("gameOver")
                end)
            else
                if self.step >= 50 or self.step >= 5 and math.random(self.step, 50) == 50 then
                    self.step = 0
                    self:encounter()
                end
            end
        end
    end

    if pd.buttonJustPressed(pd.kButtonA) then
        min = 1
        max = math.max(1, math.floor(#self.roots / 2))
        root = self.roots[math.random(min, max)]
        root:fork()
        self.screen.game.life = 10
        self.screen:UpdateValues()
    end

    if pd.buttonIsPressed(pd.kButtonB) then
        if self.screen.game.mana >= 10 then
            self.screen.game.mana -= 10
            self.screen.flower:UpdatePower(self.screen.map.power)
            self.screen.map.dry = 150
            self.screen:UpdateValues()
        end
    end

    self.power = math.floor(self.current.y / 30)

    if self.screen.flower.level >= 8 then
        self.screen:circleOut(200, 59 - 22, function()
            self.screen.game:changeCurrentScreen("victory")
        end)
    end

end

function RootsMap:encounter()

    self.current.battle = true
    fct = function()
        self.screen.game:changeCurrentScreen("battle")
        self.screen.game.screens["battle"]:ChangeHeroLife(self.screen.game.life)
    end
    self.screen:circleOut(self.current.x + 200, self.current.y + 60, fct, true)
end

class("RootPixel").extends()

function RootPixel:init(screen, x, y, level, parent, direction)
    self.screen = screen
    self.screen.current = self
    self.battle = false
    table.insert(screen.roots, self)

    if direction == nill then
        direction = 0
    end
    self.direction = direction

    self.x = x
    self.y = y
    if level == nil then
        self.level = 0
    else
        self.level = level
    end

    self.node = nil

    self.parent = parent
    if parent ~= nil then
        parent.child = this
    end


end

function RootPixel:next()
    x = self.x
    y = self.y

    if self.node ~= nil and math.abs(self.node.x - self.x) < 10 * self.level then
        x += self.direction
        y += math.random(0, 1)
    else
        y += 1
        x += math.random(-1, 1)
    end

    newPixel = RootPixel(self.screen, x, y, self.level, self, direction)
    newPixel.node = self.node
end

function RootPixel:fork()
    direction = self.direction * -1
    if direction == 0 then
        direction = 1
        if math.random(0, 1) == 0 then
            direction = -1
        end
    end

    x = self.x
    y = self.y

    y += 1
    x += direction

    newPixel = RootPixel(self.screen, x, y, self.level + 1, nil, direction)
    newPixel.node = self

end

class("FlowerSprite").extends(ScreenSprite)

function FlowerSprite:init(x, y)

    self.level = 1
    self.power = 0
    self.imagetable = gfx.imagetable.new("sprites/flower")
    image = self.imagetable:getImage(self.level, 1)
    FlowerSprite.super.init(self, image)
    self:setCenter(0.5, 1)
    self:moveTo(x, y)
end

function FlowerSprite:UpdatePower(value)

    self.power += value
    if self.power >= math.min(self.level, 5) then
        self.power = 0
        self.level += 1
        image = self.imagetable:getImage(self.level, 1)
        self:setImage(image)

    end
end
