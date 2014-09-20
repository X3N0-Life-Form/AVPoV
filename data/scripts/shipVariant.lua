--[[
		---------------------------------
		-- ship variant manager script --
		---------------------------------
In order to work, this script needs:
	- a descriptor text file
	- the global variable variantFileName needs to point to this file, eg. "data/config/ship_variants.txt"
	- call the setVariant() or sv() function via scrip-eval, with the name of the ship you want to alter and the name of the variant of the appropriate class as the function's argument.
		For instance "sv(Colly, bunny)" means you want Colly to be of the "bunny" variant.
		Keep in mind that, as of this writing, script-eval suffers from FSO's infamous 32 character limit, so you may want to keep your variant names short for the time being.
		
Descriptor file logic:
	- A new variant is identified by a '$', followed by the ship class, a ':' and then the variant's name, like this:
		$GTC Aeolus:	nerfed		--> defines the "nerf" variant for the GTC Aeolus
	- Following the variant definition is a list of attributes or turret names, potentially with their own sub-attributes.
		
			
Valid attributes:
	hull: special hit points
	armor: hull armor type
	turret armor: ship-wide turret armor type
	subsystem armor: ship-wide subsystem armor type
	
Valid sub-attributes:
	armor: armor type
	
Sample entry:
	$GTC Aeolus: nerfed
			hull: 15k
			armor: Fancy Armor
			turret armor: Fancy Armor
			subsystem armor: Fancy Armor
			turret01: Terran Huge Turret
				+armor: Weak Armor
			turret02: Terran Huge Turret
				+armor: Weak Armor
			turret03: Terran Huge Turret
			turret04: Terran Huge Turret
			turret05: Terran Huge Turret
]]--
----------------------
-- global variables --
----------------------
variantFileName = "ship_variants.txt" -- change this
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

-- screw you, 32 char limit
function sv(shipName, variantName)
	setVariant(shipName, variantName)
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
		variantMatrix = parseVariantFile(variantFileName)
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

variantMatrix = parseVariantFile(variantFileName)
