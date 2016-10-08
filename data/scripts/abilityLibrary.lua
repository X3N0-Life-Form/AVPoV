-- TODO : doc


function fireSSM(instance, class, targetName)
	local castingShip = mn.Ships[instance.Ship]
	local strikeType = class.AbilityData['Strike Type']
	local strikeTeam = castingShip.Team.Name

	mn.evaluateSEXP("(when (true) (call-ssm-strike \""..strikeType.."\" \""..strikeTeam.."\" \""..targetName.."\"))")
end


function fireEnergyDrain(instance, class, targetName)
	local castingShip = mn.Ships[instance.Ship]
	local targetShip = mn.Ships[targetName]
	
	targetShip.WeaponEnergyLeft = targetShip.WeaponEnergyLeft - class.AbilityData['Weapon drain']
	targetShip.AfterburnerFuelLeft = targetShip.AfterburnerFuelLeft - class.AbilityData['Afterburner drain']
	targetShip.Shields.CombinedLeft = targetShip.Shields.CombinedLeft - class.AbilityData['Shield drain']
end