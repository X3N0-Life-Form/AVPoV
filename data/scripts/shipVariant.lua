-- in:	variant name
--		ship name
-- ?read variant file
-- if specified variant found & ship class OK
-- for each turret
-- 		if variant specific, change it

variantFolder = "."
matrix = {}

function setVariant(shipName, variantName)
	-- get ship class
	-- lookup variant for that class
	-- start going through the attributes
	-- do switch cases exist in lua?
	ship = mn.ships[shipName]
	className = ship.Class.Name
	variantInfo = matrix[className][variantName]
	
	turretArmor = ""
	subsystemArmor = ""
	for (attribute, variantInfo) do
		value = variantInfo[attribute]
		if (attribute == "armor") then
			ship.armorClass = value --what about shield armor?
		elseif (attribute == "hull") then
			ship.HitpointsMax = value
		elseif (attribute == "turret armor") then
			turretArmor = value
		elseif (attribute == "subsystem armor") then
			subsystemArmor = value
		else -- turret
			if (ship[attribute].PrimaryBanks != nil) then -- primary banks
				ship[attribute].PrimaryBanks[1].WeaponClass = value -- TODO: multi-bank stuff
			else -- secondary banks
				ship[attribute].SecondaryBanks[1].WeaponClass = value
			end
		end
		
		-- set turrets & subsystems armor
		for (subIndex = 0, #ship) do
			subsystem = ship[subIndex]
			if (subsystem:isTurret() and turretArmor != "") then
				subsystem.ArmorClass = turretArmor
			elseif (subsystemArmor != "") then
				subsystem.ArmorClass = subsystemArmor
			end
		end
	end
end

function parseVariantFile(fileName)
	if cf.fileExists(fileName, variantFolder, true) then
		file = cf.openFile(fileName, "rb", variantFolder)
		
		while ((line = file:read("*l")) != nil) do
			if (line ~= nil
				or string.find(line, "//") == 1 --
				or string.find(line, "--") == 1 -- comment spam !!!
				or string.find(line, ";;") == 1 --
				) then
				--continue
			end
			
			--TODO: trim line
			cut = string.find(":")
			if (string.find("\t") != 1) then -- no tabs == new variant
				className = string.sub(line, 0, cut)
				variantName = string.sub(line, cut) --TODO:trim again + remove (stuff)
				
				-- init class & variant maps
				if (matrix[className] == nil) then
					matrix[className] = {}
				end
				matrix[className][variantName] = {}
			else
				attributeName = string.sub(line, 0, cut)	-- turret, hull, armor
				attributeValue = string.sub(line, cut)		-- weapon type, armor type, hull value
				--TODO:trim again + remove (stuff)
				matrix[className][variantName][attributeName] = attributeValue
			end
			--TODO: error proof previous if then else block
		
		end
		return matrix
	else
		return nil
	end
end