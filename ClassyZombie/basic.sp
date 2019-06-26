/*
static const char weaponEntities[][] = {
	{"weapon_*"},
	{"item_*"}	
};*/

static const char objectiveEntities[][] = { 	
	{"func_buyzone"},
	{"func_bomb_target"},
	{"func_hostage_rescue"},
	{"func_escapezone"},
	{"weapon_taser"},
	{"weapon_negev"}
};

static const char hostageEntity[][] = {
	{"hostage_entity"}
};

// 게임 모드와 큰 연관이 없는 스톡함수 등등을 넣는 곳.
void CleanUp(bool subjects, bool hostage)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] CleanUp(%s %s)", subjects?"subjects":"", hostage?"hostage":"");
	#endif
	
	if(subjects)
	{
		for (new i=0; i < sizeof(objectiveEntities); i++) { 
			int entity = -1; 
			while ((entity = FindEntityByClassname(entity, objectiveEntities[i])) != INVALID_ENT_REFERENCE)
			{ 
				AcceptEntityInput(entity, "Kill");
			}
		}
	}
	
	if(hostage)
	{
		for (new i=0; i < sizeof(hostageEntity); i++) { 
			int entity = -1; 
			while ((entity = FindEntityByClassname(entity, hostageEntity[i])) != INVALID_ENT_REFERENCE)
			{ 
				AcceptEntityInput(entity, "Kill");
			}
		}
	}
}

// 참일시 라운드 종료 가능, 거짓일 시 라운드 종료 불가
stock void SetCanEndRound(bool conditions)
{
	SetConVarInt(FindConVar("mp_ignore_round_win_conditions"), conditions?0:1);
}
/*
stock int GetRandomClient(int team=-1)
{
	int iPlayer[MAXPLAYERS+1], iCount = 0;
		
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if(team == -1)
			{
				iPlayer[iCount] = i;
				iCount++;
			}
			else if(team == -2)
			{
				if((GetClientTeam(i) == 2 || GetClientTeam(i) == 3) && IsPlayerAlive(i) && !IsFakeClient(i))
				{
					iPlayer[iCount] = i;
					iCount++;
				}
			}
			else if(GetClientTeam(i) == team)
			{
				iPlayer[iCount] = i;
				iCount++;
			}
		}
	}
	
	return iPlayer[GetRandomInt(0, iCount-1)];
}*/

stock bool ClearTimer(Handle &hTimer, bool autoClose=true)
{
	if(hTimer != null)
	{
//		delete hTimer;
		hTimer = null;
		return true;
	}
	return false;
}

/**
 * 클라이언트가 서버 안에서 적용될 수 있는지 확인
 * 
 * @param client 			클라이언트 인덱스
 * @return					클라이언트 인덱스가 정상이고, 연결되있는 상태면 true, 아니면 false.
 */
stock bool IsValidClient(client)
{
	if(client > 0 && client < MaxClients)
	{
		if(IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client) && !IsClientReplay(client))
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	else
	{
		return false;
	}
}

/**
 * 클라이언트가 게임 안에서 적용될 수 있는지 확인
 * 죽어있거나 옵저버는 해당안됨
 * 
 * @param client 			클라이언트 인덱스
 * @return					살아있고 적용가능한 대상이면 true, 아니면 false.
 */
stock bool IsValidPlayer(client)
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		return true;
	}
	else
	{
		return false;
	}
}

stock int GetPlayerCount()
{
	return (GetTeamClientCount(CS_TEAM_T) + GetTeamClientCount(CS_TEAM_CT));
}


#define SIZE_OF_INT		2147483647		// without 0

// Team Defines
#define	TEAM_INVALID	-1
#define TEAM_UNASSIGNED	0
#define TEAM_SPECTATOR	1
#define TEAM_ONE		2
#define TEAM_TWO		3

#define CLIENTFILTER_ALL				0		// No filtering
#define CLIENTFILTER_BOTS			( 1	<< 1  )	// Fake clients
#define CLIENTFILTER_NOBOTS			( 1	<< 2  )	// No fake clients
#define CLIENTFILTER_AUTHORIZED		( 1 << 3  ) // SteamID validated
#define CLIENTFILTER_NOTAUTHORIZED  ( 1 << 4  ) // SteamID not validated (yet)
#define CLIENTFILTER_ADMINS			( 1	<< 5  )	// Generic Admins (or higher)
#define CLIENTFILTER_NOADMINS		( 1	<< 6  )	// No generic admins
// All flags below require ingame checking (optimization)
#define CLIENTFILTER_INGAME			( 1	<< 7  )	// Ingame
#define CLIENTFILTER_INGAMEAUTH		( 1 << 8  ) // Ingame & Authorized
#define CLIENTFILTER_NOTINGAME		( 1 << 9  )	// Not ingame (currently connecting)
#define CLIENTFILTER_ALIVE			( 1	<< 10 )	// Alive
#define CLIENTFILTER_DEAD			( 1	<< 11 )	// Dead
#define CLIENTFILTER_SPECTATORS		( 1 << 12 )	// Spectators
#define CLIENTFILTER_NOSPECTATORS	( 1 << 13 )	// No Spectators
#define CLIENTFILTER_OBSERVERS		( 1 << 14 )	// Observers
#define CLIENTFILTER_NOOBSERVERS	( 1 << 15 )	// No Observers
#define CLIENTFILTER_TEAMONE		( 1 << 16 )	// First Team (Terrorists, ...)
#define CLIENTFILTER_TEAMTWO		( 1 << 17 )	// Second Team (Counter-Terrorists, ...)

stock int GetRandomPlayer(int flags=CLIENTFILTER_ALL)
{	
	int[] clients = new int[MaxClients];
	int num = GetClient(clients, flags);

	if (num == 0) {
		return -1;
	}
	else if (num == 1) {
		return clients[0];
	}

	int  random = MathGetRandomInt(0, num-1);

	return clients[random];
}

stock bool IsClientAdmin(int client, AdminFlag adminFlag=Admin_Generic)
{
	AdminId adminId = GetUserAdmin(client);
	
	if (adminId == INVALID_ADMIN_ID) {
		return false;
	}
	
	return GetAdminFlag(adminId, adminFlag);
}

stock int GetClient(int[] clients, int flags=CLIENTFILTER_ALL)
{
	int x=0;
	for (int client = 1; client <= MaxClients; client++) {

		if (!MatchClientFilter(client, flags)) {
			continue;
		}

		clients[x++] = client;
	}

	return x;
}
stock int MathGetRandomInt(int min, int max)
{
	int  random = GetURandomInt();
	
	if (random == 0) {
		random++;
	}

	return RoundToCeil(float(random) / (float(SIZE_OF_INT) / float(max - min + 1))) + min - 1;
}

stock bool MatchClientFilter(int client, int flags)
{
	bool isIngame = false;

	if (flags >= CLIENTFILTER_INGAME) {
		isIngame = IsClientInGame(client);

		if (isIngame) {
			if (flags & CLIENTFILTER_NOTINGAME) {
				return false;
			}
		}
		else {
			return false;
		}
	}
	else if (!IsClientConnected(client)) {
		return false;
	}

	if (!flags) {
		return true;
	}

	if (flags & CLIENTFILTER_INGAMEAUTH) {
		flags |= CLIENTFILTER_INGAME | CLIENTFILTER_AUTHORIZED;
	}

	if (flags & CLIENTFILTER_BOTS && !IsFakeClient(client)) {
		return false;
	}

	if (flags & CLIENTFILTER_NOBOTS && IsFakeClient(client)) {
		return false;
	}

	if (flags & CLIENTFILTER_ADMINS && !IsClientAdmin(client)) {
		return false;
	}

	if (flags & CLIENTFILTER_NOADMINS && IsClientAdmin(client)) {
		return false;
	}

	if (flags & CLIENTFILTER_AUTHORIZED && !IsClientAuthorized(client)) {
		return false;
	}

	if (flags & CLIENTFILTER_NOTAUTHORIZED && IsClientAuthorized(client)) {
		return false;
	}

	if (isIngame) {

		if (flags & CLIENTFILTER_ALIVE && !IsPlayerAlive(client)) {
			return false;
		}

		if (flags & CLIENTFILTER_DEAD && IsPlayerAlive(client)) {
			return false;
		}

		if (flags & CLIENTFILTER_SPECTATORS && GetClientTeam(client) != TEAM_SPECTATOR) {
			return false;
		}

		if (flags & CLIENTFILTER_NOSPECTATORS && GetClientTeam(client) == TEAM_SPECTATOR) {
			return false;
		}

		if (flags & CLIENTFILTER_OBSERVERS && !IsClientObserver(client)) {
			return false;
		}

		if (flags & CLIENTFILTER_NOOBSERVERS && IsClientObserver(client)) {
			return false;
		}

		if (flags & CLIENTFILTER_TEAMONE && GetClientTeam(client) != CS_TEAM_T) {
			return false;
		}

		if (flags & CLIENTFILTER_TEAMTWO && GetClientTeam(client) != CS_TEAM_CT) {
			return false;
		}
	}

	return true;
}

stock bool ConnectionCheck(int Client)
{
	if(Client > 0 && Client <= MaxClients)
	{
		if(IsClientConnected(Client) == true)
		{
			if(IsClientInGame(Client) == true)
			{
				return true;
			}
			else
			{	
				return false;	
			}
		}
		else
		{		
			return false;		
		}
	}
	else
	{		
		return false;		
	}
}

void ZeroVector(float vector[3])
{
	vector[0] = 0.0;
	vector[1] = 0.0;
	vector[2] = 0.0;
}

// Hud Element hiding flags
#define	HIDEHUD_WEAPONSELECTION		( 1<<0 )	// Hide ammo count & weapon selection
#define	HIDEHUD_FLASHLIGHT			( 1<<1 )
#define	HIDEHUD_ALL					( 1<<2 )
#define HIDEHUD_HEALTH				( 1<<3 )	// Hide health & armor / suit battery
#define HIDEHUD_PLAYERDEAD			( 1<<4 )	// Hide when local player's dead
#define HIDEHUD_NEEDSUIT			( 1<<5 )	// Hide when the local player doesn't have the HEV suit
#define HIDEHUD_MISCSTATUS			( 1<<6 )	// Hide miscellaneous status elements (trains, pickup history, death notices, etc)
#define HIDEHUD_CHAT				( 1<<7 )	// Hide all communication elements (saytext, voice icon, etc)
#define	HIDEHUD_CROSSHAIR			( 1<<8 )	// Hide crosshairs
#define	HIDEHUD_VEHICLE_CROSSHAIR	( 1<<9 )	// Hide vehicle crosshair
#define HIDEHUD_INVEHICLE			( 1<<10 )
#define HIDEHUD_BONUS_PROGRESS		( 1<<11 )	// Hide bonus progress display (for bonus map challenges)
#define HIDEHUD_RADAR				( 1<<12 )	// Hide the radar

#define HIDEHUD_BITCOUNT			13

/**
* Sets the Hide-Hud flags of a client
*
* @param client        Client index.
* @param flags        Flag to set, use one of the HIDEHUD_ hiding constants
* @noreturn
*/
stock void SetClientHideHud(int client, int flags)
{
    SetEntProp(client, Prop_Send, "m_iHideHUD", flags);
}

stock int GetClientHideHud(int client)
{
    return GetEntProp(client, Prop_Send, "m_iHideHUD");
}

//env_explotion 엔티티의 스폰플래그
#define SF_ENVEXPLOSION_NODAMAGE	0x00000001 // when set, ENV_EXPLOSION will not actually inflict damage
#define SF_ENVEXPLOSION_REPEATABLE	0x00000002 // can this entity be refired?
#define SF_ENVEXPLOSION_NOFIREBALL	0x00000004 // don't draw the fireball
#define SF_ENVEXPLOSION_NOSMOKE		0x00000008 // don't draw the smoke
#define SF_ENVEXPLOSION_NODECAL		0x00000010 // don't make a scorch mark
#define SF_ENVEXPLOSION_NOSPARKS	0x00000020 // don't make sparks
#define SF_ENVEXPLOSION_NOSOUND		0x00000040 // don't play explosion sound.
#define SF_ENVEXPLOSION_RND_ORIENT	0x00000080	// randomly oriented sprites
#define SF_ENVEXPLOSION_NOFIREBALLSMOKE 0x0100
#define SF_ENVEXPLOSION_NOPARTICLES 0x00000200
#define SF_ENVEXPLOSION_NODLIGHTS	0x00000400
#define SF_ENVEXPLOSION_NOCLAMPMIN	0x00000800 // don't clamp the minimum size of the fireball sprite
#define SF_ENVEXPLOSION_NOCLAMPMAX	0x00001000 // don't clamp the maximum size of the fireball sprite
#define SF_ENVEXPLOSION_SURFACEONLY	0x00002000 // don't damage the player if he's underwater.
stock bool:MakeExplosion(attacker = 0, inflictor = -1, const Float:attackposition[3], const String:weaponname[] = "", magnitude = 100, radiusoverride = 0, Float:damageforce = 0.0, flags = 0){
	
	new explosion = CreateEntityByName("env_explosion");
	
	if(explosion != -1){
	
		DispatchKeyValueVector(explosion, "Origin", attackposition);
		
		decl String:intbuffer[64];
		IntToString(magnitude, intbuffer, 64);
		DispatchKeyValue(explosion,"iMagnitude", intbuffer);
		if(radiusoverride > 0){
			
			IntToString(radiusoverride, intbuffer, 64);
			DispatchKeyValue(explosion,"iRadiusOverride", intbuffer);
			
		}
		if(damageforce > 0.0){
			
			DispatchKeyValueFloat(explosion,"DamageForce", damageforce);
			
		}
		if(flags != 0){
			
			IntToString(flags, intbuffer, 64);
			DispatchKeyValue(explosion,"spawnflags", intbuffer);
			
		}
		//웨폰네임 오버라이드
		if(!StrEqual(weaponname, "", false)){
			
			DispatchKeyValue(explosion,"classname", weaponname);
			
			if(inflictor != -1){
				
				DispatchKeyValue(inflictor,"classname", weaponname);
				
			}
			
		}
		DispatchSpawn(explosion);
		if(IsValidClient(attacker)){
			
			SetEntPropEnt(explosion, Prop_Send, "m_hOwnerEntity", attacker);
			
		}
		if(inflictor != -1){
			
			SetEntPropEnt(explosion, Prop_Data, "m_hInflictor", inflictor);
			
		}
		AcceptEntityInput(explosion, "Explode");
		AcceptEntityInput(explosion, "Kill");
		
		return true;
		
	}else{
		
		return false;
		
	}
	
}

/* 클라이언트 별 전체 메세지 전달 함수 */
stock SayText2ToAll(client, const String:message[])
{
	Handle buffer = StartMessageAll("SayText2", USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
	
	if (buffer != INVALID_HANDLE)
	{
		if(GetUserMessageType() == UM_Protobuf)
		{
			PbSetInt(buffer, "ent_idx", client);
			PbSetBool(buffer, "chat", true);
			PbSetString(buffer, "msg_name", message);
			PbAddString(buffer, "params", "");
			PbAddString(buffer, "params", "");
			PbAddString(buffer, "params", "");
			PbAddString(buffer, "params", "");
		}
		else
		{
			BfWriteByte(buffer, client);
			BfWriteByte(buffer, true);
			BfWriteString(buffer, message);
			
			buffer = INVALID_HANDLE;
		}
		EndMessage(); 
	}
}

stock SayText2To(client, const String:message[], int[] clients, int clientCount)
{ 
	Handle buffer = null;
	
	buffer = StartMessage("SayText2", clients, clientCount, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
			
	if (buffer != INVALID_HANDLE)
	{
		if(GetUserMessageType() == UM_Protobuf)
		{
			PbSetInt(buffer, "ent_idx", client);
			PbSetBool(buffer, "chat", true);
			PbSetString(buffer, "msg_name", message);
			PbAddString(buffer, "params", "");
			PbAddString(buffer, "params", "");
			PbAddString(buffer, "params", "");
			PbAddString(buffer, "params", "");
		}
		else
		{
			BfWriteByte(buffer, client);
			BfWriteByte(buffer, true);
			BfWriteString(buffer, message);
			
			buffer = INVALID_HANDLE;
		}
		EndMessage();
	}
}

stock SayText2ToTeam(client, const String:message[])
{ 
	Handle buffer = null;
	
	int team = GetClientTeam(client);
	int total = 0;
	int[] clients = new int[MaxClients];
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i))
		{
			if(team == GetClientTeam(i))
			{
				SetGlobalTransTarget(i);
				clients[total++] = i;
			}
		}
	
	}
	
	buffer = StartMessage("SayText2", clients, total, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
			
	if (buffer != INVALID_HANDLE)
	{
		if(GetUserMessageType() == UM_Protobuf)
		{
			PbSetInt(buffer, "ent_idx", client);
			PbSetBool(buffer, "chat", true);
			PbSetString(buffer, "msg_name", message);
			PbAddString(buffer, "params", "");
			PbAddString(buffer, "params", "");
			PbAddString(buffer, "params", "");
			PbAddString(buffer, "params", "");
		}
		else
		{
			BfWriteByte(buffer, client);
			BfWriteByte(buffer, true);
			BfWriteString(buffer, message);
			
			buffer = INVALID_HANDLE;
		}
		EndMessage();
	}
}

/* 클라이언트 별 개별 메세지 전달 함수 */
stock SayText2ToOne(client, target, const String:message[])
{
	Handle buffer = StartMessageOne("SayText2", target, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
	
	if (buffer != INVALID_HANDLE)
	{
		if(GetUserMessageType() == UM_Protobuf)
		{
			PbSetInt(buffer, "ent_idx", client);
			PbSetBool(buffer, "chat", true);
			PbSetString(buffer, "msg_name", message);
			PbAddString(buffer, "params", "");
			PbAddString(buffer, "params", "");
			PbAddString(buffer, "params", "");
			PbAddString(buffer, "params", "");
			
		}
		else
		{
			BfWriteByte(buffer, client);
			BfWriteByte(buffer, true);
			BfWriteString(buffer, message);
			
			buffer = INVALID_HANDLE;
		}
		EndMessage();
	}
}
/*
//세이텍스트올
stock SayText2ToAll(client, const char[] message, any:...)
{ 
	
	Handle buffer = INVALID_HANDLE;
	
	char txt[255];
	
	int total = 0;
	int clients[MaxClients];
	for(new i = 1; i <= MaxClients; i++){
		
		if(IsClientConnected(i)){
			
			SetGlobalTransTarget(i);
			clients[total++] = i;			
		}
	
	}
	
	VFormat(txt, sizeof(txt), message, 3);
	buffer = StartMessage("SayText2", clients, total, flags);
			
	if (buffer != INVALID_HANDLE)
	{
		if(GetUserMessageType() == UM_Protobuf)
		{
			PbSetBool(buffer, "chat", true);
			PbSetInt(buffere, "ent_idx", client);
			PbAddString(buffer, "params", message);
			PbAddString(buffer, "params", "");
			PbAddString(buffer, "params", "");
			PbAddString(buffer, "params", "");
			PbAddString(buffer, "params", "");
		}
		else
		{
			BfWriteByte(buffer, client);
			BfWriteByte(buffer, true);
			BfWriteString(buffer, txt);
			EndMessage(); 
			buffer = INVALID_HANDLE;
		}
	}
}

//세이텍스트투
stock SayText2To(client, target, const String:message[], any:...){ 
	
	Handle buffer = StartMessageOne("SayText2", target);
			
	char txt[255];
	SetGlobalTransTarget(target);
	VFormat(txt, sizeof(txt), message, 4);	
	
	if (buffer != INVALID_HANDLE)
	{
		if(GetUserMessageType() == UM_Protobuf)
		{
			PbSetBool(buffer, "chat", true);
			PbSetInt(buffere, "ent_idx", client);
			PbAddString(buffer, "params", message);
			PbAddString(buffer, "params", "");
			PbAddString(buffer, "params", "");
			PbAddString(buffer, "params", "");
			PbAddString(buffer, "params", "");
		}
		else
		{
			BfWriteByte(buffer, client);
			BfWriteByte(buffer, true);
			BfWriteString(buffer, txt);
			EndMessage(); 
			buffer = INVALID_HANDLE;
		}
	}
   
}*/


//-----------------------------------------------------------------------------
// Precaches an effect (used by DispatchEffect)
//-----------------------------------------------------------------------------
stock PrecacheEffect(const String:sEffectName[])
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("EffectDispatch");
	}
	
	new bool:save = LockStringTables(false);
	AddToStringTable(table, sEffectName);
	LockStringTables(save);
}


#define PARTICLE_DISPATCH_FROM_ENTITY		(1<<0)
#define PARTICLE_DISPATCH_RESET_PARTICLES	(1<<1)

stock TE_SetupParticleEffect(const char[] sParticleName, ParticleAttachment_t:iAttachType, entity = 0, const float fOrigin[3] = NULL_VECTOR, const float fAngles[3] = NULL_VECTOR, iAttachmentPoint = -1)
{
	TE_Start("EffectDispatch");
	
	TE_WriteNum("m_nHitBox", GetParticleEffectIndex(sParticleName));
	
	new fFlags;
	if(entity > 0)
	{
	//	if(fOrigin == NULL_VECTOR)
	//	{
			new Float:fEntityOrigin[3];
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", fEntityOrigin);
			if(g_Game < Engine_CSGO)
				TE_WriteFloatArray("m_vOrigin[0]", fEntityOrigin, 3);
			else
				TE_WriteFloatArray("m_vOrigin.x", fEntityOrigin, 3);
	//	}
	//	else
	//	{
			if(g_Game < Engine_CSGO)
			{
				TE_WriteFloat("m_vOrigin[0]", fOrigin[0]);
				TE_WriteFloat("m_vOrigin[1]", fOrigin[1]);
				TE_WriteFloat("m_vOrigin[2]", fOrigin[2]);
			}
			else
			{
				TE_WriteFloat("m_vOrigin.x", fOrigin[0]);
				TE_WriteFloat("m_vOrigin.y", fOrigin[1]);
				TE_WriteFloat("m_vOrigin.z", fOrigin[2]);
			}
	//	}
		
	//	if(fAngles != NULL_VECTOR)
	//	{
			TE_WriteFloat("m_vStart.x", fAngles[0]);
			TE_WriteFloat("m_vStart.y", fAngles[1]);
			TE_WriteFloat("m_vStart.z", fAngles[2]);
	//	}
		
		if(iAttachType != PATTACH_WORLDORIGIN)
		{
			TE_WriteNum("entindex", entity);
			fFlags |= PARTICLE_DISPATCH_FROM_ENTITY;
		}
	}
	
	/*if(fOrigin != NULL_VECTOR)
		TE_WriteFloatArray("m_vOrigin[0]", fOrigin, 3);
	if(fStart != NULL_VECTOR)
		TE_WriteFloatArray("m_vStart[0]", fStart, 3);
	if(fAngles != NULL_VECTOR)
		TE_WriteVector("m_vAngles", fAngles);*/
	
	//if(bResetAllParticlesOnEntity)
	//	fFlags |= PARTICLE_DISPATCH_RESET_PARTICLES;
	
	TE_WriteNum("m_fFlags", fFlags);
	TE_WriteNum("m_nDamageType", _:iAttachType);
	TE_WriteNum("m_nAttachmentIndex", iAttachmentPoint);
	
	TE_WriteNum("m_iEffectName", GetEffectIndex("ParticleEffect"));
}

stock TE_SetupStopParticleEffects(entity)
{
	TE_Start("EffectDispatch");
	
	if(entity > 0)
		TE_WriteNum("entindex", entity);
	
	TE_WriteNum("m_iEffectName", GetEffectIndex("ParticleEffectStop"));
}

stock TE_SetupStopParticleEffect(entity, const String:sParticleName[])
{
	TE_Start("EffectDispatch");
	
	if(entity > 0)
		TE_WriteNum("entindex", entity);
	
	TE_WriteNum("m_nHitBox", GetParticleEffectIndex(sParticleName));
	TE_WriteNum("m_iEffectName", GetEffectIndex("ParticleEffectStop"));
}

//-----------------------------------------------------------------------------
// Converts a previously precached effect into an index
//-----------------------------------------------------------------------------
stock GetEffectIndex(const String:sEffectName[])
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("EffectDispatch");
	}
	
	new iIndex = FindStringIndex(table, sEffectName);
	if(iIndex != INVALID_STRING_INDEX)
		return iIndex;
	
	// This is the invalid string index
	return 0;
}

stock GetEffectName(index, String:sEffectName[], maxlen)
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("EffectDispatch");
	}
	
	ReadStringTable(table, index, sEffectName, maxlen);
}

stock PrecacheParticleEffect(const String:sEffectName[])
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	new bool:save = LockStringTables(false);
	AddToStringTable(table, sEffectName);
	LockStringTables(save);
}

stock GetParticleEffectIndex(const String:sEffectName[])
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	new iIndex = FindStringIndex(table, sEffectName);
	if(iIndex != INVALID_STRING_INDEX)
		return iIndex;
	
	// This is the invalid string index
	return 0;
}

stock GetParticleEffectName(index, String:sEffectName[], maxlen)
{
	static table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	ReadStringTable(table, index, sEffectName, maxlen);
}