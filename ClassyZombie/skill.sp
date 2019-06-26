
#define SNDCHAN_SKILL_SOUND		11

// 보급상자 모델
// models/props_crates/static_crate_40.mdl

//탄약통 소환
stock void SetupAmmoCrate(int client)
{
	float angAngles[3];
	float vecEyePos[3];
	float pos[3];

	GetClientEyePosition(client, vecEyePos);
	GetClientEyeAngles(client, angAngles);

	Handle trace = TR_TraceRayFilterEx(vecEyePos, angAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
	}
	
	delete trace;
	
	float Dist = GetVectorDistance(pos, vecEyePos);
	int Box = TraceClientViewEntity(client);
    
	if(IsValidEntity(Box))
	{
		char Modelname[128];
		GetEntPropString(Box, Prop_Data, "m_ModelName", Modelname, 128);
		
		if(StrEqual(Modelname, AmmoCrateModel, false))
		{
			if(Dist < 200)
			{
				int AmmoCrateOwner = GetEntPropEnt(Box, Prop_Send, "m_hEffectEntity");
				int AmmoCrateLeftClip = GetEntProp(Box, Prop_Data, "m_iHealth");
				if(AmmoCrateOwner == client || !IsValidPlayer(AmmoCrateOwner) || IsClientZombie(AmmoCrateOwner))
				{
					g_iAmmoCrateClipAmount[client] += AmmoCrateLeftClip;
					SetEntProp(Box, Prop_Data, "m_iHealth", 0);
				
					if(IsValidEdict(Box))
					{
						RemoveEdict(Box);
						AcceptEntityInput(Box, "EnableMotion");
					}
				
					PrintToChat(client, "%s\x01가지고 있는 탄약량 : \x03%d", PREFIX, g_iAmmoCrateClipAmount[client]);
					EmitSoundToAll(AmmoEquipmentSound, client, _, _, _, 1.0);
				}
				else
				{
					PrintToChat(client, "%s\x01주인이 있는 탄약통은 수거할수 없습니다!", PREFIX);
				}
				return;
			}
			else
			{
//				PrintToChat(client, "%s\x01줍기에는 거리가 너무 멉니다!", PREFIX);
				return;
			}
		}
	}
		
	if(g_iAmmoCrateClipAmount[client] > 0)
	{
		int flags = GetEntityFlags(client);
		if(flags & FL_ONGROUND)
		{
			if(Dist < 200)
			{
				if(angAngles[0] > 40)
				{
					int Ent = CreateEntityByName("prop_dynamic_override");
					DispatchKeyValue(Ent, "model", AmmoCrateModel);
					DispatchKeyValueFloat(Ent, "physdamagescale", 0.0); 
					SetEntPropFloat(Ent, Prop_Send, "m_flModelScale", AmmoCrateModelSize);
					DispatchSpawn(Ent);
					
					// 남은 탄약수를 엔터티의 체력으로 기록하므로 데미지를 입어서는 안된다!
					SetEntProp(Ent, Prop_Data, "m_takedamage", 0, 1);
					
					pos[2] += 5;
					TeleportEntity(Ent, pos, NULL_VECTOR, NULL_VECTOR);
					
					AcceptEntityInput(Ent, "DisableMotion");
					
					/*
					SOLID_NONE            = 0,    // no solid model
				    SOLID_BSP            = 1,    // a BSP tree
				    SOLID_BBOX            = 2,    // an AABB
				    SOLID_OBB            = 3,    // an OBB (not implemented yet)
				    SOLID_OBB_YAW        = 4,    // an OBB, constrained so that it can only yaw
				    SOLID_CUSTOM        = 5,    // Always call into the entity for tests
				    SOLID_VPHYSICS        = 6,    // solid vphysics object, get vcollide from the model and collide with that
				    SOLID_LAST,
					*/
					SetEntProp( Ent, Prop_Data, "m_nSolidType", 6 );
					SetEntProp( Ent, Prop_Send, "m_nSolidType", 6 );
					
					/*
					FSOLID_CUSTOMRAYTEST		= (1 << 0),	// Ignore solid type + always call into the entity for ray tests
					FSOLID_CUSTOMBOXTEST		= (1 << 1),	// Ignore solid type + always call into the entity for swept box tests
					FSOLID_NOT_SOLID			= (1 << 2),	// Are we currently not solid?
					FSOLID_TRIGGER				= (1 << 3),	// This is something may be collideable but fires touch functions
															// even when it's not collideable (when the FSOLID_NOT_SOLID flag is set)
					FSOLID_NOT_STANDABLE		= (1 << 4),	// You can't stand on this
					SOLID_VOLUME_CONTENTS		= (1 << 5),	// Contains volumetric contents (like water)
					FSOLID_FORCE_WORLD_ALIGNED	= (1 << 6),	// Forces the collision rep to be world-aligned even if it's SOLID_BSP or SOLID_VPHYSICS
					FSOLID_USE_TRIGGER_BOUNDS	= (1 << 7),	// Uses a special trigger bounds separate from the normal OBB
					FSOLID_ROOT_PARENT_ALIGNED	= (1 << 8),	// Collisions are defined in root parent's local coordinate space
					FSOLID_TRIGGER_TOUCH_DEBRIS	= (1 << 9),	// This trigger will touch debris objects
					FSOLID_MAX_BITS	= 10
					*/
					SetEntProp(Ent, Prop_Data, "m_usSolidFlags", (1 << 2) | (1 << 3) || (1 << 6) || (1 << 7) || (1 << 9));
					
					SetEntData(Ent, g_offsCollision, 2, _, true);
					
//					int AmmoCrateLeftClip = GetEntProp(Box, Prop_Data, "m_iHealth"); // 나중에 쓸 일이 있을지도...
					
					if(g_iAmmoCrateClipAmount[client] >= AmmoCrateAmmoSize)
					{
						g_iAmmoCrateClipAmount[client] -= AmmoCrateAmmoSize;
						SetEntProp(Ent, Prop_Data, "m_iHealth", AmmoCrateAmmoSize);
					}
					else
					{
						SetEntProp(Ent, Prop_Data, "m_iHealth", g_iAmmoCrateClipAmount[client]);
						g_iAmmoCrateClipAmount[client] = 0;
					}
					SetEntPropEnt(Ent, Prop_Send, "m_hEffectEntity", client);
					PrintToChat(client, "%s\x01가지고 있는 탄약량 : \x03%d", PREFIX, g_iAmmoCrateClipAmount[client]);
					EmitSoundToAllAny(AmmoSetSound, Ent, _, _, _, 1.0);
					
					SDKHook(Ent, SDKHook_TraceAttack, TraceAttack);
				}
				else
				{
					PrintToChat(client, "%s\x01좀더 아래쪽을 바라보고 소환해야 합니다!", PREFIX);
				}
			}
			else
			{
				PrintToChat(client, "%s\x01소환하려는 거리가 너무 멉니다!", PREFIX);
			}
		}
		else
		{
			PrintToChat(client, "%s\x01공중에서 또는 사람을 보고 소환할수 없습니다!", PREFIX);
		}
	}
	else
	{
		PrintToChat(client, "%s\x01남은 탄약이 없습니다!", PREFIX);
	}
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask) 
{
 	if(IsValidEdict(entity))
	{
		char szClassname[64];
		GetEdictClassname(entity, szClassname, sizeof(szClassname));
		if(StrEqual(szClassname, "prop_physics") || StrEqual(szClassname, "prop_dynamic"))
			return false;
	}
 	return !IsValidClient(entity);
}

public bool tracerayfilteronlyworld(int entity, int mask, any data)
{
	if(entity == 0)
		return true;
	else
		return false;
}

//탄약통을 이용한 탄약 채우기
stock void AmmoCrateAmmo(int client)
{
	int Ent = TraceClientViewEntity(client);
    
	if(IsValidEntity(Ent) == true)
	{
		char Modelname[128];
		GetEntPropString(Ent, Prop_Data, "m_ModelName", Modelname, 128);
    
		if(StrEqual(Modelname, AmmoCrateModel, false))
		{
			char WeaponName[32];
			GetClientWeapon(client, WeaponName, 32);
			
			int eWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			int primaryWeapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			
			if(eWeapon == primaryWeapon)
			{
				float Client_Origin[3], Ent_Origin[3];
				GetClientAbsOrigin(client, Client_Origin);
				GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", Ent_Origin);
				float Dist = GetVectorDistance(Ent_Origin, Client_Origin);
		
				if(Dist > 200)
				{
					PrintToChat(client, "%s\x01탄약을 줍기에 너무 멉니다!", PREFIX);
					return;
				}
				
				
				int Ammo = GetWeaponClip(primaryWeapon);
				
				char szWeaponClassname[32];
				GetEdictClassname(eWeapon, szWeaponClassname, sizeof(szWeaponClassname));
				switch (GetEntProp(eWeapon, Prop_Send, "m_iItemDefinitionIndex"))
				{
					case 60: strcopy(szWeaponClassname, sizeof(szWeaponClassname), "weapon_m4a1_silencer");
					case 61: strcopy(szWeaponClassname, sizeof(szWeaponClassname), "weapon_usp_silencer");
					case 63: strcopy(szWeaponClassname, sizeof(szWeaponClassname), "weapon_cz75a");
				}
				int iWeaponClipSize = CacheClipSize(szWeaponClassname[7]);
				
				int iAmmoCrateLeftClip = GetEntProp(Ent, Prop_Data, "m_iHealth");
				
				if(Ammo >= iWeaponClipSize)
				{
					PrintToChat(client, "%s\x01당신은 이미 탄약이 충분합니다!", PREFIX);
					return;
				}
				
				// 채워야 할 탄약량 = (iWeaponClipSize - Ammo)
				int iAmmoToAdd = (iWeaponClipSize - Ammo);
				int iAmmoNeeded = iAmmoToAdd;
				int iAmmoSubMultiplier = 1;
				// 샷건의 경우 장탄수 4배로 깎음
				char clsname[32];
				if (GetEdictClassname(eWeapon, clsname, sizeof(clsname)))
					if(StrEqual(clsname[7], "nova") || StrEqual(clsname[7], "mag7") || StrEqual(clsname[7], "xm1014"))
						iAmmoSubMultiplier = 4;
						
				iAmmoNeeded *= iAmmoSubMultiplier;
				
				// 필요한 만큼의 탄약을 채울만한 용량이 남아있지 않을 때.
				if(iAmmoCrateLeftClip >= iAmmoNeeded)
				{
					SetWeaponClip(eWeapon, iWeaponClipSize);
					
					// 미리 깎아두고 나중에 사용하자.
					iAmmoCrateLeftClip -= iAmmoNeeded;
					SetEntProp(Ent, Prop_Data, "m_iHealth", iAmmoCrateLeftClip);
					PrintToChat(client, "%s\x01탄약통의 남은 탄약량 : \x03%d", PREFIX, iAmmoCrateLeftClip);
				}
				else
				{
					// 하지만 탄약을 하나라도 채울 용량이 남아있을 때.
					if(iAmmoCrateLeftClip >= iAmmoSubMultiplier)
					{
					//	int iAmmoToSave = iAmmoCrateLeftClip % iAmmoSubMultiplier; // 남겨야 할 탄약용량
						iAmmoNeeded = iAmmoCrateLeftClip / iAmmoSubMultiplier; // 채워야 할 탄약갯수 int와 int끼리의 나누기라 RoundToFloor()함수가 필요없다.
						
						SetWeaponClip(eWeapon, Ammo + iAmmoToAdd);
						
						// 미리 설정하고 나중에 사용하자. 남겨야 할 탄약용량에 주의할 것!
						//iAmmoCrateLeftClip - (iAmmoNeeded * iAmmoSubMultiplier)
						iAmmoCrateLeftClip -= (iAmmoNeeded * iAmmoSubMultiplier);
						
						SetEntProp(Ent, Prop_Data, "m_iHealth", iAmmoCrateLeftClip);
						PrintToChat(client, "%s\x01탄약통의 남은 탄약량 : \x03%d", PREFIX, iAmmoCrateLeftClip);
					}
					else // 탄약 하나도 채울 수 없을 때.
					{
						PrintToChat(client, "%s\x01이 탄약통에 탄약이 부족해 보급받을 수 없습니다.", PREFIX);
					}
				}
				EmitSoundToAll(AmmoPickupSound, client, _, _, _, 1.0);
				
				// 탄약을 모두 사용했을 때.
				if(iAmmoCrateLeftClip <= 0)
				{
					if(IsValidEdict(Ent))
					{
						RemoveEdict(Ent);
					}
							
					PrintToChat(client, "%s\x01탄약통의 탄약이 모두 소진되었습니다!", PREFIX);
				}
			}
			else
			{
				PrintToChat(client, "%s\x01주무기의 탄약만 채울 수 있습니다.", PREFIX);
			}
		}
	}
}

//헬스팩
stock void HealthPack(int client)
{
	int Target = TraceClientViewEntity(client);
	
	// client 에 대한 팀 체크는 OnClientRunCmd에서 처리해주므로 이곳에선 처리하지 않아도 됨.
	// 게임 시작 전에는 무조건 인간 팀이므로, or를 통해 게임 시작 전을 조건으로 걸어준다.
	if(IsValidPlayer(Target) && !IsClientZombie(Target))
	{
		float Client_Origin[3], Target_Origin[3];
		GetClientAbsOrigin(client, Client_Origin);
		GetClientAbsOrigin(Target, Target_Origin);
		
		float Dist = GetVectorDistance(Target_Origin, Client_Origin);
		
		if(Dist < 150)
		{
			char Client_Name[64], Target_Name[64];
			GetClientName(client, Client_Name, 64);
			GetClientName(Target, Target_Name, 64);
			
			/*
			client 와 target의 구분을 정확히 할 것!
			*/
			int eWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			int Ammo = GetWeaponClip(eWeapon);
			
			int iTargetMaxHealth = GetEntProp(Target, Prop_Data, "m_iMaxHealth");
			int iTargetCurrentHealth = GetClientHealth(Target);
			
			int iClientMaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
			int iClientCurrentHealth = GetClientHealth(client);
			/*
			최대 치료할 수 있는 체력: (iTargetMaxHealth-iTargetCurrentHealth)
			*/
			// 탄약이 없거나 이미 최대 체력일 경우.
			if(Ammo == 0)
			{
				PrintToChat(client, "%s\x01탄약이 부족해 치료할 수 없습니다.", PREFIX);
				return;
			}
			
			// 현재 체력이 이미 최대체력과 같거나 더 많을때,
			// 또한 감염에 걸리지 않은 경우.
			if(iTargetMaxHealth<=iTargetCurrentHealth && g_nPenetrationCount[Target] <= 0)
			{
				PrintToChat(client, "%s\x01대상이 충분히 건강합니다.", PREFIX);
				return;
			}
			
			#define BASE_HEAL_AMOUNT	10
			
			// 의무병의 레벨에 따른 힐량
			int iHealAmount = BASE_HEAL_AMOUNT + (g_iClassLevel[client][5] * 2);

			int iHealthAmoutToHealTarget;
			int iHealthAmoutToHealSelf;
			
			// 탄약도 충분하고, 타겟의 체력도 충분히 빠져있을 때.
			if(Ammo >= BASE_HEAL_AMOUNT && (iTargetMaxHealth-iTargetCurrentHealth) >= iHealAmount)
			{
				// Ammo가 BASE_HEAL_AMOUNT와 같고,
				SetWeaponClip(eWeapon, Ammo - BASE_HEAL_AMOUNT);
				EmitSoundToAllAny(HealingSound, Target, _, _, _, 0.5);
				
				iHealthAmoutToHealTarget = iHealAmount;
				iHealthAmoutToHealSelf = (g_iClassLevel[client][5] + 2);
			}
			// 탄약이 충분하지만, 타겟의 체력이 별로 빠지지 않았을 때.
			else if (Ammo >= BASE_HEAL_AMOUNT && (iTargetMaxHealth-iTargetCurrentHealth) < iHealAmount)
			{
				int iAmmoToDecrease = (iTargetMaxHealth - iTargetCurrentHealth);
				
				// 이 때 깎을 탄약은 BASE_HEAL_AMOUNT을 넘어서는 안된다.
				if(iAmmoToDecrease > BASE_HEAL_AMOUNT)
					iAmmoToDecrease = BASE_HEAL_AMOUNT;
				
				SetWeaponClip(eWeapon, Ammo - iAmmoToDecrease);
				
				iHealthAmoutToHealTarget = (iTargetMaxHealth-iTargetCurrentHealth);
				iHealthAmoutToHealSelf = (g_iClassLevel[client][5]/(iHealAmount-(iTargetMaxHealth-iTargetCurrentHealth)) + 2);
			}
			// 타겟의 체력이 충분히 빠져있지만, 탄약이 부족할 때.
			else if(Ammo < BASE_HEAL_AMOUNT && (iTargetMaxHealth-iTargetCurrentHealth) >= iHealAmount)
			{
				SetWeaponClip(eWeapon, 0);
				
				iHealthAmoutToHealTarget = Ammo;
				iHealthAmoutToHealSelf = (g_iClassLevel[client][5]/(BASE_HEAL_AMOUNT-Ammo)) + 1;
			}
			// 탄약이 부족하지만, 타겟의 체력이 별로 빠지지 않았을 때.
			else if(Ammo < BASE_HEAL_AMOUNT && (iTargetMaxHealth-iTargetCurrentHealth) < iHealAmount)
			{
				// 타겟의 체력이 탄약과 같거나 적을때
				// 타겟의 체력 위주로 치료한다.
				if((iTargetMaxHealth-iTargetCurrentHealth) <= Ammo)
				{
					int iAmmoToDecrease = (iTargetMaxHealth - iTargetCurrentHealth);
				
					// 이 때 깎을 탄약은 현재 가진 탄약 수를 넘어서는 안된다.
					if(iAmmoToDecrease > Ammo)
						iAmmoToDecrease = Ammo;
					
					SetWeaponClip(eWeapon, Ammo - iAmmoToDecrease);
					
					iHealthAmoutToHealTarget = (iTargetMaxHealth-iTargetCurrentHealth);
					iHealthAmoutToHealSelf = (g_iClassLevel[client][5]/(iHealAmount-(iTargetMaxHealth-iTargetCurrentHealth)) + 1);
				}
				// 치료해야 할 체력만큼의 탄약이 없을 때
				// 남은 탄약 위주로 치료한다.
				else
				{
					SetWeaponClip(eWeapon, 0);
					
					iHealthAmoutToHealTarget = Ammo;
					iHealthAmoutToHealSelf = (g_iClassLevel[client][5]/(BASE_HEAL_AMOUNT-Ammo)) + 1;
				}
			}
			
			EmitSoundToAllAny(HealingSound, Target, _, _, _, 0.5);
			
			SetEntityHealth(Target, iTargetCurrentHealth + iHealthAmoutToHealTarget);
			
			// 자가 치료시 최대 체력을 넘지 못하도록 제한한다.
			if((iClientMaxHealth-iClientCurrentHealth) >= iHealthAmoutToHealSelf)
			{
				SetEntityHealth(client, iClientCurrentHealth + iHealthAmoutToHealSelf);
			}
			else
			{
				SetEntityHealth(client, iClientMaxHealth);
			}
			CureHuman(Target);
			EmitSoundToAllAny(HealingSound, Target, SNDCHAN_SKILL_SOUND, _, _, _, _, _, _, _, true);
			PrintToChat(client, "%s\x03%s\x01님을 \x03%d\x01만큼 치료 해주었습니다.", PREFIX, Target_Name, iHealthAmoutToHealTarget);
			PrintToChat(Target, "%s\x03%s\x01님이 당신을 \x03%d\x01만큼 치료 해주었습니다.", PREFIX, Client_Name, iHealthAmoutToHealTarget);
			
			Client_Origin[2] += 64.0;
			Target_Origin[2] += 64.0;
			TE_SetupBubbles(Client_Origin, Client_Origin, g_iRedCrossCache, 40.0, (g_iClassLevel[client][5]/2), 0.5);
			TE_SendToAll();
			TE_SetupBubbles(Target_Origin, Target_Origin, g_iRedCrossCache, 40.0, g_iClassLevel[client][5] + 1, 0.5);
			TE_SendToAll();
		}
		else
		{
			PrintToChat(client, "%s\x01치료하려는 대상과의 거리가 너무 멉니다!", PREFIX);
		}
	}
}

//우드패널
#define BOARD_HEALTH_PER_LEVEL 30
stock void WoodBoard(int client)
{
	static float nextmovetime[MAXPLAYERS + 1];
	float now = GetEngineTime();
		
	if(nextmovetime[client] <= now)
	{
		nextmovetime[client] = now + 0.1;
		if(g_iBoardOnPlaceControl[client] == 0)
		{
			if(g_iBoardAmount[client] > 0)
			{
				if(g_iBoardOnPlaceControl[client] != 0)
				{
					if(IsValidEntity(g_iBoardOnPlaceControl[client]) == true)
					{
						RemoveEdict(g_iBoardOnPlaceControl[client]);
						return;
					}
				}
					
				g_iBoardOnPlaceControl[client] = 0;
			
				g_iBoardOnPlaceControl[client] = CreateEntityByName("prop_physics_override");
				DispatchKeyValue(g_iBoardOnPlaceControl[client], "model", BarricadeModel);
				DispatchKeyValueFloat(g_iBoardOnPlaceControl[client], "physdamagescale", 0.0);
				DispatchSpawn(g_iBoardOnPlaceControl[client]);
	
				// 나무 판자 체력 설정
				int BoardHelath = 150 + (g_iClassLevel[client][3] * BOARD_HEALTH_PER_LEVEL);
				SetEntProp(g_iBoardOnPlaceControl[client], Prop_Data, "m_iMaxHealth", BoardHelath); 
				SetEntProp(g_iBoardOnPlaceControl[client], Prop_Data, "m_iHealth", BoardHelath);
				
				AcceptEntityInput(g_iBoardOnPlaceControl[client], "DisableMotion");
				SetEntData(g_iBoardOnPlaceControl[client], g_offsCollision, 2, 4, true);
				SetEntityRenderMode(g_iBoardOnPlaceControl[client], RENDER_GLOW);
				SetEntityRenderColor(g_iBoardOnPlaceControl[client], 255, 255, 255, 127);
				SetEntProp(g_iBoardOnPlaceControl[client], Prop_Data, "m_takedamage", 0, 1);
				SetEntPropEnt(g_iBoardOnPlaceControl[client], Prop_Send, "m_hEffectEntity", client);
				
				g_flBoardHeight[client] = 0.0;
				
				SDKHook(client, SDKHook_PostThink, WoodHook);
			}
			else
			{
				PrintToChat(client, "%s\x01더 이상 나무판자를 소환할수 없습니다.", PREFIX);
			}
		}
		else
		{
			if(IsValidEntity(g_iBoardOnPlaceControl[client]) == true)
			{
				float eOri[3], cOri[3];
			
				for(int i = 1; i <= MaxClients; i++)
				{
					if(client != i)
					{
						if(IsValidPlayer(i))
						{
							GetClientEyePosition(i, cOri);
							GetEntPropVector(g_iBoardOnPlaceControl[client], Prop_Send, "m_vecOrigin", eOri);
	
							float Dist = GetVectorDistance(cOri, eOri);
							
							if(Dist < 50)
							{
								PrintToChat(client, "%s\x01소환하려는 곳에 다른 플레이어가 있습니다!", PREFIX);
								return;
							}
						}
					}
				}
				
				AcceptEntityInput(g_iBoardOnPlaceControl[client], "DisableMotion");
				SetEntProp(g_iBoardOnPlaceControl[client], Prop_Data, "m_nSolidType", 6);
				SetEntData(g_iBoardOnPlaceControl[client], g_offsCollision, 5, 4, true);
				SetEntityRenderMode(g_iBoardOnPlaceControl[client], RENDER_GLOW);
				SetEntityRenderColor(g_iBoardOnPlaceControl[client], 255, 255, 255, 255);
				SetEntProp(g_iBoardOnPlaceControl[client], Prop_Data, "m_takedamage", 2, 1);
				SDKUnhook(client, SDKHook_PostThink, WoodHook);
				
				/**
				if(BoardEnt[client][0] == 0)
				{
					BoardEnt[client][0] = g_iBoardOnPlaceControl[client];
					SDKHook(g_iBoardOnPlaceControl[client], SDKHook_StartTouch, WoodTouchHook);
				}
				else if(BoardEnt[client][1] == 0)
				{
					BoardEnt[client][1] = g_iBoardOnPlaceControl[client];
					SDKHook(g_iBoardOnPlaceControl[client], SDKHook_StartTouch, WoodTouchHook);
				}*/
				
				SDKHook(g_iBoardOnPlaceControl[client], SDKHook_Touch, WoodTouchHook);
				SDKHook(g_iBoardOnPlaceControl[client], SDKHook_StartTouch, WoodTouchHook);
				SDKHook(g_iBoardOnPlaceControl[client], SDKHook_TraceAttack, TraceAttack);
				
				g_iBoardAmount[client] -= 1;
				g_iBoardOnPlaceControl[client] = 0;
			}
			else
			{
				SDKUnhook(client, SDKHook_PostThink, WoodHook);
				if(g_iBoardOnPlaceControl[client] != 0)
					if(IsValidEntity(g_iBoardOnPlaceControl[client]) == true)
						RemoveEdict(g_iBoardOnPlaceControl[client]);
					
				g_iBoardOnPlaceControl[client] = 0;
			}
		}
	}
}
public void WoodHook(int client)
{
	// WTF!?
	// 개인 변수로 주지말고 그냥 한번에 모두 처리시키도록 하자...
	if(g_iBoardOnPlaceControl[client] != 0)
	{
		if(IsValidEntity(g_iBoardOnPlaceControl[client]) == true)
		{
			if(IsValidPlayer(client))
			{
				if(!IsClientZombie(client))
				{
					char WeaponName[32];
					GetClientWeapon(client, WeaponName, 32);	
				
					if(StrEqual(WeaponName, "weapon_knife", false))
					{
						float eAngles[3];
						float eOrigin[3];
						float pos[3];
												
						GetClientEyePosition(client, eOrigin);
						GetClientEyeAngles(client, eAngles);
										
						float cOrigin[3];
						GetClientAbsOrigin(client, cOrigin); 
										
						Handle trace = TR_TraceRayFilterEx(eOrigin, eAngles, MASK_SHOT, RayType_Infinite, tracerayfilteronlyworld);
										
						if(TR_DidHit(trace))
						{
							TR_GetEndPosition(pos, trace);
											
							pos[0] = (cOrigin[0] + (50 * Cosine(DegToRad(eAngles[1]))));
							pos[1] = (cOrigin[1] + (50 * Sine(DegToRad(eAngles[1]))));
							pos[2] = eOrigin[2] + g_flBoardHeight[client];
											
							eAngles[0] = 90.0;
							eAngles[2] = 0.0;
							TeleportEntity(g_iBoardOnPlaceControl[client], pos, eAngles, NULL_VECTOR);
						}
						
						delete trace;
					}
					else
					{
						SDKUnhook(client, SDKHook_PostThink, WoodHook);
						RemoveEdict(g_iBoardOnPlaceControl[client]);
						g_iBoardOnPlaceControl[client] = 0;
					}
				}
				else
				{
					SDKUnhook(client, SDKHook_PostThink, WoodHook);
					RemoveEdict(g_iBoardOnPlaceControl[client]);
					g_iBoardOnPlaceControl[client] = 0;
				}
			}
			else
			{
				SDKUnhook(client, SDKHook_PostThink, WoodHook);
				RemoveEdict(g_iBoardOnPlaceControl[client]);
				g_iBoardOnPlaceControl[client] = 0;
			}
		}
		else
		{
			SDKUnhook(client, SDKHook_PostThink, WoodHook);
			g_iBoardOnPlaceControl[client] = 0;
		}
	}
}

public Action WoodTouchHook(int entity, int other)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] WoodTouchHook(%i -> %i)", entity, other);
	#endif
	
	char szClassname[32];
	if(IsValidPlayer(other))
	{
		if(!IsClientZombie(other))
		{
			DataPack pack = new DataPack();
			pack.WriteCell(entity);
			pack.WriteCell(other);
			
			RequestFrame(WoodTouchHookPost, pack);
		}
	}
	else if(GetEdictClassname(other, szClassname, sizeof(szClassname)))
	{
		// 판자가 프롭에 닿으면
		if(StrEqual(szClassname, "prop_physics"))
		{
			// 판자 삭제
			AcceptEntityInput(other, "Kill");
		}
	}
}

public void WoodTouchHookPost(DataPack pack)
{
	pack.Reset();
	int entity = pack.ReadCell();
	int other = pack.ReadCell();
	delete pack;
	
	if(IsValidEdict(entity) && IsValidEdict(other))
		MakeKnockBack(entity, other, 350.0, true);
}

/*stock CreateAngleSensor(int client, float pos[3], float ang[3])
{
    new AngleSensor = CreateEntityByName("point_anglesensor");
    
    if(IsValidEntity(client) && IsValidEntity(AngleSensor))
    {
        PrintToChatAll("AngleSensor is valid!");

        DispatchKeyValue(AngleSensor, "lookatname", BoardEnt[0]);
        DispatchKeyValue(AngleSensor, "target", client);
        DispatchKeyValueFloat(AngleSensor, "duration", 3.0);
        SetEntPropFloat(AngleSensor, Prop_Data, "m_flDotTolerance", 60.0);
        DispatchKeyValue(AngleSensor, "spawnflags", "1");
        DispatchSpawn(AngleSensor);

        AcceptEntityInput(AngleSensor, "Enable");
        TeleportEntity(AngleSensor, pos, ang, NULL_VECTOR);
        //SetEntityParent(AngleSensor, client); // my own function
        
        HookSingleEntityOutput(AngleSensor, "OnFacingLookat", AngleSensorCallback);
    }
}*/


stock int TraceClientViewEntity(int client)
{
	float m_vecOrigin[3];
	float m_angRotation[3];
	GetClientEyePosition(client, m_vecOrigin);
	GetClientEyeAngles(client, m_angRotation);
	Handle tr = TR_TraceRayFilterEx(m_vecOrigin, m_angRotation, MASK_ALL, RayType_Infinite, TRDontHitSelf, client);
	int	pEntity = -1;
	if (TR_DidHit(tr))
	{
		pEntity = TR_GetEntityIndex(tr);
		CloseHandle(tr);
		return pEntity;
	}
	
	delete tr;
	return -1;
}

public bool TRDontHitSelf(int entity, int mask, any data)
{
	if (entity == data) return false;
	return true;
}


#define ACID_GAS_MAX_PENET_COUNT	6 // 가스가 최대로 입힐 수 있는 바이러스 감염횟수

stock void MakeGas(Client, float Position[3])
{		
	int smoke = CreateEntityByName("env_smokestack");
	char client_name[128];
	Format(client_name, sizeof(client_name), "smoke%s", Client);
			
	SetEntPropEnt(smoke, Prop_Send, "m_hEffectEntity", Client);
	
	DispatchKeyValue(smoke, "targetname", client_name);
	DispatchKeyValueVector(smoke, "Origin", Position);
	DispatchKeyValue(smoke, "BaseSpread", "1");
	DispatchKeyValue(smoke, "SpreadSpeed", "40");
	DispatchKeyValue(smoke, "Speed", "20");
	DispatchKeyValue(smoke, "StartSize", "50.0");
	DispatchKeyValue(smoke, "EndSize", "150.0");
	DispatchKeyValue(smoke, "Rate", "5");
	DispatchKeyValueFloat(smoke, "Roll", 30.0);
	DispatchKeyValue(smoke, "JetLength", "80");
	DispatchKeyValue(smoke, "Twist", "3");
	DispatchKeyValue(smoke, "RenderColor", "0, 200, 0");
	DispatchKeyValue(smoke, "RenderAmt", "200");
	// particle/smoke1/smoke1.vmt
	// particle/smoke1/smoke1_add_nearcull.vmt
	// particle/smoke1/smoke1_additive.vmt
	// particle/smoke1/smoke1_additive_nearcull.vmt
	// particle/smoke1/smoke1_ash.vmt
	// particle/smoke1/smoke1_nearcull.vmt
	// particle/smoke1/smoke1_nearcull2.vmt
	// particle/smoke1/smoke1_nearcull3.vmt
	// particle/smoke1/smoke1_snow.vmt
	// particle/particle_smokegrenade.vmt
	// particle/particle_smokegrenade_2.vmt
	// particle/particle_smokegrenade_sc.vmt
	// particle/particle_smokegrenade1.vmt
	// particle/particle_smokegrenade2.vmt
	// particle/particle_smokegrenade3.vmt
	DispatchKeyValue(smoke, "SmokeMaterial", "particle/particle_smokegrenade1.vmt");
			
	DispatchSpawn(smoke);
	AcceptEntityInput(smoke, "TurnOn");
	
	CreateTimer(8.0, TurnOffAcidGas, smoke);
	CreateTimer(12.0, RemoveAcidGas, smoke);
	
	// TODO 틱 훅을 걸어 데미지처리
	HookEntityThink(smoke, AcidGasThink, 0.5, -1, false);
}

public Action TurnOffAcidGas(Handle timer, any entity)
{	
	if(IsValidEdict(entity))
	{
		UnhookSingleEntityOutput(entity, "OnUser2", AcidGasThink);
		AcceptEntityInput(entity, "TurnOff");
	}
}

public Action RemoveAcidGas(Handle timer, any entity)
{	
	if(IsValidEdict(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
}

public void AcidGasThink(const char[] output, int entity, int activator, float delay)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] AcidGasThink()");
	#endif
	
	AcceptEntityInput(entity, "FireUser1");
	/*
	float flDamageTime = GetEntPropFloat(entity, Prop_Data, "m_flAnimTime");
	float flGameTime = GetGameTime();
	
	if (flDamageTime > flGameTime)	return;
	
	SetEntPropFloat(entity, Prop_Data, "m_flAnimTime", flGameTime + 1.0); // 1초간격 데미지
	*/
	if(IsValidEdict(entity))
	{
		float vecGasAbsOrigin[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vecGasAbsOrigin);
		
		int iGasOwner = GetEntPropEnt(entity, Prop_Send, "m_hEffectEntity");
		
		/*
		if(g_iGasZombie != iGasOwner)
		{
			UnhookSingleEntityOutput(entity, "OnUser2", AcidGasThink);
			return;
		}*/
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidPlayer(i) && !IsClientZombie(i))
			{
				float vecClientAbsOrigin[3];
				GetClientAbsOrigin(i, vecClientAbsOrigin);
				float Dist = GetVectorDistance(vecGasAbsOrigin, vecClientAbsOrigin);
				
				if(Dist <= 130)
				{
					if(g_nPenetrationCount[i] < ACID_GAS_MAX_PENET_COUNT)
						PenetrateVirus(i, iGasOwner);
					
					if(GetClientHealth(i) > 5)
					{
						SDKHooks_TakeDamage(i, 0, IsValidClient(iGasOwner)?iGasOwner:0, 5.0, DMG_POISON);
					}
					else
					{
						InfectHuman(i, iGasOwner);
					}
					
				}
			}
		}
	}
	else
	{
		UnhookSingleEntityOutput(entity, "OnUser2", AcidGasThink);
	}
}

stock bool HookEntityThink(iEntity, EntityOutput funcCallback, float flInterval = 0.1, int nCount = -1, bool bOnce = false)
{
	HookSingleEntityOutput(iEntity, "OnUser2", funcCallback, bOnce);
	
	char sOutput[64];
	FormatEx(sOutput, sizeof(sOutput), "OnUser1 !self:FireUser2::%.3f:%d", flInterval, nCount);
	SetVariantString(sOutput);
	AcceptEntityInput(iEntity, "AddOutput");
	
	return AcceptEntityInput(iEntity, "FireUser1");
}

void JumpSkill(client)
{
	float Angle[3], Vector[3];
	
	GetClientEyeAngles(client, Angle);
	GetAngleVectors(Angle, Vector, NULL_VECTOR, NULL_VECTOR); 
	NormalizeVector(Vector, Vector);
	ScaleVector(Vector, 650.0);
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Vector);
	EmitSoundToAllAny(SOUND_JUMP_ZOMBIE_SKILL, client, SNDCHAN_SKILL_SOUND, _, _, _, _, _, _, _, true); // TODO 사운드 추가
}

#define SKILL_HOST_ZOMBIE_SHAKE_MULTIPLIER	50.0 // 이 값이 클수록 더 잘 안흔들림.
#define SKILL_HOST_ZOMBIE_PUSH_MULTIPLIER	100.0

void ShakeEffect(client)
{
	float cOri[3], iOri[3], Dist;
	GetClientEyePosition(client, cOri);
	EmitSoundToAllAny(SOUND_HOST_ZOMBIE_SKILL, client, SNDCHAN_SKILL_SOUND, 100, _, _, _, _, _, _, true); // TODO 사운드 추가
	
	/*
	cOri[2] -= 50;
	TE_SetupBeamRingPoint(cOri, 0.0, 400.0, tube, footstepsprite, 0, 10, 0.5, 10.0, 1.5, {255, 255, 255, 255}, 5, 0);
	TE_SendToAll();
		
	cOri[2] += 25;
	TE_SetupBeamRingPoint(cOri, 0.0, 400.0, tube, footstepsprite, 0, 10, 0.5, 10.0, 1.5, {255, 255, 255, 255}, 5, 0);
	TE_SendToAll();
		
	cOri[2] += 25;
	TE_SetupBeamRingPoint(cOri, 0.0, 400.0, tube, footstepsprite, 0, 10, 0.5, 10.0, 1.5, {255, 255, 255, 255}, 5, 0);
	TE_SendToAll();
		
	cOri[2] += 25;
	TE_SetupBeamRingPoint(cOri, 0.0, 400.0, tube, footstepsprite, 0, 10, 0.5, 10.0, 1.5, {255, 255, 255, 255}, 5, 0);
	TE_SendToAll();
		
	cOri[2] += 25;
	TE_SetupBeamRingPoint(cOri, 0.0, 400.0, tube, footstepsprite, 0, 10, 0.5, 10.0, 1.5, {255, 255, 255, 255}, 5, 0);
	TE_SendToAll();
	*/
	
	Shake(client, 1.0);
			
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidPlayer(i))
		{
			if(!IsClientZombie(i))
			{
				GetClientEyePosition(i, iOri);
				Dist = GetVectorDistance(cOri, iOri);
				
				/*if(cOri[2] > iOri[2])
					Height = cOri[2] - iOri[2];
				else
					Height = iOri[2] - cOri[2];*/
						
				if(Dist <= 600)
				{
					if(Dist < SKILL_HOST_ZOMBIE_SHAKE_MULTIPLIER)
						Dist = SKILL_HOST_ZOMBIE_SHAKE_MULTIPLIER;
					else if(Dist >= 300)
						Dist /= 2.0;
					
					Shake(i, (20.0 * SKILL_HOST_ZOMBIE_SHAKE_MULTIPLIER) / Dist); // 최대 15.0 초					
					
					if(GetRandomInt(1, 5) == 1)
					{
						int iActiveWeapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
						int weapon = GetPlayerWeaponSlot(i, CS_SLOT_KNIFE);
						
						// 지금 들고있는 무기가 칼이 아닐 때
						if(iActiveWeapon != weapon)
							CS_DropWeapon(i, iActiveWeapon, true); // 던지듯이 버린다.
						else
							CS_DropWeapon(i, iActiveWeapon, false); // 바로 바닥에 떨어트린다. 
					}
					
					if(GetRandomInt(1, 5) == 2)
					{
						if(IsValidPlayer(client) && IsValidPlayer(i))
							MakeKnockBack(client, i, (200.0 * SKILL_HOST_ZOMBIE_PUSH_MULTIPLIER) / Dist, true); // 최대 400
					}
				}
			}
		}
	}
}