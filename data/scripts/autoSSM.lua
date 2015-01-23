--[[

table file syntax:

]]--


-----------------------
--- Global Variable ---
-----------------------
tableFile = "data/script-data/auto_ssm.tbl"

strike_info_id = {}	-- [index] = name; contains the name of our automated strikes

--- strike info arrays ---
--> indexed by auto strike name (see strike_info_id above)
--> contains data parsed from the table

strike_info_type = {}		-- SSM name, as defined in ssm.tbl
strike_info_cooldown = {}	-- cooldown, in seconds
strike_info_team = {}		-- team name


--- active strike info ---
--> indexed by name
--> contains data related to active automated strikes
strike_active = {}		-- boolean, is that automated strike type active? Defaults to false
strike_last_fired = {}		-- mission time at which this strike was last fired
strike_current_target = {}	-- ship name, current target
strike_target_list = {}		-- [name][target] = boolean; list of potential targets, used by target-seeking algorithms
strike_target_type = {}		-- [name][target] = ship/target type; may be used by target-seeking algorithms ??? maybe move this to info ???
strike_seeker_algo = {}		-- what target algorithm should be used?


----------------------------
--- functions - settings ---
----------------------------

function auto_ssm_setActive(name, bool)
	strike_active[name] = bool
end

function auto_ssm_setTarget(name, target)
	strike_current_target[name] = target
end

function auto_ssm_addTarget(name, target)
	strike_target_list[name][target] = true
end

function auto_ssm_removeTarget(name, target)
	strike_target_list[name][target] = nil
end

--------------------------
--- functions - strike ---
--------------------------

--- cycles through the automated strikes and fires them if necessary
--- the responsability of calling it is left to the FREDer
function auto_ssm_cycle()
	for index, name in pairs(strike_info_id) do
		if strike_active[name] then
			cd = strike_info_cooldown[name]
			lastFired = strike_last_fired[name]
			if (lastFired + cd >= mn.getMissionTime()) then
				if (auto_ssm_fire(name)) then
					strike_last_fired[name] = mn.getMissionTime()
				end
			end
		end
	end
end

--- fires the given strike
--- returns true if fired successfully
--- Note: the strike's target should be its current target, as determined by its seeking algorithm
function auto_ssm_fire(name)
	target = strike_current_target[name]

end

--- updates the given strike's current target, according to its seeking algorithm
--- algorithms defined in autoSSM-targetting.lua
function auto_ssm_updateTarget(name)
	algo = auto_ssm_algo[name]
	if (algo == "list" || algo == nil) then
		auto_ssm_seekList(name)
	elseif (algo == "round-robin") then
		auto_ssm_seekRoundRobin(name)
	elseif (algo == "random") then
		auto_ssm_seekRandom(name)
	elseif (algo == "random-death") then
		auto_ssm_seekRandomDeath(name)
	elseif (algo == "weakest") then
		auto_ssm_seekWeakest(name)
	elseif (algo == "strongest") then
		auto_ssm_seekStrongest(name)
	elseif (algo == "proximity") then
		auto_ssm_seekProximity(name)
	elseif (algo == "all") then
		auto_ssm_seekAll(name)
	else
		ba.warning("auto_ssm: Warning: Unrecognized seeking algorithm ".algo) --or fall back to default behavior???
	end
end

------------
--- main ---
------------

