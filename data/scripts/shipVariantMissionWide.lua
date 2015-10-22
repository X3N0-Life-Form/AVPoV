
------------------------
--- global variables ---
------------------------
shipVariantMissions_enableDebugPrint = false

shipVariantMissionsTable = {}

---------------------------
--- functions - utility ---
---------------------------

function dPrint_shipVariantMissions(message)
	if (shipVariantMissions_enableDebugPrint) then
		ba.print("[shipVariantMissionWide.lua] "..message)
	end
end

------------------------
--- functions - core ---
------------------------

--[[
	Sets ship variants for the entire mission
	@param categoryName name of the category in the table file
]]
function setShipVariants(categoryName)
	if not (shipVariantMissionsTable[categoryName] == nil) then
		dPrint_shipVariantMissions("Setting mission-wide variants using variant list "..categoryName.."\n")
		for shipName, attributes in pairs(shipVariantMissionsTable[categoryName]) do
			local variantName = attributes['Variant']['value']
			
			-- if this is a single ship
			if (attributes['Variant']['sub'] == nil) or (attributes['Variant']['sub']['Wing'] == nil) then
				dPrint_shipVariantMissions("\tSetting variant "..variantName.." for ship "..shipName.."\n")
				setVariant(shipName, variantName)
			else -- or if this is a wing
				dPrint_shipVariantMissions("\tSetting variant "..variantName.." for wing "..shipName.."\n")
				local wingSize = attributes['Variant']['sub']['Wing']
				for i = 1, i <= wingSize do
					setVariant(shipName.." "..i, variantName)
				end
			end
			
		end
	else
		ba.warning("[shipVariantMissionWide.lua] Could not find entry "..categoryName)
	end
end

shipVariantMissionsTable = parseTableFile("data/config/", "ship_variants_mission_wide.tbl")