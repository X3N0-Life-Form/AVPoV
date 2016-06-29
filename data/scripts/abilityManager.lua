
------------------------
--- Global Variables ---
------------------------

ability_classes = {}
ability_instances = {}


-- set to true to enable prints
ability_enableDebugPrints = true

----------------------
--- ??? Functions ---
----------------------


function ability_fireAllPossible()
	-- TODO : cycle through ability instances & fire them
end

-------------------------
--- Utility Functions ---
-------------------------

function dPrint_ability(message)
	if (ability_enableDebugPrints) then
		ba.print("[abilityManager.lua] "..message)
	end
end

--[[
	Return the specified class as a string.
	
	@param className : name of the class
]]
function ability_getClassAsString(className)
	--TODO
end

----------------------
--- Core Functions ---
----------------------


function ability_createClass(name, attributes)
	-- Initialize the class
	ability_classes[name] = {
	  Name = name,
	  TargetType = attributes['Target Type']['value'],
	  TargetTeam = attributes['Target Team']['value'],
	  Cooldown = nil,
	  Duration = nil,
	  Range = -1,
	  Cost = 0,
	  CostType = nil
	}
	
	if not (attributes['Cooldown'] == nil) then
		ability_classes[name].Cooldown = attributes['Cooldown']['value']
	end
	
	if not (attributes['Range'] == nil) then
		ability_classes[name].Range = attributes['Range']['value']
	end
	
	if not (attributes['Cost'] == nil) then
		ability_classes[name].Cost = attributes['Cost']['value']
		if not (attributes['Cost']['sub'] == nil) then --TODO : utility function to grab a sub attributes' value ???
			if not (attributes['Cost']['sub']['Cost Type'] == nil) then
				ability_classes[name].CostType = attributes['Cost']['sub']['Cost Type']
			end
		end
	end
	
	if not (attributes['Duration'] == nil) then
		ability_classes[name].Duration = attributes['Duration']['value']
	end
	
	-- Print class
	dPrint_ability(ability_getClassAsString(name))
end

--[[
	Reset the instance array. Should be called $On Gameplay Start.
]]
function ability_resetInstances()
	ability_instances = {}
end


--[[
	Create an instance of the specified ability and tie it to the specified shipName.
	
	@param instanceId : unique identifier for this instance
	@param className : name of the ability
	@param shipName : ship to tie the ability to. Can be nil.
]]
function ability_createInstance(instanceId, className, shipName)
	ability_instances[instanceId] = {
		Class = className,
		Ship = shipName,
		LastFired = 0,
		Active = true,
		Manual = false, --if that instance must be fire manually
		Ammo = -1 --needs to be set after creation if necessarys
	}
end

--[[
	Verify that this ability instance can be fired
	
	@param instanceId : id of the ability instance to test
	@return true if it can
]]
function ability_canBeFired(instanceId)
	-- Check that this is a valid idea
	if (ability_instances[instanceId] == nil) then
		ba.warning("[abilityManager.lua] Unknown instance id : "..instanceId)
		return false
	end
	
	local instance = ability_instances[instanceId]
	local class = ability_classes[instance.Class]
	-- Verify that this instance is active
	if (instance.Active) then
		-- Verify cooldown
		local missionTime = mn.getMissionTime()
		local cooldown = class.Cooldown
		if (instance.LastFired + cooldown >= missionTime) then
			--TODO : Verify cost
			return true
		end
	end
	
	-- Default
	return false
end

------------
--- main ---
------------

abilityTable = parseTableFile("data/config/", "abilities.tbl")

ba.print(getTableObjectAsString(abilityTable))


for name, attributes in pairs(abilityTable['Abilities']) do
	ability_createClass(name, attributes)
end