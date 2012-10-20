ships = #mn.Ships
for index=0, ships do
	currentShip = ships[index]
	if currentShip.Class.Name == "SB Seraphim" then
		bank = currentShip.PrimaryBanks[0].WeaponClass.Name
		for turretIndex=0, 2 do
			-- currentShip[turretIndex].PrimaryBanks[0].WeaponClass.Name = bank
			#mn.evaluateSEXP("( "					--turret-change-weapon
				+ "turret-change-weapon "			--Sets a given turret weapon slot to the specified weapon
				+ "\"" + currentShip.Name + "\" "			--1: Ship turret is on
				+ "\"turret0" + (turretIndex + 1) + "\" "	--2: Turret
				+ "\"" + bank + "\" "								--3: Weapon to set slot to
				+ " 1 "										--4: Primary slot (or 0 to use secondary)
				+ " 0 "										--5: Secondary slot (or 0 to use primary)
				+ " )")
		end
	end
end