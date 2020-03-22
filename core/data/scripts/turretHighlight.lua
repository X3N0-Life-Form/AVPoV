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


function turretHighlight_highlight()
	local targetShip = mn.Ships[hv.Player.Name].Target

	if targetShip:isValid() then
		for i = 1, #targetShip do
			local subsystem = targetShip[i]
			-- Subsystem is a living turret that's visible
			if (subsystem:isTurret() and subsystem.HitpointsLeft > 0) then
				dPrint_turretHighlight("Highlighting turret '"..subsystem.Name.."'")
				
				-- Handle turret type
				local turretType = turretHighlight_getTurretType(subsystem)
				-- TODO : visible only attribute : subsystem:isInViewFrom(mn.Ships[hv.Player.Name].Position)
				if (turretType == 'none') then
					return
				end
				
				-- Handle color
				local color = turretHighlight_getColor(turretType)
				dPrint_turretHighlight("Using color scheme: "..color[1]..", "..color[2]..", "..color[3])
				gr.setColor(color[1], color[2], color[3])
				
				-- Draw
				-- TODO : special patterns
				-- TODO : is targetting YOU
				gr.drawSubsystemTargetingBrackets(subsystem, true)
			end
		end
	end
end

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

function turretHighlight_getColor(turretType)
	if (turretType == 'default') then
		return {255, 255, 255}
	else
		return turretHighlightTable.Categories['Turret Types'].Entries[turretType].Attributes['Color'].Value
	end
end

----------
-- main --
----------

turretHighlightTable = TableObject:create("turret_highlight.tbl")

turretHighlight_init()