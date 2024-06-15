﻿-- Jackarunda 2021
AddCSLuaFile()
ENT.Base = "ent_jack_gmod_ezresource"
ENT.PrintName = "EZ Cloth Roll"
ENT.Category = "JMod - EZ Resources"
ENT.IconOverride = "materials/ez_resource_icons/cloth.png"
ENT.Spawnable = true
ENT.AdminSpawnable = true
---
ENT.EZsupplies = JMod.EZ_RESOURCE_TYPES.CLOTH
ENT.JModPreferredCarryAngles = Angle(0, -90, 100)
ENT.Model = "models/jmod/resources/cylinderx15.mdl"
ENT.Material = "models/mat_jack_gmod_clothroll"
ENT.PhysMat = "cloth"
ENT.Color = Color(200, 200, 200)
ENT.ModelScale = 1
ENT.Mass = 30
ENT.ImpactNoise1 = "Flesh.ImpactSoft"
ENT.DamageThreshold = 120
ENT.BreakNoise = "Flesh.ImpactSoft"
ENT.Flammable = 1

---
if SERVER then
	function ENT:UseEffect(pos, ent)
	end
	-- todo: find a particle effect for this
elseif CLIENT then
    local drawvec, drawang = Vector(0, -.5, 9), Angle(0, 0, 0)
	function ENT:Draw()
		self:DrawModel()

		JMod.HoloGraphicDisplay(self, drawvec, drawang, .025, 300, function()
			JMod.StandardResourceDisplay(JMod.EZ_RESOURCE_TYPES.CLOTH, self:GetResource(), nil, 0, 0, 200, false, nil, 200, nil, 0)
		end)
	end

	--language.Add(ENT.ClassName, ENT.PrintName)
end
