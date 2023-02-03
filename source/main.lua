import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "game"


local gfx <const> = playdate.graphics
local pd <const> = playdate


math.randomseed(playdate.getSecondsSinceEpoch())

pd.graphics.setBackgroundColor(gfx.kColorBlack)

local function initialize()

	game = Game()
end

initialize()

function playdate.update()
	game:update()
	gfx.sprite.update()
	pd.timer.updateTimers()

end
