int iItemEvent_ItemIndex = 0;

bool bItemEvent_Active = false;
int iItemEvent_ItemType = 0; // 1=랜덤 소모품, 2=보급 상자, 3=가벼운 상자
int iItemEvent_ItemAmount = 0;
int iItemEvent_Condition = 0; // 1=베테랑만, 2=숙주만, 3=베테랑,숙주 둘다, 4=0:00까지 생존자

bool bTempItemEvent_Active = false;
int iTempItemEvent_ItemType = 0;
int iTempItemEvent_ItemAmount = 0;
int iTempItemEvent_Condition = 0;

bool bTempItemEvent_BlockDuplication = false;

void ItemEvent_OnMapStart()
{
	bItemEvent_Active = false;
	bTempItemEvent_BlockDuplication = false;
	
	iItemEvent_ItemIndex = 0;
	
	bTempItemEvent_Active = false;
	iTempItemEvent_ItemType = 0;
	iTempItemEvent_ItemAmount = 0;
	iTempItemEvent_Condition = 0;
}

void Cmd_ItemEvent(int client)
{
	if (IsClientAdmin(client, Admin_Generic))
	{
		bTempItemEvent_Active = bItemEvent_Active;
		iTempItemEvent_ItemType = iItemEvent_ItemType;
		iTempItemEvent_ItemAmount = iItemEvent_ItemAmount;
		iTempItemEvent_Condition = iItemEvent_Condition;
		Menu_ItemEventMain(client);
	}
}

void Menu_ItemEventMain(int client)
{	
	Menu menu = new Menu(Handler_ItemEventMain);
	
	menu.SetTitle("유저 아이템 이벤트");
	
	menu.AddItem("", "이벤트 설정");
	
	char displayString[64];
	Format(displayString, sizeof(displayString), "%s 이벤트 활성화", (bTempItemEvent_Active)?"[√]":"[  ]");
	menu.AddItem("", displayString);
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public Handler_ItemEventMain(Handle menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
 		if(select == 0)
 		{
 			Menu_ItemEventSetting(client);
 		}
 		else if(select == 1)
 		{
 			if (iTempItemEvent_ItemType != 0 && iTempItemEvent_ItemAmount != 0 && iTempItemEvent_Condition != 0)
	 			bTempItemEvent_Active = !bTempItemEvent_Active;
	 		else
	 			bTempItemEvent_Active = false;
	 		
	 		Menu_ItemEventMain(client);
 		}
	}
	/*
	else if(action == MenuAction_Cancel)
	{
		if(select == MenuCancel_ExitBack)
		{
			Command_ClassLevel(client);
		}
	}*/
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}

void Menu_ItemEventSetting(int client, int page=0)
{	
	Menu menu = new Menu(Handler_ItemEventSetting);
	
	if(page == 0)
	{
		char itemtype[32], itemcondition[64];
		
		// 1=랜덤 소모품, 2=보급 상자, 3=가벼운 상자
		// 1=베테랑만, 2=숙주만, 3=베테랑,숙주 둘다, 4=0:00까지 생존자
		if(iTempItemEvent_ItemType == 0)
			Format(itemtype, sizeof(itemtype), "\"없음\"");
		else if(iTempItemEvent_ItemType == 1)
			Format(itemtype, sizeof(itemtype), "\"랜덤 소모품\"");
		else if(iTempItemEvent_ItemType == 2)
			Format(itemtype, sizeof(itemtype), "\"보급 상자\"");
		else if(iTempItemEvent_ItemType == 3)
			Format(itemtype, sizeof(itemtype), "\"가벼운 상자\"");
		else if(iTempItemEvent_ItemType == 4)
			Format(itemtype, sizeof(itemtype), "\"호박 상자\"");
		
		if(iTempItemEvent_Condition == 0)
			Format(itemcondition, sizeof(itemcondition), "\"없음\"");
		else if(iTempItemEvent_Condition == 1)
			Format(itemcondition, sizeof(itemcondition), "\"베테랑\"");
		else if(iTempItemEvent_Condition == 2)
			Format(itemcondition, sizeof(itemcondition), "\"숙주\"");
		else if(iTempItemEvent_Condition == 3)
			Format(itemcondition, sizeof(itemcondition), "\"베테랑과 숙주\"");
		else if(iTempItemEvent_Condition == 4)
			Format(itemcondition, sizeof(itemcondition), "\"[0:00]까지의 생존자\"");
			
		menu.SetTitle("유저 아이템 이벤트 설정\n현재: %s에게 %s \"%d개\" 지급", itemcondition, itemtype, iTempItemEvent_ItemAmount);
		
		menu.AddItem("0", "아이템 설정");
		
		menu.AddItem("0", "아이템 갯수 설정");
		
		menu.AddItem("0", "조건 설정");
		
		menu.ExitBackButton = true;
	}
	else if(page == 1)
	{
		menu.SetTitle("유저 아이템 이벤트 아이템 설정");
		
		menu.AddItem("1", "랜덤 소모품 주기");
		
		menu.AddItem("1", "보급 상자 주기");
		
		menu.AddItem("1", "가벼운 상자 주기");
		
		menu.AddItem("1", "호박 상자 주기");
		
		menu.ExitBackButton = false;
	}
	else if(page == 2)
	{
		menu.SetTitle("유저 아이템 이벤트 아이템 갯수 설정");
		
		menu.AddItem("2", "1개");
		
		menu.AddItem("2", "2개");
		
		menu.AddItem("2", "3개");
		if (IsClientAdmin(client, Admin_Root))
		{
			menu.AddItem("2", "5개");
			
			menu.AddItem("2", "10개");
			
			menu.AddItem("2", "15개");
		}
		
		menu.ExitBackButton = false;
	}
	else if(page == 3)
	{
		menu.SetTitle("유저 아이템 이벤트 조건 설정");
		
		menu.AddItem("3", "베테랑만 지급");
		
		menu.AddItem("3", "숙주만 지급");
		
		menu.AddItem("3", "베테랑,숙주 둘다지급");
		
		menu.AddItem("3", "[0:00] 까지 생존자만 지급");
		
		menu.ExitBackButton = false;
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

public Handler_ItemEventSetting(Menu menu, MenuAction:action, client, select)
{
	if(action == MenuAction_Select)
	{
		char info[8];
 		menu.GetItem(select, info, sizeof(info));
 		
 		int page = StringToInt(info);
 		
 		if(page == 0)
		{
			Menu_ItemEventSetting(client, select+1);
		}
		else if(page == 1)
		{
			iTempItemEvent_ItemType = select + 1;
			Menu_ItemEventSetting(client);
		}
		else if(page == 2)
		{
			if(select == 0)
				iTempItemEvent_ItemAmount = 1;
			else if(select == 1)
				iTempItemEvent_ItemAmount = 2;
			else if(select == 2)
				iTempItemEvent_ItemAmount = 3;
			else if(select == 3)
				iTempItemEvent_ItemAmount = 5;
			else if(select == 4)
				iTempItemEvent_ItemAmount = 10;
			else if(select == 5)
				iTempItemEvent_ItemAmount = 15;
				
			Menu_ItemEventSetting(client);
		}
		else if(page == 3)
		{
			iTempItemEvent_Condition = select + 1;
			Menu_ItemEventSetting(client);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(select == MenuCancel_ExitBack)
		{
			Menu_ItemEventMain(client);
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}

void ItemEvent_OnRoundStart()
{
	bItemEvent_Active = bTempItemEvent_Active;
	iItemEvent_ItemType = iTempItemEvent_ItemType;
	iItemEvent_ItemAmount = iTempItemEvent_ItemAmount;
	iItemEvent_Condition = iTempItemEvent_Condition;
	
	if(iItemEvent_ItemType == 1)
	{
		iItemEvent_ItemIndex = DDS_GetRandomItem(EXPENDABLE_ID, 0, 0, false);
	}
	else if(iItemEvent_ItemType == 2)
	{
		iItemEvent_ItemIndex = g_iItemIndices[SupplyCrate];
	}
	else if(iItemEvent_ItemType == 3)
	{
		iItemEvent_ItemIndex = g_iItemIndices[LightBox];
	}
	else if(iItemEvent_ItemType == 4)
	{
		iItemEvent_ItemIndex = g_iItemIndices[HalloweenBox];
	}
		
	bTempItemEvent_BlockDuplication = false;
	if (!bItemEvent_Active) return;
	if (iItemEvent_ItemType == 0 || iItemEvent_ItemAmount == 0 || iItemEvent_Condition == 0)	return;
	
	char itemtype[32], itemcondition[64];
	
	if(iItemEvent_ItemType == 1)
		Format(itemtype, sizeof(itemtype), "랜덤 소모품");
	else if(iItemEvent_ItemType == 2)
		Format(itemtype, sizeof(itemtype), "보급 상자");
	else if(iItemEvent_ItemType == 3)
		Format(itemtype, sizeof(itemtype), "가벼운 상자");
	else if(iTempItemEvent_ItemType == 4)
		Format(itemtype, sizeof(itemtype), "호박 상자");
	
	if(iItemEvent_Condition == 1)
		Format(itemcondition, sizeof(itemcondition), "베테랑");
	else if(iItemEvent_Condition == 2)
		Format(itemcondition, sizeof(itemcondition), "숙주");
	else if(iItemEvent_Condition == 3)
		Format(itemcondition, sizeof(itemcondition), "베테랑과 숙주");
	else if(iItemEvent_Condition == 4)
		Format(itemcondition, sizeof(itemcondition), "[0:00]까지의 생존자");
	
	PrintToChatAll("%s\x01이번 라운드의 \x06%s\x01에게 \x10%s \x03%d\x01개를 지급해드립니다!!", PREFIX, itemcondition, itemtype, iItemEvent_ItemAmount);
}

void ItemEvent_EventOccurToTarget(int target)
{
	if (!bItemEvent_Active) return;
	if (iItemEvent_ItemType == 0 || iItemEvent_ItemAmount == 0 || iItemEvent_Condition == 0) return;
	if (!IsValidClient(target))	return;	
	
	if(iItemEvent_ItemIndex != 0)
	{
		// 1 = Item Name
		char strResultItemName[64];
		DDS_GetItemInfo(iItemEvent_ItemIndex, 1, strResultItemName);
		
		DDS_SimpleGiveItem(target, iItemEvent_ItemIndex, iItemEvent_ItemAmount);
		PrintToChat(target, "%s\x01이벤트 보상으로 \x10%s\x01아이템을 \x03%d\x01개 받으셨습니다.", PREFIX, strResultItemName, iItemEvent_ItemAmount);
		
		if(iItemEvent_Condition != 4)
		{
			PrintToChatAll("%s\x06%N\x01님이 이벤트 보상으로 \x10%s\x01아이템을 \x03%d\x01개 받으셨습니다.", PREFIX, target, strResultItemName, iItemEvent_ItemAmount);
		}
		else
		{
			// 포문돌리는 부분이 존재하기땜에 이게 있어야한다...
			if(!bTempItemEvent_BlockDuplication)
			{
				PrintToChatAll("%s\x06생존자\x01들이 이벤트 보상으로 \x10%s\x01아이템을 \x03%d\x01개 받으셨습니다.", PREFIX, strResultItemName, iItemEvent_ItemAmount);
				bTempItemEvent_BlockDuplication = true;
			}
		}
	}	
}