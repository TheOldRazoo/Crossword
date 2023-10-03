
import 'CoreLibs/object'

class('StateStart').extends(State)

function StateStart:init()
    StateStart.super.init(self)
end

function StateStart:update()
    local puz, err = loadPuzzleFile('puz/uc230921.puz')
    restorePuzzle(puz)
    puz.grid[1][1] = 'A'
    puz.grid[1][2] = 'B'
    puz.grid[2][1] = 'C'
    statePlay:setPuzzle(puz)
    stateManager:setCurrentState(statePlay)
end
