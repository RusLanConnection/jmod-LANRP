-- Jackarunda 2021
AddCSLuaFile()
ENT.Base = "ent_jack_gmod_ezbomb"
ENT.Author = "Jackarunda"
ENT.Category = "JMod - EZ Explosives"
ENT.Information = "glhfggwpezpznore"
ENT.PrintName = "EZ Chlorine Bomb"
ENT.Spawnable = true
ENT.AdminSpawnable = true
---
ENT.JModPreferredCarryAngles = Angle(0, 0, 0)
ENT.EZRackOffset = Vector(0, 0, 10)
ENT.EZRackAngles = Angle(0, 0, 0)
ENT.EZbombBaySize = 5
ENT.EZguidable = false
---
ENT.Model = "models/hunter/blocks/cube025x125x025.mdl"
--ENT.Model = "models/props_phx/ww2bomb.mdl"
ENT.Mass = 100
ENT.DetSpeed = 1000
---
local STATE_BROKEN, STATE_OFF, STATE_ARMED = -1, 0, 1

---
if SERVER then
	function ENT:Detonate()
		if self.Exploded then return end
		self.Exploded = true
		local SelfPos, Att = self:GetPos() + Vector(0, 0, 100), JMod.GetEZowner(self)
		local SelfPos, Owner, SelfVel = self:LocalToWorld(self:OBBCenter()), self.EZowner or self, self:GetPhysicsObject():GetVelocity()
		local Boom = ents.Create("env_explosion")
		Boom:SetPos(SelfPos)
		Boom:SetKeyValue("imagnitude", "50")
		Boom:SetOwner(Owner)
		Boom:Spawn()
		Boom:Fire("explode", 0)
		---
		for i = 1, 200 do
			timer.Simple(i / 100, function()
				local Gas = ents.Create("ent_jack_gmod_ezchlorineparticle")
				Gas:SetPos(SelfPos)
				JMod.SetEZowner(Gas, Owner)
				Gas:Spawn()
				Gas:Activate()
				Gas.CurVel = VectorRand() * math.random(-100, 100)
				Gas.MaxLife = 60
			end)
		end
		---
		self:Remove()
	end

	function ENT:AeroDragThink()

		local Phys = self:GetPhysicsObject()

		if (self:GetState() == STATE_ARMED) and (Phys:GetVelocity():Length() > 400) and not self:IsPlayerHolding() and not constraint.HasConstraints(self) then
			self.FreefallTicks = self.FreefallTicks + 1

			if self.FreefallTicks >= 10 then
				local Tr = util.QuickTrace(self:GetPos(), Phys:GetVelocity():GetNormalized() * 100, self)

				if Tr.Hit then
					self:Detonate()
				end
			end
		else
			self.FreefallTicks = 0
		end

		JMod.AeroDrag(self, self:GetRight(), 2)
		self:NextThink(CurTime() + .1)

		return true
	end
elseif CLIENT then
	function ENT:Initialize()
		self.Mdl = ClientsideModel("models/props_phx/ww2bomb.mdl")
		self.Mdl:SetSubMaterial(0, "models/entities/chlorine_bomb")
		self.Mdl:SetModelScale(1, 0)
		self.Mdl:SetPos(self:GetPos())
		self.Mdl:SetParent(self)
		self.Mdl:SetNoDraw(true)
		--self.Guided=false

		self.snd = CreateSound(self, self.WhistleSound)
		self.snd:SetSoundLevel( 110 )
		self.snd:PlayEx(0,150)
	end

	function ENT:CalcDoppler()
		local Ent = LocalPlayer()
		local ViewEnt = Ent:GetViewEntity()

		local sVel = self:GetVelocity()
		local oVel = Ent:GetVelocity()
		local SubVel = oVel - sVel
		local SubPos = self:GetPos() - Ent:GetPos()
	
		local DirPos = SubPos:GetNormalized()
		local DirVel = SubVel:GetNormalized()
		local A = math.acos( math.Clamp( DirVel:Dot( DirPos ) ,-1,1) )
		return 1 + math.cos( A ) * SubVel:Length() / 13503.9
	end
	--
	function ENT:Draw()
		local Pos, Ang = self:GetPos(), self:GetAngles()
		Ang:RotateAroundAxis(Ang:Up(), -90)
		--self:DrawModel()
		self.Mdl:SetRenderOrigin(Pos + Ang:Right() * 6 + Ang:Forward() * 17)
		self.Mdl:SetRenderAngles(Ang)
		self.Mdl:DrawModel()
	end

	function ENT:Think()
		if self.snd then
			self.snd:ChangePitch( 100 * self:CalcDoppler(), 1 )
			self.snd:ChangeVolume(math.Clamp((self:GetVelocity():LengthSqr() - 150000) / 5000,0,1), 2)
		end
	end

	function ENT:OnRemove()
		if self.snd then
			self.snd:Stop()
		end
	end

	language.Add("ent_jack_gmod_ezbigbomb", "EZ Big Bomb")
end
