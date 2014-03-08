for index=0, #mn.Ships do
	currentShip = mn.Ships[index]
	
	-- bombers
	if currentShip.Class.Name == "SB Seraphim"
		or currentShip.Class.Name == "SB Nephilim" then
		
		mainBankClass = currentShip.PrimaryBanks[1].WeaponClass
		for subIndex=0, #currentShip do
			if (currentShip[subIndex]:isTurret()) then
				currentShip[subIndex].PrimaryBanks[1].WeaponClass = mainBankClass
			end
		end

	end
	
	-- gunships
	---- need to decide on weapon packages first
	---- examples:
	--		long range support
	--		close range support
	--		anti-capital support
	--		hull/shield repair
	--		kinetic support
	--		disarm/disable
end
