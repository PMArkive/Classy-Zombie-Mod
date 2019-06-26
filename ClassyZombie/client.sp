void ResetClientVariables(int client)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] ResetClientVariables(%i)", client);
	#endif
	
	// 해당 함수 호출 위치: 클라이언트 입장/퇴장.
	// TODO: 개인 변수 추가할 때 마다 이곳에 함수 호출 위치에 적절한 초기화 코드를 넣을 것!!!
	g_bUserDataLoaded[client] = false;
	g_bThirdPerson[client] = false;
	g_flForceFirstPersonTime[client] = 0.0;
	ChangePersonView(client, false);
	g_fButtonFlags[client] = 0;
	g_bSuppressDamageSound[client] = false;
	g_iPendingTeamNumber[client] = 0;
	g_bShouldCollide[client] = true;
	Format(g_szDefaultArmsModel[client], sizeof(g_szDefaultArmsModel[]), "models/weapons/ct_arms_gign.mdl");
	for (int i = 0; i < sizeof(g_iListenOverride[]); i++)
	{
		g_iListenOverride[client][i] = Listen_Default;
	}
	g_bIsZombie[client] = false;
	g_iVoiceCharacter[client] = -1;
	g_iFirstPenetertor[client] = -1;
	g_iLastPenetertor[client] = -1;
	g_nPenetrationCount[client] = 0;
	g_flFirstInfectionTime[client] = 0.0;
	g_flLastVirusDamagedTime[client] = 0.0;
	g_flZombieRecoverTime[client] = 0.0;
	g_nIncendiaryAmmo[client] = 0;
	g_nExplosiveAmmo[client] = 0;
	g_nArmorPiercingAmmo[client] = 0;
	ZeroVector(g_vecSpawnPoint[client]);
	g_nZteleCount[client] = 0;
	g_iClassId[client] = 0;
	g_iPendingClassId[client] = 0;
	
	g_iBoardAmount[client] = 0;
	g_iBoardOnPlaceControl[client] = -1;
	g_flBoardHeight[client] = 0.0;
	
	g_iAmmoCrateClipAmount[client] = 0;
	
	g_bWeaponCheck[client] = false;
	
	if(!g_bUserDataLoaded[client])
	{
		for (int i = 0; i < sizeof(g_iClassLevel[]); i++)
		{
			g_iClassLevel[client][i] = -1;
		}
	}
	
	if(client == g_iJumpZombie)
		g_iJumpZombie = 0;
	
	if(client == g_iGasZombie)
		g_iGasZombie = 0;
	
	Party_ResetClientPartyStatus(client);		
		
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] ResetClientVariablesPost(%i)", client);
	#endif
}

void ResetPlayerState(int client)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] ResetPlayerState(%i)", client);
	#endif
	// 해당 함수 호출 위치: 클라이언트 스폰, 클라이언트 팀(관전 조인)
	// TODO: 개인 변수 추가할 때 마다 이곳에 함수 호출 위치에 적절한 초기화 코드를 넣을 것!!!
	
	// 바이러스 침투에 관한 변수들을 초기화한다.
	CureHuman(client);
	
	g_flForceFirstPersonTime[client] = 0.0;
	
	g_nIncendiaryAmmo[client] = 0;
	g_nExplosiveAmmo[client] = 0;
	g_nArmorPiercingAmmo[client] = 0;
	g_nZteleCount[client] = 0;
	g_bWeaponCheck[client] = false;
	
	g_iBoardAmount[client] = 0;
	g_iBoardOnPlaceControl[client] = -1;
	g_flBoardHeight[client] = 0.0;
	
	g_iAmmoCrateClipAmount[client] = 0;
	
	CheckPendingClassId(client);
}

stock bool IsClientZombie(int client)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] IsClientZombie(%i)", client);
	#endif
	return (g_bGameStarted && g_bIsZombie[client]);
}

stock void GetClientClassName(int client, char[] className, maxlength)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] GetClientClassName(%i)", client);
	#endif
	if(!IsClientZombie(client) && IsPlayerAlive(client))
	{
		Format(className, maxlength, "%s", g_szConstClassName[g_iClassId[client]]);
	}
	else if(IsClientZombie(client) && IsPlayerAlive(client))
	{
		if(client == g_iHostZombie)
		{
			Format(className, maxlength, "%s", "숙주좀비");
		}
		else if(client == g_iGasZombie)
		{
			Format(className, maxlength, "%s", "변종좀비(가스)");
		}
		else if(client == g_iJumpZombie)
		{
			Format(className, maxlength, "%s", "변종좀비(도약)");
		}
		else
		{
			Format(className, maxlength, "%s", "좀비");
		}
	}
}

void CheckPendingClassId(int client)
{
	if(g_iPendingClassId[client] > 0)
	{
		g_iClassId[client] = g_iPendingClassId[client];
		g_iPendingClassId[client] = 0;
	}
}

// 무기 다 없애기
void RemoveGuns(int client, bool exceptForKnife=false)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] RemoveGuns(%i)", client);
	#endif
	
	if (!(IsClientInGame(client) && IsPlayerAlive(client)))	return;
	
	for(new i = 0; i <= 8; i++)
	{
		int weapon;
		int iCheckCount = 0;
		while((weapon = GetPlayerWeaponSlot(client, i)) != INVALID_ENT_REFERENCE && IsValidEdict(client))
		{
			if(exceptForKnife && i == CS_SLOT_KNIFE)
			{
				char clsname[32];
				if (GetEdictClassname(weapon, clsname, sizeof(clsname)))
				{
					if (StrEqual(clsname, "weapon_knife"))
					{
						if(iCheckCount > 1)
						{
							break;
						}
						else
						{
							iCheckCount++;
							continue;
						}
					}
				}
			}
			
			RemovePlayerItem(client, weapon); 
			RemoveEdict(weapon); 
		}
	}
	
	if(exceptForKnife)
	{
		if(GetPlayerWeaponSlot(client, CS_SLOT_KNIFE) == INVALID_ENT_REFERENCE)
		{
			GivePlayerItem(client, "weapon_knife");
		}
		
		FakeClientCommand(client, "use weapon_knife");
	}
	/*
	int weaponID;
	int MyWeaponsOffset = FindSendPropOffs("CBaseCombatCharacter", "m_hMyWeapons");
	
	for(int x = 0; x < 20; x += 4)
	{
		weaponID = GetEntDataEnt2(client, MyWeaponsOffset + x);
		
		if(weaponID <= 0) {
			continue;
		}
		
		if(exceptForKnife)
		{
			char weaponClassName[128];
			GetEntityClassname(weaponID, weaponClassName, sizeof(weaponClassName));
			
			if(StrEqual(weaponClassName, "weapon_knife", false)) {
				continue;
			}
			
			FakeClientCommand(client, "use weapon_knife");
		}
		
		if(weaponID != -1)
		{
			RemovePlayerItem(client, weaponID);
			RemoveEdict(weaponID);
		}
	}*/
}

stock void SetRadarAndMoneyVisiblity(int client, bool dontHide)
{
	if(!dontHide)
	{
		SetClientHideHud(client, GetClientHideHud(client) | HIDEHUD_RADAR);
		if(IsValidPlayer(client) && g_bWeaponCheck[client])
		{
			SendConVarValue(client, FindConVar("mp_playercashawards"), "0");
			SendConVarValue(client, FindConVar("mp_teamcashawards"), "0");
		}
		// 죽어있을 때에는 
		else if(IsValidClient(client) && IsClientObserver(client))
		{
			SendConVarValue(client, FindConVar("mp_playercashawards"), "0");
			SendConVarValue(client, FindConVar("mp_teamcashawards"), "0");
		}
	}
	else
	{
		SetClientHideHud(client, GetClientHideHud(client) & ~HIDEHUD_RADAR);
		SendConVarValue(client, FindConVar("mp_playercashawards"), "1");
		SendConVarValue(client, FindConVar("mp_teamcashawards"), "1");
	}
}

stock void SetFlashbangCount(int client, int amount)
{
	SetAmmo(client, CSGO_FLASH_AMMO, amount);
}

stock int GetFlashbangCount(int client)
{
	return GetAmmo(client, CSGO_FLASH_AMMO);
}

stock void SetAmmo(int client, int item, int ammo)
{
	SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, item);
}

stock int GetAmmo(int client, int item)
{
	return GetEntProp(client, Prop_Send, "m_iAmmo", _, item);
}

stock int GetWeaponClip(int weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_iClip1");
}

stock void SetWeaponClip(int weapon, int clip)
{
	SetEntProp(weapon, Prop_Send, "m_iClip1", clip);
}

stock int GetWeaponAmmoType(int weapon)
{
	return GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
}

stock void SetWeaponReserveAmmo(int client, int weapon, int ammo)
{
	int iAmmoType = GetWeaponAmmoType(weapon);
	
	if (iAmmoType > 0)
		SetAmmo(client, iAmmoType, ammo);
	
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
	SetEntProp(weapon, Prop_Send, "m_iSecondaryReserveAmmoCount", ammo);	
}

stock int GetWeaponReserveAmmo(int client, int weapon)
{
	int iAmmoType = GetWeaponAmmoType(weapon);
	
	if (iAmmoType > 0)
		return GetAmmo(client, iAmmoType);
		
	return -1;
}

stock int HideWeaponWorldModel(int weapon)
{
	if(IsValidEdict(weapon))
	{
		SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", 0);
		int weaponworldmodel = GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel");
		if(IsValidEdict(weaponworldmodel))
		{
			SetEntProp(weaponworldmodel, Prop_Send, "m_nModelIndex", 0);
		}
	}	
}

void ValidateHostZombieMoveSpeed(int client)
{
	if(client == g_iHostZombie)
	{
		int iCurrentHealth = GetClientHealth(client);
		// 15001 ~ 20000
		if(ZOMBIE_MAX_HEALTH*3/4 < iCurrentHealth && iCurrentHealth <= ZOMBIE_MAX_HEALTH)
		{
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.2);
			SetEntityGravity(client, 0.90);
		}
		// 10001 ~ 15000
		else if(ZOMBIE_MAX_HEALTH*2/4 < iCurrentHealth && iCurrentHealth <= ZOMBIE_MAX_HEALTH*3/4) 
		{
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.3);
			SetEntityGravity(client, 0.90);
		}
		// 1500 ~ 10000
		else
		{
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.4);
			SetEntityGravity(client, 0.90);
		}
	}
}

// 좀비화
void InfectHuman(int victim, int attacker)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] InfectHuman(%i, %i)", victim, attacker);
	#endif
	
	if(!IsValidPlayer(victim) || !IsValidClient(attacker))
		return;
	
	Event event = CreateEvent("player_death");
	if(event != null)
	{
		event.SetInt("userid", GetClientUserId(victim));
		event.SetInt("attacker", GetClientUserId(attacker));
		if(g_iFirstPenetertor[victim] != attacker && IsValidClient(g_iFirstPenetertor[victim]))
			event.SetInt("assister", GetClientUserId(g_iFirstPenetertor[victim]));
		event.SetString("weapon", "knife");
		event.Fire(false);
	}
	
	MakeClientZombie(victim, attacker);
}

// 바이러스 침투
void PenetrateVirus(int victim, int attacker)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] PenetrateVirus(%i, %i)", victim, attacker);
	#endif
	
	if(g_iClassId[victim] == 6 || g_iClassId[victim] == 7)
		return;
	
	if(g_flFirstInfectionTime[victim] <= 0.0)
		g_flFirstInfectionTime[victim] = GetGameTime(); // TODO: init.
	
	if(!IsValidClient(g_iFirstPenetertor[victim]))
		g_iFirstPenetertor[victim] = attacker;
	
	g_iLastPenetertor[victim] = attacker;
	g_nPenetrationCount[victim]++;
}

// 좀비 바이러스 치유
void CureHuman(int client)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] CureHuman(%i)", client);
	#endif
	
	g_iFirstPenetertor[client] = -1;
	g_iLastPenetertor[client] = -1;
	g_nPenetrationCount[client] = 0;
	
	g_flFirstInfectionTime[client] = 0.0;
	g_flLastVirusDamagedTime[client] = 0.0;
}

void SetClientClassFeature(int client)
{
	/*
	클라이언트의 클래스당 특성을 적용한다.
	호출 위치: 클라이언트 스폰
	*/
	
	CheckPendingClassId(client);
	
	if (IsWarmupPeriod())	return;
	
	int iHealthAmoutToSet = 100;
	
	int weapon = -1;
	int iAmmoToGive = 0;
	
	// 보병(기동성)
	if(g_iClassId[client] == 1)
	{
		weapon = GivePlayerItem(client, "weapon_elite");
		iAmmoToGive = 120;
		
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.10 + (g_iClassLevel[client][0]*0.02));
		
		SetEntityGravity(client, 0.85);
	}
	// 보병(정확성)
	else if(g_iClassId[client] == 2)
	{
		weapon = GivePlayerItem(client, "weapon_p250");
		iAmmoToGive = 130;
		
		iHealthAmoutToSet = 200;
		
	}
	// 보병(화력성)
	else if(g_iClassId[client] == 3)
	{
		weapon = GivePlayerItem(client, "weapon_deagle");
		iAmmoToGive = 70;
		
		iHealthAmoutToSet = 250 + (g_iClassLevel[client][2]*20);
	}
	// 저격병
	else if(g_iClassId[client] == 4)
	{
		weapon = GivePlayerItem(client, "weapon_cz75a");
		iAmmoToGive = 120;
		iHealthAmoutToSet = 150;
		
		// 4렙 단위로 판자 하나씩 증가 base=2
		g_iBoardAmount[client] = 2 + RoundToFloor(g_iClassLevel[client][3]*0.25);
	}
	// 지원병
	else if(g_iClassId[client] == 5)
	{
		weapon = GivePlayerItem(client, "weapon_usp_silencer");
		iAmmoToGive = 120;
		
		
		g_iAmmoCrateClipAmount[client] = 600 + (g_iClassLevel[client][4]*60);
	}
	// 의무병
	else if(g_iClassId[client] == 6)
	{
		weapon = GivePlayerItem(client, "weapon_fiveseven");
		iAmmoToGive = 120;
		
		iHealthAmoutToSet = 200 + (g_iClassLevel[client][5]*20);
	}
	
	SetEntityHealth(client, iHealthAmoutToSet);
	SetEntProp(client, Prop_Data, "m_iMaxHealth", iHealthAmoutToSet);
	
	if(IsValidEdict(weapon))
	{
		DataPack pack = CreateDataPack();
		pack.WriteCell(client);
		pack.WriteCell(weapon);
		pack.WriteCell(iAmmoToGive);
		
		RequestFrame(SetPistolAmmo, pack);
	}
	
	if(g_iClassId[client] > 0)
		Command_WeaponShop(client);
}

public void SetPistolAmmo(DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	int weapon = pack.ReadCell();
	int ammo = pack.ReadCell();
	delete pack;
	if(IsValidClient(client) && IsValidEdict(weapon))
		SetWeaponReserveAmmo(client, weapon, ammo);
}

// 총으로 쏘는 등의 데미지 넉백의 상황에서 적용됨
// 공격자와 피격자 사이의 각도와는 상관없이 무조건 공격자가 보는 방향으로 벡터가 가해진다.
void PushPlayerBack(attacker, victim, float flScale)
{
	if (attacker == victim)		return;
	
	float angAttackerEyeAngles[3], vecKnockBackVector[3];
	
	if(IsValidPlayer(attacker))
		GetClientEyeAngles(attacker, angAttackerEyeAngles);
	else
		GetEntPropVector(attacker, Prop_Data, "m_angRotation", angAttackerEyeAngles);
	
	vecKnockBackVector[0] = FloatMul(Cosine(DegToRad(angAttackerEyeAngles[1])), flScale);
	vecKnockBackVector[1] = FloatMul(Sine(DegToRad(angAttackerEyeAngles[1])), flScale);
	vecKnockBackVector[2] = FloatMul(Sine(DegToRad(angAttackerEyeAngles[0])), flScale);
	
	float playerspeed[3];
	GetEntPropVector(victim, Prop_Data, "m_vecVelocity", playerspeed);
	AddVectors(vecKnockBackVector, playerspeed, vecKnockBackVector);
	
	TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vecKnockBackVector);
}

// 총으로 쏜 것 이외의 상황(숙주 감염, 나무판자 밀치기)에서 적용됨
void MakeKnockBack(int attacker, int victim, float flKnockbackScale=350.0, bool noHeightVector=false)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] MakeKnockBack(%i -%.0f> %i)", attacker, flKnockbackScale, victim);
	#endif
	
	if (attacker == victim)	return;
	
	float vecReturn[3], startOrigin[3], endOrigin[3];
	
	GetEntPropVector(attacker, Prop_Data, "m_vecAbsOrigin", startOrigin);
	GetEntPropVector(victim, Prop_Data, "m_vecAbsOrigin", endOrigin);
	endOrigin[2] += 50;
	
	MakeVectorFromPoints(startOrigin, endOrigin, vecReturn);
	NormalizeVector(vecReturn, vecReturn);
	
	if(IsValidEdict(attacker) || IsValidPlayer(attacker))
	{
		ScaleVector(vecReturn, flKnockbackScale); // 200
	}
	else
	{		
		if(startOrigin[2] < endOrigin[2])
			ScaleVector(vecReturn, flKnockbackScale+(flKnockbackScale/2)); // 300
		else
			ScaleVector(vecReturn, flKnockbackScale); // 200
	}
	
	if(noHeightVector)
		vecReturn[2] = 0.0;
		
	TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vecReturn);
}

void SetClientArms(int client, char[] model=NULL_STRING)
{
	char currentmodel[128];
	GetEntPropString(client, Prop_Send, "m_szArmsModel", currentmodel, sizeof(currentmodel));
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", false, 1);
	
	if(!StrEqual(model, NULL_STRING)) 
	{
		if(!StrEqual(currentmodel, model)) SetEntPropString(client, Prop_Send, "m_szArmsModel", model);
	}
	else
	{
		if(!StrEqual(currentmodel, g_szDefaultArmsModel[client])) SetEntPropString(client, Prop_Send, "m_szArmsModel", g_szDefaultArmsModel[client]);
	}
	
	// 디버그시도!!
	RequestFrame(SetDrawViewModel, client);
}
// 디버그시도!!
public void SetDrawViewModel(any client)
{
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", true, 1);
}

void CleanClientArms(int client)
{
	/*
	char currentmodel[128];
	GetEntPropString(client, Prop_Send, "m_szArmsModel", currentmodel, sizeof(currentmodel));
	
	if(!StrEqual(currentmodel, g_szDefaultArmsModel[client]))
	{
		CreateTimer(0.5, Cleaner, client, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.75, Cleaner, client, TIMER_FLAG_NO_MAPCHANGE);
	}*/
	
	CreateTimer(0.5, Cleaner, client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.75, Cleaner, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Cleaner(Handle timer, any client)
{
	if(IsValidPlayer(client))
	{
	 	SetClientArms(client);
		if(GetClientTeam(client) == CS_TEAM_T)
		{
			CS_SwitchTeam(client, CS_TEAM_CT);
		}
		else if(GetClientTeam(client) == CS_TEAM_CT)
		{
			CS_SwitchTeam(client, CS_TEAM_T);
		}
	}
}

/**********************************************************************************************
클라이언트에 대한 시각적 및 청각적 효과 관련 함수
***********************************************************************************************/

#define FFADE_IN		0x0001		// Fade In
#define FFADE_OUT		0x0002		// Fade out
#define FFADE_PURGE		0x0010		// Purges all other fades, replacing them with this one

stock void Fade(int client, float duration)
{
	Handle hFadeClient = StartMessageOne("Fade", client);
	if (hFadeClient == null)
		return;
	
	
	float FadePower = 1.0; // Scales the fade effect, 1.0 = Normal , 2.0 = 2 x Stronger fade, etc
	
	FadePower *= 1000.0; // duration => 밀리세컨드 단위이므로 1000을 곱해준다.
	int coloroffset = 255 - RoundToFloor(duration * 85);
	//지속시간 값이 적을수록 coloroffset값은 높아진다...
	
	int color[4];
	color[0] = 0;
	color[1] = 127;
	color[2] = 255;
	color[3] = 255-(coloroffset/2);
	
	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
	{
		PbSetInt(hFadeClient, "duration", RoundToFloor(duration*FadePower));
		PbSetInt(hFadeClient, "hold_time", 0);
		PbSetInt(hFadeClient, "flags", FFADE_IN | FFADE_PURGE);
		PbSetColor(hFadeClient, "clr", color);
	}
	else
	{
		BfWriteShort(hFadeClient, RoundToFloor(duration));	// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, milliseconds duration
		BfWriteShort(hFadeClient, 0);	// FIXED 16 bit, with SCREENFADE_FRACBITS fractional, milliseconds duration until reset (fade & hold)
		BfWriteShort(hFadeClient, FFADE_IN | FFADE_PURGE); // fade type (in / out)
		BfWriteByte(hFadeClient, color[0]);	// fade red
		BfWriteByte(hFadeClient, color[1]);	// fade green
		BfWriteByte(hFadeClient, color[2]);	// fade blue
		BfWriteByte(hFadeClient, color[3]);// fade alpha
		
	}
	EndMessage();
//	delete hFadeClient;
}

stock void Shake(int client, float duration)
{
	Handle hShake = StartMessageOne("Shake", client, 1); // 이 StartMessageOne 함수의 세번째 인수값은 원래 0이었음. 2015/05/27
	if (hShake == null)
		return;
	
	float ShakePower = 25.0; // Scales the shake effect, 1.0 = Normal , 2.0 = 2 x Stronger shake, etc
	float shk = (duration * ShakePower);
	
	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
	{
		PbSetInt(hShake, "command", 0);
		PbSetFloat(hShake, "local_amplitude", shk);
		PbSetFloat(hShake, "frequency", 1.0);
		PbSetFloat(hShake, "duration", duration);
	}
	else
	{
		BfWriteByte(hShake,  0);
		BfWriteFloat(hShake, shk);
		BfWriteFloat(hShake, 1.0);
		BfWriteFloat(hShake, duration);
	}
	EndMessage();
	
	g_flForceFirstPersonTime[client] = GetGameTime() + duration;
//	delete hShake;
}

stock void ShakeScreen(int client, float amplitude=15.0, float frequency=1.0, float duration=5.0)
{
	Handle hShake = StartMessageOne("Shake", client);
    
    // Validate.
	if (hShake == null)	return;
    
	// Future code using protocol buffers (not tested). Enabling this will bump
	// SourceMod version requirement to a snapshot, we don't want to do that
    // until that branch is declared stable.
	if (GetUserMessageType() == UM_Protobuf)
	{
		PbSetInt(hShake, "command", 0);
		PbSetFloat(hShake, "local_amplitude", amplitude);
		PbSetFloat(hShake, "frequency", frequency);
		PbSetFloat(hShake, "duration", duration);
	}
	else
	{
		BfWriteByte(hShake, 0);
		BfWriteFloat(hShake, amplitude);
		BfWriteFloat(hShake, frequency);
		BfWriteFloat(hShake, duration);
	}

	EndMessage();
}

stock TE_SetupBubbles(const float vecMins[3], const float vecMaxs[3], int iModelCacheIndex, float flHeight, int iAmount, float flSpeed)
{
	TE_Start("Bubbles");
	TE_WriteVector("m_vecMins", vecMins); // 버블이 퍼지는 최소거리.
	TE_WriteVector("m_vecMaxs", vecMaxs); // 버블이 퍼지는 최대거리. 최소거리부터 최대거리까지의 선 위에서서 버블이 퍼진다
	TE_WriteNum("m_nModelIndex", iModelCacheIndex); // 이펙트 메터리얼
	TE_WriteFloat("m_fHeight", flHeight); // 얼마나 높이 올라갈 것인가
	TE_WriteNum("m_nCount", iAmount); // 몇개를 소환 할 것인가
	TE_WriteFloat("m_fSpeed", flSpeed); // 어느정도의 속도로 퍼질 것인가 (올라가는 속도에는 지장 없음, 버블이 퍼지는 정도 라고 보면된다)
}

// cam_idealyaw
void ChangePersonView(int client, bool third)
{
	if(IsValidClient(client))
	{
		if(!third)
		{
	//		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
			ClientCommand(client, "firstperson");
			if(CPS_HasSkin(client))
				CPS_SetTransmit(client, client, 0);
		}
		else
		{
			if(IsPlayerAlive(client))
			{
		//		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
				ClientCommand(client, "thirdperson");
				if(CPS_HasSkin(client))
					CPS_SetTransmit(client, client, 1);
			}
		}
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", !third, 1);
	}
}

/*
stock CreateSprite(iClient, String:sprite[], Float:offset)
{
	decl String:szTemp[ 64 ]; 
	Format( szTemp, sizeof( szTemp ), "client%i", iClient );
	DispatchKeyValue( iClient, "targetname", szTemp );

	decl Float:vOrigin[ 3 ];
	GetClientAbsOrigin( iClient, vOrigin );
	vOrigin[ 2 ] += offset;
	new ent = CreateEntityByName( "env_sprite_oriented" );
	SetEntityRenderMode( ent, RENDER_TRANSCOLOR );
	
	if ( ent > 0 ) //If we can create the entity (2048 max thing I guess)
	{
		DispatchKeyValue( ent, "model", sprite );
		DispatchKeyValue( ent, "classname", "env_sprite_oriented" );
		DispatchKeyValue( ent, "spawnflags", "1" );
		DispatchKeyValue( ent, "scale", "0.1" );
		DispatchKeyValue( ent, "rendermode", "1" );
		DispatchKeyValue( ent, "rendercolor", "255 255 255" );
		DispatchKeyValue( ent, "targetname", "redcross_spr" );
		DispatchKeyValue( ent, "parentname", szTemp );
		DispatchSpawn( ent );
		
		TeleportEntity( ent, vOrigin, NULL_VECTOR, NULL_VECTOR );

		g_iEnts[ iClient ] = ent;
		
	}
	else //Can't get a sprite (too many ent)
	{
		g_iEnts[ iClient ] = MEDIC_WITHOUT_ICON;
	}
}

//Remove the sprite if there's ones
stock KillSprite(iClient)
{
	if ( g_iEnts[ iClient ] > 0 && IsValidEntity( g_iEnts[ iClient ] ) )
	{
		AcceptEntityInput( g_iEnts[ iClient ], "kill" );
	}
	g_iEnts[ iClient ] = 0;
}
*/

/*무기월드모델제거
#include <sdkhooks>
#include <sdktools>

#define CSAddon_NONE            0
#define CSAddon_Flashbang1      (1<<0)
#define CSAddon_Flashbang2      (1<<1)
#define CSAddon_HEGrenade       (1<<2)
#define CSAddon_SmokeGrenade    (1<<3)
#define CSAddon_C4              (1<<4)
#define CSAddon_DefuseKit       (1<<5)
#define CSAddon_PrimaryWeapon   (1<<6)
#define CSAddon_SecondaryWeapon (1<<7)
#define CSAddon_Holster         (1<<8) 

public OnPluginStart()
{
   RegConsoleCmd("sm_test", test);
}

public Action:test(user, args)
{
    for(new client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client))
        {
            SDKHookEx(client, SDKHook_PostThinkPost, OnPostThinkPost);
            SetEntProp(client, Prop_Send, "m_nRenderFX", RENDERFX_NONE);
            SetEntProp(client, Prop_Send, "m_nRenderMode", RENDER_NONE);
        }
    }



    new entity = MaxClients+1;

    while( (entity = FindEntityByClassname(entity, "weaponworldmodel")) != -1 )
    {
        SetEntProp(entity, Prop_Send, "m_nModelIndex", 0);
    }
}

public OnPostThinkPost(client)
{
    //SetEntProp(client, Prop_Send, "m_iPrimaryAddon", CSAddon_NONE);
    //SetEntProp(client, Prop_Send, "m_iSecondaryAddon", CSAddon_NONE);
    SetEntProp(client, Prop_Send, "m_iAddonBits", CSAddon_NONE);
}  
*/
/*발소리제거
#include <sdktools> 

bool IsPlayerNinja[MAXPLAYERS + 1]; 
ConVar sv_footsteps; 

public OnPluginStart() 
{ 
    LoadTranslations("common.phrases"); 
    sv_footsteps = FindConVar("sv_footsteps"); 

    RegConsoleCmd("sm_test", test); 

    AddNormalSoundHook(FootstepCheck); 

    for(int i = 1; i <= MaxClients; i++) 
    { 
        if(IsClientInGame(i) && !IsFakeClient(i))    OnClientPutInServer(i); 
    } 
} 

public Action test(int client, int args) 
{ 
    char arg[MAX_NAME_LENGTH]; 
    GetCmdArg(1, arg, sizeof(arg)); 
    int target = FindTarget(client, arg, false, false); 

    if(target != -1) 
    { 
        IsPlayerNinja[target] = IsPlayerNinja[target] ? false:true; 
        ReplyToCommand(client, "%N is %s", target, IsPlayerNinja[target] ? "Ninja!":"not Ninja."); 
    } 

    return Plugin_Handled; 
} 

public void OnClientPutInServer(client) 
{ 
    if(!IsFakeClient(client))        SendConVarValue(client, sv_footsteps, "0"); 
} 

public Action:FootstepCheck(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags) 
{ 
    // Player 
    if (0 < entity <= MaxClients) 
    { 
        if(StrContains(sample, "physics") != -1 || StrContains(sample, "footsteps") != -1) 
        { 
            // Player not ninja, play footsteps 
            if(!IsPlayerNinja[entity]) 
            { 
                numClients = 0; 

                for(int i = 1; i <= MaxClients; i++) 
                { 
                    if(IsClientInGame(i) && !IsFakeClient(i)) 
                    { 
                        clients[numClients++] = i; 
                    } 
                } 

                EmitSound(clients, numClients, sample, entity); 
                //return Plugin_Changed; 
            } 
            return Plugin_Stop; 
        } 
    } 
    return Plugin_Continue; 
}  
*/