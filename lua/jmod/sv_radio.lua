﻿-- EZ Radio Code --
JMod.NotifyAllMsgs = {
	["normal"] = {
		["good drop"] = "хорошее падение, посылка рядом, возвращение на базу",
		["drop failed"] = "Сброс не удался, пилот не смог найти подходящую позицию для сброса по заявленным координатам. Самолет возвращен на базу",
		["drop soon"] = "Внимание, самолет на месте, сброс неизбежно",
		["ready"] = "внимание, теперь этот форпост готов к выполнению миссий по доставке грузов"
	},
	["bff"] = {
		["good drop"] = "МИ УРОНЫЛЫ ЕГШО, БЭРЭГИС",
		["drop failed"] = "ЙО БРАТИК Я ПОТЕРЯЛ ПОСИЛКУ, СИДИ БЕЗ ПОСЫЛОК КОРОЧ",
		["drop soon"] = "КОРОЧ СКОР БУД",
		["ready"] = "ТЫ ГДЕЛ ТАМ Я УЖЕ ГОТОВ АЛЕ"
	}
}

local function CreateRadioStation(teamID)
	return {
		state = JMod.EZ_STATION_STATE_READY,
		nextDeliveryTime = 0,
		nextReadyTime = 0,
		deliveryLocation = nil,
		deliveryType = nil,
		teamID = teamID,
		nextNotifyTime = 0,
		notified = false,
		restrictedPackageStock = {},
		restrictedPackageDelivering = nil,
		restrictedPackageDeliveryTime = 0,
		outpostDirection = Vector(math.Rand(-1, 1), math.Rand(-1, 1), 0):GetNormalized(),
		lastCaller = nil
	}
end

local function FindEZradios() 
	local Radios = {}
	for _, v in ents.Iterator() do
		if v.EZradio and (v.EZradio == true) then
			table.insert(Radios, v)
		end
	end

	return Radios
end

function JMod.NotifyAllRadios(stationID, msgID, direct)
	local Station = JMod.EZ_RADIO_STATIONS[stationID]

	for _, radio in ipairs(FindEZradios()) do
		if (radio:GetState() > JMod.EZ_STATE_OFF) and (radio:GetOutpostID() == stationID) then
			if msgID then
				if direct then
					radio:Speak(msgID)
				else
					local Personality = radio:GetVoice() or "normal"
					radio:Speak(JMod.NotifyAllMsgs[Personality][msgID])
				end
			end

			radio:SetState(Station.state)
		end
	end
end

function JMod.FindDropPosFromSignalOrigin(origin)
	local Height, Attempts, Pos, AcceptTFVonly = 0, 0, origin + Vector(0, 0, 200), false

	while (Attempts < 1000) and not (Height > 5000) do
		Height = Height + 100
		local TestPos = origin + Vector(0, 0, Height)
		local Contents = util.PointContents(TestPos)
		local IsEmpty = Contents == CONTENTS_EMPTY -- fuck bitwise ops for 0
		local IsTFV = bit.band(Contents, CONTENTS_TESTFOGVOLUME) == CONTENTS_TESTFOGVOLUME

		if IsTFV then
			-- if we ever detect testfogvolume, assume the mapmaker used it properly
			-- and from that point on, accept only tfv as an indication of empty space
			AcceptTFVonly = true
			-- otherwise, accept both tfv and contents_empty
		end

		if AcceptTFVonly then
			if IsTFV then
				Pos = TestPos
			else
				return Pos
			end
		else
			if IsEmpty or IsTFV then
				Pos = TestPos
			else
				return Pos
			end
		end
	end

	return Pos
end

local NextRadioThink = 0

hook.Add("Think", "JMod_RADIO_THINK", function()
	local Time = CurTime()
	if Time < NextRadioThink then return end
	NextRadioThink = Time + 5

	for stationID, station in pairs(JMod.EZ_RADIO_STATIONS) do
		if station.state == JMod.EZ_STATION_STATE_DELIVERING then
			if station.nextDeliveryTime < Time then
				station.nextReadyTime = Time + math.ceil(JMod.Config.RadioSpecs.DeliveryTimeMult * math.Rand(30, 60) * 3)
				station.state = JMod.EZ_STATION_STATE_BUSY
				local DropPos = JMod.FindDropPosFromSignalOrigin(station.deliveryLocation)

				local AlternateDelivery, ReturnToBaseModifier = hook.Run("JMod_OnRadioDeliver", stationID, DropPos)

				if AlternateDelivery ~= nil then
					if AlternateDelivery == true then
						JMod.NotifyAllRadios(stationID, "good drop")
					else
						JMod.NotifyAllRadios(stationID, "drop failed")
					end
					if ReturnToBaseModifier then
						station.nextDeliveryTime = Time + math.ceil(math.min(JMod.Config.RadioSpecs.DeliveryTimeMult * math.Rand(30, 60), ReturnToBaseModifier))
					end

					return 
				end
				
				if DropPos then
					local DropVelocity = station.outpostDirection
					DropVelocity = DropVelocity * 400
					local Eff = EffectData()
					Eff:SetOrigin(DropPos)
					Eff:SetStart(DropVelocity)
					util.Effect("eff_jack_gmod_jetflyby", Eff, true, true)
					local DeliveryItems = JMod.Config.RadioSpecs.AvailablePackages[station.deliveryType].results
					local IsChrimsas = JMod.GetHoliday() == "Christmas"

					timer.Simple(.9, function()
						local Box = ents.Create("ent_jack_aidbox")
						Box:SetPos(DropPos)
						Box.InitialVel = -DropVelocity * math.random(1, 3)
						Box.Contents = DeliveryItems
						Box.NoFadeIn = true
						Box:SetDTBool(0, "true")
						Box:Spawn()
						Box:SetPackageName(station.deliveryType)
						---
						sound.Play((IsChrimsas and "snd_jack_flyby_drop_Christmas.ogg") or "snd_jack_flyby_drop.ogg", DropPos, 150, 100)

						for k, playa in pairs(ents.FindInSphere(DropPos, 6000)) do
							if playa:IsPlayer() then
								sound.Play((IsChrimsas and "snd_jack_flyby_drop_Christmas.ogg") or "snd_jack_flyby_drop.ogg", playa:GetShootPos(), 50, 100)
							end
						end

						JMod.NotifyAllRadios(stationID, "good drop")
					end)
				else
					JMod.NotifyAllRadios(stationID, "drop failed")
				end
			elseif (station.nextNotifyTime < Time) and not station.notified then
				station.notified = true
				JMod.NotifyAllRadios(stationID, "drop soon")
			end
		elseif station.state == JMod.EZ_STATION_STATE_BUSY then
			if station.nextReadyTime < Time then
				station.state = JMod.EZ_STATION_STATE_READY
				JMod.NotifyAllRadios(stationID, "ready")
			end
		end

		if station.restrictedPackageDelivering then
			if station.restrictedPackageDeliveryTime < Time then
				table.insert(station.restrictedPackageStock, station.restrictedPackageDelivering)
				JMod.NotifyAllRadios(stationID, "attention, this outpost has received a special shipment of " .. station.restrictedPackageDelivering .. " from regional HQ", true)
				station.restrictedPackageDelivering = nil
				station.restrictedPackageDeliveryTime = 0
			end
		end
	end
end)

hook.Add("PlayerSay", "JMod_PLAYERSAY", function(ply, txt)
	if not IsValid(ply) then return end
	if not ply:Alive() then return end

	if txt == "hi everyone" then
		JMod.Hint(ply, "idiot")
	end

	local lowerTxt = string.lower(txt)

	if lowerTxt == "*trigger*" then
		JMod.EZ_Remote_Trigger(ply)

		return ""
	end

	if lowerTxt == "*bomb*" then
		JMod.EZ_BombDrop(ply)

		return ""
	end

	if lowerTxt == "*launch*" then
		JMod.EZ_WeaponLaunch(ply)

		return ""
	end

	if (lowerTxt == "*inv*") or (lowerTxt == "*inventory*") then
		JMod.EZ_Open_Inventory(ply)

		return ""
	end

	if (lowerTxt == "*scrounge*") or (lowerTxt == "*scavange*") then
		JMod.EZ_ScroungeArea(ply)

		return ""
	end

	for k, v in pairs(ents.FindInSphere(ply:GetPos(), 150)) do
		if v.EZreceiveSpeech and (v.GetState and v:GetState() == JMod.EZ_STATION_STATE_READY) then
			if v:EZreceiveSpeech(ply, txt) then return "" end -- hide the player's radio chatter from the server
		end
	end

	if JMod.PlyHasArmorEff(ply, "teamComms") then
		for id, data in pairs(ply.EZarmor.items) do
			local Info = JMod.ArmorTable[data.name]

			if Info.eff and Info.eff.teamComms then
				local SubtractAmt = JMod.Config.Armor.DegradationMult / 2
				data.chrg.power = math.Clamp(data.chrg.power - SubtractAmt, 0, 9e9)

				if data.chrg.power <= Info.chrg.power * .25 then
					JMod.EZarmorWarning(ply, "armor's electrical charge is almost depleted!")
				end
			end
		end

		------ Буквально радист -----


		--[[local bestradio = nil
		
		for _, v in ipairs(FindEZradios()) do
			if v:UserIsAuthorized(ply) and (not bestradio or (bestradio:GetPos():DistToSqr(ply:GetPos()) > v:GetPos():DistToSqr(ply:GetPos()))) then
				if (v.GetState and v:GetState() == JMod.EZ_STATION_STATE_READY) then
					bestradio = v
				end
			end
		end

		local ExplodedString = string.Explode(" ", lowerTxt)
		if bestradio and bestradio:EZreceiveSpeech(ply, txt) then 

			return "" 
		elseif not(bestradio) and ((ExplodedString[1] == "supply") or (ExplodedString[1] == "aid")) and (ExplodedString[2] == "radio:") then

			ply:PrintMessage(HUD_PRINTCENTER, "No good radios in range")
		end]]
	end
end)

function JMod.EZradioEstablish(transceiver, teamID, reassign)
	local AlliedStations = {}

	for k, v in pairs(JMod.EZ_RADIO_STATIONS) do
		if v.teamID == teamID then
			table.insert(AlliedStations, k)
		end
	end

	local MinimumOutposts = JMod.Config.RadioSpecs.StartingOutpostCount or 0
	if (#AlliedStations < MinimumOutposts) then
		for i = 1, MinimumOutposts - #AlliedStations do
			table.insert(JMod.EZ_RADIO_STATIONS, CreateRadioStation(teamID))
			table.insert(AlliedStations, #JMod.EZ_RADIO_STATIONS)
		end
	end

	local OriginalStation, ChosenStation = transceiver:GetOutpostID(), nil

	if not(reassign) and (OriginalStation ~= 0) and (JMod.EZ_RADIO_STATIONS[OriginalStation] and (JMod.EZ_RADIO_STATIONS[OriginalStation].teamID == teamID)) and (JMod.EZ_RADIO_STATIONS[OriginalStation].state == JMod.EZ_STATION_STATE_READY) then
		return
	end

	if not ChosenStation then
		for k, id in pairs(AlliedStations) do
			local station = JMod.EZ_RADIO_STATIONS[id]

			if (station.state == JMod.EZ_STATION_STATE_READY) then
				ChosenStation = id
				break
			end
		end
	end

	if ChosenStation then
		transceiver:SetOutpostID(ChosenStation)
	end
end

-- this is on the global table for third-party use
function JMod.AddNewRadioOutpost(teamID)
	table.insert(JMod.EZ_RADIO_STATIONS, CreateRadioStation(teamID))

	local TeamName = team.GetName(tonumber(teamID))

	if TeamName == "" then
		TeamName = player.GetByAccountID(tonumber(teamID)):Name()
	else
		TeamName = "Team " .. TeamName
	end

	for k, ply in player.Iterator() do
		ply:PrintMessage(HUD_PRINTTALK, TeamName .. " has gained a radio outpost.")
	end
end

-- this is also on the global table for third-party use
function JMod.RemoveRadioOutPost(teamID)
	local RemovedOutpost = nil
	for k, v in pairs(JMod.EZ_RADIO_STATIONS) do
		if v.teamID == teamID then
			table.remove(JMod.EZ_RADIO_STATIONS, k)
			RemovedOutpost = k
			break
		end
	end

	for _, radio in ipairs(FindEZradios()) do
		if radio:GetOutpostID() == RemovedOutpost then
			radio:StartConnecting()
		end
	end

	local TeamName = team.GetName(tonumber(teamID))

	if TeamName == "" then
		TeamName = player.GetByAccountID(tonumber(teamID)):Name()
	else
		TeamName = "Team " .. TeamName
	end

	for k, ply in player.Iterator() do
		ply:PrintMessage(HUD_PRINTTALK, TeamName .. " has lost a radio outpost.")
	end
end

concommand.Add("jmod_debug_addoutpost", function(ply, cmd, args)
	if not ply:IsUserGroup("superadmin") then return end
	local Team = 0

	if ply:GetSquadID() == -1 then
		Team = ply:AccountID()
	else
		Team = ply:GetSquadID()
	end

	JMod.AddNewRadioOutpost(tostring(Team))
end, nil, "Adds another radio outpost for your team.")

concommand.Add("jmod_debug_removeoutpost", function(ply, cmd, args)
	if not ply:IsUserGroup("superadmin") then return end
	local Team = 0

	if ply:GetSquadID() == -1 then
		Team = ply:AccountID()
	else
		Team = ply:GetSquadID()
	end

	JMod.RemoveRadioOutPost(tostring(Team))
end, nil, "Removes a radio outpost for your team.")

local function GetPlayerFromNick(nickname)
	if not nickname then return nil end
	nickname = string.lower(nickname)
	for _, v in ents.Iterator() do
		if not(IsValid(v)) and (v:IsPlayer()) and (string.lower(v:Nick())) == nickname then

			return v
		end
	end
	
	return nil
end

concommand.Add("jmod_airdropplayer", function(ply, cmd, args) 
	if not ply:IsUserGroup("superadmin") then return end
	
	local TargetPly, TargetPos, Punish = GetPlayerFromNick(args[1]), ply:GetPos(), false

	if not(IsValid(TargetPly)) then 
		TargetPly = ply 
	end
	if isnumber(tonumber(args[2])) then
		TargetPos = Vector(tonumber(args[2]), tonumber(args[3]) or 0, tonumber(args[4]) or 0)
		Punish = tobool(args[5])
	elseif tobool(args[2]) then
		Punish = tobool(args[2])
	end

	local DropPos = JMod.FindDropPosFromSignalOrigin(TargetPos)

	if DropPos then
		TargetPly:ExitVehicle()
		--TargetPly:SetPos(DropPos)
		TargetPly:SetNoDraw(true)
		local DropVelocity = VectorRand()
		DropVelocity.z = 0
		DropVelocity:Normalize()
		DropVelocity = DropVelocity * 400
		local Eff = EffectData()
		Eff:SetOrigin(DropPos)
		Eff:SetStart(DropVelocity)
		util.Effect("eff_jack_gmod_jetflyby", Eff, true, true)

		timer.Simple(0.9, function()
			local Box = ents.Create("ent_jack_aidbox")
			Box:SetPos(DropPos)
			Box.InitialVel = -DropVelocity * 10
			--Box.Contents = {"ent_jack_gmod_eztoolbox"}
			Box.NoFadeIn = true
			Box:SetDTBool(0, "true")
			Box:Spawn()
			----- Create the chair
			Box.Pod = ents.Create("prop_vehicle_prisoner_pod")
			Box.Pod:SetModel("models/vehicles/prisoner_pod_inner.mdl")
			local Ang, Up, Right, Forward = Box:GetAngles(), Box:GetUp(), Box:GetRight(), Box:GetForward()
			Box.Pod:SetPos(Box:GetPos() - Up * 30)
			Ang:RotateAroundAxis(Up, 0)
			Ang:RotateAroundAxis(Forward, 0)
			Box.Pod:SetAngles(Ang)
			Box.Pod:Spawn()
			Box.Pod:Activate()
			Box.Pod:SetParent(Box)
			Box.Pod:SetNoDraw(true)
			Box.Pod:SetThirdPersonMode(true)
			------
			Box:SetPackageName(ply:Nick())
			TargetPly:EnterVehicle(Box.Pod)
			---
			sound.Play("snd_jack_flyby_drop.ogg", DropPos, 150, 100)

			for k, playa in pairs(ents.FindInSphere(DropPos, 6000)) do
				if playa:IsPlayer() then
					sound.Play("snd_jack_flyby_drop.ogg", playa:GetShootPos(), 50, 100)
				end
			end
		end)
	end
end, nil, "Airdrops specified player on specified location")

hook.Add("PlayerLeaveVehicle", "JMod_PlayerPackageExit", function( ply, veh )
	local Box = veh:GetParent()
	if (IsValid(Box)) and (Box:GetClass() == "ent_jack_aidbox") then
		ply:SetPos(Box:GetPos())
		Box:Use(ply)
		ply:SetNoDraw(false)
	end
end)

local function GetArticle(word)
	local FirstLetter = string.sub(word, 1, 1)

	if table.HasValue({"a", "e", "i", "o", "u"}, FirstLetter) then
		return "an"
	else
		return "a"
	end
end

local function GetTimeString(seconds)
	local Minutes, Seconds, Result = math.floor(seconds / 60), math.floor(seconds % 60), ""

	if Minutes > 0 then
		Result = Minutes .. " мин"

		if Seconds > 0 then
			Result = Result .. ", " .. Seconds .. " сек"
		end
	elseif Seconds > 0 then
		Result = Seconds .. " сек"
	end

	return Result
end

--[[
hook.Add("JMod_RadioDelivery","jackatest",function(owner,radio,package,tiem,pos)
	return 4,pos
end)
--]]
local function StartDelivery(pkg, transceiver, id, bff, ply)
	local Station = JMod.EZ_RADIO_STATIONS[id]
	Station.lastCaller = transceiver
	local Time = CurTime()
	local DeliveryTime, Pos = math.ceil(JMod.Config.RadioSpecs.DeliveryTimeMult * math.Rand(30, 60)), ply:GetPos()
	local newTime, newPos = hook.Run("JMod_RadioDelivery", ply, transceiver, pkg, DeliveryTime, Pos)
	DeliveryTime = newTime or DeliveryTime
	Pos = newPos or Pos
	JMod.Hint(ply, "aid wait")
	Station.state = JMod.EZ_STATION_STATE_DELIVERING
	Station.nextDeliveryTime = Time + DeliveryTime
	Station.deliveryLocation = Pos
	Station.deliveryType = pkg
	Station.notified = false
	Station.nextNotifyTime = Time + (DeliveryTime - 5)
	JMod.NotifyAllRadios(id) -- do a notify to update all radio states
	if bff then return "АЛО, ПОНЯТНО, ОТПРАВЛЯЕМ  " .. GetArticle(pkg) .. " " .. pkg .. " КОРОБКА ПРЯМО В " .. math.Round(Pos.x) .. " " .. math.Round(Pos.y) .. " " .. math.Round(Pos.z) .. " ГДЕТ ЧРЗ " .. DeliveryTime .. " СЕК" end

	return "аська, отправляем " .. GetArticle(pkg) .. " " .. pkg .. " пакет к координатам " .. math.Round(Pos.x) .. ", " .. math.Round(Pos.z) .. "; РВП " .. DeliveryTime .. " секунд"
end

function JMod.EZradioRequest(transceiver, id, ply, pkg, bff)
	local PackageInfo, Station, Time = JMod.Config.RadioSpecs.AvailablePackages[pkg], JMod.EZ_RADIO_STATIONS[id], CurTime()
	if not Station then return end
	JMod.NotifyAllRadios(id) -- do a notify to update all radio states
	transceiver.BFFd = bff
	local override, msg = hook.Run("JMod_CanRadioRequest", ply, transceiver, pkg)
	if override == false then return msg or "отрицательный ответ на этот запрос." end

	if Station.state == JMod.EZ_STATION_STATE_DELIVERING then
		if bff then return "Не получится, бро, мы доставляем кое-что другое." end

		return "В настоящее время мы доставляем еще одну посылку по этому запросу."
	elseif Station.state == JMod.EZ_STATION_STATE_BUSY then
		if bff then return "Мех мы яще не готовы попробуйтен через... пАтом" end

		return "отрицательный ответ на этот запрос, команда доставки в настоящее время не находится на станции"
	elseif Station.state == JMod.EZ_STATION_STATE_READY then
		if table.HasValue(JMod.Config.RadioSpecs.RestrictedPackages, pkg) then
			if not JMod.Config.RadioSpecs.RestrictedPackagesAllowed then
				if bff then
					return "Не могу. Штаб-квартира сухая, как и мы."
				else
					return "Отрицательный ответ на этот запрос, ни у нас, ни у регионального штаба на данный момент ничего подобного нет."
				end
			end

			if table.HasValue(Station.restrictedPackageStock, pkg) then
				table.RemoveByValue(Station.restrictedPackageStock, pkg)

				return StartDelivery(pkg, transceiver, id, bff, ply)
			else
				if Station.restrictedPackageDelivering then
					if bff then
						return "Чувак, штаб-квартира занята другим специальным грузом, тебе придется подождать еще немного."
					else
						return "По этому запросу у нас нет ничего подобного на складе, и в настоящее время штаб-квартира доставляет еще одну специальную партию."
					end
				else
					Station.restrictedPackageDelivering = pkg
					local DeliveryTime = JMod.Config.RadioSpecs.RestrictedPackageShipTime * math.Rand(.8, 1.2)
					Station.restrictedPackageDeliveryTime = Time + DeliveryTime

					if bff then
						return "приятель, мы доставим вам специальную посылку прямо из штаб-квартиры. Дайте нам " .. GetTimeString(DeliveryTime) .. " оке?"
					else
						return "Так точно, у нас нет этого на складе, но мы заказали его в региональной штаб-квартире, он будет на этом форпосте в " .. GetTimeString(DeliveryTime)
					end
				end
			end
		else
			return StartDelivery(pkg, transceiver, id, bff, ply)
		end
	end
end


function JMod.EZradioStatus(transceiver, id, ply, bff)
	local Station, Time, Msg = JMod.EZ_RADIO_STATIONS[id], CurTime(), ""
	if not Station then return end
	JMod.NotifyAllRadios(id) -- do a notify to update all radio states
	transceiver.BFFd = bff

	if Station.state == JMod.EZ_STATION_STATE_DELIVERING then
		Msg = "этот форпост в настоящее время доставляет посылку"

		if bff then
			Msg = "Хей, мы получаем кое-что для кого-то другого прямо сейчас."
		end
	elseif Station.state == JMod.EZ_STATION_STATE_BUSY then
		Msg = "В настоящее время этот форпост готовится к поставкам"

		if bff then
			Msg = "Эй, дружище, мы сейчас очень заняты, просто задержись."
		end
	elseif Station.state == JMod.EZ_STATION_STATE_READY then
		Msg = "этот форпост готов принять задания по доставке грузов"

		if bff then
			Msg = "ВСО ЧТО ТЕБЕ НУЖН - НАХОДИТСЯ У НАС"
		end
	end

	if #Station.restrictedPackageStock > 0 then
		local InventoryList = ""

		for k, v in pairs(Station.restrictedPackageStock) do
			InventoryList = InventoryList .. v .. ", "
		end

		Msg = Msg .. ", и имеет специальный запас " .. InventoryList
	end

	if Station.restrictedPackageDelivering then
		Msg = Msg .. ", и имеет специальную доставку " .. Station.restrictedPackageDelivering .. " прибывает из регионального штаба в " .. GetTimeString(Station.restrictedPackageDeliveryTime - Time)
	end

	return Msg
end
