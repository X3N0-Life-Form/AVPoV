for index=0, #mn.Ships do
	currentShip = mn.Ships[index]
	-- bombers
	if currentShip.Class.Name == "SB Seraphim"
		or currentShip.Class.Name == "SB Nephilim" then
--
Graphics.setColor(255, 255, 255)
Graphics.drawString("Hello, world!", 5, 10)
--
		mainBankClass = currentShip.PrimaryBanks[0].WeaponClass
		for subIndex=0, #currentShip do
			if (currentShip[subIndex]:isTurret()) then
				currentShip[subIndex].PrimaryBanks[0].WeaponClass = mainBankClass
			end
		end

	end
	-- gunships
	---- need to decide on weapon packages first
end
