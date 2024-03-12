﻿-- Jackarunda 2021
AddCSLuaFile()
ENT.Base = "ent_jack_gmod_ezresource"
ENT.PrintName = "EZ Advanced Parts Box"
ENT.Category = "JMod - EZ Resources"
ENT.IconOverride = "materials/ez_resource_icons/advanced parts.png"
ENT.Spawnable = true
ENT.AdminSpawnable = true
---
ENT.EZsupplies = JMod.EZ_RESOURCE_TYPES.ADVANCEDPARTS
ENT.JModPreferredCarryAngles = Angle(0, 180, 0)
ENT.Model = "models/jmod/resources/hard_case_b.mdl"
ENT.Material = nil
ENT.Color = Color(100, 100, 100)
ENT.ModelScale = 1
ENT.Mass = 30
ENT.ImpactNoise1 = "drywall.ImpactHard"
ENT.ImpactNoise2 = "Weapon.ImpactSoft"
ENT.DamageThreshold = 120
ENT.BreakNoise = "Metal_Box.Break"

ENT.PropModels = {"models/props_lab/reciever01d.mdl", "models/props/cs_office/computer_caseb_p2a.mdl", "models/props/cs_office/computer_caseb_p3a.mdl", "models/props/cs_office/computer_caseb_p4a.mdl", "models/props/cs_office/computer_caseb_p5a.mdl", "models/props/cs_office/computer_caseb_p5b.mdl", "models/props/cs_office/computer_caseb_p6a.mdl", "models/props/cs_office/computer_caseb_p6b.mdl", "models/props/cs_office/computer_caseb_p7a.mdl", "models/props/cs_office/computer_caseb_p8a.mdl", "models/props/cs_office/computer_caseb_p9a.mdl"}

---
if SERVER then
	--[[function ENT:UseEffect(pos, ent)
		local effectdata = EffectData()
		effectdata:SetOrigin(pos + VectorRand())
		effectdata:SetNormal((VectorRand() + Vector(0, 0, 1)):GetNormalized())
		effectdata:SetMagnitude(math.Rand(2, 4)) --amount and shoot hardness
		effectdata:SetScale(math.Rand(1, 2)) --length of strands
		effectdata:SetRadius(math.Rand(2, 4)) --thickness of strands
		util.Effect("Sparks", effectdata, true, true)
	end]]--

	function ENT:CustomThink()
		local Phys = self:GetPhysicsObject()
		Phys:ApplyForceCenter(VectorRand() * math.random(1, 1000 * (Phys:GetMass() / self.Mass)))
		self:NextThink(CurTime() + math.Rand(2, 4))

		return true
	end
elseif CLIENT then
    local drawvec, drawang = Vector(0, 3.5, 1), Angle(-90, 0, 90)
	function ENT:Draw()
		self:DrawModel()

		JMod.HoloGraphicDisplay(self, drawvec, drawang, .035, 300, function()
			JMod.StandardResourceDisplay(JMod.EZ_RESOURCE_TYPES.ADVANCEDPARTS, self:GetResource(), nil, 0, 0, 200, true)
		end)
	end

	--language.Add(ENT.ClassName, ENT.PrintName)
end
