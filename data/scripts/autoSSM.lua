--[[
	------------------------------------------------
	-- Automated SSM Strike Framework - Main file --
	------------------------------------------------

	Table file syntax:
		#Automated Strikes

		$Name:							String		; required
		$Type:							String		; required, must match ssm.tbl entry
		$Cooldown:						Integer		; required
		$Default Seeking Algorithm:		String		; optional, defaults to list - autoSSM-targeting.lua

		#End
	Notable Functions:
		- auto_ssm_cycle():
				needs to be called by the FREDer
				cycles through the auto strikes, and fires SSMs if necessary
		- auto_ssm_setActive(name, boolean):	sets the strike as active
		- auto_ssm_setTarget(name, target):		sets the current target
		- auto_ssm_addTarget(name, target):		adds a target to the target list
		- auto_ssm_removeTarget(name, target):	removes a target from the target list
		- auto_ssm_fire(name):					fires a strike at its current target

]]--

-- set to true to enable prints
autoSSM_enableDebugPrints = true

------------------------
--- Global Variables ---
------------------------
auto_ssm_filePath = "data/config/"
auto_ssm_fileName = "auto_ssm.tbl"

strike_info_id = {}	-- [index] = name; contains the name of our automated strikes

--- strike info arrays ---
--> indexed by auto strike name (see strike_info_id above)
--> contains data parsed from the table
strike_info_type = {}			-- SSM name, as defined in ssm.tbl
strike_info_cooldown = {}		-- cooldown, in seconds
strike_info_seeker_algo = {}	-- what target algorithm should be used?



--- active strike info ---
--> indexed by name
--> contains data related to active automated strikes
strike_active = {}			-- boolean, is that automated strike type active? Defaults to false
strike_last_fired = {}		-- mission time at which this strike was last fired
strike_current_target = {}	-- ship name, current target (ship handle)
strike_target_list = {}		-- [name][target] = boolean; list of potential targets, used by target-seeking algorithms
strike_target_type = {}		-- [name][target] = ship/target type; may be used by target-seeking algorithms ??? maybe move this to info ???
strike_team = {}			-- [name] = team name


----------------------------
--- functions - settings ---
----------------------------

function auto_ssm_setActive(strikeName, bool)
	strike_active[strikeName] = bool
end

function auto_ssm_setTarget(strikeName, targetName)
	local target = mn.Ships[targetName]
	strike_current_target[strikeName] = target
end

function auto_ssm_addTarget(strikeName, targetName)
	strike_target_list[strikeName][targetName] = true
end

function auto_ssm_removeTarget(strikeName, targetName)
	strike_target_list[strikeName][targetName] = nil
end

---------------------------
--- functions - utility ---
---------------------------

function dPrint_autoSSM(message)
	if (autoSSM_enableDebugPrints) then
		ba.print("[auto_ssm.lua] "..message)
	end
end

function auto_ssm_get_cooldown(name)
	-- if we have a difficulty-based cooldown
	if type(strike_info_cooldown[name]) == 'array' then
		return strike_info_cooldown[name][ba.getGameDifficulty()]
	else
		return strike_info_cooldown[name]
	end
end

function auto_ssm_get_strikeType(name)
	-- if we have a difficulty-based type
	if type(strike_info_type[name]) == 'array' then
		return strike_info_type[name][ba.getGameDifficulty()]
	else
		return strike_info_type[name]
	end
end

--- updates the given strike's current target, according to its seeking algorithm
--- algorithms defined in autoSSM-targeting.lua
function auto_ssm_updateTarget(name)
	algo = strike_info_seeker_algo[name]
	if (algo == "list" or algo == nil) then
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
		ba.warning("auto_ssm: Warning: Unrecognised seeking algorithm: "..algo.."\nFalling back to default behavior")
		auto_ssm_seekList(name)
	end
end

--------------------------
--- functions - strike ---
--------------------------

--- cycles through the automated strikes and fires them if necessary
--- the responsibility of calling it is left to the FREDer
function auto_ssm_cycle()
	-- for each active strike
	for index, name in pairs(strike_info_id) do
		if strike_active[name] then
		
			-- retrieve the strike's cooldown
			local cd = auto_ssm_get_cooldown(name)
			
			-- retrieve the time stamp of the last strike fired
			lastFired = strike_last_fired[name]
			
			-- if our strike is off cooldown
			if (lastFired + cd >= mn.getMissionTime()) then
				-- fire our strike and record the firing time if successful
				if (auto_ssm_fire(name)) then
					strike_last_fired[name] = mn.getMissionTime()
				end
			end
			
		end
	end
end

--- fires the given strike
--- Note: the strike's target should be its current target, as determined by its seeking algorithm
function auto_ssm_fire(name)
	-- select the current target
	local target = strike_current_target[name]
	-- update the target's list if necessary
	auto_ssm_updateTarget(name)
	
	-- select the strike type
	local strikeType = auto_ssm_get_strikeType(name)
	
	-- select the strike's team
	local strikeTeam = strike_team[name]
	
	-- special case: don't fire if algo set to "all"
	if not (strike_info_seeker_algo[name] == "all") then
		mn.evaluateSEXP("(when (true) (call-ssm-strike \""..strikeType.."\" \""..strikeTeam.."\" \""..target.Name.."\"))")
	end
end

--- Called at gameplay start, initializes all the global variables
function auto_ssm_init_strike_tables()
	dPrint_autoSSM("Initializing arrays")
	for index, name in pairs(strike_info_id) do
		strike_active[name] = false
		strike_last_fired[name] = 0
		strike_current_target[name] = nil
		strike_target_list[name] = {}
		--strike_target_type = {}		-- [name][target] = ship/target type; may be used by target-seeking algorithms ??? maybe move this to info ???
		strike_team[name] = "Friendly"
	end
	dPrint_autoSSM(" - done\n")
end

------------
--- main ---
------------
auto_ssm_table = parseTableFile(auto_ssm_filePath, auto_ssm_fileName)
dPrint_autoSSM(getTableObjectAsString(auto_ssm_table))

local id = 0
for name, attributes in pairs(auto_ssm_table['Automated Strikes']) do
	-- record the strike's id
	strike_info_id[id] = name
	dPrint_autoSSM("Name="..name.."\n")
	
	-- for each attribute
	for attribute, prefix in pairs(attributes) do
		value = prefix['value']
		if not (type(value) == 'table') then
			dPrint_autoSSM("attribute="..attribute.."; value="..value.."\n")
		else
			local str = ""
			for index, val in pairs(value) do
				str = str..val.." "
			end
			dPrint_autoSSM(str.."\n")
		end
		
		-- store this attribute in the relevant array
		if (attribute == "Type") then
			strike_info_type[name] = value
		elseif (attribute == "Cooldown") then
			strike_info_cooldown[name] = value
		elseif (attribute == "Default Seeking Algorithm") then
			strike_info_seeker_algo[name] = value
		else
			ba.warning("[autoSSM.lua] Unrecognised attribute "..attribute.."\n");
		end
	end
	
	-- increment id count
	id = id + 1
end

