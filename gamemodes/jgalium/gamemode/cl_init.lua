
--[[---------------------------------------------------------

  Sandbox Gamemode

  This is GMod's default gamemode

-----------------------------------------------------------]]

include( 'shared.lua' )
include( 'cl_spawnmenu.lua' )
include( 'cl_notice.lua' )
include( 'cl_hints.lua' )
include( 'cl_worldtips.lua' )
include( 'cl_search_models.lua' )
include( 'gui/IconEditor.lua' )

--
-- Make BaseClass available
--
DEFINE_BASECLASS( "gamemode_base" )


local physgun_halo = CreateConVar( "physgun_halo", "1", { FCVAR_ARCHIVE }, "Draw the physics gun halo?" )

function GM:Initialize()

	BaseClass.Initialize( self )
	
end

function GM:LimitHit( name )

	self:AddNotify( "#SBoxLimit_"..name, NOTIFY_ERROR, 6 )
	surface.PlaySound( "buttons/button10.wav" )

end

function GM:OnUndo( name, strCustomString )
	
	if ( !strCustomString ) then
		self:AddNotify( "#Undone_"..name, NOTIFY_UNDO, 2 )
	else	
		self:AddNotify( strCustomString, NOTIFY_UNDO, 2 )
	end
	
	-- Find a better sound :X
	surface.PlaySound( "buttons/button15.wav" )

end

function GM:OnCleanup( name )

	self:AddNotify( "#Cleaned_"..name, NOTIFY_CLEANUP, 5 )
	
	-- Find a better sound :X
	surface.PlaySound( "buttons/button15.wav" )

end

function GM:UnfrozeObjects( num )

	self:AddNotify( "Unfroze "..num.." Objects", NOTIFY_GENERIC, 3 )
	
	-- Find a better sound :X
	surface.PlaySound( "npc/roller/mine/rmine_chirp_answer1.wav" )

end

--[[---------------------------------------------------------
	Draws on top of VGUI..
-----------------------------------------------------------]]
function GM:PostRenderVGUI()

	BaseClass.PostRenderVGUI( self )

end

local PhysgunHalos = {}

--[[---------------------------------------------------------
   Name: gamemode:DrawPhysgunBeam()
   Desc: Return false to override completely
-----------------------------------------------------------]]
function GM:DrawPhysgunBeam( ply, weapon, bOn, target, boneid, pos )

	if ( physgun_halo:GetInt() == 0 ) then return true end

	if ( IsValid( target ) ) then
		PhysgunHalos[ ply ] = target
	end
	
	return true

end

hook.Add( "PreDrawHalos", "AddPhysgunHalos", function()

	if ( !PhysgunHalos || table.Count( PhysgunHalos ) == 0 ) then return end


	for k, v in pairs( PhysgunHalos ) do

		if ( !IsValid( k ) ) then continue end

		local size = math.random( 1, 2 )
		local colr = k:GetWeaponColor() + VectorRand() * 0.3
		 
		halo.Add( PhysgunHalos, Color( colr.x * 255, colr.y * 255, colr.z * 255 ), size, size, 1, true, false )
		
	end
	
	PhysgunHalos = {}

end )


--[[---------------------------------------------------------
   Name: gamemode:NetworkEntityCreated()
   Desc: Entity is created over the network
-----------------------------------------------------------]]
function GM:NetworkEntityCreated( ent )

	--
	-- If the entity wants to use a spawn effect
	-- then create a propspawn effect if the entity was
	-- created within the last second (this function gets called
	-- on every entity when joining a server)
	--

	if ( ent:GetSpawnEffect() && ent:GetCreationTime() > (CurTime() - 1.0) ) then
	
		local ed = EffectData()
			ed:SetEntity( ent )
		util.Effect( "propspawn", ed, true, true )

	end

end

function GM:ContextMenuOpen()
	if LocalPlayer():IsAdmin() then return true end
end

net.Receive("surfacePlaySound", function(_)
	surface.PlaySound(net.ReadString())
end)

local translucent = Color(0,0,0,0)
net.Receive("initHUD", function()
	local Panel = vgui.Create( "DFrame" )
	Panel:SetPos( ScrW()*.8, ScrH()*.05 )
	Panel:SetSize( ScrW()/2, ScrH()/2 )
	Panel:SetTitle("")
	Panel:ShowCloseButton(false)
	Panel:SetSizable(false)
	Panel:SetDraggable(false)

	Panel.Paint = function(s,w,h)
		draw.RoundedBox(0, 0, 0, w, h, translucent)
	end

	Avatar_Judge = vgui.Create( "AvatarImage", Panel )
	Avatar_Judge:SetSize( ScrW()/30, ScrW()/30 )
	Avatar_Judge:SetPos( ScrW()/14.5, ScrH()/7 )
	Avatar_Judge:SetPlayer( LocalPlayer(), 64 )

	Avatar_PO = vgui.Create( "AvatarImage", Panel )
	Avatar_PO:SetSize( ScrW()/30, ScrW()/30 )
	Avatar_PO:SetPos( ScrW()*.12, ScrH()/3 )
	Avatar_PO:SetPlayer( LocalPlayer(), 64 )

	Avatar_OP = vgui.Create( "AvatarImage", Panel )
	Avatar_OP:SetSize( ScrW()/30, ScrW()/30 )
	Avatar_OP:SetPos( ScrW()*.02, ScrH()/3 )
	Avatar_OP:SetPlayer( LocalPlayer(), 64 )
end)

surface.CreateFont("JGCaseFont", {
	font = "Arial",
	extended = true,
	size = 20,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true
})

surface.CreateFont("JGCaseFont_Blur", {
	font = "Arial",
	extended = true,
	size = 20,
	weight = 500,
	blursize = 4,
	scanlines = 0,
	antialias = true
})

local bg_Color = Color(0, 0, 0, 200)
hook.Add("HUDPaint", "JGHUD", function()
	if IsValid(LocalPlayer()) then
		draw.RoundedBox(30, ScrW()*.8, ScrH()*.05, ScrW()*.17, ScrH()*.4, bg_Color)
		draw.DrawText(GetGlobalString("m_CaseName", "untitled"), "JGCaseFont", ScrW()*.885, ScrH()*.06, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
		draw.DrawText(GetGlobalString("m_CaseName", "untitled"), "JGCaseFont_Blur", ScrW()*.885, ScrH()*.06, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)

		draw.DrawText("Судья:", "JGCaseFont", ScrW()*.885, ScrH()*.14, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
		draw.DrawText("Судья:", "JGCaseFont_Blur", ScrW()*.885, ScrH()*.14, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)

		draw.DrawText(GetGlobalString("m_JudgeName", "untitled"), "JGCaseFont", ScrW()*.885, ScrH()*.165, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
		draw.DrawText(GetGlobalString("m_JudgeName", "untitled"), "JGCaseFont_Blur", ScrW()*.885, ScrH()*.165, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)

		draw.DrawText("Позиция:", "JGCaseFont", ScrW()*.836, ScrH()*.325, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
		draw.DrawText("Позиция:", "JGCaseFont_Blur", ScrW()*.836, ScrH()*.325, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)

		draw.DrawText(GetGlobalString("m_poName", "untitled"), "JGCaseFont", ScrW()*.836, ScrH()*.35, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
		draw.DrawText(GetGlobalString("m_poName", "untitled"), "JGCaseFont_Blur", ScrW()*.836, ScrH()*.35, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)

		draw.DrawText("Оппозиция:", "JGCaseFont", ScrW()*.935, ScrH()*.325, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
		draw.DrawText("Оппозиция:", "JGCaseFont_Blur", ScrW()*.935, ScrH()*.325, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)

		draw.DrawText(GetGlobalString("m_opName", "untitled"), "JGCaseFont", ScrW()*.935, ScrH()*.35, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
		draw.DrawText(GetGlobalString("m_opName", "untitled"), "JGCaseFont_Blur", ScrW()*.935, ScrH()*.35, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)

		--init avatars
		Avatar_Judge:SetPlayer(GetGlobalEntity("m_Judge", nil), 128)
		Avatar_PO:SetPlayer(GetGlobalEntity("m_op", nil), 128)
		Avatar_OP:SetPlayer(GetGlobalEntity("m_po", nil), 128)
	end
end)