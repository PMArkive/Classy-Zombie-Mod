/********************************클래스 선택**********************************/

void ClassMenu(client, bool soldierExpand=false, bool chatCommand=false)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] ClassMenu(%i)", client);
	#endif
	
	SetRadarAndMoneyVisiblity(client, true);
	Menu menu = new Menu(ClassMenuHandler);
	
	menu.SetTitle("--=   인간 병과 선택   =- \n=========================");
	char displayString[128];
	char szLevelString[8];
	if(!soldierExpand)
	{
		menu.AddItem("Soldier", "보병(Soldier) (세부 클래스 3개)", (g_iClassLevel[client][0] >= 0 || g_iClassLevel[client][1] >= 0 || g_iClassLevel[client][2] >= 0)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		
		IntToString(g_iClassLevel[client][3], szLevelString, sizeof(szLevelString));
		FormatEx(displayString, sizeof(displayString), "저격병(Sniper) (나무 판자 설치) - Lv. %s", g_iClassLevel[client][3] >= 0?szLevelString:"없음");
		menu.AddItem("Sniper", displayString, (g_iClassLevel[client][3] >= 0)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		
		IntToString(g_iClassLevel[client][4], szLevelString, sizeof(szLevelString));
		FormatEx(displayString, sizeof(displayString), "지원병(Supporter) (탄약 보급) - Lv. %s", g_iClassLevel[client][4] >= 0?szLevelString:"없음");
		menu.AddItem("Supporter", displayString, (g_iClassLevel[client][4] >= 0)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		
		IntToString(g_iClassLevel[client][5], szLevelString, sizeof(szLevelString));
		FormatEx(displayString, sizeof(displayString), "의무병(Medic) (체력, 감염 치료) - Lv. %s\n=========================", g_iClassLevel[client][5] >= 0?szLevelString:"없음");
		menu.AddItem("Medic", displayString, (g_iClassLevel[client][5] >= 0)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
					
		menu.ExitBackButton = false;
	}
	else
	{
		IntToString(g_iClassLevel[client][0], szLevelString, sizeof(szLevelString));
		FormatEx(displayString, sizeof(displayString), "기동성(Speed)(이동속도) - Lv. %s", g_iClassLevel[client][0] >= 0?szLevelString:"없음");
		menu.AddItem("Soldier-Speed", displayString, (g_iClassLevel[client][0] >= 0)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		
		IntToString(g_iClassLevel[client][1], szLevelString, sizeof(szLevelString));
		FormatEx(displayString, sizeof(displayString), "정확성(Critical)(치명타) - Lv. %s", g_iClassLevel[client][1] >= 0?szLevelString:"없음");
		menu.AddItem("Soldier-Critical", displayString, (g_iClassLevel[client][1] >= 0)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		
		IntToString(g_iClassLevel[client][2], szLevelString, sizeof(szLevelString));
		FormatEx(displayString, sizeof(displayString), "화력성(Health)(체력) - Lv. %s\n=========================", g_iClassLevel[client][2] >= 0?szLevelString:"없음");
		menu.AddItem("Soldier-Health", displayString, (g_iClassLevel[client][2] >= 0)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
		
		menu.ExitBackButton = true;
	}

	menu.ExitButton = chatCommand;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int ClassMenuHandler(Menu menu, MenuAction action, int client, int item)
{	
	if(action == MenuAction_Select)
	{		
		if(IsValidClient(client))
		{
			char info[32];
			menu.GetItem(item, info, sizeof(info));
			
			int iTempClassId = 0;
			
			if(StrEqual(info, "Soldier", false))
			{
				ClassMenu(client, true);
			}
			else if(StrEqual(info, "Soldier-Speed", false))
			{
				iTempClassId = 1;
			}
			else if(StrEqual(info, "Soldier-Critical", false))
			{
				iTempClassId = 2;
			}
			else if(StrEqual(info, "Soldier-Health", false))
			{
				iTempClassId = 3;
			}
			else if(StrEqual(info, "Sniper", false))
			{
				iTempClassId = 4;
			}
			else if(StrEqual(info, "Supporter", false))
			{
				iTempClassId = 5;
			}
			else if(StrEqual(info, "Medic", false))
			{			
				iTempClassId = 6;
			}
			
			if(iTempClassId > 0)
			{
				SetRadarAndMoneyVisiblity(client, false);
				
				if(GetClientTeam(client) == CS_TEAM_SPECTATOR)
				{
					if(g_iPendingTeamNumber[client] >= 2)
					{
						ChangeClientTeam(client, g_iPendingTeamNumber[client]);
						g_iPendingTeamNumber[client] = 0;
					}
				}
				PrintToChat(client, "%s\x01\x03%s\x01을 선택하셨습니다.", PREFIX, g_szConstClassName[iTempClassId]);
				PrintToChat(client, "%s\x01\x04!병과, !클래스, !class\x01를 입력하면 다른 병과를 선택할 수 있습니다.", PREFIX);
				
				if(IsPlayerAlive(client) && g_bGameStarted)
				{
					g_iPendingClassId[client] = iTempClassId;
					PrintToChat(client, "%s\x01게임이 진행중이므로 선택하신 병과는 \x04다음 라운드\x01에 적용됩니다.", PREFIX);
				}
				else if(IsPlayerAlive(client) && !g_bGameStarted)
				{
					// 무기를 구매하지 않은 경우.
					// 지금 당장 바꿔준다.
					if(!g_bWeaponCheck[client])
					{
						g_iClassId[client] = iTempClassId;
						CS_RespawnPlayer(client);
					}
					// 이미 무기를 구매한 경우.
					else
					{
						g_iPendingClassId[client] = iTempClassId;
						PrintToChat(client, "%s\x01이미 현재 병과의 무기를 구매하셨으므로 선택하신 병과는 \x04다음 라운드\x01에 적용됩니다.", PREFIX);
					}
				}
				// 이 부분까지 온다면 죽어있는 경우이다.
				// 지금 당장 바꿔준다.
				else
				{
					g_iClassId[client] = iTempClassId;
				}
			}
		}
	}
	if(action == MenuAction_Cancel)
	{
		if(item == MenuCancel_ExitBack)
		{
			ClassMenu(client);
		}
		else if(item != MenuCancel_Disconnected)
		{
			PrintToChat(client, "%s\x01\x03!병과, !클래스, !class\x01를 입력해 메뉴를 다시 열 수 있습니다.", PREFIX);
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}
/********************************초회 접속 기본 병과 지급********************************/
void FirstClassSelectionMenu(client, bool soldierExpand=false, int SelectedClass=0)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] FirstClassSelectionMenu(%i)", client);
	#endif
	
	SetRadarAndMoneyVisiblity(client, true);
	
	Menu menu = new Menu(FirstClassSelectionMenuHandler);
	
	if(SelectedClass <= 0)
	{
		menu.SetTitle("--=   기본 지급 병과 선택   =- \n=========================");
		if(!soldierExpand)
		{
			menu.AddItem("Soldier", "보병(Soldier) (세부 클래스 3개)");
			menu.AddItem("Sniper", "저격병(Sniper) (나무 판자 설치)");
			menu.AddItem("Supporter", "지원병(Supporter) (탄약 보급)");
			menu.AddItem("Medic", "의무병(Medic) (체력, 감염 치료) \n=========================");
						
			menu.ExitBackButton = false;
		}
		else
		{
			menu.AddItem("Soldier-Speed", "기동성(Speed)(이동속도)");
			menu.AddItem("Soldier-Critical", "정확성(Critical)(치명타)");
			menu.AddItem("Soldier-Health", "화력성(Health)(체력) \n=========================");
			menu.ExitBackButton = true;
		}
	}
	else
	{
		
		menu.SetTitle("-- 한 번 정한 초기 병과는 철회할 수 없습니다 --\n--=   정말 %s으로 선택하시겠습니까?   =-- \n=========================", g_szConstClassName[SelectedClass]);
		
		char infoString[32];
		Format(infoString, sizeof(infoString), "Yes|%i", SelectedClass);
		menu.AddItem(infoString, "예, 후회는 없습니다.");
		
		if(soldierExpand)
		{
			menu.AddItem("No|s", "아니오, 다시 생각하겠습니다.\n=========================");
		}
		else
		{
			menu.AddItem("No|n", "아니오, 다시 생각하겠습니다.\n=========================");
		}
		
		menu.ExitBackButton = false;
	}
	
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int FirstClassSelectionMenuHandler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{		
		if(IsValidClient(client))
		{
			char info[32];
			menu.GetItem(item, info, sizeof(info));
			g_iClassId[client] = 0;
			int iClassId = 0;
			
			if(StrContains(info, "Yes", false) != -1)
			{
				char buffer[8][2];
				ExplodeString(info, "|", buffer, sizeof(buffer[]), sizeof(buffer));
				iClassId = StringToInt(buffer[1]);
				g_iClassId[client] = iClassId;
				g_iClassLevel[client][iClassId - 1] = 0;
			}
			
			if(StrEqual(info, "No|s", false)) // soldier
			{
				FirstClassSelectionMenu(client, true, 0);
			}
			else if(StrEqual(info, "No|n", false)) // normal
			{
				FirstClassSelectionMenu(client, false, 0);
			}
			else if(StrEqual(info, "Soldier", false))
			{
				FirstClassSelectionMenu(client, true);
			}
			else if(StrEqual(info, "Soldier-Speed", false))
			{
				FirstClassSelectionMenu(client, false, 1);
			}
			else if(StrEqual(info, "Soldier-Critical", false))
			{
				FirstClassSelectionMenu(client, false, 2);
			}
			else if(StrEqual(info, "Soldier-Health", false))
			{
				FirstClassSelectionMenu(client, false, 3);
			}
			else if(StrEqual(info, "Sniper", false))
			{
				FirstClassSelectionMenu(client, false, 4);
			}
			else if(StrEqual(info, "Supporter", false))
			{
				FirstClassSelectionMenu(client, false, 5);
			}
			else if(StrEqual(info, "Medic", false))
			{
				FirstClassSelectionMenu(client, false, 6);
			}
			
			if(iClassId > 0)
			{
				SetRadarAndMoneyVisiblity(client, false);
				
				if(GetClientTeam(client) == CS_TEAM_SPECTATOR)
				{
					if(g_iPendingTeamNumber[client] >= 2)
					{
						ChangeClientTeam(client, g_iPendingTeamNumber[client]);
						g_iPendingTeamNumber[client] = 0;
					}
				}
				PrintToChat(client, "%s\x04%s\x01이 초기 병과로 지급되었습니다.", PREFIX, g_szConstClassName[iClassId]);
				
				char strItemName[64];
				DDS_GetItemInfo(g_iItemIndices[Voucher], 1, strItemName);
				DDS_SimpleGiveItem(client, g_iItemIndices[Voucher], 10);
				PrintToChat(client, "%s\x01시작 자본으로\x04%s\x01가 10개 지급되었습니다.", PREFIX, strItemName);
				DDS_GetItemInfo(g_iItemIndices[SupplyCrate], 1, strItemName);
				DDS_SimpleGiveItem(client, g_iItemIndices[SupplyCrate], 10);
				PrintToChat(client, "%s\x01시작 자본으로\x04%s\x01가 10개 지급되었습니다.", PREFIX, strItemName);
				DDS_GetItemInfo(g_iItemIndices[Parachute], 1, strItemName);
				DDS_SimpleGiveItem(client, g_iItemIndices[Parachute], 10);
				PrintToChat(client, "%s\x01시작 자본으로\x04%s\x01가 10개 지급되었습니다.", PREFIX, strItemName);
			}
		}
		
		SaveClientData(client);
	}
	if(action == MenuAction_Cancel)
	{
		if(item == MenuCancel_ExitBack)
		{
			FirstClassSelectionMenu(client);
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}

/********************************무기 상점********************************/
//무기 상점
public void Command_WeaponShop(int client)
{
	if (g_bWeaponCheck[client]) return;
	Handle weaponmenu = CreateMenu(Menu_WeaponShop);

	SetMenuTitle(weaponmenu, "--= 무기 목록  =-");

	for(int i = 0; i < WEAPON_COUNT; i++)
	{
		if(g_iWeaponClass[i] == g_iClassId[client])
		{
			char ShopItem[32], WeaponNum[32];
			Format(ShopItem, 32, "%s - $ %d", g_strWeaponName[i], g_iWeaponPrice[i]);
			Format(WeaponNum, 32, "%d", i);
			AddMenuItem(weaponmenu, WeaponNum, ShopItem);
		}
	}
	AddMenuItem(weaponmenu, "", "", ITEMDRAW_SPACER);
	
	int iCouponCount = DDS_GetClientItemCount(client, g_iItemIndices[SupplyMoney]);
	AddMenuItem(weaponmenu, "-1", "지원금 $3000 사용하기", iCouponCount >= 1?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);

	DisplayMenu(weaponmenu, client, MENU_TIME_FOREVER);
	
	SendConVarValue(client, FindConVar("mp_playercashawards"), "1");
	SendConVarValue(client, FindConVar("mp_teamcashawards"), "1");
	RequestFrame(ShowMoneyHud, client);
}

public void ShowMoneyHud(int client)
{
	SendConVarValue(client, FindConVar("mp_playercashawards"), "1");
	SendConVarValue(client, FindConVar("mp_teamcashawards"), "1");
}

public int Menu_WeaponShop(Handle menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select && IsValidPlayer(client))
	{
		if(IsClientZombie(client))
			return;
			
		if(g_iClassId[client] == 7)
			return;
		
 		char info[32], strWeaponClassname[32];
 		int Numb;
		GetMenuItem(menu, select, info, sizeof(info));
		StringToIntEx(info, Numb);
		
		if(Numb != -1)
		{
			Format(strWeaponClassname, 32, "weapon_%s", g_strWeaponName[Numb]);
			int Player_Money = GetEntProp(client, Prop_Send, "m_iAccount");

			if(Player_Money >= g_iWeaponPrice[Numb] && !StrEqual("weapon_", strWeaponClassname, false))
			{
				int weapon = GivePlayerItem(client, strWeaponClassname);
				SetEntProp(client, Prop_Send, "m_iAccount", GetEntProp(client, Prop_Send, "m_iAccount") - g_iWeaponPrice[Numb]);
				PrintToChat(client, "\x04[SM] - \x03%s \x01무기를 구입하셨습니다.", g_strWeaponName[Numb]);
				
				int iReserveAmmoToGive = 0;
				if(g_iClassId[client] == 3)
				{
					iReserveAmmoToGive = g_iWeaponReserveAmmo[Numb] + (g_iWeaponClipSize[Numb] * g_iClassLevel[client][2]);
					SetWeaponReserveAmmo(client, weapon, iReserveAmmoToGive);
				}
				else if(g_iClassId[client] == 6)
				{
					iReserveAmmoToGive = g_iWeaponReserveAmmo[Numb] + (g_iWeaponClipSize[Numb] * g_iClassLevel[client][5]);
					SetWeaponReserveAmmo(client, weapon, iReserveAmmoToGive);
				}
				else
				{
					SetWeaponReserveAmmo(client, weapon, g_iWeaponReserveAmmo[Numb]);
				}
				
				g_bWeaponCheck[client] = true;
				
				// 게임이 시작되지 않았다면
				if(!g_bGameStarted)
				{
					// 손 모델 리셋
					CleanClientArms(client);
				}
				
				// TODO: 이후에 도움말 메뉴를 추가할 것.
				if(g_iClassId[client] == 4)
				{
//					Helppanel6(client);
				}
				else if(g_iClassId[client] == 5)
				{
//					Helppanel(client);
				}
				else if(g_iClassId[client] == 6)
				{
//					Helppanel2(client);
				}
			}
			else
			{
				PrintToChat(client, "\x04[SM] - \x01\x03$ %d \x01가 부족합니다.", g_iWeaponPrice[Numb] - Player_Money);
				Command_WeaponShop(client);
			}
		}
		else
		{
			int iCouponCount = DDS_GetClientItemCount(client, g_iItemIndices[SupplyMoney]);
			if(iCouponCount >= 1)
			{
				SetEntProp(client, Prop_Send, "m_iAccount", GetEntProp(client, Prop_Send, "m_iAccount") + 3000);
				SetEntProp(client, Prop_Send, "m_iStartAccount", GetEntProp(client, Prop_Send, "m_iStartAccount") + 3000);
				PrintToChat(client, "%s\x01지원금 $3000를 받으셨습니다!", PREFIX);
				DDS_SimpleRemoveItem(client, g_iItemIndices[SupplyMoney], 1);
			}
			else
			{
				PrintToChat(client, "%s\x01지원금 $3000를 가지고 계시지 않습니다.", PREFIX);
			}
			
			Command_WeaponShop(client);
		}
	}
	if(action == MenuAction_Cancel)
	{
		if(select != MenuCancel_Disconnected)
		{
			if(g_iClassId[client] != 7)
			{
				PrintToChat(client, "%s\x01\x03!무기, !weapon\x01을 입력해 메뉴를 다시 열 수 있습니다.", PREFIX);
			}
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}

/********************************클래스 레벨 메뉴**********************************/
void Command_ClassLevel(client)
{
	Menu menu = new Menu(Menu_ClassLevel);
	
	int iVoucherCount = DDS_GetClientItemCount(client, g_iItemIndices[Voucher]);
	menu.SetTitle("- 클래스 레벨 관리 메뉴 -\n보유중인 증표: %d개", iVoucherCount);
	
	char szInfoString[9], szDisplayString[128];
	char szLevelString[32];

	for (int i = 0; i <= 5; i++)
	{
		if(g_iClassLevel[client][i] >= 0)
		{
			FormatEx(szLevelString, sizeof(szLevelString), "Lv. %i", g_iClassLevel[client][i]);
		}
		else
		{
			FormatEx(szLevelString, sizeof(szLevelString), "없음");
		}
		
		Format(szDisplayString, sizeof(szDisplayString), "%s : %s", g_szConstClassName[i+1], szLevelString);
		
		if(g_iClassLevel[client][i] < CLASS_MAX_LEVEL)
		{
			Format(szDisplayString, sizeof(szDisplayString), "%s -> Lv. %i", szDisplayString, g_iClassLevel[client][i]+1);
		}
		else if(g_iClassLevel[client][i] == CLASS_MAX_LEVEL)
		{
			Format(szDisplayString, sizeof(szDisplayString), "%s (최대 레벨)", szDisplayString);
		}
		
		IntToString(i, szInfoString, sizeof(szInfoString));
		menu.AddItem(szInfoString, szDisplayString, g_iClassLevel[client][i] < CLASS_MAX_LEVEL?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public Menu_ClassLevel(Handle menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
 		char info[256];
 		int class;
		GetMenuItem(menu, select, info, sizeof(info));
		StringToIntEx(info, class);
		
		Command_ClassLevelConfirm(client, class);
	}
	else if(action == MenuAction_Cancel)
	{
		/*
		if(select == MenuCancel_ExitBack)
		{
			Command_ShopMainItem(client, 0);
		}*/
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}

void Command_ClassLevelConfirm(int client, int class)
{
	Menu menu = new Menu(Menu_ClassLevelConfirm);
	
	char szTitleString[280], szInfoString[16];
	char szLevelString[32], szImprovementString[128];
	
	int iVoucherRequired = 20; // (병과를 소지중일 때) 레벨업을 하기 위해 가장 기초로 필요한 증표 갯수
	int iVoucherCount = DDS_GetClientItemCount(client, g_iItemIndices[Voucher]);
	
	if(g_iClassLevel[client][class] == -1)
	{
		iVoucherRequired /= 2; // 기초 증표 갯수의 1/2
	}
	else
	{
		// 최대 레벨이 아닐 때
		if(g_iClassLevel[client][class] < CLASS_MAX_LEVEL)
		{
			for (int i = 1; i <= g_iClassLevel[client][class]; i++)
			{
				iVoucherRequired += g_iClassLevel[client][class] * 10;
			}
		}
	}
	
	if(class == 0)
	{
		Format(szImprovementString, sizeof(szImprovementString), "스피드 + 2%%%%");		
	}
	else if(class == 1)
	{
		Format(szImprovementString, sizeof(szImprovementString), "크리티컬 데미지 + 5%%%%, 확률 + 10%%%%, 주무기 반동 - 20%%%%");
	}
	else if(class == 2)
	{
		Format(szImprovementString, sizeof(szImprovementString), "체력 + 20, 예비탄창 + 1, 샷건류 넉백 + 10%%%%");
	}
	else if(class == 3)
	{
		Format(szImprovementString, sizeof(szImprovementString), "넉백 + 50%%%%, 판자 체력 + 25\n=> (레벨 4 마다 판자 설치 + 1)");
	}
	else if(class == 4)
	{
		Format(szImprovementString, sizeof(szImprovementString), "탄약통 탄약 + 60");
	}
	else if(class == 5)
	{
		Format(szImprovementString, sizeof(szImprovementString), "체력 + 20, 치료량 + 2, 예비탄창 + 1");
	}
	
	if(g_iClassLevel[client][class] >= 0)
	{
		FormatEx(szLevelString, sizeof(szLevelString), "Lv. %i", g_iClassLevel[client][class]);
	}
	else
	{
		FormatEx(szLevelString, sizeof(szLevelString), "없음");
	}
	
	Format(szTitleString, sizeof(szTitleString), "- 클래스 레벨 관리 메뉴 -\n\n");
	Format(szTitleString, sizeof(szTitleString), "%s클래스: %s\n", szTitleString, g_szConstClassName[class+1]);
	Format(szTitleString, sizeof(szTitleString), "%s레벨: %s -> Lv. %i \n",  szTitleString, szLevelString, g_iClassLevel[client][class]+1);
	Format(szTitleString, sizeof(szTitleString), "%s향상: %s\n",  szTitleString, szImprovementString);
	Format(szTitleString, sizeof(szTitleString), "%s보유중인 증표: %d개\n", szTitleString, iVoucherCount);
	Format(szTitleString, sizeof(szTitleString), "%s필요한 증표: %d개\n\n", szTitleString, iVoucherRequired);
	
	if(iVoucherCount >= iVoucherRequired)
	{
		Format(szTitleString, sizeof(szTitleString), "%s레벨을 올리시겠습니까?", szTitleString);
	}
	else
	{
		Format(szTitleString, sizeof(szTitleString), "%s증표가 부족합니다.", szTitleString);
	}
	menu.SetTitle(szTitleString);
	
	if(iVoucherCount >= iVoucherRequired)
	{
		Format(szInfoString, sizeof(szInfoString), "Yes|%i", class);
		menu.AddItem(szInfoString, "예");
		menu.AddItem("No, Back", "아니오");
	}
	else
	{
		menu.AddItem("Back", "뒤로");
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public Menu_ClassLevelConfirm(Handle menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
 		char info[32];
 		char buffer[16][2];
 		int class = 0;
		GetMenuItem(menu, select, info, sizeof(info));
		ExplodeString(info, "|", buffer, sizeof(buffer[]), sizeof(buffer));
		
		if(StrEqual(buffer[0], "Yes", false))
		{
			class = StringToInt(buffer[1]);
			
			int iVoucherRequired = 20; // (병과를 소지중일 때) 레벨업을 하기 위해 가장 기초로 필요한 증표 갯수
			int iVoucherCount = DDS_GetClientItemCount(client, g_iItemIndices[Voucher]);
			
			if(g_iClassLevel[client][class] == -1)
			{
				iVoucherRequired /= 2; // 기초 증표 갯수의 1/2
				
				if(iVoucherCount >= iVoucherRequired)
				{
					g_iClassLevel[client][class] += 1;
					DDS_SimpleRemoveItem(client, g_iItemIndices[Voucher], iVoucherRequired);
					PrintToChat(client, "%s\x03%s \x01병과 획득!!", PREFIX, g_szConstClassName[class + 1]);
					PrintToChatAll("%s\x04%N\x01님이 \x03%s \x01병과를 획득하셨습니다!!", PREFIX, client, g_szConstClassName[class + 1]);
					SaveClientData(client);
				}
				else
				{
					PrintToChat(client, "%s\x03%s\x01 획득을 위해서는 증표 %i개가 필요합니다.", PREFIX, g_szConstClassName[class + 1], iVoucherRequired);
				}				
			}
			else
			{
				// 최대 레벨이 아닐 때
				if(g_iClassLevel[client][class] < CLASS_MAX_LEVEL)
				{
					for (int i = 1; i <= g_iClassLevel[client][class]; i++)
					{
						iVoucherRequired += g_iClassLevel[client][class] * 10;
					}
					if(iVoucherCount >= iVoucherRequired)
					{
						g_iClassLevel[client][class] += 1;
						DDS_SimpleRemoveItem(client, g_iItemIndices[Voucher], iVoucherRequired);
						PrintToChat(client, "%s\x03%s \x01병과의 레벨이 \x03%i\x01로 상승되었습니다!!", PREFIX, g_szConstClassName[class + 1], g_iClassLevel[client][class]);
						PrintToChatAll("%s\x04%N\x01님이 \x03%s \x01병과를 \x03Lv. %i\x01로 레벨업하셨습니다!!", PREFIX, client, g_szConstClassName[class + 1], g_iClassLevel[client][class]);
						SaveClientData(client);
					}
					else
					{
						PrintToChat(client, "%s다음 레벨업을 위해서는 증표 %i개가 필요합니다.", PREFIX, iVoucherRequired);
					}
				}
				else
				{
					PrintToChat(client, "%s이 클래스는 이미 최종 레벨에 도달했습니다.", PREFIX);
				}
			}
		}
		else if(StrEqual(buffer[0], "No", false))
		{
			Command_ClassLevel(client);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(select == MenuCancel_ExitBack)
		{
			Command_ClassLevel(client);
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}

/********************************좀비 메뉴**********************************/

public Command_Zmenu(client)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] Command_Zmenu(%i)", client);
	#endif
	
	if (IsWarmupPeriod() || !g_bGameStarted)	return;
	
	Menu menu = new Menu(Menu_Zmenu);
	
	menu.SetTitle("좀비 메뉴");
	
	char szDisplay[64];
	Format(szDisplay, sizeof(szDisplay), "스폰위치로 귀환 - %i회", g_nZteleCount[client]);
	menu.AddItem("", szDisplay);
	menu.AddItem("", "블럭상태로 전환");
	menu.AddItem("", "노블럭상태로 전환");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public Menu_Zmenu(Handle menu, MenuAction:action, client, select)
{	
	if (IsWarmupPeriod() || !g_bGameStarted)	return;
	
	if(action == MenuAction_Select)
	{
		if(select == 0){
			Command_ZombieTele(client, 1);
		}
			
		if(select == 1){
			Command_ZombieBlock(client);
			
		}
			
		if(select == 2){
			Command_ZombieNoBlock(client);
			
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}

void Command_ZombieBlock(client)
{
	SetEntData(client, g_offsCollision, 5, _, true);
	SetEntityRenderColor(client, 127, 127, 255, 255);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	g_flZombieBlockTime[client] = GetGameTime() + 10.0;
}

void Command_ZombieNoBlock(client)
{
	SetEntData(client, g_offsCollision, 2, _, true);
	SetEntityRenderColor(client, 255, 255, 255, 255);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	g_flZombieBlockTime[client] = 0.0;
}

/********************************개인뮤트 메뉴**********************************/
void Menu_PrivateMute(int client, int page=0)
{
	Menu menu = new Menu(PrivateMuteMenuHandler);
	menu.SetTitle("\"개인 뮤트\"할 대상을 선택해주세요");
	
	menu.AddItem("", "모두 선택");
	menu.AddItem("", "모두 선택 해제");
	char TargetName[128], TargetS[8];
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && i != client && !IsFakeClient(i))
		{
			Format(TargetName, sizeof(TargetName), "%s %N", (GetListenOverride(client, i) == Listen_No)?"[√]":"[  ]", i);
			Format(TargetS, sizeof(TargetS), "%i", i);
			menu.AddItem(TargetS, TargetName, ITEMDRAW_DEFAULT);
		}
	}
	
	menu.ExitButton = true;
	
	menu.DisplayAt(client, page, MENU_TIME_FOREVER);
}

public int PrivateMuteMenuHandler(Menu menu, MenuAction action, int client, int targetselect)
{
	char TargetS[8];
	menu.GetItem(targetselect, TargetS, sizeof(TargetS));
	
	int target = StringToInt(TargetS);
	
	if(action == MenuAction_Select){
		
		if(IsClientConnected(client) && !IsFakeClient(client))
		{
			if(targetselect == 0)
			{
				PrintToChat(client, "%s\x04모든 유저\x01의 보이스 채팅을 차단합니다.", PREFIX);
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsClientConnected(i) && i != client && !IsFakeClient(i))
					{
						g_iListenOverride[client][i] = Listen_No;
						SetListenOverride(client, i, g_iListenOverride[client][i]);
					}
				}
			}
			else if(targetselect == 1)
			{
				PrintToChat(client, "%s\x04모든 유저\x01의 보이스 채팅을 듣습니다.", PREFIX);
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsClientConnected(i) && i != client && !IsFakeClient(i))
					{
						g_iListenOverride[client][i] = Listen_Yes;
						SetListenOverride(client, i, g_iListenOverride[client][i]);
					}
				}
			}
			else
			{
				if(IsClientConnected(target) && !IsFakeClient(target))
				{
					if(GetListenOverride(client, target) == Listen_No)
					{
						PrintToChat(client, "%s\x04%N\x01님의 보이스 채팅을 듣습니다.", PREFIX, target);
						g_iListenOverride[client][target] = Listen_Yes;
					}
					else
					{
						PrintToChat(client, "%s\x04%N\x01님의 보이스 채팅을 차단합니다.", PREFIX, target);
						g_iListenOverride[client][target] = Listen_No;
					}
					
					SetListenOverride(client, target, g_iListenOverride[client][target]);
				}
			}
			
			
		}
		
		// 유저가 선택한 아이템의 페이지를 얻어낸 후 그 페이지로 메뉴 띄우기
		int MenuSelectionPosition = RoundToFloor(float(targetselect / GetMenuPagination(menu))) * GetMenuPagination(menu);
		Menu_PrivateMute(client, MenuSelectionPosition);
		
	}else if(action == MenuAction_End){
			
		CloseHandle(menu);
		
	}
	
}

/********************************역뮤트 메뉴**********************************/

void Menu_PrivateBlockVoiceSend(int client, int page=0)
{
	Menu menu = new Menu(PrivateBlockVoiceSendMenuHandler);
	menu.SetTitle("보이스를 들려주지 \"않을\" 대상을 선택해주세요");
	
	
	bool isClientAdmin = IsClientAdmin(client);
	menu.AddItem("", "모두 선택");
	menu.AddItem("", "모두 선택 해제");
	char TargetName[128], TargetS[8];
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && i != client && !IsFakeClient(i))
		{
			bool isTargetAdmin = IsClientAdmin(i);
			
			// 듣는 사람이 직접 갠뮤를 했을 경우.
			if(g_iListenOverride[i][client] == Listen_No)
				Format(TargetName, sizeof(TargetName), "%s %N", (GetListenOverride(i, client) == Listen_No)?"[■]":"[  ]", i);
			else
				Format(TargetName, sizeof(TargetName), "%s %N", (GetListenOverride(i, client) == Listen_No)?"[√]":"[  ]", i);
				
			Format(TargetS, sizeof(TargetS), "%i", i);
			
			bool bCanSelect = true;
			// 대상이 관리자
			if(isTargetAdmin){
				// 본인도 관리자
				if(isClientAdmin){
					// 역뮤트 가능
					bCanSelect = true;
				}else{
					// 본인이 관리자 아니면 역뮤트 불가능
					bCanSelect = false;
				}
			}else{
				// 대상이 관리자가 아니므로 역뮤트 가능
				bCanSelect = true;
			}
			
			// 듣는 사람이 직접 갠뮤를 했을 경우.
			if(g_iListenOverride[i][client] == Listen_No)
			{
				// 그 사람에 대한 역뮤트 관련을 건드릴 수 없다.
				bCanSelect = false;
			}
			
			if(bCanSelect)
				menu.AddItem(TargetS, TargetName, ITEMDRAW_DEFAULT);
			else
				menu.AddItem(TargetS, TargetName, ITEMDRAW_DISABLED);
		}
	}
	
	menu.ExitButton = true;
	
	menu.DisplayAt(client, page, MENU_TIME_FOREVER);
}

public int PrivateBlockVoiceSendMenuHandler(Menu menu, MenuAction action, int client, int targetselect)
{
	char TargetS[8];
	menu.GetItem(targetselect, TargetS, sizeof(TargetS));
	
	int target = StringToInt(TargetS);
	
	if(action == MenuAction_Select){
		
		if(IsClientConnected(client) && !IsFakeClient(client))
		{
			if(targetselect == 0)
			{
				PrintToChat(client, "%s\x04모두\x01에게 보이스를 들려주지 않습니다.", PREFIX);
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsClientConnected(i) && i != client && !IsFakeClient(i))
					{
						// 대상이 관리자인 경우에
						if(IsClientAdmin(i))
						{
							// 본인도 관리자여야 설정 가능
							if(IsClientAdmin(client))
							{
								PrintToChat(i, "%s\x04%N\x01님이 보이스를 들려주지 않도록 설정했습니다.", PREFIX, client);
								SetListenOverride(i, client, Listen_No);
							}
						}
						// 아닌 경우
						else
						{
							// 그냥 걸어준다.
							SetListenOverride(i, client, Listen_No);
						}
					}
				}
			}
			else if(targetselect == 1)
			{
				PrintToChat(client, "%s\x04모두\x01에게 보이스를 들려줍니다.", PREFIX);
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsClientConnected(i) && i != client && !IsFakeClient(i))
					{
						// 듣는 사람이 직접 갠뮤를 하지 않았을 경우에만
						if(g_iListenOverride[i][client] != Listen_No)
						{
							// 대상이 관리자인 경우에
							if(IsClientAdmin(i))
							{
								// 본인도 관리자여야 설정 가능
								if(IsClientAdmin(client))
								{
									PrintToChat(i, "%s\x04%N\x01님이 보이스를 들려주도록 설정했습니다.", PREFIX, client);
									SetListenOverride(i, client, Listen_Yes);
								}
							}
							// 아닌 경우
							else
							{
								// 그냥 걸어준다.
								SetListenOverride(i, client, Listen_Yes);
							}
						}
					}
				}
			}
			else
			{
				if(IsClientConnected(target) && !IsFakeClient(target))
				{
					if(GetListenOverride(target, client) == Listen_No)
					{
						PrintToChat(client, "%s\x04%N\x01님에게 보이스를 들려줍니다.", PREFIX, target);
						if(IsClientAdmin(target))
							PrintToChat(target, "%s\x04%N\x01님이 보이스를 들려주도록 설정했습니다.", PREFIX, client);
						SetListenOverride(target, client, Listen_Yes);
					}
					else
					{
						PrintToChat(client, "%s\x04%N\x01님에게 보이스를 들려주지 않습니다.", PREFIX, target);
						if(IsClientAdmin(target))
							PrintToChat(target, "%s\x04%N\x01님이 보이스를 들려주지 않도록 설정했습니다.", PREFIX, client);
						SetListenOverride(target, client, Listen_No);
					}
				}
			}
		}
		
		// 유저가 선택한 아이템의 페이지를 얻어낸 후 그 페이지로 메뉴 띄우기
		int MenuSelectionPosition = RoundToFloor(float(targetselect / GetMenuPagination(menu))) * GetMenuPagination(menu);
		Menu_PrivateBlockVoiceSend(client, MenuSelectionPosition);
		
	}else if(action == MenuAction_End){
			
		CloseHandle(menu);
		
	}
	
}