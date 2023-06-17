local gfx <const> = playdate.graphics
local pd <const> = playdate

class("SoundBox").extends()

function SoundBox:init()
    self.hurtSounds = convert({ "hurt" })
end

function SoundBox:hurt()
    index = math.random(1, #self.hurtSounds)
    self.hurtSounds[index]:play()
    print("Here")
end

function convert(soundTable)
    converted = {}

    for i = 1, #soundTable, 1 do
        table.insert(converted, pd.sound.sampleplayer.new("sfx/" .. soundTable[i]))
    end
    return converted
end
