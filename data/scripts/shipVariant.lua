
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
					ba.print("className="..className.."; variantName="..variantName)
					matrix[className][variantName] = {}
				else
					attributeName = trim(string.sub(line, 0, cut - 1))		-- turret, hull, armor
					attributeValue = trim(string.sub(line, cut + 1))		-- weapon type, armor type, hull value
					ba.print("attributeName="..attributeName.."; attributeValue="..attributeValue)
					matrix[className][variantName][attributeName] = attributeValue
				end
				--TODO: error proof previous if then else block
			end
			
			line = file:read("*l")
		end -- while
		file:close()
		return matrix
	else
		ba.warning("Variant file not found "..filename)
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
		ba.warning("Could not find ship "..shipName)
		return nil
	end
	local className = ship.Class.Name
	local variantInfo = matrix[className][variantName]
	
	local turretArmor = ""
	local subsystemArmor = ""
	for attribute, value in pairs(variantInfo) do
		--Note: value = variantInfo[attribute]
		if (attribute == "armor") then
			ship.armorClass = value --what about shield armor?
		elseif (attribute == "hull") then
			ship.HitpointsMax = value
		elseif (attribute == "turret armor") then
			turretArmor = value
		elseif (attribute == "subsystem armor") then
			subsystemArmor = value
		else -- turret
			-- TODO: multi-bank stuff
			ba.warning("Weapon class="..value.."; attribute="..attribute)
			--ba.warning(ship[attribute])
			--for i = 0, #ship do
			--	ba.warning(ship[i])
			--end
			if (ship[attribute].PrimaryBanks) then -- primary banks
				ship[attribute].PrimaryBanks[1].WeaponClass = tb.WeaponClasses[value]
			else -- secondary banks
				ship[attribute].SecondaryBanks[1].WeaponClass = tb.WeaponClasses[value]
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