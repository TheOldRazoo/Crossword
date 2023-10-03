
import 'CoreLibs/object'

class('StateStart').extends(State)

function StateStart:init()
    StateStart.super.init(self)
    self:createPuzzleDir()
end

function StateStart:update()
    stateManager:setCurrentState(statePuz)
end

function StateStart:createPuzzleDir()
    if not playdate.file.isdir('/puzzles') then
        playdate.file.mkdir('/puzzles')
    end
end
