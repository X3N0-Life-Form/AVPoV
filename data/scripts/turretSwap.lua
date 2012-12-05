ships = #mn.Ships
for index=0, ships do
	currentShip = ships[index]
	if currentShip.Class.Name == "SB Seraphim" then
		bank = currentShip.PrimaryBanks[0].WeaponClass.Name
		for turretIndex=0, 2 do
			-- currentShip[turretIndex].PrimaryBanks[0].WeaponClass.Name = bank
			#mn.evaluateSEXP(
				" ( when \n"
				+ "( true )\n"
					+ "( turret-change-weapon \n"			--Sets a given turret weapon slot to the specified weapon
					+ "\"" + currentShip.Name + "\"\n"			--1: Ship turret is on
					+ "\"turret0" + (turretIndex + 1) + "\"\n"	--2: Turret
					+ "\"" + bank + "\"\n"						--3: Weapon to set slot to
					+ "1\n"										--4: Primary slot (or 0 to use secondary)
					+ "0\n"										--5: Secondary slot (or 0 to use primary)
					+ ")\n"
				+ " ) ")
		end
	end
end

-- $Formula: ( when 
   -- ( true ) 
   -- ( turret-change-weapon 
      -- "Alpha 1" 
      -- "turret01" 
      -- "Subach HL-7" 
      -- 1 
      -- 0 
   -- )
-- )
-- +Name: turret swap
-- +Repeat Count: 1
-- +Interval: 1