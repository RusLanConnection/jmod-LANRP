-- this causes an object to rotate to point forward while moving, like a dart
function JMod.AeroDrag(ent, forward, mult, spdReq)
	if constraint.HasConstraints(ent) then return end
	if ent:IsPlayerHolding() then return end
	local Phys = ent:GetPhysicsObject()
	if not IsValid(Phys) then return end
	local Vel = Phys:GetVelocity()
	local Spd = Vel:Length()

	if not spdReq then
		spdReq = 300
	end

	if Spd < spdReq then return end
	mult = mult or 1
	local Pos, Mass = Phys:LocalToWorld(Phys:GetMassCenter()), Phys:GetMass()
	Phys:ApplyForceOffset(Vel * Mass / 6 * mult, Pos + forward)
	Phys:ApplyForceOffset(-Vel * Mass / 6 * mult, Pos - forward)
	Phys:AddAngleVelocity(-Phys:GetAngleVelocity() * Mass / 1000)
end

-- this causes an object to rotate to point and fly to a point you give it
function JMod.AeroGuide(ent, forward, targetPos, turnMult, thrustMult, angleDragMult, spdReq)
	--if(constraint.HasConstraints(ent))then return end
	--if(ent:IsPlayerHolding())then return end
	local Phys = ent:GetPhysicsObject()
	if not IsValid(Phys) then return end
	local Vel = Phys:GetVelocity()
	local Spd = Vel:Length()
	--if(Spd<spdReq)then return end
	local Pos, Mass = Phys:LocalToWorld(Phys:GetMassCenter()), Phys:GetMass()
	local TargetVec = targetPos - ent:GetPos()
	local TargetDir = TargetVec:GetNormalized()
	---
	Phys:ApplyForceOffset(TargetDir * Mass * turnMult * 5000, Pos + forward)
	Phys:ApplyForceOffset(-TargetDir * Mass * turnMult * 5000, Pos - forward)
	Phys:AddAngleVelocity(-Phys:GetAngleVelocity() * angleDragMult * 3)
	--- todo: fuck
	Phys:ApplyForceCenter(forward * 20000 * thrustMult) -- todo: make this function fucking work ARGH
end

function JMod.EZ_WeaponLaunch(ply)
	if not (IsValid(ply) and ply:Alive()) then return end
	local Weps = {}
	local Pods = {}

	for k, ent in ents.Iterator() do
		if ent.EZlaunchableWeaponLoadTime and JMod.GetEZowner(ent) == ply then
			table.insert(Pods, ent)
		elseif ent.EZlaunchableWeaponArmedTime and JMod.GetEZowner(ent) == ply and ent:GetState() == 1 then
			table.insert(Weps, ent)
		end
	end

	local FirstWep, Earliest = nil, 9e9

	for k, wep in pairs(Weps) do
		if wep.EZlaunchableWeaponArmedTime < Earliest then
			FirstWep = wep
			Earliest = wep.EZlaunchableWeaponArmedTime
		end
	end

	for k, pod in pairs(Pods) do
		if pod.EZlaunchableWeaponLoadTime < Earliest then
			FirstWep = pod
			Earliest = pod.EZlaunchableWeaponLoadTime
		end
	end

	if IsValid(FirstWep) then
		-- knock knock it's pizza time
		FirstWep:EmitSound("buttons/button6.wav", 75, 110)

		timer.Simple(.2, function()
			if IsValid(FirstWep) then
				if FirstWep.EZlaunchableWeaponLoadTime then
					FirstWep:LaunchRocket(#FirstWep.Rockets, true, ply)
				elseif FirstWep.EZlaunchableWeaponArmedTime then
					FirstWep.DropOwner = ply
					FirstWep:Launch()
				end
			end
		end)
	end
end

function JMod.EZ_BombDrop(ply)
	if not (IsValid(ply) and ply:Alive()) then return end
	local Boms = {}
	local Bays = {}

	for k, ent in ents.Iterator() do
		if ent.EZdroppableBombArmedTime and IsValid(ent.EZowner) and ent.EZowner == ply then
			table.insert(Boms, ent)
		elseif ent.EZdroppableBombLoadTime and IsValid(ent.EZowner) and ent.EZowner == ply then
			table.insert(Bays, ent)
		end
	end

	local FirstBom, Earliest = nil, 9e9

	for k, bay in pairs(Bays) do
		if (bay.EZdroppableBombLoadTime < Earliest) and (#bay.Bombs > 0) then
			FirstBom = bay
			Earliest = bay.EZdroppableBombLoadTime
		end
	end

	for k, bom in pairs(Boms) do
		if (bom.EZdroppableBombArmedTime < Earliest) and (constraint.HasConstraints(bom) or not bom:GetPhysicsObject():IsMotionEnabled()) then
			FirstBom = bom
			Earliest = bom.EZdroppableBombArmedTime
		end
	end

	if IsValid(FirstBom) then
		-- knock knock it's pizza time
		FirstBom:EmitSound("buttons/button6.wav", 75, 120)

		timer.Simple(.25, function()
			if IsValid(FirstBom) then
				if FirstBom.EZdroppableBombArmedTime then
					if FirstBom.Drop then
						FirstBom:Drop(ply)
					else
						constraint.RemoveAll(FirstBom)
						FirstBom:GetPhysicsObject():EnableMotion(true)
						FirstBom:GetPhysicsObject():Wake()
						FirstBom.DropOwner = ply
					end
				elseif FirstBom.EZdroppableBombLoadTime then
					FirstBom:BombRelease(#FirstBom.Bombs, true, ply)
				end
			end
		end)
	end
end

function JMod.DamageSpark(ent)
	local effectdata = EffectData()
	effectdata:SetOrigin(ent:GetPos() + ent:GetUp() * 10 + VectorRand() * math.random(0, 10))
	effectdata:SetNormal(VectorRand())
	effectdata:SetMagnitude(math.Rand(2, 4)) --amount and shoot hardness
	effectdata:SetScale(math.Rand(.5, 1.5)) --length of strands
	effectdata:SetRadius(math.Rand(2, 4)) --thickness of strands
	util.Effect("Sparks", effectdata, true, true)
	ent:EmitSound("snd_jack_turretfizzle.ogg", 70, 100)
end

-- copied from Homicide
function JMod.BlastThatDoor(ent, vel)
	ent.JModDoorBreachedness = nil
	local Moddel, Pozishun, Ayngul, Muteeriul, Skin = ent:GetModel(), ent:GetPos(), ent:GetAngles(), ent:GetMaterial(), ent:GetSkin()
	sound.Play("Wood_Crate.Break", Pozishun, 60, 100)
	sound.Play("Wood_Furniture.Break", Pozishun, 60, 100)
	ent:Fire("unlock", "", 0)
	ent:Fire("open", "", 0)
	ent:SetNoDraw(true)
	ent:SetNotSolid(true)

	if Moddel and Pozishun and Ayngul then
		local Replacement = ents.Create("prop_physics")
		Replacement:SetModel(Moddel)
		Replacement:SetPos(Pozishun + Vector(0, 0, 1))
		Replacement:SetAngles(Ayngul)

		if Muteeriul then
			Replacement:SetMaterial(Muteeriul)
		end

		if Skin then
			Replacement:SetSkin(Skin)
		end

		Replacement:SetModelScale(.9, 0)
		Replacement:Spawn()
		Replacement:Activate()

		if vel then
			Replacement:GetPhysicsObject():SetVelocity(vel)

			timer.Simple(0, function()
				if IsValid(Replacement) then
					Replacement:GetPhysicsObject():ApplyForceCenter(vel * 100)
				end
			end)
		end

		timer.Simple(3, function()
			if IsValid(Replacement) then
				Replacement:SetCollisionGroup(COLLISION_GROUP_WEAPON)
			end
		end)

		timer.Simple(30 * JMod.Config.Explosives.DoorBreachResetTimeMult, function()
			if IsValid(ent) then
				ent:SetNotSolid(false)
				ent:SetNoDraw(false)
			end

			if IsValid(Replacement) then
				Replacement:Remove()
			end
		end)
	end
end

-- https://developer.valvesoftware.com/wiki/Ai_sound
function JMod.EmitAIsound(pos, vol, dur, typ)
	local snd = ents.Create("ai_sound")
	snd:SetPos(pos)
	snd:SetKeyValue("volume", tostring(vol))
	snd:SetKeyValue("duration", tostring(dur))
	snd:SetKeyValue("soundtype", tostring(typ))
	snd:Spawn()
	snd:Activate()
	snd:Fire("EmitAISound")
	SafeRemoveEntityDelayed(snd, dur + .5)
end


function JMod.PackageObject(ent, pos, ang, ply)
	if pos then
		ent = ents.Create(ent)
		ent:SetPos(pos)
		ent:SetAngles(ang)

		if ply then
			JMod.SetEZowner(ent, ply)
		end

		ent:Spawn()
		ent:Activate()
	end

	local Bocks = ents.Create("ent_jack_gmod_ezcompactbox")
	Bocks:SetPos(ent:LocalToWorld(ent:OBBCenter()) + Vector(0, 0, 20))
	Bocks:SetAngles(ent:GetAngles())
	Bocks:SetContents(ent)

	if ply then
		JMod.SetEZowner(Bocks, ply)
	end

	Bocks:Spawn()
	Bocks:Activate()
	return Bocks
end

local SurfaceHardness = {
	[MAT_METAL] = .95,
	[MAT_COMPUTER] = .95,
	[MAT_VENT] = .95,
	[MAT_GRATE] = .95,
	[MAT_FLESH] = .5,
	[MAT_ALIENFLESH] = .3,
	[MAT_SAND] = .1,
	[MAT_DIRT] = .3,
	[MAT_GRASS] = .2,
	[74] = .1,
	[85] = .2,
	[MAT_WOOD] = .5,
	[MAT_FOLIAGE] = .5,
	[MAT_CONCRETE] = .9,
	[MAT_TILE] = .8,
	[MAT_SLOSH] = .05,
	[MAT_PLASTIC] = .3,
	[MAT_GLASS] = .6
}

-- Slayer Ricocheting/Penetrating Bullets FTW
function JMod.RicPenBullet(ent, pos, dir, dmg, doBlasts, wreckShit, num, penMul, tracerName, callback)
	if not IsValid(ent) then return end
	if num and num > 10 then return end
	local Attacker = ent.EZowner or ent or game.GetWorld()

	ent:FireBullets({
		Attacker = Attacker,
		Damage = dmg * 2,
		Force = dmg,
		Num = 1,
		Tracer = 1,
		TracerName = tracerName or "",
		Dir = dir,
		Spread = Vector(0, 0, 0),
		Src = pos,
		Callback = callback or nil
	})

	local initialTrace = util.TraceLine({
		start = pos,
		endpos = pos + dir * 50000,
		filter = {ent}
	})

	if not initialTrace.Hit then return end
	local AVec, IPos, TNorm, SMul = initialTrace.Normal, initialTrace.HitPos, initialTrace.HitNormal, SurfaceHardness[initialTrace.MatType]
	local Eff = EffectData()
	Eff:SetOrigin(IPos)
	Eff:SetScale(.5)
	Eff:SetNormal(TNorm)
	util.Effect("eff_jack_gmod_efpburst", Eff, true, true)

	if doBlasts then
		util.BlastDamage(ent, Attacker, IPos + TNorm * 2, dmg / 6, dmg / 4)

		timer.Simple(0, function()
			local Tr = util.QuickTrace(IPos + TNorm, -TNorm * 20)

			if Tr.Hit then
				util.Decal("FadingScorch", Tr.HitPos + Tr.HitNormal, Tr.HitPos - Tr.HitNormal)
			end
		end)
	end

	if wreckShit and not initialTrace.HitWorld then
		local Phys = initialTrace.Entity:GetPhysicsObject()

		if IsValid(Phys) then
			local Mass, Thresh = Phys:GetMass(), dmg / 2

			if Mass <= Thresh then
				constraint.RemoveAll(initialTrace.Entity)
				Phys:EnableMotion(true)
				Phys:Wake()
				Phys:ApplyForceOffset(-AVec * dmg * 2, IPos)
			end
		end
	end

	---
	if not SMul then
		SMul = .5
	end

	local ApproachAngle = -math.deg(math.asin(TNorm:Dot(AVec)))
	local MaxRicAngle = 60 * SMul

	-- all the way through (hot)
	if ApproachAngle > (MaxRicAngle * 1.05) then
		local MaxDist, SearchPos, SearchDist, Penetrated = (dmg / SMul) * .15 * (penMul or 1), IPos, 5, false

		while (not Penetrated) and (SearchDist < MaxDist) do
			SearchPos = IPos + AVec * SearchDist
			local PeneTrace = util.QuickTrace(SearchPos, -AVec * SearchDist)

			if (not PeneTrace.StartSolid) and PeneTrace.Hit then
				Penetrated = true
			else
				SearchDist = SearchDist + 5
			end
		end

		if Penetrated then
			ent:FireBullets({
				Attacker = Attacker,
				Damage = 1,
				Force = 1,
				Num = 1,
				Tracer = 0,
				TracerName = "",
				Dir = -AVec,
				Spread = Vector(0, 0, 0),
				Src = SearchPos + AVec
			})

			if doBlasts then
				util.BlastDamage(ent, Attacker, SearchPos + AVec * 2, dmg / 4, dmg / 4)

				timer.Simple(0, function()
					local Tr = util.QuickTrace(SearchPos + AVec, -AVec * 20)

					if Tr.Hit then
						util.Decal("FadingScorch", Tr.HitPos + Tr.HitNormal, Tr.HitPos - Tr.HitNormal)
					end
				end)
			end

			local ThroughFrac = 1 - SearchDist / MaxDist
			JMod.RicPenBullet(ent, SearchPos + AVec, AVec, dmg * ThroughFrac * .7, doBlasts, wreckShit, (num or 0) + 1, penMul, tracerName, callback)
		end
	elseif ApproachAngle < (MaxRicAngle * .95) then
		-- ping whiiiizzzz
		if SERVER then
			sound.Play("snds_jack_gmod/ricochet_" .. math.random(1, 2) .. ".ogg", IPos, 60, math.random(90, 100))
		end

		local NewVec = AVec:Angle()
		NewVec:RotateAroundAxis(TNorm, 180)
		NewVec = NewVec:Forward()
		JMod.RicPenBullet(ent, IPos + TNorm, -NewVec, dmg * .7, doBlasts, wreckShit, (num or 0) + 1, penMul, tracerName, callback)
	end
end

function JMod.GetEZowner(ent)
	if not IsValid(ent) then return game.GetWorld() end

	if ent.EZowner and IsValid(ent.EZowner) then

		return ent.EZowner
	elseif ent:IsPlayer() then
			
		return ent	
	else
		
		return game.GetWorld()
	end
end

function JMod.SetEZowner(ent, newOwner, setColor)
	if not IsValid(ent) then return end
	if not (newOwner and IsValid(newOwner)) then newOwner = game.GetWorld() end

	if JMod.GetEZowner(ent) == newOwner then
		if setColor == true then
			JMod.Colorify(ent)
		end

		return 
	end

	ent.EZowner = newOwner
	if newOwner:IsPlayer() then
		ent.EZownerID = newOwner:SteamID64()
		ent.EZownerTeam = newOwner:GetSquadID()
	else
		ent.EZownerID = nil
		ent.EZownerTeam = nil
	end

	if setColor == true then
		JMod.Colorify(ent)
	end

	if CPPI and isfunction(ent.CPPISetOwner) then
		ent:CPPISetOwner(newOwner)
	end
end

function JMod.AddFriend(ply, friend)
	if not (IsValid(ply) and ply:IsPlayer() and IsValid(friend) and friend:IsPlayer()) then return end
	ply.JModFriends = ply.JModFriends or {}

	table.insert(ply.JModFriends, friend)

	net.Start("JMod_Friends")
		net.WriteBit(true)
		net.WriteEntity(ply)
		net.WriteTable(ply.JModFriends)
	net.Broadcast()
end

function JMod.RemoveFriend(ply, friend)
	if not (IsValid(ply) and ply:IsPlayer() and IsValid(friend) and friend:IsPlayer()) then return end
	ply.JModFriends = ply.JModFriends or {}
	
	table.RemoveByValue(ply.JModFriends, friend)

	net.Start("JMod_Friends")
		net.WriteBit(true)
		net.WriteEntity(ply)
		net.WriteTable(ply.JModFriends)
	net.Broadcast()
end

function JMod.ShouldAllowControl(self, ply, neutral)
	neutral = neutral or false
	if not IsValid(ply) then return false end
	if (ply.EZkillme) then return false end
	local EZowner = JMod.GetEZowner(self)
	if not IsValid(EZowner) then return neutral end
	if ply == EZowner then return true end
	local Allies = EZowner.JModFriends or {}
	if table.HasValue(Allies, ply) then return true end

	return ply:GetSquadID() != -1 and ply:GetSquadID() == EZowner:GetSquadID()
end

function JMod.ShouldAttack(self, ent, vehiclesOnly, peaceWasNeverAnOption)
	if not IsValid(ent) then return false end
	if ent:IsWorld() then return false end
	local SelfOwner = JMod.GetEZowner(self)

	local Override = hook.Run("JMod_ShouldAttack", self, ent, vehiclesOnly, peaceWasNeverAnOption)
	if (Override ~= nil) then return Override end

	local Gaymode, PlayerToCheck, InVehicle = engine.ActiveGamemode(), nil, false

	if ent:IsPlayer() then
		PlayerToCheck = ent
	elseif ent:IsNextBot() then
		-- our hands are really tied with nextbots, they lack all the NPC methods
		-- so just attack all of them
		if ent.Health and (type(ent.Health) == "function") then
			local Helf = ent:Health()
			if (type(Helf) == "number") and (Helf > 0) then return true end
		elseif ent.Health and (type(ent.Health) == "number") then
			if ent.Health > 0 then return true end
		end
	elseif ent:IsNPC() then
		local Class = ent:GetClass()
		if self.WhitelistedNPCs and table.HasValue(self.WhitelistedNPCs, Class) then return true end
		if self.BlacklistedNPCs and table.HasValue(self.BlacklistedNPCs, Class) then return false end
		if not IsValid(self.EZowner) then return ent:Health() > 0 end

		if ent.Disposition and (ent:Disposition(self.EZowner) == D_HT) and ent.GetMaxHealth and ent.Health then
			if vehiclesOnly then
				return ent:GetMaxHealth() > 100 and ent:Health() > 0
			else
				return ent:GetMaxHealth() > 0 and ent:Health() > 0
			end
		else
			return peaceWasNeverAnOption or false
		end
	elseif ent:IsVehicle() then
		PlayerToCheck = ent:GetDriver()
		InVehicle = true
	elseif (ent.LVS and not(ent.ExplodedAlready)) then
		if ent.GetDriver and IsValid(ent:GetDriver()) then
			PlayerToCheck = ent:GetDriver()
			InVehicle = true
		elseif SelfOwner.lvsGetAITeam then --and ((ent.GetEngineActive and ent:GetEngineActive()))
			local OurTeam = SelfOwner:lvsGetAITeam()
			if ent.GetAITEAM and ent.GetAI and ent:GetAI() then
				local TheirTeam = ent:GetAITEAM()
				if ((OurTeam ~= 0) and (TheirTeam ~= 0) and TheirTeam ~= OurTeam) or (TheirTeam == 3) then
					return true
				end
			end
		else
			return peaceWasNeverAnOption or false
		end
	elseif ent.IS_DRONE and IsValid(JMod.GetEZowner(ent)) then
		-- Drones Rewrite compatibility
		if ent.GetHealth and ent:GetHealth() > 0 then
			PlayerToCheck = ent.EZowner
		end
	end

	if IsValid(PlayerToCheck) and PlayerToCheck.Alive then
		if vehiclesOnly and not InVehicle then return false end
		if PlayerToCheck.EZkillme then return true end -- for testing
		if PlayerToCheck:GetObserverMode() ~= 0 then return false end
		--if (SelfOwner) and (PlayerToCheck == SelfOwner) then return false end
		local Allies = (SelfOwner and SelfOwner.JModFriends) or {}
		if table.HasValue(Allies, PlayerToCheck) then return false end
		local OurTeam = nil

		if IsValid(SelfOwner) then
			OurTeam = SelfOwner:GetSquadID()
			--if Gaymode == "basewars" and SelfOwner.IsAlly then return not SelfOwner:IsAlly(PlayerToCheck) end
		end

		if not IsValid(SelfOwner) then return false end

		local squad = SquadMenu:GetSquad(SelfOwner:GetSquadID())

		if OurTeam == -1 then return PlayerToCheck:Alive() end
		if OurTeam then return PlayerToCheck:Alive() and ((PlayerToCheck:GetSquadID() ~= OurTeam) and not squad.Alliance[PlayerToCheck:GetSquadID()]) end 

		return PlayerToCheck:Alive()
	end
end

function JMod.EnemiesNearPoint(ent, pos, range, vehiclesOnly)
	for k, v in pairs(ents.FindInSphere(pos, range)) do
		if JMod.ShouldAttack(ent, v, vehiclesOnly) then return true end
	end

	return false
end

function JMod.EMP(pos, range)
	--debugoverlay.Sphere(pos, range, 5, Color(0, 0, 255), true)
	for k, ent in pairs(ents.FindInSphere(pos, range)) do
		if ent.IsJackyEZmachine and ent.SetState and ent.GetState and (ent:GetState() > 0) then
			if ent.TurnOff then 
				ent:TurnOff() 
			else
				ent:SetState(JMod.EZ_STATE_OFF)
			end
			ent.EZstayOn = nil
		end
		if ent.LVS and ent.StopEngine then
			ent:StopEngine()
			ent.EZengineNextStartTime = CurTime() + 30
		end
	end
end

hook.Add( "LVS.IsEngineStartAllowed", "JMod_DisableEMPedEngines", function(veh)
	if veh.EZengineNextStartTime and (veh.EZengineNextStartTime > CurTime()) then
		return false
	else
		veh.EZengineNextStartTime = nil 
	end
end)

function JMod.Colorify(ent)
	if (ent.EZcolorable ~= nil) and (ent.EZcolorable == false) then return end
	if IsValid(JMod.GetEZowner(ent)) then
		local Tem = ent.EZowner:GetSquadID()
		local squad = SquadMenu.squads[Tem]
		if Tem != -1 then
			local Col = Color(squad.r or 255, squad.g or 255, squad.b or 255)

			if Col then
				ent:SetColor(Col)
			end
		else
			ent:SetColor(Color(255, 255, 255))
		end
	else
		ent:SetColor(Color(255, 255, 255))
	end
end

local TriggerKeys = {IN_ATTACK, IN_USE, IN_ATTACK2}

function JMod.ThrowablePickup(playa, item, hardstr, softstr)
	playa:DropObject()
	playa:PickupObject(item)
	local HookName = "EZthrowable_" .. item:EntIndex()

	hook.Add("KeyPress", HookName, function(ply, key)
		if not IsValid(playa) then
			hook.Remove("KeyPress", HookName)

			return
		end

		if ply ~= playa then return end

		if IsValid(item) and ply:Alive() then
			local Phys = item:GetPhysicsObject()

			if key == IN_ATTACK then
				timer.Simple(0, function()
					if IsValid(Phys) then
						Phys:ApplyForceCenter(ply:GetAimVector() * (hardstr or 600) * Phys:GetMass() * JMod.GetPlayerStrength(playa))

						if item.EZspinThrow then
							Phys:ApplyForceOffset(ply:GetAimVector() * Phys:GetMass() * 50, Phys:GetMassCenter() + Vector(0, 0, 10))
							Phys:ApplyForceOffset(-ply:GetAimVector() * Phys:GetMass() * 50, Phys:GetMassCenter() - Vector(0, 0, 10))
						end
					end
				end)
			elseif key == IN_ATTACK2 then
				local vec = ply:GetAimVector()
				vec.z = vec.z + 0.3

				timer.Simple(0, function()
					if IsValid(Phys) then
						Phys:ApplyForceCenter(vec * (softstr or 400) * Phys:GetMass() * JMod.GetPlayerStrength(playa))
					end
				end)
			elseif key == IN_USE then
				if item.GetState and item:GetState() == JMod.EZ_STATE_PRIMED then
					JMod.Hint(playa, "grenade drop", item)
				end
			end
		end

		if table.HasValue(TriggerKeys, key) then
			hook.Remove("KeyPress", HookName)
		end
	end)
end

function JMod.BlockPhysgunPickup(ent, isblock)
	if isblock == false then
		isblock = nil
	end

	ent.block_pickup = isblock
end

local LiquidResourceTypes = {JMod.EZ_RESOURCE_TYPES.WATER, JMod.EZ_RESOURCE_TYPES.COOLANT, JMod.EZ_RESOURCE_TYPES.OIL, JMod.EZ_RESOURCE_TYPES.CHEMICALS, JMod.EZ_RESOURCE_TYPES.FUEL}

local SpriteResourceTypes = {JMod.EZ_RESOURCE_TYPES.GAS, JMod.EZ_RESOURCE_TYPES.SAND, JMod.EZ_RESOURCE_TYPES.PAPER, JMod.EZ_RESOURCE_TYPES.ANTIMATTER, JMod.EZ_RESOURCE_TYPES.PROPELLANT, JMod.EZ_RESOURCE_TYPES.CLOTH, JMod.EZ_RESOURCE_TYPES.POWER}

function JMod.ResourceEffect(typ, fromPoint, toPoint, amt, spread, scale, upSpeed)
	--print("Type: " .. tostring(typ) .. " From point: " .. tostring(fromPoint) .. " Amount: " .. amt)
	amt = (amt and math.Clamp(amt, 0, 1)) or 1
	spread = spread or 1
	scale = scale or 1
	upSpeed = upSpeed or 0

	amt = math.Clamp(amt, 0.5, 5)

	local UseSprites = table.HasValue(SpriteResourceTypes, typ)

	if (UseSprites) then amt = amt * 2 end

	for j = 0, 2 * amt do
		timer.Simple(j / 20, function()
			for i = 1, math.ceil(amt * JMod.Config.Machines.SupplyEffectMult) do
				local whee = EffectData()
				whee:SetOrigin(fromPoint)
				if toPoint then
					whee:SetStart(toPoint)
				end
				whee:SetFlags(JMod.ResourceToIndex[typ])
				whee:SetMagnitude(spread)
				whee:SetRadius(upSpeed)
				whee:SetScale(scale)

				if toPoint then
					whee:SetSurfaceProp(1) -- we have somewhere to go
				else
					whee:SetSurfaceProp(0) -- just do a directionless explosion of particles
				end

				if table.HasValue(LiquidResourceTypes, typ) then
					util.Effect("eff_jack_gmod_resource_liquid", whee, true, true)
				elseif UseSprites then
					util.Effect("eff_jack_gmod_resource_sprites", whee, true, true)
				else
					util.Effect("eff_jack_gmod_resource_props", whee, true, true)
				end
			end
		end)
	end
end

function JMod.FindBoltPos(ply, origin, dir)
	local Pos, Vec = origin or ply:GetShootPos(), dir or ply:GetAimVector()

	local HitTest = util.QuickTrace(Pos, Vec * 80, {ply})

	if HitTest.Hit then
		local Ent1 = HitTest.Entity
		if HitTest.HitSky or Ent1:IsPlayer() or Ent1:IsNPC() then return nil end
		if not IsValid(Ent1:GetPhysicsObject()) then return nil end
		local HitPos1 = HitTest.HitPos

		local HitTest2 = util.QuickTrace(HitPos1, HitTest.HitNormal * -30, {ply, Ent1})
		if not(HitTest2.Hit) then 
			HitTest2 = util.QuickTrace(HitPos1, HitTest.HitNormal * 30, {ply, Ent1})
		end

		if HitTest2.Hit then
			local Ent2 = HitTest2.Entity
			if (Ent1 == Ent2) or HitTest2.HitSky or Ent2:IsPlayer() or Ent2:IsNPC() then return nil end
			if not Ent2:IsWorld() and not IsValid(Ent2:GetPhysicsObject()) then return nil end
			local Dist = HitPos1:Distance(HitTest.HitPos)
			if Dist > 30 then return nil end

			return true, HitPos1, HitTest2.HitPos, Ent1, Ent2
		end
	end
end

function JMod.Bolt(ply)
	local Success, Pos, Vec, Ent1, Ent2 = JMod.FindBoltPos(ply)
	if not Success then return end
	
	local Axis = constraint.Axis(Ent1, Ent2, 0, 0, Ent1:WorldToLocal(Pos), Ent2:WorldToLocal(Vec), 50000, 0, 1, false)
	
	local Dir = (Pos - Vec):GetNormalized()
	local Bolt = ents.Create("prop_dynamic")
	Bolt:SetModel("models/crossbow_bolt.mdl")
	Bolt:SetMaterial("models/shiny")
	Bolt:SetColor(Color(50, 50, 50))
	Bolt:SetPos(Pos - Dir * 20)
	Bolt:SetAngles(Dir:Angle())
	Bolt:Spawn()
	Bolt:Activate()
	Bolt:SetParent(Ent1)
	Ent1.EZnails = Ent1.EZnails or {}
	table.insert(Ent1.EZnails, Bolt)
	sound.Play("snds_jack_gmod/ez_tools/" .. math.random(1, 27) .. ".ogg", Pos, 60, math.random(80, 120))
end

function JMod.FindNailPos(ply, origin, dir)
	local Pos, Vec = origin or ply:GetShootPos(), dir or ply:GetAimVector()

	local Tr1 = util.QuickTrace(Pos, Vec * 80, {ply})

	if Tr1.Hit then
		local Ent1 = Tr1.Entity
		if Tr1.HitSky or Ent1:IsWorld() or Ent1:IsPlayer() or Ent1:IsNPC() then return nil end
		if not IsValid(Ent1:GetPhysicsObject()) then return nil end

		local Tr2 = util.QuickTrace(Pos, Vec * 120, {ply, Ent1})

		if Tr2.Hit then
			local Ent2 = Tr2.Entity
			if (Ent1 == Ent2) or Tr2.HitSky or Ent2:IsPlayer() or Ent2:IsNPC() then return nil end
			if not Ent2:IsWorld() and not IsValid(Ent2:GetPhysicsObject()) then return nil end
			local Dist = Tr1.HitPos:Distance(Tr2.HitPos)
			if Dist > 30 then return nil end

			return true, Tr1.HitPos, Vec, Ent1, Ent2
		end
	end
end

function JMod.Nail(ply)
	local Success, Pos, Vec, Ent1, Ent2 = JMod.FindNailPos(ply)
	if not Success then return end
	local Weld = constraint.Find(Ent1, Ent2, "Weld", 0, 0)

	if Weld then
		local Strength = Weld:GetTable().forcelimit + 5000
		Weld:Remove()

		timer.Simple(.01, function()
			Weld = constraint.Weld(Ent1, Ent2, 0, 0, Strength, false, false)
		end)
	else
		Weld = constraint.Weld(Ent1, Ent2, 0, 0, 5000, false, false)
	end

	local Nail = ents.Create("prop_dynamic")
	Nail:SetModel("models/crossbow_bolt.mdl")
	Nail:SetMaterial("models/shiny")
	Nail:SetColor(Color(50, 50, 50))
	Nail:SetPos(Pos - Vec * 2)
	Nail:SetAngles(Vec:Angle())
	Nail:Spawn()
	Nail:Activate()
	Nail:SetParent(Ent1)
	Ent1.EZnails = Ent1.EZnails or {}
	table.insert(Ent1.EZnails, Nail)
	sound.Play("snds_jack_gmod/ez_tools/" .. math.random(1, 27) .. ".ogg", Pos, 60, math.random(80, 120))
end

function JMod.GetPackagableObject(packager, origin, dir)
	local PackageBlacklist = {
		"func_",

		"ent_jack_gmod_ezcrate",

		"ent_jack_gmod_ezcrate_uni",

		"ent_aboot_jsmod_ezcrate_fulton",

		"ent_jack_gmod_ezbombbay",

		"ent_rus_spawnbase",

		"build_prop"

	}

	local Tr = util.QuickTrace(origin or packager:GetShootPos(), (dir or packager:GetAimVector()) * 80, {packager})

	local Ent = Tr.Entity

	if IsValid(Ent) and not Ent:IsWorld() then
		if Ent.EZunpackagable then

			return nil, "No."
		end

		if Ent:IsPlayer() or Ent:IsNPC() then return nil end
		if Ent:IsRagdoll() then return nil end
		local Constraints, Constrained = constraint.GetTable(Ent), false

		for k, v in pairs(Constraints) do
			if v.Type ~= "NoCollide" then
				Constrained = true
				break
			end
		end

		if Constrained then

			return nil, "object is constrained"
		end

		for k, v in pairs(PackageBlacklist) do
			if string.find(Ent:GetClass(), v) then

				return nil, "can't package this"
			end
		end

		if Ent.IsJackyEZmachine and Ent.GetState and Ent:GetState() ~= 0 then
			return nil, "device must be turned off to package"
		end

		return Ent
	end

	return nil
end

function JMod.Package(packager)
	local Ent, Message = JMod.GetPackagableObject(packager)

	if Ent then
		JMod.PackageObject(Ent)
		sound.Play("snds_jack_gmod/packagify.ogg", packager:GetPos(), 60, math.random(90, 110))

		for i = 1, 3 do
			timer.Simple(i / 3, function()
				if IsValid(packager) then
					sound.Play("snds_jack_gmod/ez_tools/" .. math.random(1, 27) .. ".ogg", packager:GetPos(), 60, math.random(80, 120))
				end
			end)
		end
	elseif isstring(Message) then
		packager:PrintMessage(HUD_PRINTCENTER, Message)
	end
end

function JMod.Rope(ply, origin, dir, width, strength, mat)
	local RopeStartData = ply and ply.EZropeData
	if not(RopeStartData) or not IsValid(RopeStartData.Ent) then
		if origin and dir then
			local RopeStartTr = util.QuickTrace(origin, dir * 80)
			if not(RopeStartTr.Hit) then return end
			RopeStartData = {Pos = RopeStartTr.Entity:WorldToLocal(RopeStartTr.HitPos), Ent = RopeStartTr.Entity}
		else

			return
		end
	end

	local RopeTr = util.QuickTrace(origin or ply:GetShootPos(), (dir or ply:GetAimVector()) * 80, {ply})
	local LropePos1, LropePos2 = ply.EZropeData.Pos, RopeTr.Entity:WorldToLocal(RopeTr.HitPos)
	local Dist = ply.EZropeData.Ent:LocalToWorld(RopeStartData.Pos):Distance(RopeTr.HitPos)

	local Rope, Vrope = constraint.Rope(ply.EZropeData.Ent, RopeTr.Entity, 0, 0, LropePos1, LropePos2, Dist, 0, strength or 5000, width or 2, mat or "cable/cable2", false)
	return Rope, RopeTr.Entity
end

local ConstrBLackList = {
    ["ent_rus_gmod_ezpowerline"] = true,
    ["ent_rus_jsmod_pipe"] = true,
    ["build_prop"] = true,
}

function JMod.EZprogressTask(ent, pos, deconstructor, task, mult)
	mult = mult or 1
	local Time = CurTime()

	if not IsValid(ent) then return "Invalid Ent" end

	if task == "mining" then
		local DepositKey = JMod.GetDepositAtPos(ent, pos)
		local DepositInfo = JMod.NaturalResourceTable[DepositKey]
		if DepositInfo and ent.SetResourceType then
			local NewType = JMod.NaturalResourceTable[DepositKey].typ
			if ent.GetResourceType and (ent:GetResourceType() ~= NewType) then
				ent:SetNW2Float("EZminingProgress", 0) -- No you don't
			end 
			ent:SetResourceType(NewType)
		end
		
		if ent.EZpreviousMiningPos and ent.EZpreviousMiningPos:Distance(pos) > 200 then
			ent:SetNW2Float("EZminingProgress", 0)
			ent.EZpreviousMiningPos = nil
		end
		if ent:GetNW2Float("EZcancelminingTime", 0) <= Time then
			ent:SetNW2Float("EZminingProgress", 0)
			ent.EZpreviousMiningPos = nil
		end
		ent:SetNW2Float("EZcancelminingTime", Time + 5)
		ent.EZpreviousMiningPos = pos

		local Prog = ent:GetNW2Float("EZminingProgress", 0)
		local AddAmt = math.random(15, 25) * mult * JMod.Config.ResourceEconomy.ExtractionSpeed

		ent:SetNW2Float("EZminingProgress", math.Clamp(Prog + AddAmt, 0, 100))

		if (Prog >= 10) and not(JMod.NaturalResourceTable[DepositKey]) then
			ent:SetNW2Float("EZminingProgress", 0)
			ent.EZpreviousMiningPos = nil
			local NearestGoodDeposit = JMod.GetDepositAtPos(ent, pos, 3)
			if JMod.NaturalResourceTable[NearestGoodDeposit] then
				net.Start("JMod_ResourceScanner")
					net.WriteEntity(ent)
					net.WriteTable({JMod.NaturalResourceTable[NearestGoodDeposit]})
				net.Broadcast()
				return JMod.NaturalResourceTable[NearestGoodDeposit].typ .. " nearby"
			else
				return "nothing of value nearby"
			end
		elseif Prog >= 100 then
			local AmtToProduce

			if JMod.NaturalResourceTable[DepositKey].rate then
				local Rate = JMod.NaturalResourceTable[DepositKey].rate
				AmtToProduce = Rate * Prog
			else
				local AmtLeft = JMod.NaturalResourceTable[DepositKey].amt
				AmtToProduce = math.min(AmtLeft, math.random(5, 20))
				if (JMod.NaturalResourceTable[DepositKey].typ == JMod.EZ_RESOURCE_TYPES.DIAMOND) then
					AmtToProduce = math.min(AmtLeft, math.random(1, 2))
				end
				JMod.DepleteNaturalResource(DepositKey, AmtToProduce)
			end

			local SpawnPos = ent:WorldToLocal(pos + Vector(0, 0, 8))
			JMod.MachineSpawnResource(ent, DepositInfo.typ, AmtToProduce, SpawnPos, Angle(0, 0, 0), SpawnPos, 100)
			ent:SetNW2Float("EZminingProgress", 0)
			ent.EZpreviousMiningPos = nil
			JMod.ResourceEffect(JMod.NaturalResourceTable[DepositKey].typ, pos, nil, 1, 1, 1, 5)
			util.Decal("EZgroundHole", pos + Vector(0, 0, 10), pos + Vector(0, 0, -10))
			--
			net.Start("JMod_ResourceScanner")
				net.WriteEntity(ent)
				net.WriteTable({JMod.NaturalResourceTable[DepositKey]})
			net.Broadcast()

			ent:SetResourceType("")
			
			return nil
		end

		return nil
	end

	if ent:GetNW2Float("EZcancel"..task.."Time", 0) <= Time then
		ent:SetNW2Float("EZ"..task.."Progress", 0)
	end
	ent:SetNW2Float("EZcancel"..task.."Time", Time + 3)
	
	local Prog = ent:GetNW2Float("EZ"..task.."Progress", 0)
	local Phys = ent:GetPhysicsObject()
	
	if IsValid(Phys) then
		local WorkSpreadMult = JMod.CalcWorkSpreadMult(ent, pos)

		if task == "loosen" then
			if constraint.HasConstraints(ent) or not Phys:IsMotionEnabled() then
				local Mass = Phys:GetMass() ^ .8
				local AddAmt = 300 / Mass * WorkSpreadMult * JMod.Config.Tools.Toolbox.DeconstructSpeedMult
				ent:SetNW2Float("EZ"..task.."Progress", math.Clamp(Prog + AddAmt, 0, 100))

				if Prog >= 100 then
					sound.Play("snds_jack_gmod/ez_tools/hit.ogg", pos + VectorRand(), 70, math.random(50, 60))
					constraint.RemoveAll(ent)
					Phys:EnableMotion(true)
					Phys:Wake()
					ent:SetNW2Float("EZ"..task.."Progress", 0)
					if ent.EZnails then
						for _, v in ipairs(ent.EZnails) do
							if IsValid(v) then
								v:Remove()
							end
						end
						ent.EZnails = {}
					end
				end
			else
				return "object is already unconstrained"
			end
		elseif task == "salvage" then
			if ((ent:GetClass() == "build_prop") and (ent.Owner:GetSquadID() ~= deconstructor:GetSquadID())) or ent:IsWeapon() or ent:GetClass() == "ent_weapondrop" or ent:GetClass() == "ent_weapondrop" or scripted_ents.IsBasedOn(ent:GetClass(), "ent_jack_gmod_ezweapon") then 
				return "you cannot salvage this "
			elseif (constraint.HasConstraints(ent) or not Phys:IsMotionEnabled() and not FrozenProps[ent]) and not ConstrBLackList[ent:GetClass()] then
				return "object is constrained"
			if constraint.HasConstraints(ent) or not Phys:IsMotionEnabled() then
				return "object must be loosened first"
			else
				local Mass = (Phys:GetMass() * ent:GetPhysicsObjectCount()) ^ .8
				ent:ForcePlayerDrop()
				local Yield, Message = JMod.GetSalvageYield(ent)

				if #table.GetKeys(Yield) <= 0 then
					return Message
				else
					local AddAmt = 250 / Mass * WorkSpreadMult * JMod.Config.Tools.Toolbox.DeconstructSpeedMult

					if ent:GetClass() == "build_prop" then
						AddAmt = 250 / 50 * WorkSpreadMult * JMod.Config.Tools.Toolbox.DeconstructSpeedMult
					end

					ent:SetNW2Float("EZ"..task.."Progress", math.Clamp(Prog + AddAmt, 0, 100))
					
					if Prog >= 100 then
						sound.Play("snds_jack_gmod/ez_tools/hit.ogg", pos + VectorRand(), 70, math.random(50, 60))

						for k, v in pairs(Yield) do
							local AmtLeft = v

							while AmtLeft > 0 do
								local Remove = math.min(AmtLeft, 100 * JMod.Config.ResourceEconomy.MaxResourceMult)
								local Ent = ents.Create(JMod.EZ_RESOURCE_ENTITIES[k])
								Ent:SetPos(pos + VectorRand() * 40 + Vector(0, 0, 30))
								Ent:SetAngles(AngleRand())
								Ent:Spawn()
								Ent:Activate()
								Ent:SetEZsupplies(k, Remove)
								JMod.SetEZowner(Ent, deconstructor)
								timer.Simple(.1, function()
									if (IsValid(Ent) and IsValid(Ent:GetPhysicsObject())) then 
										Ent:GetPhysicsObject():SetVelocity(Vector(0, 0, 0)) --- This is so jank
									end
								end)
								AmtLeft = AmtLeft - Remove
							end
						end
						if ent.JModInv then
							for _, v in ipairs(ent.JModInv.items) do
								JMod.RemoveFromInventory(ent, v.ent, pos + VectorRand() * 50)
							end
						end
						SafeRemoveEntity(ent)
					end
				end
			end
		end
	end
end

function JMod.ConsumeNutrients(ply, amt)
	if not IsValid(ply) or not ply:Alive() then return false end
	local Time = CurTime()
	amt = math.Round(amt)
	--
	ply.EZnutrition = ply.EZnutrition or {
		NextEat = 0,
		Nutrients = 0
	}
	if (ply.EZnutrition.NextEat or 0) > Time then JMod.Hint(activator, "can not eat") return false end
	if (ply.EZnutrition.Nutrients or 0) >= 100 then JMod.Hint(ply, "nutrition filled") return false end
	--
	ply.EZnutrition.NextEat = Time + amt / JMod.Config.FoodSpecs.EatSpeed
	ply.EZnutrition.Nutrients = math.Round(ply.EZnutrition.Nutrients + amt * JMod.Config.FoodSpecs.ConversionEfficiency)

	local result = hook.Run("JMod_ConsumeNutrients", ply, amt)

	ply:PrintMessage(HUD_PRINTCENTER, "nutrition: " .. ply.EZnutrition.Nutrients .. "/100")
	return true
end

hook.Add("JMod_ConsumeNutrients", "DarkRP_EnergyCompat", function(ply, amt)
	if ply.getDarkRPVar and ply.setDarkRPVar and ply:getDarkRPVar("energy") then
		local Old = ply:getDarkRPVar("energy")
		ply:setDarkRPVar("energy", math.Clamp(Old + amt * JMod.Config.FoodSpecs.ConversionEfficiency, 0, 100))
	end
end)

function JMod.GetPlayerStrength(ply)
	if not(IsValid(ply) and ply:IsPlayer() and ply:Alive()) then return 1 end
	local PlyHealth = ply:Health()
	local PlyMaxHealth = ply:GetMaxHealth()

	--jprint(1 + (math.max(PlyHealth - PlyMaxHealth, 0) ^ 1.2 / (PlyMaxHealth)) * JMod.Config.General.HandGrabStrength)
	return 1 + (math.max(PlyHealth - PlyMaxHealth, 0) ^ 1.2 / (PlyMaxHealth)) * JMod.Config.General.HandGrabStrength
end

function JMod.DebugArrangeEveryone(ply, mult)
	local Origin, Dist, Ang = ply:GetPos(), 50, Angle(0, 0, 0)
	local Beings = player.GetAll()
	table.Add(Beings, ents.FindByClass("npc_*"))
	for k, playa in pairs(Beings) do
		if (playa ~= ply) then
			local Target = Origin + Ang:Forward() * Dist
			local Tr = util.QuickTrace(Target + Vector(0, 0, 300), Vector(0, 0, -600), playa)
			playa:SetPos(Tr.HitPos)
			playa:SetHealth(playa:GetMaxHealth())
			Ang:RotateAroundAxis(vector_up, 25)
			Dist = Dist + 120 * mult
		end
	end
	ply:SetPos(Origin + Vector(0, 0, 200))
	ply:SetMoveType(MOVETYPE_NOCLIP)
	ply:SetHealth(999)
	RunConsoleCommand("r_cleardecals")
end

function JMod.EZimmobilize(victim, timeToImmobilize, immobilizer)
	if not IsValid(victim) then return end
	victim.EZimmobilizers = victim.EZimmobilizers or {}
	if not(IsValid(immobilizer)) then immobilizer = victim end
	victim.EZimmobilizers[immobilizer] = (victim.EZimmobilizers[immobilizer] or CurTime()) + timeToImmobilize
	victim.EZImmobilizationTime = timeToImmobilize
end

function JMod.EZinstallMachine(machine, install)
	install = install or true
	if not(IsValid(machine)) then return end
	local Phys = machine:GetPhysicsObject()
	if not(IsValid(Phys)) then return end

	machine.EZinstalled = install
	Phys:EnableMotion(not install)
end

function JMod.StartConnection(machine, ply)
	if not(IsValid(machine)) then return end
	if IsValid(machine.EZconnectorPlug) then 
		if machine.EZconnectorPlug:IsPlayerHolding() then return end
		SafeRemoveEntity(machine.EZconnectorPlug)
	end
	if not(JMod.ShouldAllowControl(machine, ply, true)) then return end
	if not IsValid(ply) then return end

	local Plugy = ents.Create("ent_jack_gmod_ezhook")
	if not IsValid(Plugy) then return end
	Plugy:SetPos(machine:GetPos() + Vector(0, 0, 50)) -- Adjust the position as needed
	Plugy:SetAngles(machine:GetAngles())
	Plugy.Model = "models/props_lab/tpplug.mdl"
	Plugy.EZhookType = "Plugin"
	Plugy.EZconnector = machine
	Plugy:Spawn()
	Plugy:Activate()
	machine.EZconnectorPlug = Plugy

	local ropeLength = machine.MaxConnectionRange or 1000
	local Rope = constraint.Rope(machine, Plugy, 0, 0, machine.EZpowerSocket or Vector(0,0,0), Vector(10,0,0), ropeLength, 0, 1000, 2, "cable/cable2", false)
	Plugy.Chain = Rope

	ply:DropObject()
	ply:PickupObject(Plugy)
end

function JMod.CreateConnection(machine, ent, resType, plugPos, dist, cable)
	dist = dist or 1000
	if not (IsValid(machine) and IsValid(ent) and resType) then return false end
	if not IsValid(ent) or (ent == machine) then return false end
	if not (ent.EZconsumes and table.HasValue(ent.EZconsumes, resType)) and not (resType == JMod.EZ_RESOURCE_TYPES.POWER and (ent.EZpowerProducer and not machine.EZpowerProducer)) then return false end
	if ent.IsJackyEZcrate and ent.GetResourceType and not(ent:GetResourceType() == resType or ent:GetResourceType() == "generic") then return false end
	if not JMod.ShouldAllowControl(ent, JMod.GetEZowner(machine), true) then return false end
	local PluginPos = ent.EZpowerSocket or plugPos or ent:OBBCenter()
	if not IsValid(cable) then
		local DistanceBetween = (machine:GetPos() - ent:LocalToWorld(PluginPos)):Length()
		if (DistanceBetween > dist) then return false end
	end
	--
	machine.EZconnections = machine.EZconnections or {}
	local AlreadyConnected = false
	local EntID = ent:EntIndex()
	for entID, cable in pairs(machine.EZconnections) do
		if entID == EntID then
			AlreadyConnected = true

			break
		end
	end
	if AlreadyConnected then return false end
	
	ent.EZconnections = ent.EZconnections or {}
	local MachineIndex = machine:EntIndex()
	for entID, cable in pairs(ent.EZconnections) do
		if (EntID == MachineIndex) then
			if IsValid(cable) then
				cable:Remove()
			end
			ent.EZconnections[entID] = nil
		end
	end
	--
	if not IsValid(cable) then
		cable = constraint.Rope(machine, ent, 0, 0, machine.EZpowerSocket or Vector(0, 0, 0), PluginPos, dist + 20, 10, 100, 2, "cable/cable2")
	end
	
	ent.EZconnections[MachineIndex] = cable
	machine.EZconnections[EntID] = cable

	return true
end

function JMod.RemoveConnection(machine, connection)
	if not IsValid(machine) then return end
	-- Check if connection is a entity first
	if type(connection) == "Entity" and IsValid(connection) then
		-- Check if it is connected
		connection = connection:EntIndex()
	end
	if not(machine.EZconnections[connection]) then return end
	local ConnectedEnt = Entity(connection)
	local Cable = machine.EZconnections[connection]
	if IsValid(Cable) then
		Cable:Remove()
	end
	machine.EZconnections[connection] = nil
end

function JMod.ConnectionValid(machine, otherMachine)
	if not(IsValid(machine) and IsValid(otherMachine)) then return false end
	if not(machine.EZconnections and otherMachine.EZconnections) then return false end
	if not(IsValid(machine.EZconnections[otherMachine:EntIndex()])) then return false end
	return true
end

function JMod.EnergeticsCookoff(pos, attacker, powerMult, numExplo, numBullet, numFire)
	-- spark/smoke effects
	for i = 1, numExplo do
		timer.Simple(math.Rand(0, .5), function()
			JMod.Sploom(attacker, pos + VectorRand() * powerMult, powerMult * 10, 50)
		end)
	end
	for i = 1, numBullet do
		timer.Simple(math.Rand(0, .5), function()
			local dir = VectorRand():GetNormalized()
			local firer = (IsValid(attacker) and attacker) or game.GetWorld()

			sound.Play("snd_jack_fireworkpop" .. math.random(1, 5) .. ".ogg", pos + VectorRand() * 10, 75, math.random(90, 110))

			firer:FireBullets({
				Attacker = attacker,
				Damage = powerMult,
				Force = 0,
				Num = 1,
				Src = pos,
				Tracer = 0,
				TracerName = "Tracer",
				Dir = dir,
				Spread = 1,
				AmmoType = "Buckshot"
			})
		end)
	end
	for i = 1, numFire do
		local tr = util.QuickTrace(pos, VectorRand() * powerMult * 20, attacker)
		if tr.Hit then
			local Haz = ents.Create("ent_jack_gmod_ezfirehazard")

			if IsValid(Haz) then
				Haz:SetDTInt(0, 1)
				Haz:SetPos(tr.HitPos + tr.HitNormal * 2)
				Haz:SetAngles(tr.HitNormal:Angle())
				JMod.SetEZowner(Haz, JMod.GetEZowner(attacker))
				Haz.HighVisuals = true
				Haz.Burnin = true
				Haz:Spawn()
				Haz:Activate()
				
				if IsValid(tr.Entity) and tr.Entity:IsWorld() then
					Haz:SetParent(tr.Entity)
				end
			end
		else
			local FireVec = (VectorRand() * powerMult + Vector(0, 0, .3)):GetNormalized()
			FireVec.z = FireVec.z / 2
			local Flame = ents.Create("ent_jack_gmod_eznapalm")
			Flame:SetPos(pos + VectorRand() * 10)
			Flame:SetAngles(FireVec:Angle())
			Flame:SetOwner(JMod.GetEZowner(attacker))
			JMod.SetEZowner(Flame, attacker.EZowner or attacker)
			Flame.SpeedMul = (powerMult / 4)
			Flame.Creator = attacker
			Flame.HighVisuals = math.random(1, numFire) >= numFire / 2
			Flame:Spawn()
			Flame:Activate()
		end
	end
end

hook.Add("PhysgunPickup", "EZPhysgunBlock", function(ply, ent)
	if ent.block_pickup then
		JMod.Hint(ply, "blockphysgun")

		return false
	end
end)

concommand.Add("jacky_sandbox", function(ply, cmd, args)
	if not (IsValid(ply) and ply:IsSuperAdmin()) then return end
	if not GetConVar("sv_cheats"):GetBool() then return end

	for k, v in pairs({
		{"impulse 101", 10},
		"sbox_maxballoons 9e9", "sbox_maxbuttons 9e9", "sbox_maxdynamite 9e9", "sbox_maxeffects 9e9", "sbox_maxemitters 9e9", "sbox_maxhoverballs 9e9", "sbox_maxlamps 9e9", "sbox_maxlights 9e9", "sbox_maxnpcs 9e9", "sbox_maxprops 9e9", "sbox_maxragdolls 9e9", "sbox_maxsents 9e9", "sbox_maxthrusters 9e9", "sbox_maxturrets 9e9", "sbox_maxvehicles 9e9", "sbox_maxwheels 9e9", "sbox_noclip 1", "sbox_weapons 1"
	}) do
		if type(v) == "string" then
			ply:ConCommand(v)
		else
			for i = 1, v[2] do
				ply:ConCommand(v[1])
			end
		end
	end

	for k, v in pairs(JMod.AmmoTable) do
		ply:GiveAmmo(150, k)
	end

	local Helf = ply:Health()

	if Helf < 999 then
		ply:SetHealth(999)
	else
		ply:SetHealth(Helf + 1000)
	end
end, nil, "Sets us to Sandbox god mode thing.")

concommand.Add("jmod_debug_destroy", function(ply, cmd, args)
	if not GetConVar("sv_cheats"):GetBool() then return end
	if not ply:IsSuperAdmin() then return end
	local Tr = ply:GetEyeTrace()

	if not Tr.Entity then
		print("No Entity to destroy")

		return
	end

	local ent = Tr.Entity

	if ent.Destroy then
		print("Destroying ent: " .. tostring(ent))
		ent:Destroy(DamageInfo())
	else
		print("Entity does not have a destroy function")
	end
end, nil, "Destroys the current JMod thing you are looking at")
