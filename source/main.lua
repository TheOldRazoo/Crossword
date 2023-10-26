
import 'CoreLibs/sprites'
import 'CoreLibs/graphics'
import 'Utility/State'
import 'Utility/StateManager'
import 'utility'
import 'loadpuz'
import 'screen'
import 'states/StateStart'
import 'states/StatePlay'
import 'states/StatePuz'

local firstTime = true

lastPuzzleName = 'lastPuzzle'
rebusName = 'rebus'
rebus = playdate.datastore.read(rebusName)
if rebus == nil then
    rebus = true
end

stateStart = StateStart()
statePlay = StatePlay()
stateManager = StateManager(stateStart)

function playdate.update()
    if firstTime then
        playdate.setMenuImage(getMenuImage())
        firstTime = false
    end

    playdate.timer.updateTimers()
    stateManager:getCurrentState():update()
end

function playdate.gameWillTerminate()
    if stateManager:getCurrentState() == statePlay then
        statePlay:savePuzzle()
    end
end