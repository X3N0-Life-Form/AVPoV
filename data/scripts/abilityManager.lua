
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
		ba.print("[abilityManager.lua] "..message.."\n")
	end
end

--[[
	Returns the specified class as a string.
	
	@param className : name of the class
	@return class as printable string
]]
function ability_getClassAsString(className)
	local class = ability_classes[className]
	return "Ability class:\t"..class.Name.."\n"
		.."\tTargetType = "..getValueAsString(class.TargetType).."\n"
		.."\tTargetTeam = "..getValueAsString(class.TargetTeam).."\n"
		.."\tCooldown = "..getValueAsString(class.Cooldown).."\n"
		.."\tDuration = "..getValueAsString(class.Duration).."\n"
		.."\tRange = "..getValueAsString(class.Range).."\n"
		.."\tCost = "..getValueAsString(class.Cost).."\n"
		.."\t\tCostType = "..ability_getCostTypeAsString(class.CostType).."\n"
end

--[[
	Returns a cost type as a string.
	
	@param costType : structure
	@return cost type as printable string
]]
function ability_getCostTypeAsString(costType)
	local str = "nil"
	
	if not (costType == nil) then
		str = costType.Type
		
		if (costType.Global) then
			str = str.." (global)"
		end
		
		if (costType.Energy) then
			str = str.." (energy)"
		end
	end
	
	return str
end

--[[
	Returns an instance as a string.
	
	@param instanceId : instance id
	@return instance as a printable string
]]
function ability_getInstanceAsString(instanceId)
	local instance = ability_instances[instanceId]
	return "Ability instance:\t"..instance.Class.."\n"
		.."\tShip = "..getValueAsString(instance.Ship).."\n"
		.."\tLastFired = "..getValueAsString(instance.LastFired).."\n"
		.."\tActive = "..getValueAsString(instance.Active).."\n"
		.."\tManual = "..getValueAsString(instance.Manual).."\n"
		.."\tAmmo = "..getValueAsString(instance.Ammo).."\n"
end

----------------------
--- Core Functions ---
----------------------

--[[
	Creates a class of the specified name and attributes
]]
function ability_createClass(name, attributes)
	dPrint_ability("Creating class : "..name)
	-- Initialize the class
	ability_classes[name] = {
	  Name = name,
	  TargetType = attributes['Target Type']['value'],--TODO : use getValue ?
	  TargetTeam = attributes['Target Team']['value'],--TODO : ditto
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
				ability_classes[name].CostType = ability_createCostType(attributes['Cost']['sub']['Cost Type'])
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
	Creates a cost type
	
	@return cost type
]]
function ability_createCostType(costTypeValue)
	dPrint_ability("Creating cost type : "..costTypeValue)
	-- Init
	local costType = {
		Type = "none",
		Global = false,
		Energy = false
	}
	
	-- Extract value
	costType.Type = extractRight(costTypeValue)
	
	-- Identify subType
	if not (costTypeValue:find(":") == nil) then
		local subType = extractLeft(costTypeValue)
		if (subType == "global") then
			costType.Global = true
		elseif (subType == "energy") then
			costType.Energy = true
		else
			ba.warning("[abilityManager.lua] Unrecognised cost sub type : "..subType)
		end
	end
	
	return costType
end

--[[
	Resets the instance array. Should be called $On Gameplay Start.
]]
function ability_resetInstances()
	ability_instances = {}
end


--[[
	Creates an instance of the specified ability and tie it to the specified shipName.
	
	@param instanceId : unique identifier for this instance
	@param className : name of the ability
	@param shipName : ship to tie the ability to. Can be nil.
]]
function ability_createInstance(instanceId, className, shipName)
	dPrint_ability("Creating instance of class "..className.." with id "..instanceId.." for ship "..getValueAsString(shipName))
	ability_instances[instanceId] = {
		Class = className,
		Ship = shipName,
		LastFired = 0,
		Active = true,
		Manual = false, --if that instance must be fire manually
		Ammo = -1 --needs to be set after creation if necessary
	}
	
	dPrint_ability(ability_getInstanceAsString(instanceId))
end

--[[
	Verifies that this ability instance can be fired
	
	@param instanceId : id of the ability instance to test
	@return true if it can
]]
function ability_canBeFired(instanceId)
	-- Check that this is a valid id
	if (ability_instances[instanceId] == nil) then
		ba.warning("[abilityManager.lua] Unknown instance id : "..instanceId)
		return false
	end
	
	local instance = ability_instances[instanceId]
	local class = ability_classes[instance.Class]
	dPrint_ability("Can '"..instanceId.."' ("..instance.Class..") be fired ?")
	
	-- Verify that this instance is active
	if (instance.Active) then
		
		-- Verify cooldown
		local missionTime = mn.getMissionTime()
		local cooldown = getValue(class.Cooldown)
		if (instance.LastFired + cooldown >= missionTime) then
			
			dPrint_ability("\tCooldown OK")
			-- Verify cost
			if (class.Cost >= 0) then
				-- Handle cost type
				-- TODO : refactor cost handling into a sub function
				local costType = class.CostType
				local costTest = -1
				if (costType == nil) then
					costTest = instance.Ammo - class.Cost
				elseif (costType.Global) then
					ba.warning("Not yet implemented")--TODO
				elseif (costType.Energy) then
					local ship = mn.Ships[instance.Ship]
					costTest = ship.WeaponEnergyLeft - class.Cost
				else
					costTest = instance.Ammo - class.Cost
				end
				
				-- Actual cost test
				if (costTest >= 0) then
					dPrint_ability("\tCost OK")
					return true
				end
				
			else
				-- Case : no cost
				dPrint_ability("\tNo ammo cost")
				return true
			end
		end
	end
	
	-- Default
	return false
end

--[[
	Verifies that the target is in range and of a valid type
	
	@param instanceId : id of the ability instance to test
	@param target : name of the target ship
	@return true if it can
]]
function ability_canBeFiredAt(instanceId, targetName)
	local instance = ability_instances[instanceId]
	-- Verify id
	if (ability_instances[instanceId] == nil) then
		ba.warning("[abilityManager.lua] Unknown instance id : "..instanceId)
		return false
	end
	
	dPrint_ability("Can '"..instanceId.."' be fired at "..targetName.." ?")
	local class = ability_classes[instance.Class]
	local firingShip = mn.Ships[instance.Ship]
	local targetShip = mn.Ships[targetName]
	-- Verify that both handles are valid
	if (firingShip == nil or targetShip == nil) then
		ba.warning("TODO")--TODO : warning + handle checks
		return false
	else
		local distance = firingShip.Position:getDistance(targetShip.Position)
		dPrint_ability("\tDistance to target: "..distance)
		-- Verify range
		if (distance <= class.Range or class.Range == -1) then
			dPrint_ability("\tTarget in range")
			
			-- Verify target team
			if (ability_isValidTeam(class, firingShip, targetShip)) then
				dPrint_ability("\tTarget team is valid")
			
				-- Verify target type
				if (ability_isValidShipType(class, targetShip)) then
					dPrint_ability("\tTarget type is valid")
					return true
				end
			end
		end
		
		-- Default
		return false
	end
end

--[[
	Verifies the IFF of two ships compared to who the ability can target
	
	@param class : ability class
	@param firingShip : handle for the ship firing the ability
	@param targetShip : handle for the targetted ship
	@return true if the team is a valid target
]]
function ability_isValidTeam(class, firingShip, targetShip)
	dPrint_ability("Is "..targetShip.Team.Name.." a valid target for a "..class.Name.." called by "..firingShip.Team.Name.." ?")
	
	local isHostile = firingShip.Team:attacks(targetShip.Team)
	if (isHostile and contains(class.TargetTeam, "Hostile")) then
		return true
	elseif (not isHostile and contains(class.TargetTeam, "Friendly")) then
		return true
	end
	
	return false
end

--[[
	Verifies that a ship is of a valid type for an ability

	@param class : ability class
	@param targetShip : valid ship handle
	@return true if the target ship is of a valid type
]]
function ability_isValidShipType(class, targetShip)
	dPrint_ability("Is "..targetShip.Type.Name.." a valid target type for "..class.Name.." ?")

	if (type(class.TargetType) == 'table') then
		for i, typeName in pairs(class.TargetType) do
			if (targetShip.Type.Name == typeName) then
				return true
			end
		end
	else
		if (targetShip.Type.Name == class.TargetType) then
				return true
		end
	end
	
	-- Default
	return false
end

------------
--- main ---
------------

--TODO : PR for .tbl support in config
abilityTable = parseTableFile("data/config/", "abilities.tbl")

ba.print(getTableObjectAsString(abilityTable))


for name, attributes in pairs(abilityTable['Abilities']) do
	ability_createClass(name, attributes)
end
