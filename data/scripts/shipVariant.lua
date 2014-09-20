----------------------
-- global variables --
----------------------
variantFilename = "ship_variants.txt"
variantMatrix = {}


-----------------------
-- utility functions --
-----------------------

function trim(str)
	return str:find'^%s*$' and '' or str:match'^%s*(.*%S)'
end

function removeComments(line)
	return line:gsub("--(.)*|//(.)*|;;(.)*", "")
end


--------------------
-- core functions --
--------------------

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
				if not (string.find(line, "[+]") == nil) then
					if (attributeName == nil) then
						ba.warning("parseVariantFile: assigning a sub-attribute without a super-attribute: "..line)
					else
						subAttributeName = trim(string.sub(line, 2, cut - 1))	-- armor
						subAttributeValue = trim(string.sub(line, cut + 1))		-- armor type
						ba.print("parseVariantFile: subAttributeName="..subAttributeName.."; subAttributeValue="..subAttributeValue)
						matrix[className][variantName]["+"..attributeName..":"..subAttributeName] = subAttributeValue
					end
				elseif not (string.find(line, "[$]") == nil) then
					className = trim(string.sub(line, 2, cut - 1))
					variantName = trim(string.sub(line, cut + 1))
					
					-- init class & variant maps
					if (matrix[className] == nil) then
						matrix[className] = {}
					end
					ba.print("parseVariantFile: className="..className.."; variantName="..variantName)
					matrix[className][variantName] = {}
					
					-- clean up potential leftovers
					attributeName = nil
					attributeValue = nil
				else
					attributeName = trim(string.sub(line, 0, cut - 1))		-- turret, hull, armor
					attributeValue = trim(string.sub(line, cut + 1))		-- weapon type, armor type, hull value
					ba.print("parseVariantFile: attributeName="..attributeName.."; attributeValue="..attributeValue)
					matrix[className][variantName][attributeName] = attributeValue
				end
				--TODO: error check results of previous if then else block?
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
	if (variantMatrix == nil) then
		variantMatrix = parseVariantFile(variantFilename)
	end
	-- get ship class
	-- lookup variant for that class
	-- start going through the attributes
	local ship = mn.Ships[shipName]
	if (ship == nil) then
		ba.warning("setVariant: Could not find ship "..shipName)
		return nil
	end
	
	local className = ship.Class.Name
	local variantInfo = variantMatrix[className][variantName]
	if (variantInfo == nil) then
		ba.warning("setVariant: Could not find variant info for "..className..":"..variantName)
		return nil
	end
	
	local turretArmor = ""
	local subsystemArmor = ""
	local subToSkip = {}
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
			
			-- set max & current hit points
			ba.print("setVariant: hull ==> "..value)
			ratio = value / ship.HitpointsMax
			ship.HitpointsMax = value
			ship.HitpointsLeft = ship.HitpointsLeft * ratio
		elseif (attribute == "turret armor") then
			turretArmor = value
		elseif (attribute == "subsystem armor") then
			subsystemArmor = value
		elseif not (string.find(attribute, "+") == nil) then -- sub-attribute
			-- note: logic borrowed from the parser
			line = attribute
			cut = string.find(line, ":")
			attribute = string.sub(line, 2, cut - 1)
			subAttribute = string.sub(line, cut + 1)
			ba.print("setVariant: setting sub attribute for "..attribute)
			ba.print("setVariant:     "..subAttribute.." ==> "..value)
			if (subAttribute == "armor") then
				ship[attribute].ArmorClass = value
				-- also, need to make sure general armor settings don't override this
				subToSkip[attribute] = true
			else
				ba.warning("Unrecognised sub attribute: "..subAttribute)
			end
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
			if (subsystem:isTurret() and not (turretArmor == "") and not (subToSkip[subsystem])) then
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

variantMatrix = parseVariantFile(variantFilename)
