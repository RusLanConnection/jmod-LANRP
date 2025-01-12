﻿-- Jackarunda 2021
AddCSLuaFile()
ENT.Type = "anim"
ENT.Author = "Jackarunda"
ENT.Category = "JMod - EZ Explosives"
ENT.Information = "glhfggwpezpznore"
ENT.PrintName = "EZ Nuclear Rocket"
ENT.Spawnable = true -- temporary, until we fix the textures and drawfunc
ENT.AdminOnly = true
---
ENT.JModPreferredCarryAngles = Angle(0, 90, 0)
ENT.EZRackOffset = Vector(0, 0, 10)
ENT.EZRackAngles = Angle(0, 90, 0)

ENT.WhistleSound = "bomb/nukefly.wav"
---
local STATE_BROKEN, STATE_OFF, STATE_ARMED, STATE_LAUNCHED = -1, 0, 1, 2

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "State")
end

---
if SERVER then
    function ENT:SpawnFunction(ply, tr)
        local SpawnPos = tr.HitPos + tr.HitNormal * 40
        local ent = ents.Create(self.ClassName)
        ent:SetAngles(Angle(180, 0, 0))
        ent:SetPos(SpawnPos)
        JMod.SetEZowner(ent, ply)
        ent:Spawn()
        ent:Activate()
        --local effectdata=EffectData()
        --effectdata:SetEntity(ent)
        --util.Effect("propspawn",effectdata)

        return ent
    end

    function ENT:Initialize()
        self:SetModel("models/hunter/blocks/cube05x4x05.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:DrawShadow(true)
        self:SetUseType(SIMPLE_USE)

        ---
        timer.Simple(.01, function()
            self:GetPhysicsObject():SetMass(40)
            self:GetPhysicsObject():Wake()
            self:GetPhysicsObject():EnableDrag(false)
        end)

        ---
        self:SetState(STATE_OFF)
        --self.NextDet = 0
        self.FuelLeft = 1000

        if istable(WireLib) then
            self.Inputs = WireLib.CreateInputs(self, {"Detonate", "Arm", "Launch"}, {"Directly detonates rocket", "Arms rocket", "Launches rocket"})
            self.Outputs = WireLib.CreateOutputs(self, {"State", "Fuel"}, {"-1 broken \n 0 off \n 1 armed \n 2 launched", "Fuel left in the tank"})
        end
    end

    function ENT:TriggerInput(iname, value)
        if iname == "Detonate" and value > 0 then
            self:Detonate()
        elseif iname == "Arm" and value > 0 then
            self:SetState(STATE_ARMED)
        elseif iname == "Arm" and value == 0 then
            self:SetState(STATE_OFF)
        elseif iname == "Launch" and value > 0 then
            self:SetState(STATE_ARMED)
            self:Launch()
        end
    end

    function ENT:PhysicsCollide(data, physobj)
        if not IsValid(self) then return end

        if data.DeltaTime > 0.2 then
            if data.Speed > 50 then
                self:EmitSound("Canister.ImpactHard")
            end

            if (self:GetState() == STATE_LAUNCHED) and data.HitEntity:GetClass() == "lvs_missile" then
                self:Break()
            end

            local DetSpd = 300
            if (data.Speed > DetSpd) and (self:GetState() == STATE_LAUNCHED) then
                self:Detonate()
                return
            end
            --
            if data.Speed > 2000 then
                self:Break()
            end
        end
    end

    function ENT:Break()
        if self:GetState() == STATE_BROKEN then return end
        self:SetState(STATE_BROKEN)
        self:EmitSound("snd_jack_turretbreak.ogg", 70, math.random(80, 120))

        for i = 1, 20 do
            JMod.DamageSpark(self)
        end

        for k = 1, 10 do
            local Gas = ents.Create("ent_jack_gmod_ezfalloutparticle")
            Gas:SetPos(self:GetPos())
            JMod.SetEZowner(Gas, JMod.GetEZowner(self))
            Gas:Spawn()
            Gas:Activate()
            Gas.CurVel = VectorRand() * math.random(-100, 100)
        end

        SafeRemoveEntityDelayed(self, 10)
    end

    function ENT:OnTakeDamage(dmginfo)
        if IsValid(self.DropOwner) then
            local Att = dmginfo:GetAttacker()
            if IsValid(Att) and (self.DropOwner == Att) then return end
        end

        self:TakePhysicsDamage(dmginfo)

        if JMod.LinCh(dmginfo:GetDamage(), 60, 120) then
            --if math.random(1, 3) == 1 then
                self:Break()
            --else
            --    JMod.SetEZowner(self, dmginfo:GetAttacker())
            --    self:Detonate()
            --end
        end
    end

    function ENT:JModEZremoteTriggerFunc(ply)
        if not (IsValid(ply) and ply:Alive() and (ply == self.EZowner)) then return end
        if not ((self:GetState() == STATE_LAUNCHED)) then return end
        self:Detonate()
    end

    function ENT:Use(activator)
        local State = self:GetState()
        if State < 0 then return end
        local Alt = activator:KeyDown(JMod.Config.General.AltFunctionKey)

        if State == STATE_OFF then
            if Alt then
                local squad = SquadMenu:GetSquad(JMod.GetEZowner(self):GetSquadID())

                if not squad then return end

                if not GetConVar("sv_cheats"):GetBool() then
                    if squad.hp >= 70 and not GetGlobalVar("NuclearWar") then 
                        activator:LanRPChatPrint(Color(255,255,255), "Мораль вашей фракции должна быть ниже ", Color(255,0,0), "70", Color(255,255,255), " единиц.") 
                        return 
                    end
                end

                JMod.SetEZowner(self, activator)
                self:EmitSound("snds_jack_gmod/bomb_arm.ogg", 60, 120)
                self:SetState(STATE_ARMED)
                self.EZlaunchableWeaponArmedTime = CurTime()
                JMod.Hint(activator, "launch")
            else
                --activator:PickupObject(self)
                JMod.Hint(activator, "arm")
            end
        elseif State == STATE_ARMED then
            self:EmitSound("snds_jack_gmod/bomb_disarm.ogg", 60, 120)
            self:SetState(STATE_OFF)
            JMod.SetEZowner(self, activator)
            self.EZlaunchableWeaponArmedTime = nil
        end
    end

    local function SendClientNukeEffect(pos, range)
        net.Start("JMod_NuclearBlast")
        net.WriteVector(pos)
        net.WriteFloat(range)
        net.WriteFloat(1)
        net.Broadcast()
    end

    function ENT:Detonate()  
        if self.Exploded then return end
        self.Exploded = true
        local SelfPos, Att, Power, Range = self:GetPos() + Vector(0, 0, 100), JMod.GetEZowner(self), JMod.Config.Explosives.Nuke.PowerMult, 1

		local oldselfpos = self:GetPos()
        --[[JMod.Sploom(Att,SelfPos,500)
        timer.Simple(.1, function()
            JMod.BlastDamageIgnoreWorld(SelfPos, Att, nil, 1200, 6000)
        end)]]

        ---
        SendClientNukeEffect(SelfPos, 12000)
        util.ScreenShake(SelfPos, 1000, 10, 10, 2000 * Range)
        local Eff = "pcf_jack_nuke_ground"

        if not util.QuickTrace(SelfPos, Vector(0, 0, -300), {self}).HitWorld then
            Eff = "pcf_jack_nuke_air"
        end

        for i = 1, 19 do
            sound.Play("ambient/explosions/explode_" .. math.random(1, 9) .. ".wav", SelfPos + VectorRand() * 1000, 150, math.random(80, 110))
        end

        ---
        if (JMod.Config.QoL.NukeFlashLightEnabled) then
            local NukeFlash = ents.Create("ent_jack_gmod_nukeflash")
            NukeFlash:SetPos(SelfPos + Vector(0, 0, 32))
            NukeFlash.LifeDuration = 10
            NukeFlash.MaxAltitude = 500
            NukeFlash:Spawn()
            NukeFlash:Activate()
        end

        ---
        --[[for h = 1, 30 do
            timer.Simple(h / 10, function()
                local ThermalRadiation = DamageInfo()
                ThermalRadiation:SetDamageType(DMG_BURN)
                ThermalRadiation:SetDamage(25 / h)
                ThermalRadiation:SetAttacker(Att)
                ThermalRadiation:SetInflictor(game.GetWorld())
                util.BlastDamageInfo(ThermalRadiation, SelfPos, 15000)
            end)
        end]]

        for _, ply in player.Iterator() do 
            if ply:GetPos():Distance(SelfPos + Vector(0,0, 1024)) <= 15000 then
                local TraceSee = util.TraceLine( {
                    start = SelfPos,
                    endpos = ply:GetPos(),
                })

                if TraceSee.HitWorld and not ply:IsOnFire() then
                    print("GOVNO")
                    ply:Ignite(30)
                end
            end
        end

        for _, ply in player.Iterator() do 
            if ply:GetPos():Distance(SelfPos) <= 8000 then
                ply:GodEnable()
                ply:SetLaggedMovementValue(0.3)
                ply:StripWeapons()

                timer.Simple(4.5, function()
                    ply:ScreenFade( SCREENFADE.IN, Color( 255, 255, 255 ), 2, 3 )
                end)

                timer.Simple(6, function()
                    if IsValid(ply) and ply:Alive() then
                        ply:Extinguish()
                        ply:GodDisable()
                        ply:SetLaggedMovementValue(1)

                        ply:Kill()
                    end
                end)
            end
        end

        ---
        for k, ply in player.Iterator() do
            local Dist = ply:GetPos():Distance(SelfPos)

            if Dist > 1000 then
                timer.Simple(Dist / 6000, function()
                    ply:EmitSound("snds_jack_gmod/nuke_far.ogg", 55, 100)
                    util.ScreenShake(ply:GetPos(), 1000, 10, 10, 100)
                end)
            end
        end

        ---
        for i = 1, 20 do
            timer.Simple(i / 5, function()
                SelfPos = SelfPos + Vector(0, 0, 128)
                ---
                local powa, renj = 10 + i * 2.5, 1 + i / 10

                ---
                if i == 1 then
                    JMod.EMP(SelfPos, renj * 15000)

                    for k, ent in pairs(ents.FindInSphere(SelfPos, renj)) do
                        if ent:GetClass() == "npc_helicopter" then
                            ent:Fire("selfdestruct", "", math.Rand(0, 2))
                        end
                    end
                end

                ---
				debugoverlay.Sphere( SelfPos, 250 * i, 2, Color( 255, 0, 0 ), true )
                util.BlastDamage(game.GetWorld(), Att, SelfPos, 400 * i, 6000 / i + 50)

                ---
                JMod.WreckBuildings(nil, SelfPos, powa, renj, i < 3)
                JMod.BlastDoors(nil, SelfPos, powa, renj, i < 3)
                ---
                SendClientNukeEffect(SelfPos, 2000 * renj)

                ---
                if i == 10 then
                    JMod.DecalSplosion(SelfPos + Vector(0, 0, 500) + Vector(0, 0, 1000), "GiantScorch", 8000, 40)
                end

                ---
                if i == 20 then
                    for j = 1, 10 do
                        timer.Simple(j / 10, function()
                            for k = 1, 20 do
                                local Gas = ents.Create("ent_jack_gmod_ezfalloutparticle")
                                Gas:SetPos(oldselfpos + Vector(math.random(-500, 500), math.random(-500, 500), math.random(-400, 0)))
                                JMod.SetEZowner(Gas, Att)
                                Gas:Spawn()
                                Gas:Activate()
                                Gas.CurVel = (Vector(math.random(-500, 500), math.random(-500, 500), math.random(-100, 0)))
                            end
                        end)
                    end
                end
            end)
        end

        ---
        self:Remove()

        timer.Simple(0, function()
            ParticleEffect(Eff, SelfPos, Angle(0, 0, 0))
        end)

        ---
    end

    function ENT:OnRemove()
    end
    --

    function ENT:CalculateLastPos() 
        local Grav = physenv.GetGravity()
        local FT = FrameTime() 
        local MissilePos = self:GetPos() 
        local oPos = MissilePos 
        local Vel = -self:GetAngles():Right() * 2250 
        local Acceleration = 280 -- Ускорение
        local dist = 0 
        local EndPos 
        local positions = {} 
        local Iteration = 0 
    
        while Iteration < 5000 do 
            Iteration = Iteration + 0.05 
    
            -- Увеличиваем предварительно скорость с учетом ускорения
            Vel = Vel + Vel:GetNormalized() * Acceleration * FT
            Vel = Vel + Grav * FT
    
            local StartPos = oPos 
            EndPos = oPos + Vel * FT 
    
            dist = dist + StartPos:Distance(EndPos) 
    
            local trace = util.TraceLine({ 
                start = StartPos, 
                endpos = EndPos, 
                filter = self, 
                mask = MASK_SOLID_BRUSHONLY, 
            }) 
    
            debugoverlay.Axis(oPos, Angle(), 100, 10, true) 
    
            positions[#positions + 1] = oPos 
    
            oPos = EndPos 
    
            if trace.Hit then 
                break 
            end 
        end 
    
        return EndPos 
    end

    function ENT:calculateRocketPosition(LastPos)
        local Grav = physenv.GetGravity() / 2
        local FT = FrameTime()
        local MissilePos = self:GetPos()
        local oPos = MissilePos
        local Vel = self:GetVelocity()

        local dist = 0

        local EndPos


        local positions = {}


        local Iteration = 0
        while Iteration < 300 do
            Iteration = Iteration + 1

            Vel = Vel + Grav * FT

            local StartPos = oPos
            EndPos = oPos + Vel * FT

            dist = dist + StartPos:Distance(EndPos)

            local trace = util.TraceLine( {
                start = StartPos,
                endpos = EndPos,
                filter = self
            } )

			debugoverlay.Axis( oPos, Angle(), 100, 10, true )

            positions[#positions + 1] = oPos

            oPos = EndPos

            if trace.Hit then
                break
            end
        end

        return positions
    end

    local ruslan_red = Color(180, 22, 22)

    function ENT:Launch()
        local squad = SquadMenu:GetSquad(JMod.GetEZowner(self):GetSquadID())

        if not squad then return end
        
        if self:GetState() ~= STATE_ARMED then return end
        self:SetState(STATE_LAUNCHED)
        local Phys = self:GetPhysicsObject()
        constraint.RemoveAll(self)
        Phys:EnableMotion(true)
        Phys:Wake()

        --self:SetGravity(0)

        Phys:ApplyForceCenter(-self:GetRight() * 20000)
        ---
        self:EmitSound("snds_jack_gmod/rocket_launch.ogg", 80, math.random(60, 80))
        local Eff = EffectData()
        Eff:SetOrigin(self:GetPos())
        Eff:SetNormal(self:GetRight())
        Eff:SetScale(5)
        util.Effect("eff_jack_gmod_rocketthrust", Eff, true, true)

        ---
        for i = 1, 4 do
            util.BlastDamage(self, JMod.GetEZowner(self), self:GetPos() + self:GetRight() * i * 40, 50, 50)
        end

        util.ScreenShake(self:GetPos(), 20, 255, .5, 300)

        --[[timer.Simple(2, function()

            local predictedPath = calculateRocketTrajectory(self)

            for _, pos in ipairs(predictedPath) do
                debugoverlay.Axis( pos, Angle(0,0,0), 100, 5, true )
            end
        end)]]
        ---
        --self.NextDet = CurTime() + .25

        JMod.Hint(JMod.GetEZowner(self), "backblast", self:GetPos())
        --------------
        
        if squad.YaderkaLaunched == nil then
            squad.YaderkaLaunched = CurTime()
        end

        if squad and squad.YaderkaLaunched <= CurTime() then
            for k, v in pairs(player.GetAll()) do
                v:LanRPChatPrint(ruslan_red, "Фракция ", Color(squad.r,squad.g,squad.b), squad.name, ruslan_red, " запустила ядерные ракеты!")
                v:PlayLocalSound("hoi4/NukeLaunch.wav")

                --[[local random = math.random(1, 100)
                if random <= 15 then
                    timer.Simple(3, function()
                        v:LanRPChatPrint(ruslan_red, "Нам всем конец...")
                    end)
                end]]
            end

            squad.YaderkaLaunched = CurTime() + 60
        end

        for _, ply in player.Iterator() do
            if ply:GetPos():Distance(self:GetPos()) >= 10000 then
                timer.Simple(0.5, function()
                    if IsValid(ply) then
                        ply:PlayLocalSound("LANRP/nuke/missile_launch_far_0" .. math.random(1,2) .. ".ogg")
                    end
                end)
            else
                ply:PlayLocalSound("LANRP/nuke/missile_launch_map_0" .. math.random(1,2) .. ".ogg")
            end
        end
    end

    function ENT:OnRemove()
        if not GetGlobalVar( "NuclearWar") and self:GetState() == STATE_LAUNCHED then
            timer.Simple(10, function()
                for _, ply in player.Iterator() do
                    ply:SendMessageOnTop("НАЧАЛАСЬ ЯДЕРНАЯ ВОЙНА", Color(120, 0, 0))
                    ply:PlayLocalSound("LANRP/nuke/nuclear war.wav") 
                end

                SetGlobalVar( "NuclearWar", true)

                timer.Create("NuclearWar", 900, 1, function()
                    for _, ply in player.Iterator() do
                        ply:LanRPChatPrint(Color(87, 87, 255), "[Глобальное сообщение] ", Color(120, 0, 0), "Закончилась ядерная война!")
                        ply:PlayLocalSound("hoi4/War_declaration_01.wav")
                    end

                    SetGlobalVar( "NuclearWar", false)
                end)
            end)
        end
    end

    function ENT:EZdetonateOverride(detonator)
        self:Detonate()
    end

    function ENT:Think()
        if istable(WireLib) then
            WireLib.TriggerOutput(self, "State", self:GetState())
            WireLib.TriggerOutput(self, "Fuel", self.FuelLeft)
        end
        local ThrustDir = self:GetRight()

        local Phys = self:GetPhysicsObject()
        JMod.AeroDrag(self, -ThrustDir, .75)

        if self:GetState() == STATE_LAUNCHED then
            if self.FuelLeft > 0 then
                Phys:ApplyForceCenter(-ThrustDir * 8000)
                self.FuelLeft = self.FuelLeft - 5
                ---
                local Eff = EffectData()
                Eff:SetOrigin(self:GetPos() + ThrustDir * 100)
                Eff:SetNormal(ThrustDir)
                Eff:SetScale(8)
                util.Effect("eff_jack_gmod_rockettrail", Eff, true, true)

                local Eff = EffectData()
                Eff:SetOrigin(self:GetPos())
                Eff:SetNormal(self:GetRight())
                Eff:SetScale(5)
                util.Effect("eff_jack_gmod_rocketthrust", Eff, true, true)

                Phys:SetVelocity( Phys:GetVelocity() * 0.9 )
            end
        end

        self:NextThink(CurTime() + .05)

        return true
    end
elseif CLIENT then
    function ENT:Initialize()
        self.Mdl = ClientsideModel("models/jmod/explosives/bombs/bomb_nukekab.mdl")
        --self.Mdl:SetMaterial("models/jmod/explosives/bombs/bomb_nukekab")
        self.Mdl:SetModelScale(2, 0)
        self.Mdl:SetPos(self:GetPos())
        self.Mdl:SetParent(self)
        self.Mdl:SetNoDraw(true)

        self.snd = CreateSound(self, self.WhistleSound)
		self.snd:SetSoundLevel( 120 )
		self.snd:PlayEx(0,250)
    end
    --
    local GlowSprite = Material("mat_jack_gmod_glowsprite")
    local Trefoil = Material("png_jack_gmod_radiation.png")

    function ENT:Draw()
        local Pos, Ang, Dir = self:GetPos(), self:GetAngles(), self:GetRight()
        Ang:RotateAroundAxis(Ang:Up(), 90)
        --self:DrawModel()
        self.Mdl:SetRenderOrigin(Pos + Ang:Up() * 1.5 - Ang:Right() * 0 - Ang:Forward() * 1)
        self.Mdl:SetRenderAngles(Ang)
        self.Mdl:DrawModel()

        local Ang, Pos = self:GetAngles(), self:GetPos()
        local Closeness = LocalPlayer():GetFOV() * EyePos():Distance(Pos)
        local DetailDraw = Closeness < 21000

        if DetailDraw then
            local Up, Right, Forward = Ang:Up(), Ang:Right(), Ang:Forward()
            Ang:RotateAroundAxis(Ang:Up(), 0)
            Ang:RotateAroundAxis(Ang:Right(), 90)
            Ang:RotateAroundAxis(Ang:Forward(), 180)
            
            cam.Start3D2D(Pos - Up * 4 - Right * 3 + Forward * 16, Ang, .05)
            surface.SetDrawColor(255, 255, 255, 120)
            surface.SetMaterial(Trefoil)
            surface.DrawTexturedRect(0, 0, 256, 256)
            cam.End3D2D()
            ---
            Ang:RotateAroundAxis(Ang:Forward(), 180)
            cam.Start3D2D(Pos - Up * 4 - Right * 3 - Forward * 16, Ang, .05)
            surface.SetDrawColor(255, 255, 255, 120)
            surface.SetMaterial(Trefoil)
            surface.DrawTexturedRect(0, 0, 256, 256)
            cam.End3D2D()
        end

        if self:GetState() == STATE_LAUNCHED then
            self.BurnoutTime = self.BurnoutTime or CurTime() + 2

            if self.BurnoutTime > CurTime() then
                render.SetMaterial(GlowSprite)

                for i = 1, 10 do
                    local Inv = 10 - i
                    render.DrawSprite(Pos + Dir * (i * 10 + math.random(100, 130)), 8 * Inv, 8 * Inv, Color(255, 255 - i * 10, 255 - i * 20, 255))
                end

                local dlight = DynamicLight(self:EntIndex())

                if dlight then
                    dlight.pos = Pos + Dir * 130
                    dlight.r = 255
                    dlight.g = 175
                    dlight.b = 100
                    dlight.brightness = 2
                    dlight.Decay = 200
                    dlight.Size = 400
                    dlight.DieTime = CurTime() + .5
                end
            end
        end
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
		return 0.2 + math.cos( A ) * SubVel:Length() / 1000 --13503.9
	end
	--

	function ENT:Think()
		if self.snd and self:GetState() == STATE_LAUNCHED then
			self.snd:ChangePitch(100 * self:CalcDoppler(), 1 )
			self.snd:ChangeVolume(math.Clamp((self:GetVelocity():LengthSqr() - 150000) / 5000,0,1), 2)
		end
	end

	function ENT:OnRemove()
		if self.snd then
			self.snd:Stop()
		end
	end
    


    language.Add("ent_jack_gmod_eznukerocket", "EZ Nuke Rocket")
end
