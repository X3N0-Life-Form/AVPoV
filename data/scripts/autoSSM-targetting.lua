--[[
	Contains target seeking algorithms & associated utility functions
	See auto_ssm_updateTarget function @ autoSSM.lua
	Valid algorithms are:
		- list (default)
		- round-robin
		- random
		- random-death
		- weakest
		- strongest
		- proximity
		- all
]]--

-------------------------
--- Utility Functions ---
-------------------------

--- checks whether the current target is valid
--- & removes it from the target list if it isn't
--- @param name: auto ssm name
function auto_ssm_isCurrentTargetValid(name)
	if(strike_current_target[name].HitpointsLeft > 0) then
		return true
	else
		strike_target_list[name][strike_current_target[name]] = nil
		strike_current_target[name] = nil
		return false
	end
end


------------------
--- Algorithms ---
------------------

--- Seeks the next target in the targetting list
--- Changes target upon death of the current target
function auto_ssm_seekList(name)
	if not (auto_ssm_isCurrentTargetValid(name)) then
		return
	end
	auto_ssm_seekRoundRobin(name)
end

--- Seeks the next target in the list
--- Changes target upon call
function auto_ssm_seekRoundRobin(name)
	local lookUpCurrentTarget = true
	for target, value in pairs(strike_target_list[name]) do
		if (target == strike_current_target[name]) then
			lookUpCurrentTarget = false
		elseif (lookUpCurrentTarget == false && not (target == strike_current_target[name])) then
			strike_current_target[name] = target
			break
		end
	end
end

--- Seeks a random target
--- Changes target upon call
function auto_ssm_seekRandom(name)
	targetId = math.random(#strike_target_list[name])
	strike_current_target[name] = strike_target_list[name][targetId]
end

--- Seeks a random target
--- Changes target upon death
function auto_ssm_seekRandomDeath(name)
	if not (auto_ssm_isCurrentTargetValid(name)) then
		return
	end
	auto_ssm_seekRandom(name)
end

--- Seeks the target with the lowest number of hitpoints
--- Changes target upon call
function auto_ssm_seekWeakest(name)
	local weakest = nil
	local weakestHull = 10000000000 -- hopefully, should be high enough
	for target, value in pairs(ssm_target_list[name]) do
		if (target.HitpointsLeft < weakestHull) then
			weakest = target
			weakestHull = target.HitpointsLeft
		end
	end
	strike_current_target[name] = weakest
end

--- Seeks the target with the largest number of hitpoints
--- Changes target upon call
function auto_ssm_seekStrongest(name)
	local strongest = nil
	local strongestHull = 1
	for target, value in pairs(ssm_target_list[name]) do
		if (target.HitpointsLeft > strongestHull) then
			strongest = target
			strongestHull = target.HitpointsLeft
		end
	end
	strike_current_target[name] = strongest
end

--- Calls a strike on every target in the list
function auto_ssm_seekAll(name)
	for target, value in pairs(ssm_target_list[name]) do
		mn.evaluateSEXP("(when (true) (call-ssm-strike \""..strike_info_type[name].."\" \""..strike_team[name].."\" \""..target.Name.."\"))")
	end
end

--- Seeks the target closest to proximityTarget
--- Changes target upon call
function auto_ssm_seekProximity(name)
	local distance = 1000000000 -- again, let's hope this is high enough
	local closest = nil
	for target, value in pairs(ssm_target_list[name]) do
		-- if distance between target & proximityTarget < distance
		-- nu distance
		closest = target
	end
	strike_current_target[name] = closest
end

proximityTarget = nil


