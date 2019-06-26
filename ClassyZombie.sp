/*
TODO: Have you tried returning Plugin_Handled in TraceAttack hook? As far as I know bullets will not deal damage/even hit player.
Or you can try to ShouldCollide hook, check for MASK_SHOT collision group (or whatever its called) and return result to 'true' or 'false'.

자살 방지
*/
/*
mp_ignore_round_win_conditions 
*/
#pragma semicolon 1

#define PLUGIN_AUTHOR "Trostal (Originally designed by Nika)"
#define PLUGIN_VERSION "0.10a"

#define PREFIX "\x01\x04[SM] - "

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <emitsoundany>
#include <scp>
#include <CustomPlayerSkins>

#include <dds>

public Plugin myinfo = 
{
	name = "Classy Zombie",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};


#include "ClassyZombie/definition.sp"
#include "ClassyZombie/files.sp"
#include "ClassyZombie/db.sp"
#include "ClassyZombie/roundtime.sp"
#include "ClassyZombie/basic.sp"
#include "ClassyZombie/client.sp"
#include "ClassyZombie/skill.sp"
#include "ClassyZombie/itemevent.sp"
#include "ClassyZombie/events.sp"
#include "ClassyZombie/classweapon.sp"
#include "ClassyZombie/menu.sp"
#include "ClassyZombie/items.sp"
#include "ClassyZombie/party.sp"
#include "ClassyZombie/parachute.sp"

public void OnPluginStart()
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] OnPluginStart()");
	#endif
	
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
	{
		SetFailState("This plugin can run on CS:GO servers only.");
	}
	
	//classweapon.sp
	AddingWeapon();
	SetEvents();
	SetCommands();
	
	g_offsPunchAngleVel = FindSendPropInfo("CBasePlayer", "m_aimPunchAngleVel");
	g_offsCollision = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	
	DB_OnPluginStart();
	
	Party_OnPluginStart();
	
	Para_OnPluginStart();

	HookUserMessage(GetUserMessageId("TextMsg"), BlockWarmupNoticeTextMsg, true);
}

void SetEvents()
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] SetEvents()");
	#endif
	
	// 팀 자동 조인 해제용
	HookEvent("player_connect_full", Event_OnFullConnect, EventHookMode_Pre);
	
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_team", OnPlayerJoinedTeamPre, EventHookMode_Pre);
	HookEvent("player_team", OnPlayerJoinedTeam);
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_freeze_end", OnRoundFreezeTimeEnd);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("bullet_impact", OnBulletImpact);
	HookEvent("weapon_fire", OnWeaponFire);
	
	HookUserMessage(GetUserMessageId("TextMsg"), BlockWarmupNoticeTextMsg, true);
	
	AddNormalSoundHook(OnNormalSoundEmit);
}

void SetCommands()
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] SetCommands()");
	#endif
	
	AddCommandListener(OnClientChat, "say");
	AddCommandListener(OnClientChat, "say_team");
	AddCommandListener(OnClientJoinTeam, "jointeam");
	
	AddCommandListener(OnF3Command, "autobuy");
	AddCommandListener(OnF4Command, "rebuy");
	
	AddCommandListener(OnCommaCommand, "buyammo1");
	AddCommandListener(OnPeriodCommand, "buyammo2");
	AddCommandListener(OnKButtonCommand, "+lookatweapon");
	
//	AddCommandListener(OnMButtonCommand, "teammenu");
	
	AddCommandListener(OnSuicideCommand, "kill");
	AddCommandListener(OnSuicideCommand, "explode");
	
	RegConsoleCmd("sm_class", Cmd_ClassMenu, "클래스 메뉴를 엽니다.");
	RegConsoleCmd("sm_level", Cmd_ClassLevel, "클래스 레벨 메뉴를 엽니다.");
	RegConsoleCmd("sm_party", Cmd_PartyMenu, "파티 메뉴를 엽니다.");
	RegConsoleCmd("sm_weapon", Cmd_WeaponMenu, "무기 상점 메뉴를 엽니다.");
	RegConsoleCmd("sm_load", Cmd_LoadUserData, "유저 데이터를 수동으로 불러옵니다.");
	RegConsoleCmd("sm_shop", Cmd_OpenShopMain, "상점 메인 메뉴를 엽니다.");
	RegConsoleCmd("sm_box", Cmd_CrateInventoryMenu, "상자 인벤토리 메뉴를 엽니다.");
	
	// 인칭 명령어
	RegConsoleCmd("sm_1", Cmd_FirstPerson, "1인칭 화면으로 전환합니다.");
	RegConsoleCmd("sm_3", Cmd_ThirdPerson, "3인칭 화면으로 전환합니다.");	
	
	// 아이템 명령어
	RegConsoleCmd("sm_rocket", Cmd_UseRocketItem, "나로호 아이템 사용.");
	RegConsoleCmd("sm_naroho", Cmd_UseRocketItem, "나로호 아이템 사용.");
	
	RegConsoleCmd("sm_sentry", Cmd_UseSentryGunItem, "센트리건 아이템 사용.");
	RegConsoleCmd("sm_chicken", Cmd_UseSentryGunItem, "센트리건 아이템 사용.");
	RegConsoleCmd("sm_sentrygun", Cmd_UseSentryGunItem, "센트리건 아이템 사용.");
}

public void SetConVars(any data)
{
	/*	
	Locked Cvar: sv_pushaway_clientside - Clientside physics push away (0=off, 1=only localplayer, 1=all players)
	Locked Cvar: sv_pushaway_clientside_size - Minimum size of pushback objects
	Locked Cvar: sv_pushaway_force - How hard physics objects are pushed away from the players on the server.
	Locked Cvar: sv_pushaway_max_force - Maximum amount of force applied to physics objects by players.
	Locked Cvar: sv_pushaway_max_player_force - Maximum of how hard the player is pushed away from physics objects.
	Locked Cvar: sv_pushaway_min_player_speed - If a player is moving slower than this, don't push away physics objects (enables ducking behind things).
	Locked Cvar: sv_pushaway_player_force - How hard the player is pushed away from physics objects (falls off with inverse square of distance).
	*/
	SetConVarInt(FindConVar("mp_roundtime"), 6);
	
	SetConVarInt(FindConVar("mp_playerid"), 0);
	SetConVarInt(FindConVar("mp_friendlyfire"), 0);
	SetConVarInt(FindConVar("mp_free_armor"), 0);
	SetConVarInt(FindConVar("mp_autoteambalance"), 0);
	SetConVarInt(FindConVar("sv_ignoregrenaderadio"), 0);
	
	SetConVarInt(FindConVar("sv_allow_thirdperson"), 1);
	SetConVarInt(FindConVar("mp_solid_teammates"), 1);
	
	// 팀메뉴 띄우기 방지
//	SetConVarInt(FindConVar("sv_disable_show_team_select_menu"), 1);
	
	SetConVarInt(FindConVar("mp_forcecamera"), 0);
	SetConVarInt(FindConVar("sv_alltalk"), 1);
	SetConVarInt(FindConVar("sv_full_alltalk"), 1);
	SetConVarInt(FindConVar("sv_deadtalk"), 1);
	
	
	SetConVarInt(FindConVar("sv_show_voip_indicator_for_enemies"), 0); // 1일 시, 보이스 사용할 때 상대편 머리위에도 마이크 아이콘 표시

	// 프롭 밀기 관련
	SetConVarInt(FindConVar("sv_turbophysics"), 1);
	SetConVarInt(FindConVar("phys_pushscale"), 3); // 공격시 프롭 미는 힘
	SetConVarInt(FindConVar("sv_pushaway_force"), 30000); // 미는 힘
	SetConVarInt(FindConVar("sv_pushaway_max_force"), 2500); // 이게 중요!: 물체가 최대로 받을 수 있는 힘 양
	
	// 프롭 몸으로 밀기(?) 관련
//	SetConVarInt(FindConVar("sv_pushaway_min_player_speed"), 75);
	
	// 아래 두개가 0이면 돈 표시가 안뜸
	SetConVarInt(FindConVar("mp_playercashawards"), 1);
	SetConVarInt(FindConVar("mp_teamcashawards"), 1);
	
	// 무기 관련
	SetConVarString(FindConVar("mp_t_default_secondary"), ""); // 기본 권총을 없앰
	SetConVarString(FindConVar("mp_ct_default_secondary"), ""); // 기본 권총을 없앰
	SetConVarInt(FindConVar("mp_death_drop_gun"), 2);
	SetConVarInt(FindConVar("mp_weapons_allow_map_placed"), 1);
	SetConVarInt(FindConVar("weapon_reticle_knife_show"), 1); // 칼 든 상태에서 이름표 표시
	
	SetConVarInt(FindConVar("ammo_grenade_limit_default"), 2);
	SetConVarInt(FindConVar("ammo_grenade_limit_flashbang"), 0);
	SetConVarInt(FindConVar("ammo_grenade_limit_default"), 2);
	
	SetConVarInt(FindConVar("ammo_338mag_max"), 999);
	SetConVarInt(FindConVar("ammo_357sig_max"), 999);
	SetConVarInt(FindConVar("ammo_357sig_min_max"), 999);
	SetConVarInt(FindConVar("ammo_357sig_p250_max"), 999);
	SetConVarInt(FindConVar("ammo_357sig_small_max"), 999);
	SetConVarInt(FindConVar("ammo_45acp_max"), 999);
	SetConVarInt(FindConVar("ammo_50AE_max"), 999);
	SetConVarInt(FindConVar("ammo_556mm_box_max"), 999);
	SetConVarInt(FindConVar("ammo_556mm_max"), 999);
	SetConVarInt(FindConVar("ammo_556mm_small_max"), 999);
	SetConVarInt(FindConVar("ammo_57mm_max"), 999);
	SetConVarInt(FindConVar("ammo_762mm_max"), 999);
	SetConVarInt(FindConVar("ammo_9mm_max"), 999);
	SetConVarInt(FindConVar("ammo_buckshot_max"), 999);
	
	SetConVarInt(FindConVar("mp_afterroundmoney"), 800);
	SetConVarInt(FindConVar("mp_startmoney"), 800);
	
	SetConVarInt(FindConVar("cash_player_bomb_defused"), 0);
	SetConVarInt(FindConVar("cash_player_bomb_planted"), 0);
	SetConVarInt(FindConVar("cash_player_damage_hostage"), 0);
	SetConVarInt(FindConVar("cash_player_interact_with_hostage"), 0);
	SetConVarInt(FindConVar("cash_player_killed_enemy_default"), 0);
	SetConVarInt(FindConVar("cash_player_killed_enemy_factor"), 0);
	SetConVarInt(FindConVar("cash_player_killed_hostage"), 0);
	SetConVarInt(FindConVar("cash_player_killed_teammate"), 0);
	SetConVarInt(FindConVar("cash_player_rescued_hostage"), 0);
	SetConVarInt(FindConVar("cash_team_elimination_bomb_map"), 0);
	SetConVarInt(FindConVar("cash_team_elimination_hostage_map_t"), 0);
	SetConVarInt(FindConVar("cash_team_elimination_hostage_map_ct"), 0);
	SetConVarInt(FindConVar("cash_team_hostage_alive"), 0);
	SetConVarInt(FindConVar("cash_team_hostage_interaction"), 0);
	SetConVarInt(FindConVar("cash_team_loser_bonus"), 0);
	SetConVarInt(FindConVar("cash_team_loser_bonus_consecutive_rounds"), 0);
	SetConVarInt(FindConVar("cash_team_planted_bomb_but_defused"), 0);
	SetConVarInt(FindConVar("cash_team_rescued_hostage"), 0);
	SetConVarInt(FindConVar("cash_team_terrorist_win_bomb"), 0);
	SetConVarInt(FindConVar("cash_team_win_by_defusing_bomb"), 0);
	SetConVarInt(FindConVar("cash_team_win_by_hostage_rescue"), 0);
	SetConVarInt(FindConVar("cash_team_win_by_time_running_out_hostage"), 0);
	SetConVarInt(FindConVar("cash_team_win_by_time_running_out_bomb"), 0);
}

void SetGame(int retryCount=0)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] SetGame(%i)", retryCount);
	#endif
	
	g_flHostZombieSkillTimer = 0.0;
	g_flGasZombieSkillTimer = 0.0;
	g_flJumpZombieSkillTimer = 0.0;
	g_iJumpZombie = 0;
	g_iGasZombie = 0;
	
	if (IsWarmupPeriod() || g_bRoundEnded)	return;
	
	CheckTeamAliveCounter();
	if(IsValidPlayer(g_iHostZombie))
	{		
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsValidPlayer(i) && i != g_iHostZombie)
			{
				CS_SwitchTeam(i, CS_TEAM_CT);
			}
		}
		CheckTeamAliveCounter(false);
		
		MakeClientZombie(g_iHostZombie, _, true);
		
		PrintCenterTextAll("좀비 바이러스가 발병했습니다!\n<font color='#ff3f3f'>%N</font>님이 숙주입니다!", g_iHostZombie);
		
		if (bItemEvent_Active)
		{
			if(iItemEvent_Condition == 2 || iItemEvent_Condition == 3)
			{
				ItemEvent_EventOccurToTarget(g_iHostZombie);
			}
		}
	}
	// 미리 선택된 좀비가 나가거나 한 경우.
	else
	{
		if(retryCount < 10)
		{
			SelectHostZombie();
			SetGame(retryCount+1);
		}
		else
		{
			CS_TerminateRound(3.0, CSRoundEnd_Draw);
		}
	}
	
	/*
	아래 초기화 코드를 위로 올리지 말 것,
	
	이 함수 블록의
	
	CheckTeamAliveCounter(false); 부분에서
	
	CheckTeamAliveCounter(true);로 할 시
	
	2명일 때 라운드가 끝나버린다.
	
	*/
	SetCanEndRound(true);
	
	g_bGameStarted = true;
	g_bHostSelectionTime = false;
}

int RandomVeteran()
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] RandomVeteran()");
	#endif
	
	int Veteran = GetRandomPlayer(CLIENTFILTER_INGAME | CLIENTFILTER_ALIVE | CLIENTFILTER_NOSPECTATORS | CLIENTFILTER_NOOBSERVERS);
	if(IsValidPlayer(Veteran))
	{
		if(g_iClassId[Veteran] != 7)
			g_iPendingClassId[Veteran] = g_iClassId[Veteran];
		g_iClassId[Veteran] = 7;
		
		SetEntityHealth(Veteran, 450);
		SetEntProp(Veteran, Prop_Data, "m_iMaxHealth", 450);
		
		SetEntPropFloat(Veteran, Prop_Data, "m_flLaggedMovementValue", 1.25);	
		SetEntityGravity(Veteran, 0.9);
				
		if(GetPlayerWeaponSlot(Veteran, CS_SLOT_PRIMARY) != -1)		RemovePlayerItem(Veteran, GetPlayerWeaponSlot(Veteran, CS_SLOT_PRIMARY));
		if(GetPlayerWeaponSlot(Veteran, CS_SLOT_SECONDARY) != -1)	RemovePlayerItem(Veteran, GetPlayerWeaponSlot(Veteran, CS_SLOT_SECONDARY));
				
		int weaponM249 = GivePlayerItem(Veteran, "weapon_m249");
		GivePlayerItem(Veteran, "weapon_elite");
		GivePlayerItem(Veteran, "weapon_hegrenade");
		
		if(IsValidEdict(weaponM249))
			SetWeaponReserveAmmo(Veteran, weaponM249, 750);
		
		SetEntProp(Veteran, Prop_Send, "m_iAccount", GetEntProp(Veteran, Prop_Send, "m_iStartAccount"));
		
		PrintToChatAll("%s\x03%N\x01 님이 이번 라운드의 베테랑입니다!!", PREFIX, Veteran);
		PrintCenterTextAll("<font color='#7f7fff'>%N</font> 님이 이번 라운드의 베테랑 입니다!!", Veteran);
		
		CancelClientMenu(Veteran);
		CleanClientArms(Veteran);
		
		char clanTag[sizeof(g_szConstClassName[])];
		clanTag = g_szConstClassName[g_iClassId[Veteran]];
		ReplaceString(clanTag, sizeof(clanTag), "성)", ")");
		CS_SetClientClanTag(Veteran, clanTag);
		
		if (bItemEvent_Active)
		{
			if(iItemEvent_Condition == 1 || iItemEvent_Condition == 3)
			{
				ItemEvent_EventOccurToTarget(Veteran);
			}
		}
	}
}

stock PrintCenterTextAdmin(bool forAdmin=true, const char[] format, any ...)
{	
	char buffer[192];

	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(forAdmin && !IsClientAdmin(i, Admin_Root))
			{
				continue;
			}
			else if(!forAdmin && IsClientAdmin(i, Admin_Root))
			{
				continue;
			}
			
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 3);
			PrintCenterText(i, "%s", buffer);
		}
	}
}

int SelectHostZombie(int retry=0)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] SelectHostZombie()");
	#endif
	
	g_iHostZombie = GetRandomPlayer(CLIENTFILTER_INGAME | CLIENTFILTER_ALIVE | CLIENTFILTER_NOSPECTATORS | CLIENTFILTER_NOOBSERVERS);
	
	if(IsValidClient(g_iHostZombie))
	{
		if(g_iClassId[g_iHostZombie] == 7 && retry < 10)
		{
			SelectHostZombie(retry+1);
			return -1;
		}
	}
	
	#if defined _DEBUG_
		PrintToChatAll("HOST ZOMBIE: %i", g_iHostZombie);
	#endif
	
	return g_iHostZombie;
}

void MakeClientZombie(int client, int attacker=-1, bool isHostZombie=false, bool checkTeamAliveCount=true)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] MakeClientZombie()");
	#endif
	
	if (!IsValidPlayer(client))	return;
	
	g_bIsZombie[client] = true;
	if(isHostZombie)
		SetClientArms(client, ARMS_HOST_ZOMBIE);
	else
		SetClientArms(client, ARMS_NORMAL_ZOMBIE);
	
	CS_SwitchTeam(client, CS_TEAM_T);
	RemoveGuns(client, true);
	int knife = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	HideWeaponWorldModel(knife);
	knife = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	HideWeaponWorldModel(knife);
	
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
	SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0);
	
	if(checkTeamAliveCount){
		// 팀 변경 이후에 체크하도록 한다!
		CheckTeamAliveCounter();
	}
	
	ShakeScreen(client, 5.0, 10.0, 10.0);
	
	//**좀비 관련 변수 초기화**//
	g_nZteleCount[client] = 3;
	g_flZombieRecoverTime[client] = 0.0;
	g_flZombieBlockTime[client] = 0.0;
	
	//**이동속도 초기화, 기본 1.2**//
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.2);
	SetEntityGravity(client, 0.90);
	
	int ZombieHealthToSet;
	
	if(isHostZombie)
	{	
		SetEntProp(client, Prop_Send, "m_iAccount", GetEntProp(client, Prop_Send, "m_iStartAccount"));
		g_flHostZombieSkillTimer = 0.0;
		
		PrintHintText(client, "<font color='#ff3f3f'>숙주 좀비</font>가 되었습니다!\n모든 인간을 감염시키십시오!");
		PrintToChatAll("%s\x03%N\x01 님이 숙주 좀비가 되었습니다!!", PREFIX, client);
		
		if(CPS_HasSkin(client))
		{
			CPS_RemoveSkin(client);
		}
		
		SetEntityModel(client, MODEL_HOST_ZOMBIE);
		EmitSoundToAllAny(SOUND_HOST_ZOMBIE_SPAWN, client, SNDCHAN_RELOAD_SOUND, _, _, _, _, _, _, _, true);

		ZombieHealthToSet = ZOMBIE_HEALTH_PER_HUMAN * g_nAliveCT;
		if(ZombieHealthToSet > ZOMBIE_MAX_HEALTH)
			ZombieHealthToSet = ZOMBIE_MAX_HEALTH;
		else if(ZombieHealthToSet <= 0)
			ZombieHealthToSet = ZOMBIE_HEALTH_PER_HUMAN;
			
		// 좀비의 체력 설정
		SetEntityHealth(client, ZombieHealthToSet);
		// 최대 체력을 한정한다.
		SetEntProp(client, Prop_Data, "m_iMaxHealth", ZombieHealthToSet);
		
		// 체력을 적게 주는 대신, 이동속도를 더 늘려준다, 인원이 너무 적을때를 대비한 숙주에게 주는 메리트.
		ValidateHostZombieMoveSpeed(client);
		
		
		// 가까이 있는 인간에게 가벼운 넉백을 주면서 바이러스를 침투시킨다.
		float vecHostZombieOrigin[3];
		GetClientAbsOrigin(client, vecHostZombieOrigin);
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidPlayer(i))
			{
				 if(!IsClientZombie(i))
				 {
				 	float vecHumanOrigin[3];
					GetClientAbsOrigin(i, vecHumanOrigin);
					float flDist = GetVectorDistance(vecHostZombieOrigin, vecHumanOrigin);
					 
					if(flDist <= 200)
					{
						MakeKnockBack(client, i, 350.0);
						PenetrateVirus(i, client);
					}
				}
			}
		}
		
		CS_SetClientClanTag(client, "숙주좀비");
	}
	else
	{
		/**************** 좀비가 된 인간에 대한 설정 ****************/
		// 실제 최대 인원을 구한다.
		int iMaxHumanPlayerCount = GetMaxHumanPlayers();
		
		if(IsValidPlayer(attacker))
		{
//			int iMaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
			int iCurrentHealth = GetClientHealth(attacker);
//			ZombieHealthToSet = iCurrentHealth * 2 / 3;
			
			if(g_nAliveCT >= (iMaxHumanPlayerCount * 1/2) /*+3 = 15*/ && iCurrentHealth * 2/3 < ZOMBIE_HEALTH_PER_HUMAN+(ZOMBIE_HEALTH_PER_HUMAN * 3/3))		ZombieHealthToSet = ZOMBIE_HEALTH_PER_HUMAN+(ZOMBIE_HEALTH_PER_HUMAN * 3/3);
			else if(g_nAliveCT >= (iMaxHumanPlayerCount * 1/2 * 2/3) /*+2 = 10*/  && iCurrentHealth * 2/3 < ZOMBIE_HEALTH_PER_HUMAN+(ZOMBIE_HEALTH_PER_HUMAN * 2/3))	ZombieHealthToSet = ZOMBIE_HEALTH_PER_HUMAN+(ZOMBIE_HEALTH_PER_HUMAN * 2/3);
			else if(g_nAliveCT >= (iMaxHumanPlayerCount * 1/2 * 1/3) /*+1 = 5*/ && iCurrentHealth * 2/3 < ZOMBIE_HEALTH_PER_HUMAN+(ZOMBIE_HEALTH_PER_HUMAN * 1/3))	ZombieHealthToSet = ZOMBIE_HEALTH_PER_HUMAN+(ZOMBIE_HEALTH_PER_HUMAN * 1/3);
			else if(iCurrentHealth *2/3 < ZOMBIE_HEALTH_PER_HUMAN)	ZombieHealthToSet = ZOMBIE_HEALTH_PER_HUMAN;
			else ZombieHealthToSet = ZOMBIE_HEALTH_PER_HUMAN;
			
		}
		else
		{
			if(g_nAliveCT >= iMaxHumanPlayerCount * 1/2)			ZombieHealthToSet = ZOMBIE_HEALTH_PER_HUMAN+(ZOMBIE_HEALTH_PER_HUMAN * 3/3);
			else if(g_nAliveCT >= iMaxHumanPlayerCount * 1/2 * 2/3)	ZombieHealthToSet = ZOMBIE_HEALTH_PER_HUMAN+(ZOMBIE_HEALTH_PER_HUMAN * 2/3);
			else if(g_nAliveCT >= iMaxHumanPlayerCount * 1/2 * 1/3)		ZombieHealthToSet = ZOMBIE_HEALTH_PER_HUMAN+(ZOMBIE_HEALTH_PER_HUMAN * 1/3);
			else ZombieHealthToSet = 	ZOMBIE_HEALTH_PER_HUMAN;
		}
		
		if(ZombieHealthToSet < 3000)
			ZombieHealthToSet = 3000;
		if(ZombieHealthToSet > 7000)
			ZombieHealthToSet = 7000;
		SetEntityHealth(client, ZombieHealthToSet);
		SetEntProp(client, Prop_Data, "m_iMaxHealth", ZombieHealthToSet);
		
		// TODO: MUST DO THIS SHIT LATER.
		
		int iSkinRandom;
		iSkinRandom = GetRandomInt(0, sizeof(CommonZombieModels)-1);
		if(CPS_HasSkin(client))
		{
			CPS_RemoveSkin(client);
		}
		
		SetEntityModel(client, CommonZombieModels[iSkinRandom]);
		EmitSoundToAllAny(SOUND_COMMON_ZOMBIE_SPAWN, client, SNDCHAN_RELOAD_SOUND, _, _, _, _, _, _, _, true);
		PrintHintText(client, "<font color='#ff3f3f'>좀비 바이러스가 온 몸을 지배합니다!\n모든 인간을 감염시키십시오!</font>");
		
		CS_SetClientClanTag(client, "좀비");
		
		/**************** 인간을 잡은 좀비에 대한 보상 ****************/
	  	// 좀비가 가질 수 있는 최대 체력을 넘지 않는 한, 인간을 잡을 때 마다 최대 체력이 ZOMBIE_HEAL_AMOUNT_PER_KILL값 만큼 늘어난다.
		if(!IsFakeClient(client))
		{
			DDS_SetUserMoney(attacker, 2, HUMAN_INFECTION_REWARD);
			PrintToChat(attacker, "%s\x01인간을 감염시켜 \x03%i\x01 킬 포인트를 획득 하셨습니다!", PREFIX, HUMAN_INFECTION_REWARD);
			SetEntProp(attacker, Prop_Send, "m_iAccount", GetEntProp(attacker, Prop_Send, "m_iAccount")+REWARD_CASH_INFECT_HUMAN);
			PrintToChat(attacker, " \x06+$%d\x01: 인간을 감염시킨 것에 대한 보상.", REWARD_CASH_INFECT_HUMAN);
		}
		
	  	if(IsValidPlayer(attacker))
	  	{
		  	int iMaxHealth = GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
		  	if(iMaxHealth + ZOMBIE_HEAL_AMOUNT_PER_KILL < ZOMBIE_MAX_HEALTH)	iMaxHealth += ZOMBIE_HEAL_AMOUNT_PER_KILL;
		  	else	iMaxHealth = ZOMBIE_MAX_HEALTH;
		  	
		  	// 최대 체력을 한정한다.
		  	SetEntProp(attacker, Prop_Data, "m_iMaxHealth", iMaxHealth);
		  	
		  	// (현재 체력 + 인간을 잡아 오르는 체력량)이 한정된 최대 체력을 넘지 않는다면,
		  	if(GetClientHealth(attacker) + ZOMBIE_HEAL_AMOUNT_PER_KILL < iMaxHealth)	
			{
				SetEntityHealth(attacker, GetClientHealth(attacker) + ZOMBIE_HEAL_AMOUNT_PER_KILL);
			}
		  	else
			{
				SetEntityHealth(attacker, iMaxHealth);
			}
			
			if(g_iHostZombie != attacker)
			{
				int RandomZombie = GetRandomInt(1, 4);
				if(RandomZombie <= 1)
				{
					if(IsClientZombie(attacker))
					{
						RandomZombie = GetRandomInt(1, 4);
						if(g_iGasZombie <= 0 && RandomZombie <= 2 && g_iJumpZombie != attacker)
						{
							g_flGasZombieSkillTimer = 0.0;
							if(CPS_HasSkin(attacker))
							{
								CPS_RemoveSkin(attacker);
							}
							
							SetEntityModel(attacker, MODEL_GAS_ZOMBIE);
							SetEntityHealth(attacker, 2500);
							SetEntProp(attacker, Prop_Data, "m_iMaxHealth", 2500);
							g_iGasZombie = attacker;
							Shake(attacker, 3.0); // ShakeScreen(attacker, 5.0, 10.0);
							PrintToChat(attacker, "%s\x03특수좀비(가스)\x01로 돌연변이화 되셨습니다!", PREFIX);
							PrintCenterTextAll("<font color='#ff7f7f'>변종 좀비가 나타났습니다!</font>");
							PrintCenterText(attacker, "<font color='#ff7f7f'>변종 좀비가 되었습니다!\nR을 눌러 가스를 배출할 수 있습니다.</font>");
		//					Helppanel4(attacker); // TODO: 도움말 패널 추가
							CS_SetClientClanTag(attacker, "가스좀비");
							EmitSoundToClientAny(attacker, SOUND_BECOME_SPECIAL_ZOMBIE, SOUND_FROM_PLAYER, 99/*채널*/);
						}
						if(g_iJumpZombie <= 0 && RandomZombie > 2 && g_iGasZombie != attacker)
						{
							g_flJumpZombieSkillTimer = 0.0;
							if(CPS_HasSkin(attacker))
							{
								CPS_RemoveSkin(attacker);
							}
							
							SetEntityModel(attacker, MODEL_JUMP_ZOMBIE);
							SetEntityHealth(attacker, 4000);
							SetEntProp(attacker, Prop_Data, "m_iMaxHealth", 4000);
							g_iJumpZombie = attacker;
							Shake(attacker, 3.0); // ShakeScreen(attacker, 5.0, 10.0);
							PrintToChat(attacker, "%s\x03특수좀비(도약)\x01로 돌연변이화 되셨습니다!", PREFIX);
							PrintCenterTextAll("<font color='#ff7f7f'>변종 좀비가 나타났습니다!</font>");
							PrintCenterText(attacker, "<font color='#ff7f7f'>변종 좀비가 되었습니다!\nR을 눌러 도약할 수 있습니다.</font>");
		//					Helppanel3(attacker); // TODO: 도움말 패널 추가
							CS_SetClientClanTag(attacker, "도약좀비");
							EmitSoundToClientAny(attacker, SOUND_BECOME_SPECIAL_ZOMBIE, SOUND_FROM_PLAYER, 99/*채널*/);
						}
						SetClientArms(attacker, ARMS_SPECIAL_ZOMBIE);
						
					}
				}
			}
		}
	}
	
	/**************** 좀비가 된 인간에 관련된 뒷처리 ****************/
	CancelClientMenu(client);
	Party_PlayerBecomeZombie(client, isHostZombie);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	SetEntityRenderMode(client, RENDER_TRANSALPHA);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{	
	char clsname[32];
	if(GetEdictClassname(client, clsname, sizeof(clsname)))
	{
		if (!StrEqual(clsname, "player")){
			return Plugin_Continue;
		}
	}
	
	if (g_iClassId[client] < 1)	SetEntPropFloat(client, Prop_Send, "m_fForceTeam", GetGameTime()+817.0);
	
	if (IsWarmupPeriod())
	{
		if(CPS_HasSkin(client))
		{
			SetEntityRenderColor(client, 255, 255, 255, 0);
			SetEntityRenderMode(client, RENDER_TRANSALPHA);
		}
		return Plugin_Continue;
	}
	
	if(GetClientMenu(client) == MenuSource_None)
	{
		if(GetClientHideHud(client) & HIDEHUD_RADAR)
			// 드러낸다
			SetRadarAndMoneyVisiblity(client, true);
	}
	else
	{
		if(!(GetClientHideHud(client) & HIDEHUD_RADAR))
			// 숨긴다
			SetRadarAndMoneyVisiblity(client, false);
	}
	
	if(g_flForceFirstPersonTime[client] > 0.0)
	{
		if(g_flForceFirstPersonTime[client] >= GetGameTime())
		{
			if(g_bThirdPerson[client])
			{
				ChangePersonView(client, false);
			}
		}
		else
		{
			if(g_bThirdPerson[client])
			{
				ChangePersonView(client, g_bThirdPerson[client]);
				g_flForceFirstPersonTime[client] = 0.0;
			}
		}			
	}
	
	// 인간 팀 틱 처리, 살아 있을 때.
	// 게임 시작 전에는 무조건 인간 팀이므로, or를 통해 게임 시작 전을 조건으로 걸어준다.
	if(IsValidPlayer(client) && !IsClientZombie(client))
	{
		if(CPS_HasSkin(client))
		{
			SetEntityRenderColor(client, 255, 255, 255, 0);
			SetEntityRenderMode(client, RENDER_TRANSALPHA);
		}
		
		// 무기 탄약 설정부분
		int eWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (IsValidEdict(eWeapon))
		{
			char weaponClassname[32];
			if(GetEdictClassname(eWeapon, weaponClassname, sizeof(weaponClassname)))
			{
				if(StrEqual(weaponClassname[7], "nova") || StrEqual(weaponClassname[7], "xm1014") || StrEqual(weaponClassname[7], "sawedoff"))
				{
					int ammo = GetWeaponReserveAmmo(client, eWeapon);
					SetEntProp(eWeapon, Prop_Send, "m_iSecondaryReserveAmmoCount", ammo);
					/*
					// 샷건(쉘) 리로드중
					int iReloadState = GetEntProp(eWeapon, Prop_Send, "m_reloadState");
					if(iReloadState > 0)
					{
						int ammo = GetWeaponReserveAmmo(client, eWeapon);
						SetEntProp(eWeapon, Prop_Send, "m_iSecondaryReserveAmmoCount", ammo);
					}*/
				}
				else
				{
					// 일반 총(매거진 사용) 리로드 중
					if(GetEntProp(eWeapon, Prop_Data, "m_bInReload"))
					{
						int ammo = GetWeaponReserveAmmo(client, eWeapon);
						SetEntProp(eWeapon, Prop_Send, "m_iSecondaryReserveAmmoCount", ammo);	
					}
				}
			}
		}
		
		
		int iGroundEntity = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
		if(IsValidEdict(iGroundEntity))
		{
			char szClassname[32];
			GetEdictClassname(iGroundEntity, szClassname, 32);
			if(StrEqual(szClassname, "prop_physics"))
			{
				char Modelname[128];
				GetEntPropString(iGroundEntity, Prop_Data, "m_ModelName", Modelname, 128);
				
				if(StrEqual(Modelname, BarricadeModel, false))
				{
					buttons &= ~IN_JUMP;
					return Plugin_Changed;
				}
			}
		}
		// 바이러스에 감염되었을 때.
		if(g_nPenetrationCount[client] > 0)
		{
			float flGameTime = GetGameTime();
			if(g_flLastVirusDamagedTime[client] <= flGameTime)
			{
				g_flLastVirusDamagedTime[client] = flGameTime + INFECTION_DAMAGE_INTERVAL;
				
				// 팩터 = (현재 게임시간 - 감염 시작시간) / 데미지 간격
				// 결국 시간이 지날수록 감염으로 인한 데미지가 커진다.
				float dmg_factor = (flGameTime - g_flFirstInfectionTime[client]) / INFECTION_DAMAGE_INTERVAL;
				float dmg = (dmg_factor * g_nPenetrationCount[client]) * INFECTION_DAMAGE_MULTIPLIER;
				
				#if defined _DEBUG_
					PrintToChat(client, "Virus Damage: %.2f", dmg);
				#endif
				
				if(dmg >= 1)
				{
					if(GetClientHealth(client) > dmg)
					{
						g_bSuppressDamageSound[client] = true;
						SDKHooks_TakeDamage(client, 0, IsValidClient(g_iLastPenetertor[client])?g_iLastPenetertor[client]:0, dmg, DMG_POISON);
						
						// TODO: 이곳에 기침 사운드를 삽입
						// 대체 사운드도 적용
						#define SNDCHAN_COUGH_SOUND		9
						
						int SoundRandom = GetRandomInt(0, sizeof(CoughSoundFilesPath[])-1);
						EmitSoundToAllAny(CoughSoundFilesPath[g_iVoiceCharacter[client]][SoundRandom], client, SNDCHAN_COUGH_SOUND, _, _, _, _, _, _, _, true);
					}
					else
					{
						InfectHuman(client, g_iLastPenetertor[client]);
					}
				}
			}
		}
		
		if(buttons & IN_USE)
		{
			if(!(g_fButtonFlags[client] & IN_USE))
			{
				g_fButtonFlags[client] |= IN_USE;
				AmmoCrateAmmo(client);
				CheckPlayerStatus(client);
				AcquireSupplyBox(client);
			}
		}
		else
		{
			if(g_fButtonFlags[client] & IN_USE)
			{
				g_fButtonFlags[client] &= ~IN_USE;
			}
		}
		
		// 왼쪽 마우스를 누르고 있을 때.
		if(buttons & IN_ATTACK)
		{
			if(!(g_fButtonFlags[client] & IN_ATTACK))
			{				
				char WeaponName[32];
				GetClientWeapon(client, WeaponName, sizeof(WeaponName));
				// 저격수
				if(g_iClassId[client] == 4)
				{
					if(StrEqual("knife", WeaponName[7]))
					{
						if(g_flBoardHeight[client]+0.5 > SKILL_BOARD_MAX_HEIGHT)
							g_flBoardHeight[client] = SKILL_BOARD_MAX_HEIGHT;
						else
							g_flBoardHeight[client] += 0.5;
					}
				}
				else	g_fButtonFlags[client] |= IN_ATTACK;
			}
		}
		else
		{
			if(g_fButtonFlags[client] & IN_ATTACK)
			{
				g_fButtonFlags[client] &= ~IN_ATTACK;
			}
		}
		
		// 오른쪽 마우스를 누르고 있을 때.
		if(buttons & IN_ATTACK2)
		{
			if(!(g_fButtonFlags[client] & IN_ATTACK2))
			{				
				char WeaponName[32];
				GetClientWeapon(client, WeaponName, sizeof(WeaponName));
				// 저격수
				if(g_iClassId[client] == 4)
				{
					if(StrEqual("knife", WeaponName[7]))
					{
						float absOrigin[3], eOrigin[3];
						GetClientAbsOrigin(client, absOrigin);
						GetClientEyePosition(client, eOrigin);

						if(eOrigin[2]+g_flBoardHeight[client]-0.5 < absOrigin[2])
							g_flBoardHeight[client] = absOrigin[2]-eOrigin[2];
						else
							g_flBoardHeight[client] -= 0.5;
					}
				}
				else	g_fButtonFlags[client] |= IN_ATTACK2;
				
				// 지원병
				if(g_iClassId[client] == 5)
				{
					if(StrEqual("bizon", WeaponName[7]) || StrEqual("mp7", WeaponName[7]) || StrEqual("mp9", WeaponName[7]))
					{
						SetupAmmoCrate(client);
					}
				}
				// 의무병
				else if(g_iClassId[client] == 6)
				{
					if(StrEqual("ump45", WeaponName[7]) || StrEqual("mac10", WeaponName[7]))
					{
						HealthPack(client);
					}
				}
			}
		}
		else
		{
			if(g_fButtonFlags[client] & IN_ATTACK2)
			{
				g_fButtonFlags[client] &= ~IN_ATTACK2;
			}
		}
		
		// 재장전 키를 누르고 있을 때
		if(buttons & IN_RELOAD)
		{
			if(!(g_fButtonFlags[client] & IN_RELOAD))
			{
				g_fButtonFlags[client] |= IN_RELOAD;
				
				char WeaponName[32];
				GetClientWeapon(client, WeaponName, sizeof(WeaponName));
				// 저격수
				if(g_iClassId[client] == 4)
				{
					if(StrEqual("knife", WeaponName[7]))
					{
						WoodBoard(client);
					}
				}
			}
		}
		else
		{
			if(g_fButtonFlags[client] & IN_RELOAD)
			{
				g_fButtonFlags[client] &= ~IN_RELOAD;
			}
		}
	}
	// 좀비 팀 틱 처리, 살아 있을 때.
	// 좀비는 무조건 게임 시작 후에만 나타나므로, and를 통해 게임 시작 이후를 조건으로 걸어준다.
	if(IsClientZombie(client) && IsValidPlayer(client))
	{		
		#define CSAddon_NONE	0
		SetEntProp(client, Prop_Send, "m_iAddonBits", CSAddon_NONE);
		int eWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		HideWeaponWorldModel(eWeapon);
		
		int flag = GetEntityFlags(client);
		if(flag & FL_ONGROUND && flag & FL_DUCKING)
		{
			if(g_flZombieRecoverTime[client] <= GetGameTime())
			{
				int iCurrentHealth = GetClientHealth(client);
				int iMaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
				int iRandomHealth = GetRandomInt(10, 15);
				
				if(iMaxHealth != iCurrentHealth)
				{
					g_flZombieRecoverTime[client] = GetGameTime() + 0.1;
					if(iMaxHealth > iCurrentHealth + iRandomHealth)
					{
						SetEntityHealth(client, iCurrentHealth + iRandomHealth);
					}
					else
					{
						SetEntityHealth(client, iMaxHealth);
					}
				}
			}
		}
		
		// 좀비 블락을 사용 중일 때, 사용 후에는 반드시 이 값을 0으로 둘 것!
		if(g_flZombieBlockTime[client] > 0.0)
		{
			if(g_flZombieBlockTime[client] <= GetGameTime())
			{
				Command_ZombieNoBlock(client);
				PrintHintText(client, "자동으로 <font color='#3fff3f'>노블럭 상태</font>로 전환되었습니다.");
			}
		}
		
		if(buttons & IN_SPEED)
		{
			if(!(g_fButtonFlags[client] & IN_SPEED))
			{
				g_fButtonFlags[client] |= IN_SPEED;
				Command_Zmenu(client);
			}
		}
		else
		{
			if(g_fButtonFlags[client] & IN_SPEED)
			{
				g_fButtonFlags[client] &= ~IN_SPEED;
			}
		}
		
		if(buttons & IN_RELOAD)
		{
			if(!(g_fButtonFlags[client] & IN_RELOAD))
			{
				g_fButtonFlags[client] |= IN_RELOAD;
				
				if(g_iHostZombie == client)
				{
					// 쿨다운 체크
					if(g_flHostZombieSkillTimer <= GetGameTime())
					{
						// 스킬 사용 후 쿨다운 적용
						ShakeEffect(client);
						g_flHostZombieSkillTimer = GetGameTime() + 20.0;
					}
					else
					{
						PrintHintText(client, "아직 사용할수 없습니다.\n<font color='#3fff3f'>%.1f</font>초 후 사용가능.", g_flHostZombieSkillTimer - GetGameTime());
					}
				}
				else if(g_iJumpZombie == client)
				{
					if(GetEntityFlags(client) & FL_ONGROUND)
					{
						// 쿨다운 체크
						if(g_flJumpZombieSkillTimer <= GetGameTime())
						{
							// 스킬 사용 후 쿨다운 적용
							JumpSkill(client);						
							g_flJumpZombieSkillTimer = GetGameTime() + 3.0;
	//						EmitSoundToAll(JumpSound, client, _, _, _, 1.0); // TODO: 사운드 추가
						}
						else
						{
							PrintHintText(client, "아직 사용할수 없습니다.\n<font color='#3fff3f'>%.1f</font>초 후 사용가능.", g_flJumpZombieSkillTimer - GetGameTime());
						}
					}
				}
				else if(g_iGasZombie == client)
				{
					// 쿨다운 체크
					if(g_flGasZombieSkillTimer <= GetGameTime())
					{
						// 스킬 사용 후 쿨다운 적용
						float eAngles[3];
						float eOrigin[3];
						float pos[3];
					
						GetClientEyePosition(client, eOrigin);
						GetClientEyeAngles(client, eAngles);
					
						Handle trace = TR_TraceRayFilterEx(eOrigin, eAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
						
						if(TR_DidHit(trace))
						{
							TR_GetEndPosition(pos, trace);
						}
						
						delete trace;
						
						float Dist = GetVectorDistance(pos, eOrigin);
					
						if(Dist < 300)
						{
							g_flGasZombieSkillTimer = GetGameTime() + 36.0;
							MakeGas(client, pos);
						}
						else
						{
							PrintHintText(client, "연기를 뱉기에는 너무 멉니다.");
						}
					}
					else
					{
						PrintHintText(client, "아직 사용할수 없습니다.\n<font color='#3fff3f'>%.1f</font>초 후 사용가능.", g_flGasZombieSkillTimer - GetGameTime());
					}
				}
			}
		}
		else
		{
			if(g_fButtonFlags[client] & IN_RELOAD)
			{
				g_fButtonFlags[client] &= ~IN_RELOAD;
			}
		}
	}
	
	// 플레이어 충돌 가능 체크
	if(IsValidPlayer(client) && !g_bShouldCollide[client] && IsClientZombie(client))
	{
		int ent;
		float pos[3];
		float ang[3];
		float mins[3];
		float maxs[3];
		ang[0]=90.0;
		ang[1]=0.0;
		ang[2]=0.0;
		
		GetClientEyePosition(client, pos);
		GetClientMins(client, mins);
		GetClientMaxs(client, maxs);

		TR_TraceRayFilter(pos, ang, MASK_PLAYERSOLID, RayType_Infinite, DontHitSelf, client);

		float down[3];

		TR_GetEndPosition(down);

		down[2] -= 100.0;

		TR_TraceHullFilter(pos, down, mins, maxs, MASK_PLAYERSOLID, DontHitSelf, client);

		if (TR_DidHit(INVALID_HANDLE))
		{
			ent = TR_GetEntityIndex(INVALID_HANDLE);
		}

		if((ent == 0 || ent > MaxClients))
		{
			g_bShouldCollide[client]=true;
		}
	}
	
	if(IsValidPlayer(client))
	{
		Para_OnRunCmd(client, buttons);
	}
	
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] OnPlayerRunCmdPost(%i)", client);
	#endif
	return Plugin_Continue;
}

public bool DontHitSelf(entity, mask, any:data)
{
	if(entity == data)
		return false;
	return true;
}

public CheckPlayerStatus(client)
{
	// 게임이 진행중일 때
	if(g_bGameStarted)
	{
		int target = GetClientAimTarget(client, true);
		
		/*
		client 에 대한 유효성 체크는 이미 OnPlayerRunCmd에서 확인한다.
		이 함수는 OnPlayerRunCmd에서만 호출하도록 하여 혼란이 없도록 해야한다.
		*/
		if(IsValidPlayer(target) && !IsClientZombie(target))
		{			
			char szPlayerStatusString[128];
				
			if(g_nPenetrationCount[target] > 0)
			{
				Format(szPlayerStatusString, sizeof(szPlayerStatusString), "상태 : <font color='#ff3f3f'>%d</font>회 감염 (<font color='#ff3f3f'>%.0f</font>초 지남)", g_nPenetrationCount[target], GetGameTime()-g_flFirstInfectionTime[target]);
			}
			else
			{
				Format(szPlayerStatusString, sizeof(szPlayerStatusString), "상태 : <font color='#7f7fff'>정상</font>");
			}
				
			PrintHintText(client, "<font color='#3f3fff'>%N</font> 님 - \n클래스 : %s\n%s", target, g_szConstClassName[g_iClassId[target]], szPlayerStatusString);
		}
		else
		{
			int entity = GetClientAimTarget(client, false);
			if(IsValidEntity(entity))
			{
				char szClassname[64];
				GetEntityClassname(entity, szClassname, sizeof(szClassname));
			}	
		}
	}
	
}

//좀비 텔포
public Action Command_ZombieTele(client, Arguments)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] Command_ZombieTele()");
	#endif
	
	if(IsClientZombie(client))
	{
		if(IsPlayerAlive(client))
		{
			if(g_nZteleCount[client] >= 1)
			{
				int target = GetRandomPlayer(CLIENTFILTER_INGAME | CLIENTFILTER_ALIVE | CLIENTFILTER_NOSPECTATORS | CLIENTFILTER_NOOBSERVERS);
				if(target != -1)
				{
					g_nZteleCount[client] -= 1;
				
					TeleportEntity(client, g_vecSpawnPoint[target], NULL_VECTOR, NULL_VECTOR);
					PrintToChat(client, "%s\x01남은 사용 가능 횟수 : \x03%d\x01번", PREFIX, g_nZteleCount[client]);
				}
			}
			else
			{
				PrintToChat(client, "%s\x01더 이상 해당 명령어를 사용하실 수 없습니다.", PREFIX);	
			}
		}
		else
		{
			PrintToChat(client, "%s\x01죽은 상태에서는 사용할 수 없습니다.", PREFIX);	
		}
	}
	else
	{
		PrintToChat(client, "%s\x01해당 명령어는 좀비만 사용 가능 합니다.", PREFIX);	
	}
}

//라운드 체크
void CheckTeamAliveCounter(bool validate=true)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] CheckTeamAliveCounter()");
	#endif
	
	g_nAliveT = 0;
	g_nAliveCT = 0;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidPlayer(i))
		{
			if(GetClientTeam(i) == CS_TEAM_CT)
			{		
				g_nAliveCT += 1;
			}
			else if(GetClientTeam(i) == CS_TEAM_T)
			{
				g_nAliveT += 1;
			}
		}
	}
	if(validate && !(!IsWarmupPeriod() && !g_bGameStarted && g_bHostSelectionTime))
	{
		if(g_nAliveCT == 0)
		{
			// 테러리스트 승리
			if(GetPlayerCount() >= MIN_PLAYER_TO_PLAY && g_bGameStarted)	CS_TerminateRound(GetRoundRestartDelay(), CSRoundEnd_TerroristWin);
		}
		
		if(g_nAliveT == 0)
		{
			// 대테러리스트 승리
			if(GetPlayerCount() >= MIN_PLAYER_TO_PLAY && g_bGameStarted)	CS_TerminateRound(GetRoundRestartDelay(), CSRoundEnd_CTWin);
		}
	}
}
