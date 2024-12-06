
--[[
	This singleton manages the state machine used to determine which code should
	be invoked at any point in the game.

	Example:
		startState = MyStartState()		-- extends State
		stateMgr = StateManager(startState)
		stateMgr:getCurrentState():update()
		stateManager:setCurrentState(someOtherState)

	Bob Withers
	bwit@pobox.com
	06/10/2023
]]

import 'CoreLibs/object'

class('StateManager').extends()

-- Instance variables
local currState


function StateManager:init(startState)
	self.currState = startState
	if startState then
		self.currState:enter(nil)
	end
end

function StateManager:getCurrentState()			-- returns State
	return self.currState
end

function StateManager:setCurrentState(state)
	local prevState = self.currState
	if prevState then
		prevState:exit()
	end
	self.currState = state
	self.currState:enter(prevState)
end

--[[
	Allow a state to capture all updates without notifying
	the current state.  The current state is returned and
	should be preserved to regain control via release()
]]
function StateManager:capture(state)
    local currState = self.currState
	self.currState = state
	return currState
end

--[[
	Allow a state that has captured updates to return control
	to another state, presumably the state that was in control
	at the time of capture.
]]
function StateManager:release(state)
    self.currState = state
end