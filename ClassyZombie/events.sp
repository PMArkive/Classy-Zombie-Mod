static int iOldReloadState[MAXPLAYERS + 1];

static int iSpyCigaretteEnt[MAXPLAYERS + 1] = {-1, ...};

/****************************** General *****************************/
public void OnMapStart()
{
	ServerCommand("hostname \"[KR][B★RS] 뱅슈터의 좀비서버 [!!!Open Beta!!!]\"");
	
	CleanUp(true, true);
	RequestFrame(SetConVars);
	
	PrepareResources();
	
	Party_Reset();
	
	Para_OnMapStart();
	ItemEvent_OnMapStart();
	//	WeaponModels_AddWeaponByClassName("weapon_knife", "models/ghost/ghost.mdl", "models/ghost/ghost.mdl", WeaponModels_OnWeapon);
}

public void OnClientPutInServer(int client)
{
	#if defined _DEBUG_
	PrintToServer("[BST Zombie] OnClientPutInServer(%i)", client);
	#endif
	
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_TraceAttack, TraceAttack);
	SDKHook(client, SDKHook_WeaponCanUse, OnClientCanUseWeapon);
	SDKHook(client, SDKHook_WeaponDropPost, OnWeaponDropPost);
	
	SDKHook(client, SDKHook_ShouldCollide, OnShouldCollide);
	SDKHook(client, SDKHook_StartTouch, Touch);
	SDKHook(client, SDKHook_Touch, Touch);
	
	// 다시는 스팡니를 무시하지 말아라...
	iSpyCigaretteEnt[client] = -1;
	
	Para_OnClientPutInServer(client);
	
	#if defined _DEBUG_
	PrintToServer("[BST Zombie] OnClientPutInServerPost(%i)", client);
	#endif
}

public void OnClientAuthorized(int client)
{
	#if defined _DEBUG_
	PrintToServer("[BST Zombie] OnClientAuthorized(%i)", client);
	#endif
	
	ResetClientVariables(client);
	
	#if defined _DEBUG_
	PrintToServer("[BST Zombie] OnClientAuthorizedPost(%i)", client);
	#endif
}

public void OnClientPostAdminCheck(int client)
{
	DB_OnClientPostAdminCheck(client);
	Cmd_ClassMenu(client, 0);
}

public void OnClientDisconnect(int client)
{
	#if defined _DEBUG_
	PrintToServer("[BST Zombie] OnClientDisconnect(%i)", client);
	#endif
	
	ResetClientVariables(client);
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKUnhook(client, SDKHook_TraceAttack, TraceAttack);
	SDKUnhook(client, SDKHook_WeaponCanUse, OnClientCanUseWeapon);
	SDKUnhook(client, SDKHook_WeaponDropPost, OnWeaponDropPost);
	
	SDKUnhook(client, SDKHook_ShouldCollide, OnShouldCollide);
	SDKUnhook(client, SDKHook_StartTouch, Touch);
	SDKUnhook(client, SDKHook_Touch, Touch);
	
	if (GetPlayerCount() < MIN_PLAYER_TO_PLAY)
	{
		StartWarmup();
		return;
	}
	
	// 준비 시간이 아니고, 좀비 선택시간이 아니며, 게임이 시작되었을 때. (완전히 게임이 진행중일 때)
	if (!IsWarmupPeriod() && g_bGameStarted && !g_bHostSelectionTime)
	{
		if (GetTeamClientCount(CS_TEAM_T) <= 0)
		{
			// 대테러리스트 승리
			CS_TerminateRound(GetRoundRestartDelay(), CSRoundEnd_CTWin);
			return;
		}
		// 주의! 이 조건문에 else if를 하지 않을 시, 테러 0명, 대테러 0명인 상황에서 서버가 터진다!(중첩 라운드 종료 문제)
		else if (GetTeamClientCount(CS_TEAM_CT) <= 0)
		{
			// 테러리스트 승리
			CS_TerminateRound(GetRoundRestartDelay(), CSRoundEnd_TerroristWin);
			return;
		}
	}
	
	Para_OnClientDisconnect(client);
	
	#if defined _DEBUG_
	PrintToServer("[BST Zombie] OnClientDisconnectPost(%i)", client);
	#endif
}

public void OnWeaponDropPost(int client, int weapon)
{
	if (IsValidClient(client) && IsValidEdict(weapon))
	{
		DataPack pack = CreateDataPack();
		pack.WriteCell(client);
		pack.WriteCell(weapon);
		RequestFrame(PrintAmmoCount, pack);
	}
}

public void PrintAmmoCount(DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	int weapon = pack.ReadCell();
	delete pack;
	if (IsValidClient(client) && IsValidEdict(weapon))
	{
		SetWeaponReserveAmmo(client, weapon, GetEntProp(weapon, Prop_Send, "m_iSecondaryReserveAmmoCount"));
	}
	/*
	PrintToChat(client, "ReserveAmmoBindedToClient: %i", GetWeaponReserveAmmo(client, weapon));
	PrintToChat(client, "m_iPrimaryReserveAmmoCount: %i", GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount"));
	PrintToChat(client, "m_iSecondaryReserveAmmoCount: %i", GetEntProp(weapon, Prop_Send, "m_iSecondaryReserveAmmoCount"));
	*/
	
}

/**** 플레이어 충돌 가능 체크 부분 ****/
public bool OnShouldCollide(int entity, int collisiongroup, int contentsmask, bool result)
{
	#if defined _DEBUG_
	PrintToServer("[BST Zombie] OnShouldCollide(%i)", entity);
	#endif
	if (contentsmask == 33636363)
	{
		if (!g_bShouldCollide[entity])
		{
			result = false;
			return false;
		}
		else
		{
			result = true;
			return true;
		}
	}
	
	return true;
}

public Touch(ent1, ent2)
{
	#if defined _DEBUG_
	PrintToServer("[BST Zombie] Touch(%i <-> %i)", ent1, ent2);
	#endif
	
	if (ent1 == ent2)
		return;
	if (ent1 > MaxClients || ent1 == 0)
		return;
	if (ent2 > MaxClients || ent2 == 0)
		return;
	
	// 같은 좀비면 충돌 가능하도록 한다.
	//	if(GetClientTeam(ent1) == GetClientTeam(ent2))
	if (IsClientZombie(ent1) && IsClientZombie(ent2))
	{
		g_bShouldCollide[ent1] = true;
		g_bShouldCollide[ent2] = true;
		return;
	}
	
	g_bShouldCollide[ent1] = false;
	g_bShouldCollide[ent2] = false;
}

/**** 플레이어 충돌 가능 체크 부분 끝****/

/*
public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	if(!IsWarmupPeriod())
	{
		if(!g_bGameStarted && g_bHostSelectionTime)
		{
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}*/

public Action OnClientJoinTeam(int client, const char[] command, int argc)
{
	#if defined _DEBUG_
	PrintToServer("[BST Zombie] OnClientJoinTeam()");
	#endif
	
	char Arg[8];
	GetCmdArg(1, Arg, sizeof(Arg));
	
	if (g_bUserDataLoaded[client])
	{
		// 유효한 병과가있는지 체크 후 알맞는 메뉴를 띄움.
		// 유효한 병과가 없거나 선택된 병과가 없으면 팀 이동을 중단시킨다.
		if (!ForceClientSelectClass(client, false, StringToInt(Arg) != 1 ? CS_TEAM_CT : CS_TEAM_SPECTATOR))
		{
			return Plugin_Handled;
		}
		// 팀 이동을 허용할 때
		else
		{
			// 준비 시간도 아니고, 게임이 시작됐을 경우, 클라이언트가 살아있다면
			if (!IsWarmupPeriod() && g_bGameStarted && IsPlayerAlive(client))
			{
				// 이동을 막는다.
				return Plugin_Handled;
			}
		}
	}
	else
	{
		PrintToChat(client, "%s\x04유저 데이터가 완전히 로드되지 않았습니다, 잠시 후 다시 시도해주세요.", PREFIX);
		Cmd_LoadUserData(client, 0);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action OnNormalSoundEmit(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	if (StrContains(sample, "physics/flesh/flesh_impact_bullet") != -1)
	{
		if (IsValidPlayer(entity) && g_bSuppressDamageSound[entity])
		{
			g_bSuppressDamageSound[entity] = false;
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	#if defined _DEBUG_
	PrintToServer("[BST Zombie] OnTakeDamage(%i -%.0f> %i)", attacker, damage, victim);
	#endif
	
	if (!g_bGameStarted || g_bRoundEnded)
		return Plugin_Stop;
	
	// 피해자와 공격자 모두 유효한 클라이언트여야 함!
	// 게임 시작 이전 공격 무효 체크를 위해 피해자를 먼저 체크한 뒤, 공격자를 체크한다.
	if (!IsValidClient(victim))
		return Plugin_Continue;
	
	if (damagetype & DMG_ENERGYBEAM)
		return Plugin_Stop;
	
	// 인간이 낙하 데미지를 받았을 때
	if (!IsClientZombie(victim) && damagetype & DMG_FALL)
	{
		// 낙하 데미지가 현재 체력보다 높을 때(낙사할 때)
		if (damage >= GetClientHealth(victim))
		{
			// 바이러스에 감염되었을 때.
			if (g_nPenetrationCount[victim] > 0)
			{
				InfectHuman(victim, IsValidClient(g_iLastPenetertor[victim]) ? g_iLastPenetertor[victim]:0);
			}
		}
	}
	
	if (!IsValidClient(attacker))
		return Plugin_Continue;
	
	int victimTeam = GetClientTeam(victim);
	int attackerTeam = GetClientTeam(attacker);
	// ShakeScreen(client, 1.5, 10.0, 2.5); // on damage
	
	char strWeaponName[32], strInflictorName[32];
	if (IsValidEdict(weapon))GetEdictClassname(weapon, strWeaponName, sizeof(strWeaponName));
	if (IsValidEdict(inflictor))GetEdictClassname(inflictor, strInflictorName, sizeof(strInflictorName));
	
	if (!g_bGameStarted || victimTeam == attackerTeam)
	{
		if (StrEqual("Explosion_Ammo", strInflictorName, false))
		{
			return Plugin_Stop;
		}
	}
	
	// 좀비 ==>> 인간
	if (IsClientZombie(attacker) && !IsClientZombie(victim))
	{
		// 데미지 타입이 DMG_POISON과 DMG_SLASH 둘 다 아닌경우, 모종의 다른 데미지가 작용한 것이다.
		if(!((damagetype & DMG_POISON) || (damagetype & DMG_SLASH)))
			return Plugin_Stop; // 따라서 데미지 무효화
		
		// 숙주, 연산 전의 데미지가 체력을 초과
		// GetClientHealth(victim) <= damage 로 인해 등을 찍었을 때에도 데미지 감소 없이 연산되므로 바로 좀비가 될 수 있다.
		if (attacker == g_iHostZombie || GetClientHealth(victim) <= damage)
		{
			InfectHuman(victim, attacker);
			return Plugin_Handled;
		}
		else
		{
			damage *= 0.25;
			
			// 바이러스가 침투하지 않으므로 데미지를 좀 더 줘야한다.
			if (g_iClassId[victim] == 6)
			{
				damage *= 2.0;
			}
			else if (g_iClassId[victim] == 7)
			{
				damage *= 1.5;
			}
			// 의무병이나 베테랑이 아니면 바이러스가 체내에 침투한다.
			else
			{
				PenetrateVirus(victim, attacker);
			}
			
			return Plugin_Changed;
		}
	}
	// 인간 ==>> 좀비
	else if (!IsClientZombie(attacker) && IsClientZombie(victim))
	{
		/*****************
		  크리티컬 제어부
		******************/
		
		// 숙주가 데미지를 입어 생기는 속도 저하 제거
		DataPack pack = CreateDataPack();
		pack.WriteCell(attacker);
		pack.WriteCell(victim);
		RequestFrame(RecoverZombieVelocity, pack);
		
		if (StrEqual("knife", strWeaponName[7], false))
		{
			if (damage > 80)
			{
				damage = 80.0;
			}
		}
		
		// 보병(정확성)
		if (g_iClassId[attacker] == 2)
		{
			if (StrEqual("sg556", strWeaponName[7], false) || StrEqual("aug", strWeaponName[7], false))
			{
				int Crit;
				float Crit2;
				/*
				레벨 10에서 무조건 크리티컬이 뜨게 된다!
				*/
				if (g_iClassLevel[attacker][1] <= 20)Crit = GetRandomInt(0, 20 - g_iClassLevel[attacker][1]);
				
				if (Crit <= g_iClassLevel[attacker][1])
				{
					if (g_iClassLevel[attacker][1] <= 8)
						Crit2 = GetRandomFloat(1.2 + (g_iClassLevel[attacker][1] * 0.1), 2.0);
					else
						Crit2 = GetRandomFloat(2.0, 2.0 + (g_iClassLevel[attacker][1] * 0.1));
					
					//					PrintToChat(attacker, "\x04[SM] - \x01크리티컬 데미지 !! : \x03%3.0f", damage*Crit2);
					PrintHintText(attacker, "크리티컬 데미지 !! : <font color='#7f7fff'>%.0f</font>", damage * Crit2);
					damage *= Crit2;
				}
			}
		}
		
		if (g_iClassId[attacker] == 6)
		{
			damage *= 0.8;
		}
		
		if (g_iClassId[attacker] == 7)
		{
			if (!StrEqual("hegrenade_projectile", strInflictorName, false) && !StrEqual("knife", strWeaponName[7], false))
			{
				int Crit;
				Crit = GetRandomInt(1, 15);
				
				if (Crit <= 5)
				{
					float Crit2;
					Crit2 = GetRandomFloat(2.0, 2.5);
					
					PrintHintText(attacker, "크리티컬 데미지 !! : <font color='#7f7fff'>%.0f</font>", damage * Crit2);
					damage *= Crit2;
				}
			}
		}
		
		/*****************
		   아이템 제어부
		******************/
		// 주무기를 들고 있는 경우에만
		if (GetPlayerWeaponSlot(attacker, CS_SLOT_PRIMARY) == GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon"))
		{
			if (g_nIncendiaryAmmo[attacker] > 0)
			{
				IgniteEntity(victim, 3.0, false, 0.1, false);
			}
			
			if (g_nArmorPiercingAmmo[attacker] > 0)
			{
				damage *= 1.1;
			}
		}
		
		/*** 숙주의 체력에 따른 이동속도 제어 ***/
		ValidateHostZombieMoveSpeed(victim);
		
		/*****************
		    넉백 제어부
		******************/
		// 보병(화력성)
		if (g_iClassId[attacker] == 3)
		{
			if (StrEqual("nova", strWeaponName[7], false) || StrEqual("mag7", strWeaponName[7], false) || StrEqual("xm1014", strWeaponName[7], false))
			{
				PushPlayerBack(attacker, victim, damage * (1.0 + (0.1 * g_iClassLevel[attacker][2])));
			}
			else
			{
				if (!StrEqual("hegrenade", strWeaponName[7], false) && !StrEqual("knife", strWeaponName[7], false))
					PushPlayerBack(attacker, victim, damage * 1.0);
			}
		}
		// 저격병
		else if (g_iClassId[attacker] == 4)
		{
			if (StrEqual("ssg08", strWeaponName[7], false)
				 || StrEqual("awp", strWeaponName[7], false)
				 || StrEqual("g3sg1", strWeaponName[7], false)
				 || StrEqual("scar20", strWeaponName[7], false))
			{
				PushPlayerBack(attacker, victim, damage * (1.0 + (0.5 * g_iClassLevel[attacker][3])));
			}
			else
			{
				if (!StrEqual("hegrenade", strWeaponName[7], false) && !StrEqual("knife", strWeaponName[7], false))
					PushPlayerBack(attacker, victim, damage * 1.0);
			}
		}
		else if (!StrEqual("hegrenade", strWeaponName[7], false) && !StrEqual("knife", strWeaponName[7], false))
		{
			PushPlayerBack(attacker, victim, damage * 1.0);
		}
		
		/*******************************
		 히트 사운드 및 흔들림 효과 제어부
		********************************/
		
		/*** 히트 사운드 제어 ***/
		/* TODO
		// 머리에 맞은 경우(헤드샷)
		int RandomSound;
		if(damagetype & (1 << 30))
		{
			RandomSound = GetRandomInt(1, 3);

			if(RandomSound == 1)	EmitSoundToAll(HeadShot1, client, _, _, _, 1.0);
			else if(RandomSound == 2)	EmitSoundToAll(HeadShot2, client, _, _, _, 1.0);
			else if(RandomSound == 3)	EmitSoundToAll(HeadShot3, client, _, _, _, 1.0);
		}
		
		RandomSound = GetRandomInt(1, 6);
	
		if(RandomSound == 1)	EmitSoundToAll(ZombiePain1, client, _, _, _, 1.0);
		else if(RandomSound == 2)	EmitSoundToAll(ZombiePain2, client, _, _, _, 1.0);
		else if(RandomSound == 3)	EmitSoundToAll(ZombiePain3, client, _, _, _, 1.0);
		else if(RandomSound == 4)	EmitSoundToAll(ZombiePain4, client, _, _, _, 1.0);
		else if(RandomSound == 5)	EmitSoundToAll(ZombiePain5, client, _, _, _, 1.0);
		else if(RandomSound == 6)	EmitSoundToAll(ZombiePain6, client, _, _, _, 1.0);
		*/
		
		/*** 흔들림 효과 제어 ***/
		int iShakeFactor = 150;
		if (victim == g_iHostZombie)
			Shake(victim, damage / (iShakeFactor * 3));
		else
			Shake(victim, damage / iShakeFactor);
	}
	return Plugin_Changed;
}

public void RecoverZombieVelocity(DataPack pack)
{
	pack.Reset();
	int attacker = pack.ReadCell();
	int victim = pack.ReadCell();
	
	if (!IsClientZombie(attacker))
	{
		float currentVelMod = GetEntPropFloat(victim, Prop_Send, "m_flVelocityModifier");
		float decreased = 1.0 - currentVelMod;
		float resultVelMod;
		
		// 피격자가 숙주좀비일 때
		/*
		if(victim == g_iHostZombie)
		{
			// 속도 보정 이전의 속도가 0.7보다 작을때만.
			// 속도 보정으로 인해 오히려 속도가 떨어지는 경우를 막기 위함.
			if(currentVelMod < 0.7)
			{
				SetEntPropFloat(victim, Prop_Send, "m_flVelocityModifier", 0.7);
			}
		}*/
		
		// 공격자의 클래스가 보병, 기동성이면서 일반좀비를 때릴 때
		if (g_iClassId[attacker] == 1 && victim != g_iHostZombie)
		{
			resultVelMod = 1.0 - (decreased * 1.2);
		}
		// 기동성이면서 대상이 숙주일 때.
		else if (g_iClassId[attacker] == 1 && victim == g_iHostZombie)
		{
			resultVelMod = 1.0 - (decreased * 0.45) * 1.5;
		}
		// 기동성이 아니면서 대상이 숙주일 때.
		else if (g_iClassId[attacker] != 1 && victim == g_iHostZombie)
		{
			resultVelMod = 1.0 - (decreased * 0.45);
		}
		else
		{
			resultVelMod = currentVelMod;
		}
		
		if (resultVelMod < 0.1)
			resultVelMod = 0.1;
		
		SetEntPropFloat(victim, Prop_Send, "m_flVelocityModifier", resultVelMod);
		/*
		if(IsClientAdmin(victim))
		{
			PrintHintText(victim, "현재 이속 수정자: %f\n깎인 값: %f", resultVelMod, 1.0 - resultVelMod);
		}
		*/
	}
	delete pack;
}

public Action TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	#if defined _DEBUG_
	PrintToServer("[BST Zombie] TraceAttack(%i -> %i)", attacker, victim);
	#endif
	
	if (IsValidClient(victim) && IsValidClient(attacker))
	{
		if (victim == attacker)
		{
			char strInflictorName[32];
			GetEdictClassname(inflictor, strInflictorName, sizeof(strInflictorName));
			if (StrEqual(strInflictorName, "Explosion_Ammo"))
			{
				return Plugin_Stop;
			}
		}
		else if (GetClientTeam(victim) == GetClientTeam(attacker))
		{
			return Plugin_Stop;
		}
	}
	
	if (IsValidEdict(victim))
	{
		char szClassname[32];
		GetEdictClassname(victim, szClassname, 32);
		if (StrEqual(szClassname, "prop_dynamic") || StrEqual(szClassname, "prop_physics"))
		{
			char Modelname[128];
			GetEntPropString(victim, Prop_Data, "m_ModelName", Modelname, 128);
			
			if (StrEqual(Modelname, AmmoCrateModel, false))
			{
				return Plugin_Stop;
			}
			else if (StrEqual(Modelname, BarricadeModel, false))
			{
				//GetClientTeam(attacker) == CS_TEAM_T && g_bGameStarted
				// 칼 이외의 모든 공격을 차단시키자
				if (inflictor == attacker && (damagetype & DMG_SLASH) && ammotype == -1)
				{
					return Plugin_Continue;
				}
				else
				{
					// 칼, DMG_SLASH | DMG_NEVERGIB ammotype -1
					// 총(ak47), DMG_BULLET| DMG_NEVERGIB ammotype 2
					// 수류탄(inflictor가 수류탄으로 잡힘)
					//					PrintToServer("[BST Zombie] HIT BARRICADE! with %i %i %i", inflictor, damagetype, ammotype);
					return Plugin_Stop;
				}
			}
		}
	}
	
	if (!g_bGameStarted || g_bRoundEnded)
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action OnClientCanUseWeapon(int client, int weapon)
{
	#if defined _DEBUG_
	PrintToServer("[BST Zombie] OnClientCanUseWeapon(%i -> %i)", client, weapon);
	#endif
	
	if (IsClientZombie(client))
	{
		char szClassname[64];
		if (GetEdictClassname(weapon, szClassname, sizeof(szClassname)))
			if (!StrEqual(szClassname[7], "knife"))
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public OnEntityCreated(entity, const char[] classname)
{
	#if defined _DEBUG_
	PrintToServer("[BST Zombie] OnEntityCreated(%i)", entity);
	#endif
	
	if (StrContains(classname, "weapon_") != -1 && !StrEqual(classname, "weapon_hegrenade") && !StrEqual(classname, "weapon_flashbang") && !StrEqual(classname, "weapon_smokegrenade") && !StrEqual(classname, "weapon_c4"))
	{
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
	}
}

public void OnEntitySpawned(entity)
{
	SDKHook(entity, SDKHook_ReloadPost, OnWeaponReloadPost);
}

public void OnWeaponReloadPost(weapon, bool bSuccessful)
{
	int client = GetEntPropEnt(weapon, Prop_Data, "m_hOwnerEntity");
	if (IsValidEntity(weapon))
	{
		RequestFrame(ReloadSoundCheck, client);
	}
}

//리로드 사운드 체크
public void ReloadSoundCheck(any client)
{
	int eWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (IsValidEntity(eWeapon))
	{
		char weaponClassname[32];
		if(GetEdictClassname(eWeapon, weaponClassname, sizeof(weaponClassname)))
		{
			if(StrEqual(weaponClassname[7], "nova") || StrEqual(weaponClassname[7], "xm1014") || StrEqual(weaponClassname[7], "sawedoff"))
			{				
				// 샷건(쉘) 리로드중
				int iReloadState = GetEntProp(eWeapon, Prop_Send, "m_reloadState");
				if(iReloadState > 0)
				{
					// 샷건 장전중에 원래 있어야 할 클립보다 더 많은 클립이 총에 담겨있을 때.
					switch (GetEntProp(eWeapon, Prop_Send, "m_iItemDefinitionIndex"))
					{
						case 60: strcopy(weaponClassname, sizeof(weaponClassname), "weapon_m4a1_silencer");
						case 61: strcopy(weaponClassname, sizeof(weaponClassname), "weapon_usp_silencer");
						case 63: strcopy(weaponClassname, sizeof(weaponClassname), "weapon_cz75a");
					}
					if(GetWeaponClip(eWeapon) >= CacheClipSize(weaponClassname[7]))
						SetEntProp(eWeapon, Prop_Send, "m_reloadState", 0);
						
					if(iOldReloadState[client] == 0)
					{
						// TODO: 이곳에 재장전 사운드를 삽입
						// 대체 사운드도 적용
						#define SNDCHAN_RELOAD_SOUND		10
						if (g_nPenetrationCount[client] > 0)
						{
							int SoundRandom = GetRandomInt(0, sizeof(IntensedReloadSoundFilesPath[]) - 1);
							EmitSoundToAllAny(IntensedReloadSoundFilesPath[g_iVoiceCharacter[client]][SoundRandom], client, SNDCHAN_RELOAD_SOUND, _, _, _, _, _, _, _, true);
						}
						else
						{
							int SoundRandom = GetRandomInt(0, sizeof(ReloadSoundFilesPath[]) - 1);
							EmitSoundToAllAny(ReloadSoundFilesPath[g_iVoiceCharacter[client]][SoundRandom], client, SNDCHAN_RELOAD_SOUND, _, _, _, _, _, _, _, true);
						}
					}
					DataPack pack;
					CreateDataTimer(0.01, Timer_CheckShotgunEnd, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
					pack.WriteCell(EntIndexToEntRef(eWeapon));
					pack.WriteCell(GetClientUserId(client));
				}
				
				iOldReloadState[client] = iReloadState;
			}
			else
			{
				if (GetEntProp(eWeapon, Prop_Data, "m_bInReload"))
				{
					// TODO: 이곳에 재장전 사운드를 삽입
					// 대체 사운드도 적용
					#define SNDCHAN_RELOAD_SOUND		10
					if (g_nPenetrationCount[client] > 0)
					{
						int SoundRandom = GetRandomInt(0, sizeof(IntensedReloadSoundFilesPath[]) - 1);
						EmitSoundToAllAny(IntensedReloadSoundFilesPath[g_iVoiceCharacter[client]][SoundRandom], client, SNDCHAN_RELOAD_SOUND, _, _, _, _, _, _, _, true);
					}
					else
					{
						int SoundRandom = GetRandomInt(0, sizeof(ReloadSoundFilesPath[]) - 1);
						EmitSoundToAllAny(ReloadSoundFilesPath[g_iVoiceCharacter[client]][SoundRandom], client, SNDCHAN_RELOAD_SOUND, _, _, _, _, _, _, _, true);
					}
				}
			}
		}
	}
}

public Action Timer_CheckShotgunEnd(Handle timer, any:data)
{
	ResetPack(data);
	
	int iWeapon = EntRefToEntIndex(ReadPackCell(data));
	int client = GetClientOfUserId(ReadPackCell(data));
	
	// Weapon is gone?!
	if(iWeapon == INVALID_ENT_REFERENCE)
	{
		if(client > 0)
			iOldReloadState[client] = 0;
		return Plugin_Stop;
	}
	
	int iOwner = GetEntPropEnt(iWeapon, Prop_Send, "m_hOwnerEntity");
	// Weapon dropped?
	if(iOwner <= 0)
	{
		// Reset the old client
		if(client > 0)
			iOldReloadState[client] = 0;
		
		return Plugin_Stop;
	}

	int iReloadState = GetEntProp(iWeapon, Prop_Send, "m_reloadState");
	
	// Still reloading
	if(iReloadState > 0)
		return Plugin_Continue;
	
	// Done reloading.
	iOldReloadState[client] = iReloadState;
	
	return Plugin_Stop;
}
/****************************** Events ******************************/
public Action Event_OnFullConnect(Event event, char[] name, bool broadcast)
{
	#if defined _DEBUG_
	PrintToServer("[BST Zombie] Event_OnFullConnect");
	#endif
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client || !IsClientInGame(client))
		return Plugin_Continue;
	
	// 팀 자동 조인 해제
	SetEntPropFloat(client, Prop_Send, "m_fForceTeam", GetGameTime() + 817.0);
	ForceClientSelectClass(client, false);
	return Plugin_Continue;
}

public void OnPlayerSpawn(Event event, char[] name, bool broadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	#if defined _DEBUG_
	PrintToServer("[BST Zombie] OnPlayerSpawn(%i)", client);
	#endif
	
	if (IsValidPlayer(client))
	{
		// 글옵 Bloodhound 부터 추가된 trace 기반의 위치 감춤을 비활성화한다.
		SetEdictFlags(client, GetEdictFlags(client) | FL_EDICT_ALWAYS);
		
		g_bIsZombie[client] = false;
		RemoveGuns(client, true);
		
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		SetEntityGravity(client, 1.0);
		
		char szSkinOption[32];
		DDS_GetItemInfo(DDS_GetUserItemID(client, 3), 10, szSkinOption);
		if ((DDS_GetUserItemID(client, 3) > 0) && DDS_GetItemUse(3))
		{
			if (StrEqual(szSkinOption, "male", false))
				g_iVoiceCharacter[client] = GetRandomInt(0, 1); // 0~1 남성, 2~3 여성
			else if (StrEqual(szSkinOption, "female", false))
				g_iVoiceCharacter[client] = GetRandomInt(2, 3); // 0~1 남성, 2~3 여성
			else if (StrEqual(szSkinOption, "coach", false))
				g_iVoiceCharacter[client] = 0;
			else if (StrEqual(szSkinOption, "mechanic", false))
				g_iVoiceCharacter[client] = 1;
			else if (StrEqual(szSkinOption, "pd", false))
				g_iVoiceCharacter[client] = 2;
			else if (StrEqual(szSkinOption, "teengirl", false))
				g_iVoiceCharacter[client] = 3;
			else
				g_iVoiceCharacter[client] = GetRandomInt(0, 3);
		}
		else g_iVoiceCharacter[client] = GetRandomInt(0, 1);
		
		ResetPlayerState(client);
		SetClientClassFeature(client);
		GetClientAbsOrigin(client, g_vecSpawnPoint[client]);
		
		RequestFrame(PrepareToSetupGlow, client);
		
		char currentmodel[128];
		GetEntPropString(client, Prop_Send, "m_szArmsModel", currentmodel, sizeof(currentmodel));
		
		if (!StrEqual(currentmodel, ARMS_HOST_ZOMBIE) && !StrEqual(currentmodel, ARMS_SPECIAL_ZOMBIE) && !StrEqual(currentmodel, ARMS_NORMAL_ZOMBIE))
		{
			Format(g_szDefaultArmsModel[client], sizeof(g_szDefaultArmsModel[]), currentmodel);
		}
		else CleanClientArms(client);
		
		CS_SwitchTeam(client, CS_TEAM_CT);
		
		char clanTag[sizeof(g_szConstClassName[])];
		clanTag = g_szConstClassName[g_iClassId[client]];
		ReplaceString(clanTag, sizeof(clanTag), "성)", ")");
		CS_SetClientClanTag(client, clanTag);
		
		// 노블럭 처리
		SetEntData(client, g_offsCollision, 2, _, true);
		
		// 3인칭 취소 처리
		if (g_bThirdPerson[client])
		{
			g_bThirdPerson[client] = false;
			ChangePersonView(client, g_bThirdPerson[client]);
		}
		
		SetEntityRenderColor(client, 255, 255, 255, 255);
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	}
}

public Action:SetTransmitSpyCigarette(entity, client)
{
	/*
	// 3인칭 시점(m_iObserverMode)에서만 보이도록 설정
	if (entity == iSpyCigaretteEnt[client])
	{
		if(g_bThirdPerson[client])
			return Plugin_Continue;
		if (GetEntProp(client, Prop_Send, "m_iObserverMode") == 5)
			return Plugin_Continue;
		else
			return Plugin_Stop;
	}
	else
	{
		// 제 3 자가 보았을 때 모델이 나타나도록 설정
		if (IsClientObserver(client))
		{
			new obtarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			
			if (obtarget > 0)
			{
				if (entity == iSpyCigaretteEnt[obtarget])
				{
					if(GetEntProp(client, Prop_Send, "m_iObserverMode") == 4)
						return Plugin_Handled;
					else
						return Plugin_Continue;
				}
				else
				{
					return Plugin_Continue;
				}
			}
			else
			{
				return Plugin_Continue;
			}
		}
		else
		{
			return Plugin_Continue;
		}
	}*/
	return Plugin_Stop;
}

// 클라이언트가 죽을 때
public void OnPlayerDeath(Event event, char[] name, bool broadcast)
{
	#if defined _DEBUG_
	PrintToServer("[BST Zombie] OnPlayerDeath()");
	#endif
	
	if (IsWarmupPeriod() || !g_bGameStarted)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	//	char weaponname[32];
	//	event.GetString("weapon", weaponname, 32, "defaultweaponname");
	//	PrintToServer("player_death: \"weapon\": '%s'", weaponname);
	
	//	bool headshot = event.GetBool("headshot");
	if (IsValidClient(attacker))
	{
		Para_OnPlayerDeath(client);
		
		// 인간 ==>> 좀비
		if (!IsClientZombie(attacker) && IsClientZombie(client) && !IsFakeClient(client))
		{
			SetEntProp(attacker, Prop_Send, "m_iAccount", GetEntProp(attacker, Prop_Send, "m_iAccount") + REWARD_CASH_KILL_ZOMBIE);
			PrintToChat(attacker, " \x06+$%d\x01: 좀비를 사살한 것에 대한 보상.", REWARD_CASH_KILL_ZOMBIE);
			DropSupplyBoxFrom(client);
			if (client == g_iHostZombie)
			{
				DDS_SetUserMoney(attacker, 2, HOST_ZOMBIE_KILL_REWARD);
				PrintToChat(attacker, "%s\x01숙주좀비를 잡아서 \x03%i\x01 킬 포인트를 획득 하셨습니다!", PREFIX, HOST_ZOMBIE_KILL_REWARD);
			}
			else if (client == g_iJumpZombie || client == g_iGasZombie)
			{
				DDS_SetUserMoney(attacker, 2, SPECIAL_ZOMBIE_KILL_REWARD);
				PrintToChat(attacker, "%s\x01변종좀비를 잡아서 \x03%i\x01 킬 포인트를 획득 하셨습니다!", PREFIX, SPECIAL_ZOMBIE_KILL_REWARD);
				
				// 다음 변종 좀비가 나타날 수 있도록 변수를 초기화한다.
				if (client == g_iJumpZombie)
					g_iJumpZombie = -1;
				else if (client == g_iGasZombie)
					g_iGasZombie = -1;
			}
			else
			{
				DDS_SetUserMoney(attacker, 2, NORMAL_ZOMBIE_KILL_REWARD);
				PrintToChat(attacker, "%s\x01좀비를 잡아서 \x03%i\x01 킬 포인트를 획득 하셨습니다!", PREFIX, NORMAL_ZOMBIE_KILL_REWARD);
			}
		}
		// TODO: CODE HERE
		RemoveSkin(client);
		Party_ValidateGlowObject(Party_GetClientPartyIndex(client));
	}
	
	if (IsValidClient(client) && !IsPlayerAlive(client))
	{
		// 3인칭 처리, 죽을 때에는 1인칭으로
		if (g_bThirdPerson[client])
		{
			g_bThirdPerson[client] = false;
			ChangePersonView(client, g_bThirdPerson[client]);
		}
	}
	
	CheckTeamAliveCounter();
}

public void OnPlayerJoinedTeamPre(Event event, char[] name, bool dontBroadcast)
{
	event.BroadcastDisabled = true;
}

public void OnPlayerJoinedTeam(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int team = event.GetInt("team");
	
	#if defined _DEBUG_
	PrintToServer("[BST Zombie] OnPlayerJoinedTeam(%i)", client);
	#endif
	
	if (IsValidClient(client))
	{
		if (team == 1)
		{
			ResetPlayerState(client);
		}
		else
		{
			if (ForceClientSelectClass(client, true, CS_TEAM_CT, true))
			{
				ChangeClientTeam(client, CS_TEAM_SPECTATOR);
			}
		}
	}
	
	char szClanTag[32];
	if (!IsClientZombie(client) && IsPlayerAlive(client))
	{
		Format(szClanTag, sizeof(szClanTag), "%s", g_szConstClassName[g_iClassId[client]], name);
	}
	else if (IsClientZombie(client) && IsPlayerAlive(client))
	{
		if (client == g_iHostZombie)
		{
			Format(szClanTag, sizeof(szClanTag), "%s", "숙주좀비", name);
		}
		else if (client == g_iGasZombie)
		{
			Format(szClanTag, sizeof(szClanTag), "%s", "변종좀비(가스)", name);
		}
		else if (client == g_iJumpZombie)
		{
			Format(szClanTag, sizeof(szClanTag), "%s", "변종좀비(도약)", name);
		}
		else
		{
			Format(szClanTag, sizeof(szClanTag), "%s", "좀비", name);
		}
	}
	
	char clanTag[sizeof(g_szConstClassName[])];
	clanTag = g_szConstClassName[g_iClassId[client]];
	ReplaceString(clanTag, sizeof(clanTag), "성)", ")");
	CS_SetClientClanTag(client, clanTag);
	
	event.BroadcastDisabled = true;
}

// 라운드 시작
public void OnRoundStart(Event event, char[] name, bool dontBroadcast)
{
	#if defined _DEBUG_
	PrintToServer("[BST Zombie] OnRoundStart()");
	#endif
	
	/* !!!WARNING!!!
	WTF Is This Fucking Shit!?
	라운드가 무한으로 반복해서 No Free Edicts 버그가 생길 수 있다.
	*/
	if (GetPlayerCount() < MIN_PLAYER_TO_PLAY)
		StartWarmup();
	
	CleanUp(false, true);
	SetCanEndRound(false);
	
	g_bGameStarted = false;
	g_bRoundEnded = false;
	g_bHostSelectionTime = false;
	
	g_iHostZombie = -1;
	
	Party_OnRoundStart();
	ItemEvent_OnRoundStart();
}

public Action OnRoundFreezeTimeEnd(Event event, char[] name, bool dontBroadcast)
{
	#if defined _DEBUG_
	PrintToServer("[BST Zombie] OnRoundFreezeTimeEnd()");
	#endif
	
	g_bGameStarted = false;
	g_bRoundEnded = false;
	g_bHostSelectionTime = true;
	
	if (!IsWarmupPeriod())
	{
		/*********
		랜덤 선택
		**********/
		int RandomVeteranSpawn;
		RandomVeteranSpawn = GetRandomInt(1, 5);
		if (RandomVeteranSpawn == 1)RandomVeteran();
		
		SelectHostZombie();
	}
}

// 라운드 끝
public void OnRoundEnd(Event event, char[] name, bool broadcast)
{
	#if defined _DEBUG_
	PrintToServer("[BST Zombie] OnRoundEnd()");
	#endif
	
	g_bRoundEnded = true;
	g_bHostSelectionTime = false;
	
	int winner = event.GetInt("winner");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			CleanClientArms(i);
			
			if (winner == CS_TEAM_CT)
			{
				if (IsPlayerAlive(i) && !IsClientZombie(i))
				{
					SetEntProp(i, Prop_Send, "m_iAccount", GetEntProp(i, Prop_Send, "m_iAccount") + REWARD_CASH_ROUND_WIN);
					PrintToChat(i, " \x06+$%d\x01: 인간으로서 생존한 것에 대한 보상.", REWARD_CASH_ROUND_WIN);
				}
			}
			else if (winner == CS_TEAM_T)
			{
				if (IsPlayerAlive(i) && IsClientZombie(i))
				{
					SetEntProp(i, Prop_Send, "m_iAccount", GetEntProp(i, Prop_Send, "m_iAccount") + REWARD_CASH_ROUND_WIN);
					PrintToChat(i, " \x06+$%d\x01: 모든 인간을 감염시킨 것에 대한 보상.", REWARD_CASH_ROUND_WIN);
				}
			}
		}
	}
}

//파이어 이벤트
public Action OnWeaponFire(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) == GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon"))
	{
		if (g_nIncendiaryAmmo[client] > 0)
		{
			g_nIncendiaryAmmo[client]--;
		}
		if (g_nExplosiveAmmo[client] > 0)
		{
			g_nExplosiveAmmo[client]--;
		}
		if (g_nArmorPiercingAmmo[client] > 0)
		{
			g_nArmorPiercingAmmo[client]--;
		}
	}
	
	char weapon[32];
	event.GetString("weapon", weapon, sizeof(weapon));	
	
	if (g_iClassId[client] == 2)
	{
		if (StrEqual("sg556", weapon, false) || StrEqual("aug", weapon, false))
		{
			if(g_offsPunchAngleVel != -1)
			{
				if(g_iClassLevel[client][1] > 0)
				{
					static float vecOldPunchVel[MAXPLAYERS + 1][3]; // 이전 펀치앵글
					float vecPunchVel[3]; // 현재 펀치앵글, 그리고 연산 후 최종 펀치앵글을 담는다
					float vecTempPunchVel[3]; // 이전 펀치 앵글에서, 현재 펀치 앵글간의 변화폭을 담는다.
					
					int fired = GetEntProp(client, Prop_Send, "m_iShotsFired");
					// 처음 쏠 때
					if (fired == 0)
					{
						vecOldPunchVel[client][0] = 0.0;
						vecOldPunchVel[client][1] = 0.0;
					}
					
					//m_iRecoilIndex
					int eWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
					SetEntPropFloat(eWeapon, Prop_Send, "m_fAccuracyPenalty", 0.0);
					
		//			SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
					
					float temppvel[3];
					GetEntDataVector(client, g_offsPunchAngleVel, vecPunchVel);
					
					temppvel[0] = vecPunchVel[0];
					temppvel[1] = vecPunchVel[1];
					temppvel[2] = vecPunchVel[2];
					
					vecTempPunchVel[0] = vecPunchVel[0] - vecOldPunchVel[client][0];
					vecTempPunchVel[1] = vecPunchVel[1] - vecOldPunchVel[client][1];
					
					// 5렙일 시, 명중률 100%
					if(g_iClassLevel[client][1] < 5)
					{
						// 1렙일 때: 1 - 1.0/5 => 1 - 0.2 => 0.8 => 80%
						vecTempPunchVel[0] *= float(1) - ((float(g_iClassLevel[client][1]) / float(5)) * 1.11111);
						vecTempPunchVel[1] *= float(1) - ((float(g_iClassLevel[client][1]) / float(5)) * 1.11111);
							
						vecPunchVel[0] = vecOldPunchVel[client][0] + vecTempPunchVel[0];
						vecPunchVel[1] = vecOldPunchVel[client][1] + vecTempPunchVel[1];
					}
					else
					{
						vecPunchVel[0] = 0.0;
						vecPunchVel[1] = 0.0;
					}
					
//					PrintHintText(client, "이전값: %.2f %.2f\n결과값: %.2f %.2f\nShotsFired: %d", temppvel[0], temppvel[1], vecPunchVel[0], vecPunchVel[1], fired);
					
					SetEntDataVector(client, g_offsPunchAngleVel, vecPunchVel, true);
					
					vecOldPunchVel[client][0] = vecPunchVel[0];
					vecOldPunchVel[client][1] = vecPunchVel[1];
				}
			}
		}
	}
}

#define MAX_BULLET_PENETERATION_COUNT	1

//뷸렛 이벤트
public Action OnBulletImpact(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	float _fOrigin[3], _fImpact[3], _fDifference[3];
	float angEyeAngles[3];
	GetClientEyeAngles(client, angEyeAngles);
	GetClientEyePosition(client, _fOrigin);
	_fImpact[0] = event.GetFloat("x");
	_fImpact[1] = event.GetFloat("y");
	_fImpact[2] = event.GetFloat("z");
	
	float _fDistance = GetVectorDistance(_fOrigin, _fImpact);
	float _fPercent = (0.4 / (_fDistance / 100.0));
	
	_fDifference[0] = _fOrigin[0] + ((_fImpact[0] - _fOrigin[0]) * _fPercent);
	_fDifference[1] = _fOrigin[1] + ((_fImpact[1] - _fOrigin[1]) * _fPercent) - 0.08;
	_fDifference[2] = _fOrigin[2] + ((_fImpact[2] - _fOrigin[2]) * _fPercent);
	
	
	int iMaxBulletPenetrationCount = MAX_BULLET_PENETERATION_COUNT;
	
	// 샷건의 경우
	char clsname[32];
	int eWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (GetEdictClassname(eWeapon, clsname, sizeof(clsname)))
	{
		if (StrEqual(clsname[7], "nova"))
			iMaxBulletPenetrationCount *= 9; // Each shot contains 9 pellets.
		else if (StrEqual(clsname[7], "mag7") || StrEqual(clsname[7], "sawedoff"))
			iMaxBulletPenetrationCount *= 8; // Each shot contains 8 pellets.
		else if (StrEqual(clsname[7], "xm1014"))
			iMaxBulletPenetrationCount *= 6; // Each shot contains 6 pellets.
	}
	
	if (GetPlayerWeaponSlot(client, 0) == eWeapon && g_nBulletPenetrationCount[client] < iMaxBulletPenetrationCount)
	{
		g_nBulletPenetrationCount[client]++;
		if (g_nArmorPiercingAmmo[client] > 0)
		{
			TE_SetupSparks(_fImpact, NULL_VECTOR, 50, 100);
			TE_SendToAll();
			//			TE_SetupBeamPoints(_fDifference, _fImpact, tube, 0, 0, 0, 1.0, 1.0, 1.0, 0, 0.0, {255, 255, 255, 50}, 0);
		}
		if (g_nExplosiveAmmo[client] > 0)
		{
			Handle tracer = TR_TraceRayFilterEx(_fOrigin, angEyeAngles, MASK_SHOT, RayType_Infinite, function_filter, client);
			
			if (TR_DidHit(tracer))
			{
				float plane[3], plane_ang[3];
				TR_GetPlaneNormal(tracer, plane);
				GetVectorAngles(plane, plane_ang);
				
				TE_SetupExplosion(_fImpact, 0, 0.01, 1, 0, 1, 1, plane_ang);
				TE_SendToAll();
			}
			
			delete tracer;
			_fImpact[2] += 10.0;
			MakeExplosion(IsValidClient(client) ? client : 0, -1, _fImpact, "Explosion_Ammo", 25, _, 5.0, SF_ENVEXPLOSION_NOFIREBALL | SF_ENVEXPLOSION_NOSMOKE | SF_ENVEXPLOSION_NOSPARKS | SF_ENVEXPLOSION_NOSOUND);
		}
		
		RequestFrame(ResetPenetrationBlock, client);
	}
	
	return Plugin_Handled;
}

public void ResetPenetrationBlock(any client)
{
	g_nBulletPenetrationCount[client] = 0;
}

public bool function_filter(int entity, int mask, any client)
{
	if (entity != client)
	{
		return true;
	}
	else
	{
		return false;
	}
}

/****************************** Commands ******************************/

// 세번째 매개변수는 접속 시, 바로 팀을 선택한 뒤, 병과를 선택하고 다시 팀을 고르는 불편함을 없애기 위함...
// 클래스 선택 메뉴나 초기 병과 선택 메뉴까지 끌고가서 처리해줘야 한다.
bool ForceClientSelectClass(int client, bool bIsChatCommand, int team = CS_TEAM_NONE, bool checkOnly = false)
{
	#if defined _DEBUG_
	PrintToServer("[BST Zombie] ForceClientSelectClass(%i)", client);
	#endif
	
	// 가려고 하는 팀이 관전인 경우이므로 갈 수 있도록 true를 리턴한다.
	if (team == CS_TEAM_NONE && !bIsChatCommand)
		return true;
	
	bool bHasValidClass = false;
	for (int i = 0; i < sizeof(g_iClassLevel[]); i++)
	{
		if (g_iClassLevel[client][i] != -1)
		{
			bHasValidClass = true;
			break;
		}
	}
	
	if (g_iClassId[client] > 0 && !bIsChatCommand)
	{
		return true;
	}
	else if (checkOnly)
	{
		return false;
	}
	
	if (bHasValidClass)
	{
		ClassMenu(client, _, bIsChatCommand);
		
		// 채팅 명령어로 친 게 아닌경우. (팀 이동시 뜬 경우)
		if (!bIsChatCommand)
		{
			ChangeClientTeam(client, CS_TEAM_SPECTATOR);
			g_iPendingTeamNumber[client] = team;
			PrintToChat(client, "%s\x04플레이하실 병과를 선택해주세요.", PREFIX);
		}
	}
	else
	{
		ChangeClientTeam(client, CS_TEAM_SPECTATOR);
		g_iPendingTeamNumber[client] = team;
		PrintToChat(client, "%s\x01처음으로 사용하실 병과를 \x04한 가지 \x01선택해주세요.", PREFIX);
		FirstClassSelectionMenu(client);
	}
	return false;
}
public Action Cmd_ClassMenu(int client, int arg)
{
	if (g_bUserDataLoaded[client])
	{
		ForceClientSelectClass(client, true);
	}
	else
	{
		PrintToChat(client, "%s\x04유저 데이터가 완전히 로드되지 않았습니다, 잠시 후 다시 시도해주세요.", PREFIX);
		Cmd_LoadUserData(client, 0);
	}
	
	return Plugin_Handled;
}

public Action Cmd_ClassLevel(int client, int arg)
{
	if (g_bUserDataLoaded[client])
	{
		Command_ClassLevel(client);
	}
	else
	{
		PrintToChat(client, "%s\x04유저 데이터가 완전히 로드되지 않았습니다, 잠시 후 다시 시도해주세요.", PREFIX);
		Cmd_LoadUserData(client, 0);
	}
	return Plugin_Handled;
}

public Action Cmd_PartyMenu(int client, int arg)
{
	if (g_bUserDataLoaded[client])
	{
		if (g_iClassId[client] > 0)
			Command_PartyMain(client);
	}
	else
	{
		PrintToChat(client, "%s\x04유저 데이터가 완전히 로드되지 않았습니다, 잠시 후 다시 시도해주세요.", PREFIX);
		Cmd_LoadUserData(client, 0);
	}
	return Plugin_Handled;
}

public Action Cmd_WeaponMenu(int client, int arg)
{
	if (g_iClassId[client] > 0 && IsValidPlayer(client))
	{
		Command_WeaponShop(client);
	}
	return Plugin_Handled;
}

public Action Cmd_LoadUserData(int client, int arg)
{
	if (!g_bUserDataLoaded[client])
	{
		DB_OnClientPostAdminCheck(client);
	}
	else
	{
		PrintToChat(client, "%s\x04이미 유저 데이터가 로드되었습니다.", PREFIX);
	}
	return Plugin_Handled;
}

public Action Cmd_CrateInventoryMenu(int client, int arg)
{
	DDS_OpenInventoryMenu(client, CRATE_ID);
	return Plugin_Handled;
}

public Action Cmd_OpenShopMain(int client, int arg)
{
	DDS_OpenMainMenu(client);
	return Plugin_Handled;
}

public Action Cmd_FirstPerson(int client, int args)
{
	if (IsPlayerAlive(client))
	{
		if (g_bThirdPerson[client])
		{
			ChangePersonView(client, !g_bThirdPerson[client]);
			
			g_bThirdPerson[client] = !g_bThirdPerson[client];
		}
	}
	else ChangePersonView(client, false);
	
	return Plugin_Stop;
}

public Action Cmd_ThirdPerson(int client, int args)
{
	if (IsPlayerAlive(client))
	{
		if (!g_bThirdPerson[client])
		{
			if (g_flForceFirstPersonTime[client] < GetGameTime())
			{
				ChangePersonView(client, !g_bThirdPerson[client]);
				g_bThirdPerson[client] = !g_bThirdPerson[client];
			}
		}
	}
	else ChangePersonView(client, false);
	
	return Plugin_Stop;
}

public Action OnChatMessage(int &client, Handle recipients, char[] name, char[] message, char[] translationName)
{
	/*
		\x01 => Default(White)
		\x02 => Strong Red
		\x03 => Team Color
		\x04 => Green
		\x05 => Turquoise
		\x06 => Yellow-Green
		\x07 => Light Red
		\x08 => Gray
		\x09 => Light Yellow
		\x0A => Light Blue
		\x0C => Purple
		\x0E => Pink
		\x10 => Orange
	*/
	char className[32];
	GetClientClassName(client, className, sizeof(className));
	if (!IsClientZombie(client) && IsPlayerAlive(client))
	{
		Format(name, MAXLENGTH_NAME, "[\x06%s\x03] %s", className, name);
	}
	else if (IsClientZombie(client) && IsPlayerAlive(client))
	{
		Format(name, MAXLENGTH_NAME, "[\x07%s\x03] %s", className, name);
	}
	
	if (StrContains(message, "/") == 0)
	{
		return Plugin_Stop;
	}
	return Plugin_Changed;
}

public Action OnClientChat(int client, char[] command, int argc)
{
	#if defined _DEBUG_
	PrintToServer("[BST Zombie] OnClientChat()");
	#endif	
	
	char Msg[256];
	GetCmdArgString(Msg, sizeof(Msg));
	Msg[strlen(Msg) - 1] = '\0';
	
	if (StrEqual(Msg[1], "!병과", false) || StrEqual(Msg[1], "!클래스", false))
	{
		Cmd_ClassMenu(client, 0);
	}
	else if (StrEqual(Msg[1], "!레벨", false))
	{
		Cmd_ClassLevel(client, 0);
	}
	else if (StrEqual(Msg[1], "!파티", false))
	{
		Cmd_PartyMenu(client, 0);
	}
	else if (StrEqual(Msg[1], "!무기", false))
	{
		Cmd_WeaponMenu(client, 0);
	}
	else if (StrEqual(Msg[1], "!로드", false))
	{
		Cmd_LoadUserData(client, 0);
	}
	else if (StrEqual(Msg[1], "!박스", false) || StrEqual(Msg[1], "!상자", false))
	{
		Cmd_CrateInventoryMenu(client, 0);
	}
	else if (StrEqual(Msg[1], "!인칭", false))
	{
		OnPeriodCommand(client, "buyammo1", 0);
	}
	else if (StrEqual(Msg[1], "!1인칭", false))
	{
		Cmd_FirstPerson(client, 0);
	}
	else if (StrEqual(Msg[1], "!3인칭", false))
	{
		Cmd_ThirdPerson(client, 0);
	}
	else if (StrEqual(Msg[1], "!나로호", false) || StrEqual(Msg[1], "!로켓", false))
	{
		Cmd_UseRocketItem(client, 0);
	}
	else if (StrEqual(Msg[1], "!센트리", false) || StrEqual(Msg[1], "!센트리건", false) || StrEqual(Msg[1], "!닭", false) || StrEqual(Msg[1], "!닭트리건", false))
	{
		Cmd_UseSentryGunItem(client, 0);
	}
	else if (StrEqual(Msg[1], "!이벤트", false))
	{
		Cmd_ItemEvent(client);
	}
	
	
	if (Party_IsClientChangingPartyName(client))
	{
		Party_ChangeName(Party_GetClientPartyIndex(client), Msg[1], _, true);
		return Plugin_Stop;
	}
	
	if (StrContains(Msg[1], "/") == 0)
	{
		char className[32], message[253];
		GetClientClassName(client, className, sizeof(className));
		if (!IsClientZombie(client) && IsPlayerAlive(client))
		{
			Format(message, sizeof(message), "[\x06%s\x03] %N", className, client);
		}
		else if (IsClientZombie(client) && IsPlayerAlive(client))
		{
			Format(message, sizeof(message), "[\x07%s\x03] %N", className, client);
		}
		
		Format(message, sizeof(message), "\x03(\x10파티\x03) %s : \x04%s", message, Msg[2]);
		
		if (Party_Chat(client, Party_GetClientPartyIndex(client), message))
		{
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

public Action OnF3Command(int client, char[] command, int argc)
{
	Cmd_PartyMenu(client, 0);
	return Plugin_Handled;
}

public Action OnF4Command(int client, char[] command, int argc)
{
	static float flDoublePressTimer[MAXPLAYERS + 1];
	
	if(flDoublePressTimer[client] < GetGameTime())
	{
		Menu_PrivateBlockVoiceSend(client);
		flDoublePressTimer[client] = GetGameTime() + 0.3;
	}
	else
	{
		Menu_PrivateMute(client);
		flDoublePressTimer[client] = 0.0;
	}
	return Plugin_Handled;
}

public Action OnCommaCommand(int client, char[] command, int argc)
{
	DDS_OpenInventoryMenu(client, EXPENDABLE_ID);
	return Plugin_Handled;
}

public Action OnPeriodCommand(int client, char[] command, int argc)
{
	if (IsPlayerAlive(client))
	{
		if (g_flForceFirstPersonTime[client] < GetGameTime())
		{
			ChangePersonView(client, !g_bThirdPerson[client]);
			g_bThirdPerson[client] = !g_bThirdPerson[client];
		}
	}
	else ChangePersonView(client, false);
	
	return Plugin_Stop;
}

public Action OnKButtonCommand(client, const char[] command, argc)
{
	if (!IsValidPlayer(client)) //If player is not in-game then ignore!
		return Plugin_Continue;
	
	SetEntProp(client, Prop_Send, "m_fEffects", GetEntProp(client, Prop_Send, "m_fEffects") ^ 4);
	
	return Plugin_Handled;
}

/*
public Action OnMButtonCommand(client, const char[] command, argc)
{
	if (!IsValidPlayer(client)) //If player is not in-game then ignore!
		return Plugin_Continue;
	
	Cmd_ClassMenu(client, 0);
	
	return Plugin_Handled;
}
*/

public Action OnSuicideCommand(int client, char[] command, int argc)
{
	if (!IsWarmupPeriod())
		return Plugin_Stop;
	
	return Plugin_Continue;
}

void HumanWin()
{
	Party_TeamWin(CS_TEAM_CT);
	PrintCenterTextAll("인간들이 생존에 성공하였습니다!");
	PrintToChatAll("%s\x03인간들이 생존에 성공하였습니다!", PREFIX);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i))
		{
			if (!IsClientZombie(i) && !IsFakeClient(i))
			{
				PrintToChat(i, "%s\x01생존점수 \x03%i\x01 킬포인트 추가.", PREFIX, HUMAN_SURVIVE_REWARD);
				DDS_SetUserMoney(i, 2, HUMAN_SURVIVE_REWARD);
				//할로윈 이벤트
				/*
				PrintToChat(i, "%s\x01생존 보너스로 \x10호박 상자 \x031개\x01 지급.", PREFIX, HUMAN_SURVIVE_REWARD);
				DDS_SimpleGiveItem(i, g_iItemIndices[HalloweenBox], 1);
				*/
				
				if (bItemEvent_Active)
				{
					if (iItemEvent_Condition == 4)
					{
						ItemEvent_EventOccurToTarget(i);
					}
				}
			}
		}
	}
	
	/*decl Random;
	Random = GetRandomInt(1, 15);
	
	if(Random == 1)
	{
		new Maxselect = 0;
		new Selects[MAXPLAYERS+1];
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(AllCheck(i) == true)
			{
				if(GetClientTeam(i) == 3)
				{
					decl String:target_name[64];
					GetClientName(i, target_name, sizeof(target_name));
				
					if(!StrEqual(target_name, "[BOT]좀비팀") && !StrEqual(target_name, "[BOT]인간팀"))
					{
						Maxselect++;
						Selects[Maxselect] = i;
					}
				}
			}
		}
		
		if(Maxselect != 0)
		{
			new Target = Selects[GetRandomInt(1, Maxselect)];
			
			PrintToChatAll("\x04[SM] - \x03%s\x01님이 \x04선물상자\x01 당첨!");
			Item[Target][101] += 1;
		}
	}*/
} 