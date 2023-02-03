import "CoreLibs/sprites"
import "CoreLibs/string"

local gfx <const> = playdate.graphics
local pd <const> = playdate


class("Game").extends()

function Game:init()

    introScreen = Screen(self, gfx.kColorWhite)
    test = ScreenSprite("player", 200, 120)
    introScreen:add(test)

    gameScreen = Screen(self)
    other = ScreenSprite("block", 200, 120)
    gameScreen:add(other)

    self.screens = { intro = introScreen, game = gameScreen }

    self:changeCurrentScreen("intro")

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

function Screen:update()
    if (pd.buttonJustPressed(pd.kButtonA)) then
        self.game:changeCurrentScreen("game")
    end

end

class("ScreenSprite").extends(gfx.sprite)

function ScreenSprite:init(imagePath, x, y)

    imagePath = "sprites/" .. imagePath
    ScreenSprite.super.init(self)
    image = gfx.image.new(imagePath)
    self:setImage(image)
    self:moveTo(x, y)

    self.screen = nil

end

function ScreenSprite:update()

    if (self.screen.active) then
        ScreenSprite.super.update(self)
    end
end
