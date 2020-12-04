--[[---------------------------------------------------------

  Sandbox Gamemode

  This is GMod's default gamemode

-----------------------------------------------------------]]

-- These files get sent to the client

AddCSLuaFile( "cl_hints.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_notice.lua" )
AddCSLuaFile( "cl_search_models.lua" )
AddCSLuaFile( "cl_spawnmenu.lua" )
AddCSLuaFile( "cl_worldtips.lua" )
AddCSLuaFile( "persistence.lua" )
AddCSLuaFile( "player_extension.lua" )
AddCSLuaFile( "save_load.lua" )
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "gui/IconEditor.lua" )

include( 'shared.lua' )
include( 'commands.lua' )
include( 'player.lua' )
include( 'spawnmenu/init.lua' )

--
-- Make BaseClass available
--
DEFINE_BASECLASS( "gamemode_base" )

function GM:PlayerSpray(pl)
	return pl:IsAdmin() or false
end

function GM:PlayerShouldTaunt(pl, act)
	return false
end

local spawnpoints = {
	Vector(2044.438354, -3303.602539, 576.031250),
	Vector(2044.646484, -3246.735107, 576.031250),
	Vector(2045.101807, -3195.870117, 576.031250)
}

hook.Add("PlayerSpawn", "JGPlayerSpawn", function(pl)
	if IsValid(pl) then
		pl:SetPos(table.Random(spawnpoints))
		pl:SetRunSpeed(100)
		pl:SetWalkSpeed(100)
	end
end)

hook.Add( "ShouldCollide", "CustomCollisions", function( ent1, ent2 )
    if ( ent1:IsPlayer() and ent2:IsPlayer() ) then return false end
end )

util.AddNetworkString("initHUD")
hook.Add("PlayerInitialSpawn", "JGPlayerInitialSpawn", function(pl)
	if IsValid(pl) then
		pl:SetPos(table.Random(spawnpoints))
		pl:SetRunSpeed(100)
		pl:SetWalkSpeed(100)
		net.Start("initHUD")
		net.Send(pl)
	end
end)

hook.Add("Think", "OffPlayerCollide", function()
	for k, v in ipairs(ents.FindByClass("player")) do
		v:SetCustomCollisionCheck(true)
		v:CollisionRulesChanged()
	end
end)

local msgs = {
	"Иди обратно в суд",
	"Эрик ждёт когда ты будешь сидеть у кресла",
	"Ничего не получится"
}

util.AddNetworkString("surfacePlaySound")
hook.Add("Think", "JGPlayerPostThink", function(pl)
	for k, v in ipairs(ents.FindInBox(Vector(2063.088867, -3720.988281, 768.031250), Vector(1973.026245, -3657.031250, 900.531250))) do
		if v:IsPlayer() then
			v:SetPos(table.Random(spawnpoints))
			v:ChatPrint(msgs[math.random(1,#msgs)])
			v:ScreenFade(SCREENFADE.IN, Color( 255, 0, 0, 128 ), 0.3, 0)
			net.Start("surfacePlaySound")
				net.WriteString("ambient/levels/labs/teleport_weird_voices"..math.random(1,2)..".wav")
			net.Send(v)
		end
	end

	for k, v in ipairs(ents.FindInBox(Vector(1529.391357, -3352.990967, 576.031250), Vector(1427.150146, -3145.031250, 1000.031250))) do
		if v:IsPlayer() then
			v:SetPos(table.Random(spawnpoints))
			v:ChatPrint(msgs[math.random(1,#msgs)])
			v:ScreenFade(SCREENFADE.IN, Color( 255, 0, 0, 128 ), 0.3, 0)
			net.Start("surfacePlaySound")
				net.WriteString("ambient/levels/labs/teleport_weird_voices"..math.random(1,2)..".wav")
			net.Send(v)
		end
	end
end)

hook.Add("InitPostEntity", "JBInitPostEntity", function()
	for k, v in ipairs(ents.FindByClass("func_door_rotating")) do
		v:Fire("close")
		v:Fire("lock")
	end

	timer.Simple(1, function()
		game.ConsoleCommand("sv_alltalk 3\n")
	end)
end)

--[[---------------------------------------------------------
   Name: gamemode:PlayerSpawn( )
   Desc: Called when a player spawns
-----------------------------------------------------------]]
function GM:PlayerSpawn( pl )

	player_manager.SetPlayerClass( pl, "player_gamemode" )

	BaseClass.PlayerSpawn( self, pl )
	
end


--[[---------------------------------------------------------
   Name: gamemode:OnPhysgunFreeze( weapon, phys, ent, player )
   Desc: The physgun wants to freeze a prop
-----------------------------------------------------------]]
function GM:OnPhysgunFreeze( weapon, phys, ent, ply )
	
	-- Don't freeze persistent props (should already be froze)
	if ( ent:GetPersistent() ) then return false end

	BaseClass.OnPhysgunFreeze( self, weapon, phys, ent, ply )

	ply:SendHint( "PhysgunUnfreeze", 0.3 )
	ply:SuppressHint( "PhysgunFreeze" )
	
end


--[[---------------------------------------------------------
   Name: gamemode:OnPhysgunReload( weapon, player )
   Desc: The physgun wants to unfreeze
-----------------------------------------------------------]]
function GM:OnPhysgunReload( weapon, ply )

	local num = ply:PhysgunUnfreeze()
	
	if ( num > 0 ) then
		ply:SendLua( "GAMEMODE:UnfrozeObjects("..num..")" )
	end

	ply:SuppressHint( "PhysgunReload" )

end


--[[---------------------------------------------------------
   Name: gamemode:PlayerShouldTakeDamage
   Return true if this player should take damage from this attacker
   Note: This is a shared function - the client will think they can 
	 damage the players even though they can't. This just means the 
	 prediction will show blood.
-----------------------------------------------------------]]
function GM:PlayerShouldTakeDamage( ply, attacker )

	-- The player should always take damage in single player..
	if ( game.SinglePlayer() ) then return true end

	-- Global godmode, players can't be damaged in any way
	if ( cvars.Bool( "sbox_godmode", false ) ) then return false end

	-- No player vs player damage
	if ( attacker:IsValid() && attacker:IsPlayer() ) then
		return cvars.Bool( "sbox_playershurtplayers", true )
	end
	
	-- Default, let the player be hurt
	return true

end


--[[---------------------------------------------------------
   Show the search when f1 is pressed
-----------------------------------------------------------]]
function GM:ShowHelp( ply )

	ply:SendLua( "hook.Run( 'StartSearch' )" );
	
end


--[[---------------------------------------------------------
   Called once on the player's first spawn
-----------------------------------------------------------]]
function GM:PlayerInitialSpawn( ply )

	BaseClass.PlayerInitialSpawn( self, ply )
	
end


--[[---------------------------------------------------------
   Desc: A ragdoll of an entity has been created
-----------------------------------------------------------]]
function GM:CreateEntityRagdoll( entity, ragdoll )

	-- Replace the entity with the ragdoll in cleanups etc
	undo.ReplaceEntity( entity, ragdoll )
	cleanup.ReplaceEntity( entity, ragdoll )
	
end


--[[---------------------------------------------------------
   Name: gamemode:PlayerUnfrozeObject( )
-----------------------------------------------------------]]
function GM:PlayerUnfrozeObject( ply, entity, physobject )

	local effectdata = EffectData()
		effectdata:SetOrigin( physobject:GetPos() )
		effectdata:SetEntity( entity )
	util.Effect( "phys_unfreeze", effectdata, true, true )	
	
end


--[[---------------------------------------------------------
   Name: gamemode:PlayerFrozeObject( )
-----------------------------------------------------------]]
function GM:PlayerFrozeObject( ply, entity, physobject )

	if ( DisablePropCreateEffect ) then return end
	
	local effectdata = EffectData()
		effectdata:SetOrigin( physobject:GetPos() )
		effectdata:SetEntity( entity )
	util.Effect( "phys_freeze", effectdata, true, true )	
	
end


--
-- Who can edit variables?
-- If you're writing prop protection or something, you'll
-- probably want to hook or override this function.
--
function GM:CanEditVariable( ent, ply, key, val, editor )

	-- Only allow admins to edit admin only variables!
	if ( editor.AdminOnly ) then
		return ply:IsAdmin()
	end

	-- This entity decides who can edit its variables
	if ( isfunction( ent.CanEditVariables ) ) then
		return ent:CanEditVariables( ply )
	end

	-- default in sandbox is.. anyone can edit anything.
	return true

end

concommand.Add("_t", function(pl, cmd, args)
	if IsValid(pl) then
		if args[1] then
			SetGlobalString("m_CaseName", tostring(args[1]))
			SetGlobalEntity("m_Judge", pl)
			SetGlobalString("m_JudgeName", pl:Name())

			net.Start("surfacePlaySound")
				net.WriteString("ambient/alarms/warningbell1.wav")
			net.Broadcast()

			pl:SetTeam(TEAM_JUDGE)
			pl:SetModel("models/player/breen.mdl")
			pl:SetPlayerColor(Vector(0.8, 0.8, 0.8))

			concommand.Remove("_t")
		else
			pl:ChatPrint("Напишите название кейса в кавычках!")
		end
	end
end)

concommand.Add("_op", function(pl, cmd, args)
	if IsValid(pl) and pl:Team() == TEAM_JUDGE then
		if args[1] then
			for k, v in ipairs(player.GetAll()) do
				if v:Name():find(args[1]) then
					SetGlobalEntity("m_op", v)
					SetGlobalString("m_opName", v:Name())

					net.Start("surfacePlaySound")
						net.WriteString("ambient/alarms/warningbell1.wav")
					net.Broadcast()

					v:SetTeam(TEAM_OP)
					v:SetModel("models/player/Group01/male_07.mdl")
					v:SetPlayerColor(Vector(0.8, 0.4, 0.4))

					concommand.Remove("_op")
				end
			end
		else
			pl:ChatPrint("Напишите ник игрока в кавычках!")
		end
	end
end)

concommand.Add("_po", function(pl, cmd, args)
	if IsValid(pl) and pl:Team() == TEAM_JUDGE then
		if args[1] then
			for k, v in ipairs(player.GetAll()) do
				if v:Name():find(args[1]) then
					SetGlobalEntity("m_po", v)
					SetGlobalString("m_poName", v:Name())

					net.Start("surfacePlaySound")
						net.WriteString("ambient/alarms/warningbell1.wav")
					net.Broadcast()

					v:SetTeam(TEAM_PO)
					v:SetModel("models/player/Group01/male_07.mdl")
					v:SetPlayerColor(Vector(0.4, 0.4, 0.8))

					concommand.Remove("_po")
				end
			end
		else
			pl:ChatPrint("Напишите ник игрока в кавычках!")
		end
	end
end)

concommand.Add("_ban", function(pl, cmd, args)
	if IsValid(pl) and pl:IsAdmin() then
		if args[1] then
			for k, v in ipairs(player.GetAll()) do
				if v:Name():find(args[1]) then
					v:Ban(5, false)
					v:Kick("Access Restrict")
				end
			end
		else
			pl:ChatPrint("Напишите ник игрока в кавычках!")
		end
	end
end)