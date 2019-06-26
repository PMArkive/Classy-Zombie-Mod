#define SNDCHAN_SKILL_SOUND		11

public void OnAllPluginsLoaded()
{
	if (DDS_IsPluginOn())
	{
		DDS_RemoveGlobalItem(CRATE_ID);
		DDS_RemoveGlobalItem(COMMON_ID);
		DDS_RemoveGlobalItem(EXPENDABLE_ID);
		
		DDS_CreateGlobalItem(CRATE_ID, "상자", "crate", false);
		DDS_CreateGlobalItem(COMMON_ID, "일반", "common", false);
		DDS_CreateGlobalItem(EXPENDABLE_ID, "소모품", "expendable supply", false);
		
		Handle cvarModZombie = FindConVar("dds_switch_modzombie");
		
		if(cvarModZombie != null)
		{
			SetConVarInt(cvarModZombie, 1);
		}
	}
}

/* 포워드 처리 - DDS_OnSetGlobalItemListPost */
public void DDS_OnSetGlobalItemListPost(int itemid, const char[] itemname, int itemcode, const char[] itemadrs, itemcolor[4], int itemprice, int itemproc, itempos[3], itemang[3], int itemspecial, int itemtime, char[] itemoption, int itemuse)
{
	// 보급상자 인덱스 구하기
	if(itemcode == 17 && StrEqual(itemoption, "supply crate", false))
	{
		g_iItemIndices[SupplyCrate] = itemid;
	}
	// 선물상자 인덱스 구하기
	if(itemcode == 17 && StrEqual(itemoption, "gift box", false))
	{
		g_iItemIndices[GiftBox] = itemid;
	}
	// 가벼운 상자 인덱스 구하기
	if(itemcode == 17 && StrEqual(itemoption, "light box", false))
	{
		g_iItemIndices[LightBox] = itemid;
	}
	// 스킨 박스 인덱스 구하기
	if(itemcode == 17 && StrEqual(itemoption, "skin box", false))
	{
		g_iItemIndices[SkinBox] = itemid;
	}
	// 레어스킨 박스 인덱스 구하기
	if(itemcode == 17 && StrEqual(itemoption, "special skin box", false))
	{
		g_iItemIndices[SpecialSkinBox] = itemid;
	}
	// 모자 박스 인덱스 구하기
	if(itemcode == 17 && StrEqual(itemoption, "hat box", false))
	{
		g_iItemIndices[HatBox] = itemid;
	}
	// 증표 인덱스 구하기
	else if(itemcode == 18 && StrEqual(itemoption, "voucher", false))
	{
		g_iItemIndices[Voucher] = itemid;
	}
	else if(itemcode == 19 && StrEqual(itemoption, "supply dollar|3000", false))
	{
		g_iItemIndices[SupplyMoney] = itemid;
	}
	else if(itemcode == 19 && StrEqual(itemoption, "parachute", false))
	{
		g_iItemIndices[Parachute] = itemid;
	}
	// 로켓 인덱스
	if(itemcode == 19 && StrEqual(itemoption, "rocket", false))
	{
		g_iItemIndices[Rocket] = itemid;
	}
	if(itemcode == 17 && StrEqual(itemoption, "halloween box", false))
	{
		g_iItemIndices[HalloweenBox] = itemid;
	}
	// 센트리건 인덱스
	if(itemcode == 19 && StrEqual(itemoption, "sentry gun", false))
	{
		g_iItemIndices[SentryGun] = itemid;
	}
}

public Action DDS_OnClientSetItemPre(int client, int itemcode, int itemid)
{
	if (DDS_IsPluginOn())
	{
		if (IsClientInGame(client))
		{
			// 아이템 갯수 구하기
			int iItemCount = DDS_GetClientItemCount(client, itemid);
			// 아이템 갯수가 모자랄 때
			if(iItemCount <= 0)
			{
				DDS_PrintToChat(client, "아이템이 부족하여 사용할 수 없습니다.");
				return Plugin_Stop;
			}
			
			if (itemcode == CRATE_ID)
			{
				if(IsValidClient(client))
				{
					// 10 = Item Option
					char strOption[32], strItemName[64];
					DDS_GetItemInfo(itemid, 1, strItemName);
					DDS_GetItemInfo(itemid, 10, strOption);
					//TODO: CODE HERE TO ACTIVATE ITEM
					
					// 보급상자
					if(StrEqual(strOption, "supply crate", false))
					{
						int resultItem = DDS_GetRandomItem(EXPENDABLE_ID, 0, 0, true);
						if(resultItem != 0)
						{
							// 1 = Item Name
							char strResultItemName[64];
							DDS_GetItemInfo(resultItem, 1, strResultItemName);
							
							int itemAmount = MathGetRandomInt(1, 3);
							
							PrintToChat(client, "%s\x10%s\x01에서 \x04%s %d\x01개가 나왔습니다.", PREFIX, strItemName, strResultItemName, itemAmount);
							DDS_SimpleGiveItem(client, resultItem, itemAmount);
						}
						else
						{
							int random = MathGetRandomInt(0, 1);
							
							if(random == 1)
							{
								resultItem = g_iItemIndices[SentryGun];
								
								// 1 = Item Name
								char strResultItemName[64];
								DDS_GetItemInfo(resultItem, 1, strResultItemName);
								
								// 센트리건 무조건 1개
								int itemAmount = 1;
								
								PrintToChat(client, "%s\x10%s\x01에서 \x04%s %d\x01개가 나왔습니다.", PREFIX, strItemName, strResultItemName, itemAmount);
								DDS_SimpleGiveItem(client, resultItem, itemAmount);
							}
							else
							{
								PrintToChat(client, "%s\x01%s에서 아무것도 나오지 않았습니다.", PREFIX, strItemName);
							}
						}
					}
					// 선물 상자
					else if(StrEqual(strOption, "gift box", false))
					{
						float setmin = 0.0, setmax = 10000.0;
						float ranfloat, ranper;
						
						ranfloat = MathGetRandomFloat(setmin, setmax);
						ranper = (ranfloat / setmax) * 100.0;
						int resultItem;
						if (ranper <= 50.0) // 확률이 50% 일 때
						{
							resultItem = g_iItemIndices[SpecialSkinBox];
						}
						else if (ranper <= 100.0)
						{
							resultItem = g_iItemIndices[HatBox];
						}
						
						if(resultItem > 0)
						{
							// 1 = Item Name
							char strResultItemName[64];
							DDS_GetItemInfo(resultItem, 1, strResultItemName);
							
							PrintToChat(client, "%s\x10%s\x01에서 \x04%s \x01아이템이 나왔습니다.", PREFIX, strItemName, strResultItemName);
							DDS_SimpleGiveItem(client, resultItem, 1);
							
							PrintToChatAll("%s\x03%N\x01님이 \x10%s\x01에서 \x04%s \x01아이템을 꺼냈습니다.", PREFIX, client, strItemName, strResultItemName);
						}
						else
						{
							PrintToChat(client, "%s\x01아이템 항목이 부족하여 아무것도 받지 못했습니다.", PREFIX);
						}
					}
					// 가벼운 상자
					else if(StrEqual(strOption, "light box", false))
					{
						float setmin = 0.0, setmax = 10000.0;
						float ranfloat, ranper;
						
						ranfloat = MathGetRandomFloat(setmin, setmax);
						ranper = (ranfloat / setmax) * 100.0;
						
						if (ranper <= 0.5) // 확률이 1% 일 때
						{
							int resultItem = g_iItemIndices[GiftBox];
							if(resultItem > 0)
							{
								// 1 = Item Name
								char strResultItemName[64];
								DDS_GetItemInfo(resultItem, 1, strResultItemName);
								
								PrintToChat(client, "%s\x10%s\x01에서 \x04%s \x01아이템이 나왔습니다.", PREFIX, strItemName, strResultItemName);
								DDS_SimpleGiveItem(client, resultItem, 1);
								
								PrintToChatAll("%s\x03%N\x01님이 \x10%s\x01에서 \x04%s \x01아이템을 꺼냈습니다.", PREFIX, client, strItemName, strResultItemName);
							}
							else
							{
								PrintToChat(client, "%s\x01아이템 항목이 부족하여 아무것도 받지 못했습니다.", PREFIX);
							}
						}
						else if (ranper <= 10.0) // 확률이 (10.0 - 1.0)%일 때
						{
							int resultItem = g_iItemIndices[SkinBox];
							if(resultItem > 0)
							{
								// 1 = Item Name
								char strResultItemName[64];
								DDS_GetItemInfo(resultItem, 1, strResultItemName);
								
								PrintToChat(client, "%s\x10%s\x01에서 \x04%s \x01아이템이 나왔습니다.", PREFIX, strItemName, strResultItemName);
								DDS_SimpleGiveItem(client, resultItem, 1);
								
								PrintToChatAll("%s\x03%N\x01님이 \x10%s\x01에서 \x04%s \x01아이템을 꺼냈습니다.", PREFIX, client, strItemName, strResultItemName);
							}
							else
							{
								PrintToChat(client, "%s\x01아이템 항목이 부족하여 아무것도 받지 못했습니다.", PREFIX);
							}
						}
						else
						{
							PrintToChat(client, "%s\x01%s에서 아무것도 나오지 않았습니다.", PREFIX, strItemName);
						}
					}
					// 일반 스킨 상자
					else if(StrEqual(strOption, "skin box", false))
					{						
						int resultItem = DDS_GetRandomItem(3, 0, 0, true);
						if(resultItem > 0)
						{
							// 1 = Item Name
							char strResultItemName[64];
							DDS_GetItemInfo(resultItem, 1, strResultItemName);
							
							PrintToChat(client, "%s\x10%s\x01에서 \x04%s \x01아이템이 나왔습니다.", PREFIX, strItemName, strResultItemName);
							DDS_SimpleGiveItem(client, resultItem, 1);
							
							PrintToChatAll("%s\x03%N\x01님이 \x10%s\x01에서 \x04%s \x01아이템을 꺼냈습니다.", PREFIX, client, strItemName, strResultItemName);
						}
						else
						{
							PrintToChat(client, "%s\x01%s에서 아무것도 나오지 않았습니다.", PREFIX, strItemName);
						}
					}
					// 레어 스킨 상자
					else if(StrEqual(strOption, "special skin box", false))
					{
						int resultItem = DDS_GetRandomItem(3, 2, 2, false);
						if(resultItem > 0)
						{
							// 1 = Item Name
							char strResultItemName[64];
							DDS_GetItemInfo(resultItem, 1, strResultItemName);
							
							PrintToChat(client, "%s\x10%s\x01에서 \x04%s \x01아이템이 나왔습니다.", PREFIX, strItemName, strResultItemName);
							DDS_SimpleGiveItem(client, resultItem, 1);
								
							PrintToChatAll("%s\x03%N\x01님이 \x10%s\x01에서 \x04%s \x01아이템을 꺼냈습니다.", PREFIX, client, strItemName, strResultItemName);
						}
						else
						{
							PrintToChat(client, "%s\x01아이템 항목이 부족하여 아무것도 받지 못했습니다.", PREFIX);
						}
					}
					// 모자 상자
					else if(StrEqual(strOption, "hat box", false))
					{
						int resultItem = DDS_GetRandomItem(14, 2, 2, false);
						if(resultItem > 0)
						{
							// 1 = Item Name
							char strResultItemName[64];
							DDS_GetItemInfo(resultItem, 1, strResultItemName);
							
							PrintToChat(client, "%s\x01%s에서 \x04%s \x01아이템이 나왔습니다.", PREFIX, strItemName, strResultItemName);
							DDS_SimpleGiveItem(client, resultItem, 1);
								
							PrintToChatAll("%s\x03%N\x01님이 \x01%s에서 \x04%s \x01아이템을 꺼냈습니다.", PREFIX, client, strItemName, strResultItemName);
						}
						else
						{
							PrintToChat(client, "%s\x01아이템 항목이 부족하여 상자를 열 수 없습니다.", PREFIX);
							return Plugin_Handled;
						}
					}
					// 할로윈 상자
					else if(StrEqual(strOption, "halloween box", false))
					{
						float setmin = 0.0, setmax = 10000.0;
						float ranfloat, ranper;
						
						ranfloat = MathGetRandomFloat(setmin, setmax);
						ranper = (ranfloat / setmax) * 100.0;
						
						if (ranper <= 0.3) // 확률이 1% 일 때
						{
							int resultItem = g_iItemIndices[GiftBox];
							if(resultItem > 0)
							{
								// 1 = Item Name
								char strResultItemName[64];
								DDS_GetItemInfo(resultItem, 1, strResultItemName);
								
								PrintToChat(client, "%s\x10%s\x01에서 \x04%s \x01아이템이 나왔습니다.", PREFIX, strItemName, strResultItemName);
								DDS_SimpleGiveItem(client, resultItem, 1);
								
								PrintToChatAll("%s\x03%N\x01님이 \x10%s\x01에서 \x04%s \x01아이템을 꺼냈습니다.", PREFIX, client, strItemName, strResultItemName);
							}
							else
							{
								PrintToChat(client, "%s\x01아이템 항목이 부족하여 아무것도 받지 못했습니다.", PREFIX);
							}
						}
						else if (ranper <= 2.3)
						{
							int resultItem = DDS_GetRandomItem(14, 0, 0, false);
							if(resultItem > 0)
							{
								// 1 = Item Name
								char strResultItemName[64];
								DDS_GetItemInfo(resultItem, 1, strResultItemName);
								
								PrintToChat(client, "%s\x10%s\x01에서 \x04%s \x01아이템이 나왔습니다.", PREFIX, strItemName, strResultItemName);
								DDS_SimpleGiveItem(client, resultItem, 1);
								
								PrintToChatAll("%s\x03%N\x01님이 \x10%s\x01에서 \x04%s \x01아이템을 꺼냈습니다.", PREFIX, client, strItemName, strResultItemName);
							}
							else
							{
								PrintToChat(client, "%s\x01아이템 항목이 부족하여 아무것도 받지 못했습니다.", PREFIX);
							}
						}
						else if (ranper <= 52.3)
						{
							int resultItem = g_iItemIndices[SupplyCrate];
							if(resultItem > 0)
							{
								// 1 = Item Name
								char strResultItemName[64];
								DDS_GetItemInfo(resultItem, 1, strResultItemName);
								
								PrintToChat(client, "%s\x10%s\x01에서 \x04%s \x01아이템이 나왔습니다.", PREFIX, strItemName, strResultItemName);
								DDS_SimpleGiveItem(client, resultItem, 1);
							}
							else
							{
								PrintToChat(client, "%s\x01아이템 항목이 부족하여 아무것도 받지 못했습니다.", PREFIX);
							}
						}
						else
						{
							PrintToChat(client, "%s\x01%s에서 아무것도 나오지 않았습니다.", PREFIX, strItemName);
						}
					}
				}
			}
			else if (itemcode == EXPENDABLE_ID)
			{
				if(IsValidPlayer(client) && !IsClientZombie(client) && !IsWarmupPeriod())
				{
					// 10 = Item Option
					char strOption[32];
					DDS_GetItemInfo(itemid, 10, strOption);
					//TODO: CODE HERE TO ACTIVATE ITEM
					
					// 응급치료킷
					if(StrEqual(strOption, "medikit", false))
					{
						int iHealAmount = 30;
						int iMaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
						int iCurrentHealth = GetClientHealth(client);
						// 현재 체력이 이미 최대체력과 같거나 더 많을때,
						// 또한 감염에 걸리지 않은 경우.
						if(iMaxHealth<=iCurrentHealth && g_nPenetrationCount[client] <= 0)
						{
							PrintToChat(client, "%s\x01이미 충분히 건강합니다.", PREFIX);
							return Plugin_Stop;
						}
						
						CureHuman(client);
						if(iCurrentHealth + iHealAmount > iMaxHealth)
						{
							SetEntityHealth(client, iMaxHealth);
						}
						else
						{
							SetEntityHealth(client, iCurrentHealth + iHealAmount);
						}
						
						EmitSoundToAllAny(HealingSound, client, SNDCHAN_SKILL_SOUND, _, _, _, _, _, _, _, true);
						
						return Plugin_Continue;
					}
					
					// 사탕
					if(StrEqual(strOption, "candy", false))
					{
						// 또한 감염에 걸리지 않은 경우.
						if(g_nPenetrationCount[client] <= 0)
						{
							PrintToChat(client, "%s\x01이미 충분히 건강합니다.", PREFIX);
							return Plugin_Stop;
						}
						
						CureHuman(client);
						
						return Plugin_Continue;
					}
					
					// 쿠키
					if(StrEqual(strOption, "cookie", false))
					{
						int iHealAmount = 80;
						int iMaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
						int iCurrentHealth = GetClientHealth(client);
						// 현재 체력이 이미 최대체력과 같거나 더 많을때,
						if(iMaxHealth<=iCurrentHealth)
						{
							PrintToChat(client, "%s\x01이미 충분히 건강합니다.", PREFIX);
							return Plugin_Stop;
						}
						
						if(iCurrentHealth + iHealAmount > iMaxHealth)
						{
							SetEntityHealth(client, iMaxHealth);
						}
						else
						{
							SetEntityHealth(client, iCurrentHealth + iHealAmount);
						}
						
						return Plugin_Continue;
					}
					
					// 여분탄창
					if(StrEqual(strOption, "reserve ammo", false))
					{
						int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
						if(weapon != -1)
						{
							char szWeaponClassname[32];
							GetEdictClassname(weapon, szWeaponClassname, sizeof(szWeaponClassname));
							switch (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
							{
								case 60: strcopy(szWeaponClassname, sizeof(szWeaponClassname), "weapon_m4a1_silencer");
								case 61: strcopy(szWeaponClassname, sizeof(szWeaponClassname), "weapon_usp_silencer");
								case 63: strcopy(szWeaponClassname, sizeof(szWeaponClassname), "weapon_cz75a");
							}
							int weaponClipSize = CacheClipSize(szWeaponClassname[7]);
							
							SetWeaponReserveAmmo(client, weapon, GetWeaponReserveAmmo(client, weapon)+weaponClipSize);
							
							return Plugin_Continue;
						}
						else
						{
							PrintToChat(client, "%s\x01보유중인 주무기가 없습니다!", PREFIX);
							return Plugin_Stop;
						}
					}
					// 소이탄창
					if(StrEqual(strOption, "incendiary ammo", false))
					{
						int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
						if(weapon != -1)
						{
							char szWeaponClassname[32];
							GetEdictClassname(weapon, szWeaponClassname, sizeof(szWeaponClassname));
							switch (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
							{
								case 60: strcopy(szWeaponClassname, sizeof(szWeaponClassname), "weapon_m4a1_silencer");
								case 61: strcopy(szWeaponClassname, sizeof(szWeaponClassname), "weapon_usp_silencer");
								case 63: strcopy(szWeaponClassname, sizeof(szWeaponClassname), "weapon_cz75a");
							}
							int weaponClipSize = CacheClipSize(szWeaponClassname[7]);
							
							g_nIncendiaryAmmo[client] += weaponClipSize;
							
							return Plugin_Continue;
						}
						else
						{
							PrintToChat(client, "%s\x01보유중인 주무기가 없습니다!", PREFIX);
							return Plugin_Stop;
						}
					}
					// 폭발탄창
					if(StrEqual(strOption, "explosive ammo", false))
					{
						int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
						if(weapon != -1)
						{
							char szWeaponClassname[32];
							GetEdictClassname(weapon, szWeaponClassname, sizeof(szWeaponClassname));
							switch (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
							{
								case 60: strcopy(szWeaponClassname, sizeof(szWeaponClassname), "weapon_m4a1_silencer");
								case 61: strcopy(szWeaponClassname, sizeof(szWeaponClassname), "weapon_usp_silencer");
								case 63: strcopy(szWeaponClassname, sizeof(szWeaponClassname), "weapon_cz75a");
							}
							int weaponClipSize = CacheClipSize(szWeaponClassname[7]);
							
							g_nExplosiveAmmo[client] += weaponClipSize;
							return Plugin_Continue;
						}
						else
						{
							PrintToChat(client, "%s\x01보유중인 주무기가 없습니다!", PREFIX);
							return Plugin_Stop;
						}
						
					}
					// 철갑탄창
					if(StrEqual(strOption, "AP ammo", false))
					{
						int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
						if(weapon != -1)
						{
							char szWeaponClassname[32];
							GetEdictClassname(weapon, szWeaponClassname, sizeof(szWeaponClassname));
							switch (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
							{
								case 60: strcopy(szWeaponClassname, sizeof(szWeaponClassname), "weapon_m4a1_silencer");
								case 61: strcopy(szWeaponClassname, sizeof(szWeaponClassname), "weapon_usp_silencer");
								case 63: strcopy(szWeaponClassname, sizeof(szWeaponClassname), "weapon_cz75a");
							}
							int weaponClipSize = CacheClipSize(szWeaponClassname[7]);
							
							g_nArmorPiercingAmmo[client] += weaponClipSize;
							return Plugin_Continue;
						}
						else
						{
							PrintToChat(client, "%s\x01보유중인 주무기가 없습니다!", PREFIX);
							return Plugin_Stop;
						}
					}
					// 나로호
					if(StrEqual(strOption, "rocket", false))
					{
						RemoveGuns(client);
						SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
						
						int SkinIndex = client;
						if(CPS_HasSkin(client))
						{
							SkinIndex = CPS_GetSkin(client);
						}
						SetEntityRenderColor(SkinIndex, 255, 0, 0, 255);
						SetEntityRenderMode(SkinIndex, RENDER_TRANSCOLOR);
						
						EmitSoundToAllAny(ITEM_SOUND_NAROHO, client, 200/*채널*/, 150, _, 1.0);
						CreateTimer(3.0, Launch, client, TIMER_FLAG_NO_MAPCHANGE);
						CreateTimer(16.2, Detonate, client, TIMER_FLAG_NO_MAPCHANGE);
						CureHuman(client);
					}
					// 센트리건
					if(StrEqual(strOption, "sentry gun", false))
					{
						SpawnSentryGun(client);
					}
				}
				else
				{
					PrintToChat(client, "%s\x01사용할 수 없는 상태입니다", PREFIX);
					return Plugin_Stop;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

//보급상자 소환
void DropSupplyBoxFrom(client)
{
	float vecClientOrigin[3];
	GetClientAbsOrigin(client, vecClientOrigin);

	int Ent = CreateEntityByName("prop_physics_override");			
	DispatchKeyValue(Ent, "model", MODEL_SUPPLY_CRATE);
	DispatchKeyValue(Ent, "targetname", "Supply Crate"); 
	DispatchKeyValueFloat(Ent, "physdamagescale", 0.0);
	DispatchSpawn(Ent);
	
	vecClientOrigin[2] += 5;
	TeleportEntity(Ent, vecClientOrigin, NULL_VECTOR, NULL_VECTOR);
	SetEntProp(Ent, Prop_Data, "m_takedamage", 1, 1);
	SetEntData(Ent, g_offsCollision, 2, 4, true);
}

//보급상자 습득
void AcquireSupplyBox(client)
{
	int Ent = GetClientAimTarget(client, false);
    
	if(IsValidEntity(Ent))
	{
		char szModelname[128];
		GetEntPropString(Ent, Prop_Data, "m_ModelName", szModelname, 128);
    
		if(StrEqual(szModelname, MODEL_SUPPLY_CRATE, false))
		{
			char szEntityTargetName[64];
			GetEntPropString(Ent, Prop_Data, "m_iName", szEntityTargetName, sizeof(szEntityTargetName));
			if(StrEqual(szEntityTargetName, "Supply Crate"))
			{
				float vecClientOrigin[3], vecEntityOrigin[3];
				GetClientEyePosition(client, vecClientOrigin);
				GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", vecEntityOrigin);
				float Dist = GetVectorDistance(vecEntityOrigin, vecClientOrigin);
				
				if(GetClientTeam(client) == 3)
				{
					if(Dist >= 100 && Dist <= 500)
					{
						PrintToChat(client, "%s\x01상자를 줍기에 너무 멉니다!", PREFIX);
					}
					else
					{
						if(IsValidEntity(Ent) == true)
						{
							RemoveEdict(Ent);
							DDS_SimpleGiveItem(client, 9, 1);
							PrintToChat(client, "%s\x03보급상자\x01를 습득하셨습니다.", PREFIX);
						}
					}
				}
			}
		}
	}
}

public int DDS_ShouldDrawHatForcibly(int client)
{
	return (g_bThirdPerson[client] && g_flForceFirstPersonTime[client] <= 0.0)?1:0;
}

#include "BSTZombie/items/rocket.sp"
#include "BSTZombie/items/sentrygun.sp"

/**
 * Returns a random, uniform Float number in the specified (inclusive) range.
 * This is safe to use multiple times in a function.
 * The seed is set automatically for each plugin.
 * 
 * @param min			Min value used as lower border
 * @param max			Max value used as upper border
 * @return				Random Float number between min and max
 */
stock Float:MathGetRandomFloat(Float:min, Float:max)
{
	return (GetURandomFloat() * (max  - min)) + min;
}

/**
 * Gets the percentage of amount in all as Integer where
 * amount and all are numbers and amount usually
 * is a subset of all.
 * 
 * @param value			Integer value
 * @param all			Integer value
 * @return				An Integer value between 0 and 100 (inclusive).
 */
stock MathGetPercentage(value, all) {
	return RoundToNearest((float(value) / float(all)) * 100.0);
}

/**
 * Gets the percentage of amount in all as Float where
 * amount and all are numbers and amount usually
 * is a subset of all.
 * 
 * @param value			Float value
 * @param all			Float value
 * @return				A Float value between 0.0 and 100.0 (inclusive).
 */
stock Float:MathGetPercentageFloat(Float:value, Float:all) {
	return (value / all) * 100.0;
}