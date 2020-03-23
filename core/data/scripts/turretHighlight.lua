-- TODO : doc
------------------------
--- Global Variables ---
------------------------

turretHighlight_enableDebugPrint = true

turretHighlightTable = {}
turretHighlightWeapons = {}

-----------------------
-- utility functions --
-----------------------

function dPrint_turretHighlight(message)
	if (waypointHighlight_enableDebugPrint) then
		ba.print("[turretHighlight.lua] "..message.."\n")
	end
end

----------------------
--- Core functions ---
----------------------
--[[
	Initialize highlight data after parsing
]]
function turretHighlight_init()
	dPrint_turretHighlight("Initializing correspondance table")
	local entries = turretHighlightTable.Categories['Turret Types'].Entries
	
	for entryName, entry in pairs(entries) do
		dPrint_turretHighlight("Listing weapons for type '"..entryName.."'")
		
		local weapons = entry.Attributes['Weapons'].Value
		for i = 1, #weapons do
			local weaponName = weapons[i]
			dPrint_turretHighlight("\t"..weaponName)
			turretHighlightWeapons[weaponName] = entry.Name
		end
	end
end

--[[
	Main highlight call. Should be called each frame during gameplay
]]
function turretHighlight_highlight()
	local targetShip = mn.Ships[hv.Player.Name].Target

	if targetShip:isValid() then
		for i = 1, #targetShip do
			local subsystem = targetShip[i]
			-- Subsystem is a living turret that's visible
			if (subsystem:isTurret() and subsystem.HitpointsLeft > 0) then
				dPrint_turretHighlight("Considering turret '"..subsystem.Name.."' for highlight")
				
				-- Handle turret type
				local turretType = turretHighlight_getTurretType(subsystem)
				if (turretHighlight_shouldHighlight(subsystem, turretType)) then
				
					-- Handle color
					local color = turretHighlight_getColor(turretType)
					dPrint_turretHighlight("Using color scheme: "..color[1]..", "..color[2]..", "..color[3])
					gr.setColor(color[1], color[2], color[3])
					
					-- Draw
					-- TODO : special patterns
					local bracketPositions = gr.drawSubsystemTargetingBrackets(subsystem, true)
					-- TODO : is targetting YOU
					-- if (bracketPositions ~= nil and subsystem.Target == mn.Ships[hv.Player.Name]) then
						-- dPrint_turretHighlight("Player is being targetted")
						-- if (math.random(100) > 50) then
							-- gr.setColor(255, 0, 0)
						-- else
							-- gr.setColor(255, 255, 0)
						-- end
						-- local centerX = bracketPositions[1] + (bracketPositions[3] - bracketPositions[1])
						-- local centerY = bracketPositions[2] + (bracketPositions[4] - bracketPositions[2])
						-- gr.drawCircle(5, centerX, centerY, false)
					-- end
				end
			end
		end
	end
end


---------------------
--- Aux functions ---
---------------------
--[[
	Should the specified subsystem be highlighted, according to the specified turret type ?
	
	@param subsystem : subsystem
	@param turretType : turret type name
	@return true if it should be highlighted
]]
function turretHighlight_shouldHighlight(subsystem, turretType)
	return (turretType ~= 'none'
			-- Always highlight or visible only
			and (	(turretHighlight_getEntry(turretType).Attributes['Visible only'] == nil
						or getValueAsBoolean(turretHighlight_getEntry(turretType).Attributes['Visible only'].Value) == false
					)
				or (getValueAsBoolean(turretHighlight_getEntry(turretType).Attributes['Visible only'].Value) == true
						and subsystem:isInViewFrom(mn.Ships[hv.Player.Name].Position)
					)
			)
		)
end

--[[
	Get the turret type for the specified subsystem
	
	@param subsystem : subsystem
	@return turret type name
]]
function turretHighlight_getTurretType(subsystem)
	local turretType = "none"
	for i = 1, #subsystem.PrimaryBanks do
		local weapon = subsystem.PrimaryBanks[i].WeaponClass
		
		dPrint_turretHighlight("Primary weapon: "..weapon.Name)
		turretType = turretHighlightWeapons[weapon.Name]
	end
	
	for i = 1, #subsystem.SecondaryBanks do
		local weapon = subsystem.SecondaryBanks[i].WeaponClass
		
		dPrint_turretHighlight("Secondary weapon: "..weapon.Name)
		turretType = turretHighlightWeapons[weapon.Name]
	end
	
	-- TODO : handle multi-types
	if (turretType == nil) then
		turretType = "default"
		ba.warning("[turretHighlight.lua] Turret type not found for weapon class '"..weapon.Name.."'")
	end
	dPrint_turretHighlight("Turret type: "..turretType)
	return turretType
end

--[[
	Get the highlight color for the specified turret type
	
	@param turretType : turret type name
	@return {R, G, B} array
]]
function turretHighlight_getColor(turretType)
	if (turretType == 'default') then
		return {255, 255, 255}
	else
		return turretHighlight_getEntry(turretType).Attributes['Color'].Value
	end
end

--[[
	Get the table entry for the specified turret type
	
	@param turretType : turret type name
	@return table entry
]]
function turretHighlight_getEntry(turretType)
	return turretHighlightTable.Categories['Turret Types'].Entries[turretType]
end

----------
-- main --
----------

turretHighlightTable = TableObject:create("turret_highlight.tbl")

turretHighlight_init()