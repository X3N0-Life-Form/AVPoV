
function trim(str)
	return str:find'^%s*$' and '' or str:match'^%s*(.*%S)'
end

function removeComments(line)
	return line:gsub("--(.)*|//(.)*|;;(.)*", "")
end

function parseVariantFile(fileName)
	if (matrix == nil) then
		matrix = {}
	end
	if cf.fileExists(fileName, "", true) then
		local file = cf.openFile(fileName, "r")
		
		local line = file:read("*l")
		i = 0
		while (not (line == nil)) do
			i = i+1
			line = removeComments(line)
			line = trim(line)
			
			cut = string.find(line, ":")
			if not (cut == nil) then -- we've got a parsable line
				if not (string.find(line, "[$]") == nil) then
					className = trim(string.sub(line, 2, cut - 1))
					variantName = trim(string.sub(line, cut + 1))
					
					-- init class & variant maps
					if (matrix[className] == nil) then
						matrix[className] = {}
					end
					ba.print("parseVariantFile: className="..className.."; variantName="..variantName)
					matrix[className][variantName] = {}
				else
					attributeName = trim(string.sub(line, 0, cut - 1))		-- turret, hull, armor
					attributeValue = trim(string.sub(line, cut + 1))		-- weapon type, armor type, hull value
					ba.print("parseVariantFile: attributeName="..attributeName.."; attributeValue="..attributeValue)
					matrix[className][variantName][attributeName] = attributeValue
				end
				--TODO: error proof previous if then else block
			end
			
			line = file:read("*l")
		end -- while
		file:close()
		return matrix
	else
		ba.warning("parseVariantFile: Variant file not found "..filename)
		return nil
	end
end

function setVariant(shipName, variantName)
	local variantFolder = "."
	local variantFilename = "ship_variants.txt"
	local matrix = {}
	matrix = parseVariantFile(variantFilename)
	-- get ship class
	-- lookup variant for that class
	-- start going through the attributes
	local ship = mn.Ships[shipName]
	if (ship == nil) then
		ba.warning("setVariant: Could not find ship "..shipName)
		return nil
	end
	local className = ship.Class.Name
	local variantInfo = matrix[className][variantName]
	
	local turretArmor = ""
	local subsystemArmor = ""
	for attribute, value in pairs(variantInfo) do
		--Note: value = variantInfo[attribute]
		if (attribute == "armor") then
			ba.print("setVariant: Armor ==> "..value)
			ship.armorClass = value
		elseif (attribute == "shield armor") then
			ba.print("setVariant: Shield Armor ==> "..value)
			ship.ShieldArmorClass = value
		elseif (attribute == "hull") then
			-- deal with orders of magnitude
			if not (string.find(value, "k") == nil) then
				value = string.gsub(value, "k", "")
				value = value * 1000
			elseif not (string.find(value, "M") == nil) then
				value = string.gsub(value, "M", "")
				value = value * 1000000
			elseif not (string.find(value, "G") == nil) then
				value = string.gsub(value, "G", "")
				value = value * 1000000000
			end
			ship.HitpointsMax = value
		elseif (attribute == "turret armor") then
			turretArmor = value
		elseif (attribute == "subsystem armor") then
			subsystemArmor = value
		else -- turret
			if (ship[attribute].PrimaryBanks) then -- primary banks
				for i = 0, #ship[attribute].PrimaryBanks do
					ba.print("setVariant: Prim "..attribute.." - "..ship[attribute].PrimaryBanks[i].WeaponClass.Name.." ==> "..tb.WeaponClasses[value].Name)
					ship[attribute].PrimaryBanks[i].WeaponClass = tb.WeaponClasses[value]
				end
			else -- secondary banks
				for i = 0, #ship[attribute].SecondaryBanks do
					ba.print("setVariant: Sec "..attribute.." - "..ship[attribute].SecondaryBanks[i].WeaponClass.Name.." ==> "..tb.WeaponClasses[value].Name)
					ship[attribute].SecondaryBanks[i].WeaponClass = tb.WeaponClasses[value]
				end
			end
		end
		
		-- set turrets & subsystems armor
		for subIndex = 0, #ship do
			local subsystem = ship[subIndex]
			if (subsystem:isTurret() and not (turretArmor == "")) then
				subsystem.ArmorClass = turretArmor
			elseif not (subsystemArmor == "") then
				subsystem.ArmorClass = subsystemArmor
			end
		end
	end
end

----------
-- main --
----------
variantFolder = "./"
variantFilename = "ship_variants.txt"
matrix = {}

matrix = parseVariantFile(variantFilename)
