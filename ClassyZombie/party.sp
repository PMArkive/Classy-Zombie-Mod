#define PARTY_CHAT_SOUND		"buttons/button15.wav"

/* 제작 : Trostal */
#define PARTY_LEADER_SHORT_CHAR	"*"		// L, Leader
#define PARTY_MEMBER_SHORT_CHAR "-"		// M, Member

#define PARTY_DEFAULT_NAME_SUFFIX	" 님의 파티"

#define MAX_PARTY 10 // 최대로 생성 가능한 파티 갯수
#define MAX_PARTY_MEMBER 4 // 한 파티에 최대로 속할 수 있는 멤버 수

#define PARTY_CONTROL_LOCK_TIME		60 // 라운드를 시작한 뒤 몇 초 후에 파티 제어(참가 및 초대, 파티장 위임)을 막을 것인가?

#define PARTY_QUICK_MATCHING_MIN_PLAYER		3	// 빠른 파티 매칭에서 최소로 필요한 유저 수

int MyPartyIndex[MAXPLAYERS+1] = {-1, ...};

bool InputNewPartyName[MAXPLAYERS+1];

int g_iPlayerGlowObject[MAXPLAYERS + 1];

int PartyLeader[MAX_PARTY] = {-1, ...};
int PartyMembers[MAX_PARTY][MAX_PARTY_MEMBER];

char PartyName[MAX_PARTY][256];

bool IsActivatedParty[MAX_PARTY];
bool IsPrivateParty[MAX_PARTY];
bool IsFreeToJoinParty[MAX_PARTY];

Handle QuickPartyMatchList = INVALID_HANDLE;

void Party_OnPluginStart()
{
	QuickPartyMatchList = CreateArray();
}

void Party_OnRoundStart()
{
	MatchQuickParty();
}

// 클라이언트 퇴장
void Party_ResetClientPartyStatus(int client)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] Party_ResetClientPartyStatus(%i)", client);
	#endif
	
	g_iPlayerGlowObject[client] = INVALID_ENT_REFERENCE;
	Party_ClientExit(client);
	EraseClientOnList(client, false);
	
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] Party_ResetClientPartyStatusPost(%i)", client);
	#endif
}

stock bool Party_Chat(int &client, int PIndex, char []message)
{
	if(-1 < PIndex && PIndex < MAX_PARTY)
	{
//		ClearArray(recipients);
		int total = 0;
		int clients[MAX_PARTY_MEMBER];
		for(int i;i < MAX_PARTY_MEMBER;i++)
		{
			if(IsValidPlayer(PartyMembers[PIndex][i]))
			{
				clients[total++] = PartyMembers[PIndex][i];
//				PushArrayCell(recipients, PartyMembers[PIndex][i]);
				EmitSoundToClient(PartyMembers[PIndex][i], PARTY_CHAT_SOUND, SOUND_FROM_PLAYER, 98);
			}
		}
		SayText2To(client, message, clients, total);
		return true;
	}
	return false;
}

// 파티 구성원의 사기 저하
void Party_DestroyMorale(int PIndex, int client)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] Party_DestroyMorale(%i)", PIndex);
	#endif
	
	for(int i;i < MAX_PARTY_MEMBER;i++)
	{
		if(IsValidPlayer(PartyMembers[PIndex][i]) && !IsClientZombie(PartyMembers[PIndex][i]))
		{
			if(PartyMembers[PIndex][i] != client)
			{
				SetEntityHealth(PartyMembers[PIndex][i], GetClientHealth(PartyMembers[PIndex][i])/2);
				PrintToChat(PartyMembers[PIndex][i], "%s\x03파티장\x01이 죽어 사기력이 저하되었습니다.", PREFIX);
			}
		}
	}
}

// 파티 구성원 좀비화
void Party_PlayerBecomeZombie(int client, bool IsHostZombie=false)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] Party_PlayerBecomeZombie(%i)", client);
	#endif
	
	/*
	SetGame() 함수에서 MakeClientZombie() 함수를 먼저 호출하고, 이후에 g_bGameStarted 값을 true로 바꾸기 때문에
	if(!g_bGameStarted) 조건문은 처음 숙주가 된 사람에 대한 처리로는 적합하지 않게된다.
	따라서 IsHostZombie 인수를 추가
	*/
	if (!g_bGameStarted && !IsHostZombie)	return;
	
	RemoveSkin(client);
	
	if(MyPartyIndex[client] > -1)
	{
		Party_ValidateGlowObject(MyPartyIndex[client]);
		
		if(PartyLeader[MyPartyIndex[client]] == client)
		{
			PrintToChatMembers(MyPartyIndex[client], "%s\x03파티장\x01인 \x03%N\x01님이 좀비로 감염되셨습니다!", PREFIX, client);
			
			Party_DestroyMorale(MyPartyIndex[client], client);
		}
		else
		{
			PrintToChatMembers(MyPartyIndex[client], "%s\x01파티원인 \x03%N\x01님이 좀비로 감염되셨습니다!", PREFIX, client);
		}
	}
}

void Party_ValidateGlowObject(int PIndex)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] Party_ValidateGlowObject(%i)", PIndex);
	#endif
	
	if(-1 < PIndex && PIndex < MAX_PARTY)
	{
		for(int i=0;i < MAX_PARTY_MEMBER;i++)
		{
			// 좀비가 되었을 때, 이전에 보이던 파티원의 글로우를 보이지 않도록 처리하면
			// 글로우 오브젝트가 0.0, 0.0, 0.0 좌표에 위치한 것으로 보이게 되고, 숨겨지지 않는다.
			// 하지만 글로우 오브젝트가 생성된 이후 한 번도 보이도록 처리하지 않으면 계속 보이지 않는다.
			// 따라서 한 명이 글로우를 보지 않도록 해야할 때 마다 글로우 주인에게 갱신을 요청한다.
			if(PartyMembers[PIndex][i] > 0 && IsValidClient(PartyMembers[PIndex][i]))
			{
				if(IsPlayerAlive(PartyMembers[PIndex][i]))
				{
					if(!IsClientZombie(PartyMembers[PIndex][i]))
					{
						// 여기서 RequestFrame을 쓰지 않도록 조심하자.
						PrepareToSetupGlow(PartyMembers[PIndex][i]);
					}
					else
					{
						RemoveSkin(PartyMembers[PIndex][i]);
					}
				}
				else
				{
					RemoveSkin(PartyMembers[PIndex][i]);
				}
			}
		}
	}
}

void Party_TeamWin(int team)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] Party_TeamWin(%i)", team);
	#endif
	
	if (!g_bGameStarted || team != CS_TEAM_CT)	return;
	for(int p=0;p < MAX_PARTY;p++)
	{
		// 파티가 활성화 된 상태일 때
		if(IsActivatedParty[p])
		{
			/** 파티 내부의 생존자 수 체크 시작**/
			int nAliveMemberCount=0;
			for(int i=0;i < MAX_PARTY_MEMBER;i++)
			{
				if(IsValidPlayer(PartyMembers[p][i]) && !IsClientZombie(PartyMembers[p][i]))
				{
					nAliveMemberCount++;
				}
			}
			/** 파티 내부의 생존자 수 체크 끝**/
			
			if(nAliveMemberCount == 0)
			{
				PrintToChatMembers(p, "%s\x01파티에서 아무도 생존하지 못했습니다, 파티 생존 실패!", PREFIX);
			}
			else if(nAliveMemberCount == 1)
			{
				PrintToChatMembers(p, "%s\x01파티에서 1명밖에 생존하지 못했습니다, 파티 생존 실패!", PREFIX);
			}
			else
			{
				Party_GivePartyMemberMoney(p, nAliveMemberCount);
				PrintToChatMembers(p, "%s\x03%d\x01명이 파티 생존에 성공하였습니다, \x03%d\x01 킬포인트 추가!", PREFIX, nAliveMemberCount, nAliveMemberCount);
				
				if(nAliveMemberCount == MAX_PARTY_MEMBER*3/4)
				{
					PrintToChatMembers(p, "%s\x01파티원 %i명이 생존하였습니다 \x04협력 생존의 증표 %d개 지급", PREFIX, MAX_PARTY_MEMBER*3/4, REWARD_VOUCHER_3_4_SURVIVE);
					// 협력 생존의 증표
					Party_GivePartyMemberItem(p, g_iItemIndices[Voucher], REWARD_VOUCHER_3_4_SURVIVE);
				}
				if(nAliveMemberCount == MAX_PARTY_MEMBER)
				{
					PrintToChatMembers(p, "%s\x01파티 전원이 생존하였습니다, 대단합니다! \x04보급상자 1개 와 협력 생존의 증표 %d개 지급", PREFIX, REWARD_VOUCHER_ALL_SURVIVE);
					// 보급 상자
					Party_GivePartyMemberItem(p, g_iItemIndices[SupplyCrate], 1);
					// 협력 생존의 증표
					Party_GivePartyMemberItem(p, g_iItemIndices[Voucher], REWARD_VOUCHER_ALL_SURVIVE);
					
					// 할로윈 이벤트
					/*
					PrintToChatMembers(p, "%s\x01파티 생존 보너스로 \x10호박 상자 \x031개\x01 지급.", PREFIX, HUMAN_SURVIVE_REWARD);
					Party_GivePartyMemberItem(p, g_iItemIndices[HalloweenBox], 1);
					*/
				}
			}
		}
	}
}

void Party_GivePartyMemberMoney(int PIndex, int amount)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] Party_GivePartyMemberMoney(%i -> %i)", PIndex, amount);
	#endif
	
	for(int i;i < MAX_PARTY_MEMBER;i++)
	{
		if(PartyMembers[PIndex][i] > 0 && IsClientInGame(PartyMembers[PIndex][i]))
		{
			if(IsValidClient(PartyMembers[PIndex][i]))
			{
				DDS_SetUserMoney(PartyMembers[PIndex][i], 2, amount);
			}
		}
	}
}

void Party_GivePartyMemberItem(int PIndex, int itemid, int amount)
{
	for(int i;i < MAX_PARTY_MEMBER;i++)
	{
		if(PartyMembers[PIndex][i] > 0 && IsClientInGame(PartyMembers[PIndex][i]))
		{
			if(IsValidClient(PartyMembers[PIndex][i]))
			{
				DDS_SimpleGiveItem(PartyMembers[PIndex][i], itemid, amount);
			}
		}
	}
}

void Command_PartyMain(int client)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] Command_PartyMain(%i)", client);
	#endif
	
	Menu menu = new Menu(Menu_PartyMain);
	
	bool PlayerInParty;
	
	if(MyPartyIndex[client] > -1)
		PlayerInParty = true;
	else
		PlayerInParty = false;
	
	if(!PlayerInParty)
		menu.SetTitle("-= 가입된 파티가 없습니다 =-");
	else
		menu.SetTitle("-= 파티 =-\n%s에 가입되어 있습니다.\n멤버 수: (%i/%i)\n공개 파티 여부: %s\n자유 가입: %s", PartyName[MyPartyIndex[client]], CountPartyMembers(MyPartyIndex[client]), MAX_PARTY_MEMBER, IsPrivateParty[MyPartyIndex[client]] ? "비공개" : "공개", IsFreeToJoinParty[MyPartyIndex[client]] ? "허용" : "비허용");
	
	// 참가중인 파티가 없을 때
	if(!PlayerInParty)
	{
		if(CountParties(false) > 0)
		{
			if (IsPartyControlTime())
				menu.AddItem("Button-1", "파티 만들기");
			else
				menu.AddItem("Button-1", "파티 만들기 *생성 가능한 시간이 지났습니다.*", ITEMDRAW_DISABLED);
		}
		else
		{
			menu.AddItem("Button-1", "파티 만들기 *더 이상 파티를 만들 수 없습니다*", ITEMDRAW_DISABLED);
		}
		
		if(CountParties(true) > 0)
		{
			menu.AddItem("Button-2", "파티 목록 보기");
		}
		else
		{
			menu.AddItem("Button-2", "파티 목록 보기 *생성된 파티가 없습니다*", ITEMDRAW_DISABLED);
		}
		
		if(!IsClientListedOnQuickPartyMatching(client))
			menu.AddItem("Button-3", "빠른 파티 참가");
		else
			menu.AddItem("Button-3", "빠른 파티 참가 취소");
	}
	else
	{
		if(PartyLeader[MyPartyIndex[client]] == client)
		{
			menu.AddItem("Button-4", "파티 설정 변경");
			
			if(IsPartyControlTime())
			{
				if(CountClients(false) > 0)	menu.AddItem("Button-5", "파티 초대");
				else	menu.AddItem("Button-5", "파티 초대 *초대할 수 있는 유저가 없습니다*", ITEMDRAW_DISABLED);
			}
			else
			{
				menu.AddItem("Button-5", "파티 초대 *초대 가능한 시간이 지났습니다.*", ITEMDRAW_DISABLED);
			}
		}
		
		menu.AddItem("Button-6", "파티 탈퇴");
		for(int m;m < MAX_PARTY_MEMBER;m++)
		{
			/*
			 * 파티에 가입되어 있으므로 파티 멤버 목록을 출력합니다.
			 * 만약 자신에 RPG 플러그인에 이 코드들을 쓰려고 한다면,
			 * 레벨이나 직업등을 추가로 입력할 수도 있습니다.
			 * 
			 * 기본적으로 아래 코드를 사용하여 출력할 시에는,
			 * 
			 * [L] 플레이어 이름  (리더의 경우)
			 * [M] 플레이어 이름  (일반 멤버의 경우)
			 * 
			 * 의 형태로 출력됩니다.
			 */
			if(IsValidClient(PartyMembers[MyPartyIndex[client]][m]))
			{
				int i = PartyMembers[MyPartyIndex[client]][m];
				char IndexS[16], Name[32], DisplayS[256];
				GetClientName(i, Name, sizeof(Name));
				
				Format(IndexS, sizeof(IndexS), "PIndex-%i", i);
				
				//Format(DisplayS, sizeof(DisplayS), "%i)", m+1);
				
				if(PartyLeader[MyPartyIndex[client]] == i)
				{
					Format(DisplayS, sizeof(DisplayS), "%s[%s]", DisplayS, PARTY_LEADER_SHORT_CHAR);
				}
				else
				{
					Format(DisplayS, sizeof(DisplayS), "%s[%s]", DisplayS, PARTY_MEMBER_SHORT_CHAR);
				}
				
				// 베테랑이 아닐 때
				if(g_iClassId[i] != 7 && g_iClassId[i] > 0)
					Format(DisplayS, sizeof(DisplayS), "%s %s (Lv. %i %s)", DisplayS, Name, g_iClassLevel[i][g_iClassId[i]-1], g_szConstClassName[g_iClassId[i]]);
				else // 베테랑일 때
					Format(DisplayS, sizeof(DisplayS), "%s %s (%s)", DisplayS, Name, g_szConstClassName[g_iClassId[i]]);
				
				if(i != client)
					menu.AddItem(IndexS, DisplayS);
				else
					menu.AddItem(IndexS, DisplayS, ITEMDRAW_DISABLED);
			}
		}
	}
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_PartyMain(Menu menu, MenuAction action, int client, int selectbutton)
{
	if(action == MenuAction_Select)
	{
		char Info[256], ExplodedInfo[2][256];
		menu.GetItem(selectbutton, Info, sizeof(Info));
		ExplodeString(Info, "-", ExplodedInfo, 2, 256);
		
		if(StrEqual(ExplodedInfo[0], "Button", false)) // 버튼으로 쓰이기 위한 인포스트링이다.
		{
			int Select = StringToInt(ExplodedInfo[1]);
			
			if(Select == 1)
			{
				if (IsPartyControlTime())
				{
					if(MyPartyIndex[client] < 0)
					{
						if(CountParties(false) > 0)
						{
							char DefaultPName[256], Name[32];
							
							GetClientName(client, Name, sizeof(Name));
							Format(DefaultPName, sizeof(DefaultPName), "%s%s", Name, PARTY_DEFAULT_NAME_SUFFIX);
							Command_CreateParty(client, DefaultPName, false);
						}
						else
						{
							PrintToChat(client, "\x01[\x04Party\x01] \x04- \x01더 이상 파티를 생성할 수 없습니다.");
						}
					}
					else
					{
						PrintToChat(client, "\x01[\x04Party\x01] \x04- \x01이미 파티에 가입되어 있습니다.");
					}
				}
				else
				{
					PrintToChat(client, "\x01[\x04Party\x01] \x04- \x01생성 가능한 시간이 지났습니다, 라운드 시작 후 %i초 까지만 가능합니다.", PARTY_CONTROL_LOCK_TIME);
				}
			}
			else if(Select == 2)
			{
				if(MyPartyIndex[client] < 0)
				{
					if(CountParties(true) > 0)
					{
						Command_PartyList(client);
					}
					else
					{
						PrintToChat(client, "\x01[\x04Party\x01] \x04- \x01생성된 파티가 없습니다.");
					}
				}
			}
			else if(Select == 3)
			{
				// 빠른 파티 참가 리스트 등록
				if(!IsClientListedOnQuickPartyMatching(client))
					ListQuickParty(client);
				else
					EraseClientOnList(client, true);
				
			}
			else if(Select == 4)
			{
				if(MyPartyIndex[client] > -1)
				{
					if(PartyLeader[MyPartyIndex[client]] == client)
					{
						Command_PartySettings(client);
					}
				}
			}
			else if(Select == 5)
			{
				if(MyPartyIndex[client] > -1)
				{
					if(PartyLeader[MyPartyIndex[client]] == client)
					{
						if(CountClients(false) > 0)
							Command_PartyInvite(client);
						else
							Command_PartyMain(client);
					}
				}
			}
			else if(Select == 6)
			{
				if(MyPartyIndex[client] > -1)
				{
					if(PartyLeader[MyPartyIndex[client]] != client)
					{
						Party_ClientExit(client);
					}
					else
					{
						Command_LeaderExit(client);
					}
				}
			}
		}
		else if(StrEqual(ExplodedInfo[0], "PIndex", false)) // 플레이어 인덱스를 구분하기 위한 인포스트링이다.
		{
			int Target = StringToInt(ExplodedInfo[1]);
			
			if(MyPartyIndex[client] > -1)
			{
				Command_MemberInfo(client, Target);
			}
		}
	}
	else if(action == MenuAction_End)	CloseHandle(menu);
}

void Command_CreateParty(int client, char PName[256], bool PP=false, bool FJ=true)
{
	Menu menu = new Menu(Menu_CreateParty);
	
	TrimString(PName);
	StripQuotes(PName);
	
	/*
	char PPString[16], FJString[16];
	if(PP)	PPString = "비공개";
	else	PPString = "공개";
	
	if(FJ) FJString = "허용";
	else FJString = "비허용";
	*/
	
	menu.SetTitle("파티 생성하기\n생성될 파티 이름: %s", PName);
	
	char InfoS[512];
	
	Format(InfoS, sizeof(InfoS), "%s|%i|%i", PName, (PP) ? 1 : 0, (FJ) ? 1 : 0);
	
	menu.AddItem(InfoS, "파티 생성");
	
	if(!PP)	menu.AddItem(InfoS, "[  ]비공개 파티"); // 공개 상태
	else	menu.AddItem(InfoS, "[√]비공개 파티"); // 비공개 상태
	
	if(FJ)	menu.AddItem(InfoS, "[√]자유 가입"); // 자유 가입가능
	else	menu.AddItem(InfoS, "[  ]자유 가입");  // 자유 가입 불가능
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_CreateParty(Menu menu, MenuAction action, int client, int select)
{
	if(action == MenuAction_Select)
	{
		char Info[256], ExplodedInfo[3][256];
		menu.GetItem(select, Info, sizeof(Info));
		ExplodeString(Info, "|", ExplodedInfo, 3, 256);
		
		bool PP = (StringToInt(ExplodedInfo[1]) == 1) ? true : false; // 1 일 경우 비공개 파티.
		bool FJ = (StringToInt(ExplodedInfo[2]) == 1) ? true : false; // 1 일 경우 자유 가입 파티.
		
		if(select == 0)
		{
			if(CountParties(false) > 0)
			{
				if(MyPartyIndex[client] < 0)
				{
					Party_Create(client, ExplodedInfo[0], PP, FJ);
				}
				else
				{
					PrintToChat(client, "\x01[\x04Party\x01] \x04- \x01이미 파티에 가입되어 있습니다.");
				}
			}
			else
			{
				PrintToChat(client, "\x01[\x04Party\x01] \x04- \x01더 이상 파티를 생성할 수 없습니다.");
			}
		}
		else if(select == 1)
		{
			if(!PP)
			{
				Command_CreateParty(client, ExplodedInfo[0], true, FJ);
			}
			else
			{
				Command_CreateParty(client, ExplodedInfo[0], false, FJ);
			}
		}
		
		else if(select == 2)
		{
			if(!FJ)
			{
				Command_CreateParty(client, ExplodedInfo[0], PP, true);
			}
			else
			{
				Command_CreateParty(client, ExplodedInfo[0], PP, false);
			}
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(select == MenuCancel_ExitBack)
		{
			Command_PartyMain(client);
		}
	}
	else if(action == MenuAction_End)	CloseHandle(menu);
}

void Command_PartyList(int client)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] Command_PartyList(%i)", client);
	#endif
	
	Menu menu = new Menu(Menu_PartyList);
	
	menu.SetTitle("-= 파티 목록 =-");
	
	for(int i=0;i < MAX_PARTY;i++)
	{
		if(IsActivatedParty[i] && PartyLeader[i] > 0)
		{
			int MemberCount = CountPartyMembers(i);
			if(MemberCount > 0)
			{
				char InfoS[9], DisplayS[512];
				IntToString(i, InfoS, sizeof(InfoS));
				Format(DisplayS, sizeof(DisplayS), "%s%s%s (%i/%i)", (IsPrivateParty[i]) ? "[비공개 파티] " : "", (!IsPrivateParty[i] && IsFreeToJoinParty[i]) ? "[자유] " : "", (!IsPrivateParty[i]) ? PartyName[i] : "", MemberCount, MAX_PARTY_MEMBER);
				if(IsPrivateParty[i])
					menu.AddItem(InfoS, DisplayS, ITEMDRAW_DISABLED);
				else
					menu.AddItem(InfoS, DisplayS);
			}
		}
	}
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_PartyList(Menu menu, MenuAction action, int client, int select)
{
	if(action == MenuAction_Select)
	{
		char Info[256];
		menu.GetItem(select, Info, sizeof(Info));
		
		Command_PartyInfo(client, StringToInt(Info));
	}
	else if(action == MenuAction_Cancel)
	{
		if(select == MenuCancel_ExitBack)
		{
			Command_PartyMain(client);
		}
	}
	else if(action == MenuAction_End)	CloseHandle(menu);
}

void Command_PartyInfo(int client, int PIndex)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] Command_PartyInfo(%i -> %i)", client, PIndex);
	#endif
	
	Menu menu = new Menu(Menu_PartyInfo);
	
	menu.SetTitle("-= 파티 =-\n%s\n멤버 수: (%i/%i)\n공개 파티 여부: %s\n자유 가입: %s", PartyName[PIndex], CountPartyMembers(PIndex), MAX_PARTY_MEMBER, IsPrivateParty[PIndex] ? "비공개" : "공개", IsFreeToJoinParty[PIndex] ? "허용" : "비허용");
	
	if(IsActivatedParty[PIndex])
	{
		char IndexS[16];
		IntToString(PIndex, IndexS, sizeof(IndexS));
		
		if(!IsPartyControlTime())
			menu.AddItem(IndexS, "파티 가입 *가입 가능한 시간이 지났습니다.*", ITEMDRAW_DISABLED);
		else if(CountPartyMembers(PIndex) >= MAX_PARTY_MEMBER)
			menu.AddItem(IndexS, "파티 가입 *파티가 꽉 찼습니다*", ITEMDRAW_DISABLED);
		else
			menu.AddItem(IndexS, "파티 가입");
		
		#if defined _DEBUG_
			PrintToChat(client, "[BST Zombie] PartyInfoIndexString: %i(%s)", PIndex, IndexS);
		#endif
			
		for(int m;m < MAX_PARTY_MEMBER;m++)
		{
			if(PartyMembers[PIndex][m] > 0)
			{
				/*
				 * 파티에 가입되어 있으므로 파티 멤버 목록을 출력합니다.
				 * 만약 자신에 RPG 플러그인에 이 코드들을 쓰려고 한다면,
				 * 레벨이나 직업등을 추가로 입력할 수도 있습니다.
				 * 
				 * 기본적으로 아래 코드를 사용하여 출력할 시에는,
				 * 
				 * 1) [L] 플레이어 이름  (리더의 경우)
				 * 2) [M] 플레이어 이름  (일반 멤버의 경우)
				 * 
				 * 의 형태로 출력됩니다.
				 */
				int i = PartyMembers[PIndex][m];
				char Name[32], DisplayS[256];
				GetClientName(i, Name, sizeof(Name));
				
				//Format(DisplayS, sizeof(DisplayS), "%i)", m+1);
				
				if(PartyLeader[PIndex] == i)
				{
					Format(DisplayS, sizeof(DisplayS), "%s[%s]", DisplayS, PARTY_LEADER_SHORT_CHAR);
				}
				else
				{
					Format(DisplayS, sizeof(DisplayS), "%s[%s]", DisplayS, PARTY_MEMBER_SHORT_CHAR);
				}
				
				// 베테랑이 아닐 때
				if(g_iClassId[i] != 7 && g_iClassId[i] > 0)
					Format(DisplayS, sizeof(DisplayS), "%s %s (Lv. %i %s)", DisplayS, Name, g_iClassLevel[i][g_iClassId[i]-1], g_szConstClassName[g_iClassId[i]]);
				else // 베테랑일 때
					Format(DisplayS, sizeof(DisplayS), "%s %s (%s)", DisplayS, Name, g_szConstClassName[g_iClassId[i]]);
					
					
				menu.AddItem("", DisplayS, ITEMDRAW_DISABLED);
			}
		}
	}
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_PartyInfo(Menu menu, MenuAction action, int client, int select)
{
	if(action == MenuAction_Select)
	{
		int PIndex;
		char Info[256];
		menu.GetItem(select, Info, sizeof(Info));
		
		PIndex = StringToInt(Info);
		
		#if defined _DEBUG_
			PrintToServer("[BST Zombie] Trying to join a party(%i -> %i)", client, PIndex);
		#endif
		
		if(!StrEqual(Info, ""))
		{
			if (IsPartyControlTime())
			{
				if(!(CountPartyMembers(PIndex) >= MAX_PARTY_MEMBER))
				{
					if(IsFreeToJoinParty[PIndex])
					{
						Party_ClientJoin(client, PIndex);
					}
					else if(!IsFreeToJoinParty[PIndex])
					{
						Command_JoinReq(PartyLeader[PIndex], client);
					}
				}
				else
				{
					PrintToChat(client, "\x01[\x04Party\x01] \x04- \x01파티가 꽉 찼습니다.");
				}
			}
			else
			{
				PrintToChat(client, "\x01[\x04Party\x01] \x04- \x01파티 참가 가능 시간이 지났습니다, 라운드 시작 후 %i초 까지만 가능합니다.", PARTY_CONTROL_LOCK_TIME);
			}
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(select == MenuCancel_ExitBack)
		{
			Command_PartyList(client);
		}
	}
	else if(action == MenuAction_End)	CloseHandle(menu);
}

void Command_JoinReq(int Leader, int ReqClient)
{
	if (!IsPartyControlTime())	return;
	Menu menu = new Menu(Menu_JoinReq);
	
	char IndexS[9], ReqClientName[32];
	
	GetClientName(ReqClient, ReqClientName, sizeof(ReqClientName));
	
	// 베테랑이 아닐 때
	if(g_iClassId[ReqClient] != 7)
		menu.SetTitle("-= 파티 가입 요청 =-\n%s님(Lv. %i %s)이 파티 가입을 요청하셨습니다.\n수락 하시겠습니까?", ReqClientName, g_iClassLevel[ReqClient][g_iClassId[ReqClient]-1], g_szConstClassName[g_iClassId[ReqClient]]);
	else // 베테랑일 때
		menu.SetTitle("-= 파티 가입 요청 =-\n%s님(%s)이 파티 가입을 요청하셨습니다.\n수락 하시겠습니까?", ReqClientName, g_szConstClassName[g_iClassId[ReqClient]]);
	
	IntToString(ReqClient, IndexS, sizeof(IndexS));
	
	menu.AddItem(IndexS, "수락");
	menu.AddItem(IndexS, "거절");
	
	menu.ExitButton = true;
	menu.Display(Leader, MENU_TIME_FOREVER);
}

public int Menu_JoinReq(Menu menu, MenuAction action, int client, int select)
{
	if(action == MenuAction_Select)
	{
		char Info[256];
		menu.GetItem(select, Info, sizeof(Info));
		
		int Target = StringToInt(Info);
		if(select == 0)
		{
			PrintToChat(Target, "\x01[\x04Party\x01] \x04- \x01파티 리더가 요청을 수락했습니다.");
			Party_ClientJoin(Target, MyPartyIndex[client]);
		}
		else if(select == 1)
		{
			PrintToChat(Target, "\x01[\x04Party\x01] \x04- \x01파티 리더가 요청을 거절했습니다.");
		}
	}
	else if(action == MenuAction_End)	CloseHandle(menu);
}

void Command_PartySettings(int client)
{
	Menu menu = new Menu(Menu_PartySettings);
	
	menu.SetTitle("-= 파티 설정 변경 =-\n파티명: %s", PartyName[MyPartyIndex[client]]);
	
	menu.AddItem("", "파티 이름 바꾸기");
	
	if(IsPrivateParty[MyPartyIndex[client]])
		menu.AddItem("", "[√]비공개 파티");		// 비공개 상태
	else
		menu.AddItem("", "[  ]비공개 파티");	// 공개 상태
	
	if(IsFreeToJoinParty[MyPartyIndex[client]])
		menu.AddItem("", "[√]자유 가입");	// 자유 가입가능
	else
		menu.AddItem("", "[  ]자유 가입");	// 자유 가입불가능
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_PartySettings(Menu menu, MenuAction action, int client, int select)
{
	if(action == MenuAction_Select)
	{
		if(select == 0)
		{
			InputNewPartyName[client] = true;
			PrintToChat(client, "\x01[\x04Party\x01] \x04- \x01채팅창에 바꿀 파티명을 입력해주세요.");
		}
		int PIndex = MyPartyIndex[client];
		if(select == 1)
		{
			if(IsPrivateParty[PIndex])
			{
				IsPrivateParty[PIndex] = false;
				PrintToChatMembers(PIndex, "\x01[\x04Party\x01] \x04- \x01파티설정이 \x04공개 \x01파티로 바뀌었습니다.");
			}
			else
			{
				IsPrivateParty[PIndex] = true;
				PrintToChatMembers(PIndex, "\x01[\x04Party\x01] \x04- \x01파티설정이 \x04비공개 \x01파티로 바뀌었습니다."); 
			}
			Command_PartySettings(client);
		}
		if(select == 2)
		{
			if(IsFreeToJoinParty[PIndex])
			{
				IsFreeToJoinParty[PIndex] = false;
				PrintToChatMembers(PIndex, "\x01[\x04Party\x01] \x04- \x01파티설정이 \x04자유 가입 비허용 \x01파티로 바뀌었습니다.");
			}
			else
			{
				IsFreeToJoinParty[PIndex] = true;
				PrintToChatMembers(PIndex, "\x01[\x04Party\x01] \x04- \x01파티설정이 \x04자유 가입 허용 \x01파티로 바뀌었습니다."); 
			}
			Command_PartySettings(client);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(select == MenuCancel_ExitBack)
		{
			Command_PartyMain(client);
		}
	}
	else if(action == MenuAction_End)	CloseHandle(menu);
}

void Command_PartyInvite(int client, int page=0)
{
	if (!IsPartyControlTime())
	{
		PrintToChat(client, "\x01[\x04Party\x01] \x04- \x01파티 초대 가능 시간이 지났습니다, 라운드 시작 후 %i초 까지만 가능합니다.", PARTY_CONTROL_LOCK_TIME);
		return;
	}
	
	Menu menu = new Menu(Menu_PartyInvite);
	menu.SetTitle("파티 초대 메뉴");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(!IsFakeClient(i))
			{
				if(i != client)
				{
					char Name[128], InfoS[9];
					GetClientName(i, Name, sizeof(Name));
					IntToString(i, InfoS, sizeof(InfoS));
					
					if(MyPartyIndex[i] > -1)
					{
						if(MyPartyIndex[i] == MyPartyIndex[client])
						{
							Format(Name, sizeof(Name), "%s (내 파티)", Name);
							menu.AddItem(InfoS, Name, ITEMDRAW_DISABLED);
						}
						else
						{
							Format(Name, sizeof(Name), "%s (다른 파티)", Name);
							menu.AddItem(InfoS, Name, ITEMDRAW_DISABLED);
						}
					}
					else if(GetClientTeam(i) != CS_TEAM_T && GetClientTeam(i) != CS_TEAM_CT)
					{
						Format(Name, sizeof(Name), "%s (관전 중)", Name);
						menu.AddItem(InfoS, Name, ITEMDRAW_DISABLED);
					}
					/*
					else if(IsTrading[i] > 0)
					{
						Format(Name, sizeof(Name), "%s (거래 중)", Name);
						menu.AddItem(InfoS, Name, ITEMDRAW_DISABLED);
					}*/
					else	menu.AddItem(InfoS, Name);
				}
			}
		}
	}

	menu.ExitBackButton = true;
	menu.DisplayAt(client, page, MENU_TIME_FOREVER);
}

public int Menu_PartyInvite(Menu menu, MenuAction action, int client, int select)
{
	if(action == MenuAction_Select)
	{
		if (!IsPartyControlTime())
		{
			PrintToChat(client, "\x01[\x04Party\x01] \x04- \x01파티 초대 가능 시간이 지났습니다, 라운드 시작 후 %i초 까지만 가능합니다.", PARTY_CONTROL_LOCK_TIME);
			return;
		}
		char Info[256];
		int Target;
		menu.GetItem(select, Info, sizeof(Info));
		
		Target = StringToInt(Info);
		
		Command_PartyInvitedAsk(client, Target);
		
		int MenuSelectionPosition = RoundToFloor(float(select / GetMenuPagination(menu))) * GetMenuPagination(menu);
		Command_PartyInvite(client, MenuSelectionPosition);
	}
	else if(action == MenuAction_Cancel)
	{
		if(select == MenuCancel_ExitBack)
		{
			Command_PartyMain(client);
		}
	}
	else if(action == MenuAction_End)	CloseHandle(menu);
}

Command_PartyInvitedAsk(Leader, client)
{
	if (!IsPartyControlTime())
		return;
	
	Menu menu = new Menu(Menu_PartyInvitedAsk);
	
	char InfoS[9], LeaderName[32];
	GetClientName(Leader, LeaderName, sizeof(LeaderName));
	IntToString(Leader, InfoS, sizeof(InfoS));

	menu.SetTitle("%s 님이 파티 초대를 하셨습니다.\n수락 하시겠습니까?", LeaderName);
	
	menu.AddItem(InfoS, "수락");
	menu.AddItem("", "거절");
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public Menu_PartyInvitedAsk(Menu menu, MenuAction action, int client, int select)
{
	if(action == MenuAction_Select)
	{
		if(select == 0)
		{
			char Info[256];
			int Leader, PIndex;
			menu.GetItem(select, Info, sizeof(Info));
			
			Leader = StringToInt(Info);
			PIndex = MyPartyIndex[Leader];
			
			if(MyPartyIndex[client] < 0 && 0 <= PIndex && PIndex < MAX_PARTY)
			{
				if (!IsPartyControlTime())
				{
					PrintToChat(client, "\x01[\x04Party\x01] \x04- \x01파티 참가 가능 시간이 지났습니다, 라운드 시작 후 %i초 까지만 가능합니다.", PARTY_CONTROL_LOCK_TIME);
					return;
				}
				if(!(CountPartyMembers(PIndex) >= MAX_PARTY_MEMBER))
				{
					Party_ClientJoin(client, PIndex);
					PrintToChat(Leader, "\x01[\x04Party\x01] \x04- \x01상대방이 초대를 수락했습니다.");
				}
				else
				{
					PrintToChat(client, "\x01[\x04Party\x01] \x04- \x01파티가 꽉 찼습니다.");
					PrintToChat(Leader, "\x01[\x04Party\x01] \x04- \x01파티가 꽉 차, 상대방이 가입할 수 없습니다.");
				}
			}
			else
			{
				PrintToChat(client, "\x01[\x04Party\x01] \x04- \x01이미 다른 파티에 속해있습니다.");
				PrintToChat(Leader, "\x01[\x04Party\x01] \x04- \x01상대방이 이미 다른 파티에 속해있습니다.");
			}
		}
	}
	else if(action == MenuAction_End)	CloseHandle(menu);
}

Command_MemberInfo(client, Target)
{
	Menu menu = new Menu(Menu_MemberInfo);
	
	char InfoS[64], TargetName[32];
	GetClientName(Target, TargetName, sizeof(TargetName));
	
	menu.SetTitle("-= 파티원 정보 보기 =-", TargetName);
	
	// 메뉴 아이템 추가는 알아서 조절하길.
	// 레벨이나 직업 등을 추가할 수 있다.
	
	char DisplayS[256];
	
	Format(DisplayS, sizeof(DisplayS), "직위: %s", (PartyLeader[MyPartyIndex[Target]] == Target) ? "리더" : "멤버");
	menu.AddItem("직위", DisplayS, ITEMDRAW_DISABLED);
	Format(DisplayS, sizeof(DisplayS), "이름: %s", TargetName);
	menu.AddItem("이름", DisplayS, ITEMDRAW_DISABLED);
	if(g_iClassId[Target] > 0)
	{
		Format(DisplayS, sizeof(DisplayS), "병과: %s", g_szConstClassName[g_iClassId[Target]]);
		menu.AddItem("직업", DisplayS, ITEMDRAW_DISABLED);
		// id 7 은 베테랑, 레벨이 없다.
		if(g_iClassId[Target] <= 6)
		{
			Format(DisplayS, sizeof(DisplayS), "레벨: %i", g_iClassLevel[Target][g_iClassId[Target]-1]);
			menu.AddItem("레벨", DisplayS, ITEMDRAW_DISABLED);
		}
	}
	
	if(PartyLeader[MyPartyIndex[client]] == client)
	{
		Format(InfoS, sizeof(InfoS), "Button-1-%i", Target);
		if (IsPartyControlTime())
			menu.AddItem(InfoS, "파티장 위임");
		else
			menu.AddItem(InfoS, "파티장 위임 *위임 가능 시간이 지났습니다*", ITEMDRAW_DISABLED);
		Format(InfoS, sizeof(InfoS), "Button-2-%i", Target);
		menu.AddItem(InfoS, "멤버 추방");
	}
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public Menu_MemberInfo(Menu menu, MenuAction action, int client, int select)
{
	if(action == MenuAction_Select)
	{
		char Info[256], ExplodedInfo[3][256];
		menu.GetItem(select, Info, sizeof(Info));
		ExplodeString(Info, "-", ExplodedInfo, 3, 256);
		
		if(StrEqual(ExplodedInfo[0], "Button", false)) // 버튼으로 쓰이기 위한 인포스트링이다.
		{
			int Select = StringToInt(ExplodedInfo[1]);
			
			if(Select == 1)
			{
				if (IsPartyControlTime())
				{
					if(MyPartyIndex[client] > -1)
					{
						if(PartyLeader[MyPartyIndex[client]] == client)
						{
							int Target = StringToInt(ExplodedInfo[2]);
							Party_LeaderSwap(client, Target);
						}
					}
				}
				else
				{
					PrintToChat(client, "\x01[\x04Party\x01] \x04- \x01파티장 위임 가능 시간이 지났습니다, 라운드 시작 후 %i초 까지만 가능합니다.", PARTY_CONTROL_LOCK_TIME);
				}
			}
			else if(Select == 2)
			{
				if(MyPartyIndex[client] > -1)
				{
					if(PartyLeader[MyPartyIndex[client]] == client)
					{
						int Target = StringToInt(ExplodedInfo[2]);
						Party_ClientExit(Target, true);
					}
				}
			}
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(select == MenuCancel_ExitBack)
		{
			Command_PartyMain(client);
		}
	}
	else if(action == MenuAction_End)	CloseHandle(menu);
}

Command_LeaderExit(int client)
{
	/*
	시간이 지났다 하더라도 파티 탈퇴할 때에는 위임 가능하도록 하자.
	*/
	if(PartyLeader[MyPartyIndex[client]] == client)
	{
		Menu menu = new Menu(Menu_LeaderExit);
		
		char InfoS[64];
		
		menu.SetTitle("-= 파티 리더 탈퇴 =-\n파티 리더를 위임해 줄 멤버를 선택해주세요.");
		
		if(CountPartyMembers(MyPartyIndex[client]) > 1)
			menu.AddItem("랜덤 선택", "임의의 멤버에게 위임");
		else
			menu.AddItem("랜덤 선택", "임의의 멤버에게 위임 *위임할 수 있는 멤버가 없습니다*", ITEMDRAW_DISABLED);
		
		menu.AddItem("해산", "파티 해산");
		
		for(int i;i < MAX_PARTY_MEMBER;i++)
		{
			if(PartyMembers[MyPartyIndex[client]][i] > 0)
			{
				if(PartyMembers[MyPartyIndex[client]][i] != client)
				{
					char Name[32];
					
					GetClientName(PartyMembers[MyPartyIndex[client]][i], Name, sizeof(Name));
					Format(InfoS, sizeof(InfoS), "Member-%i", PartyMembers[MyPartyIndex[client]][i]);
					menu.AddItem(InfoS, Name);
				}
			}
		}
		
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public Menu_LeaderExit(Menu menu, MenuAction action, int client, int select)
{
	if(action == MenuAction_Select)
	{
		char Info[256], ExplodedInfo[2][256];
		menu.GetItem(select, Info, sizeof(Info));
		ExplodeString(Info, "-", ExplodedInfo, 2, 256);
		
		int ExitAction = -1;
		
		if(select == 0)
		{
			if(CountPartyMembers(MyPartyIndex[client]) > 1)
				ExitAction = 0;
			else
				ExitAction = -1;
		}
		if(select == 1)
		{
			ExitAction = -1;
		}
		
		if(StrEqual(ExplodedInfo[0], "Member", false))
		{
			if(MyPartyIndex[client] > -1)
			{
				if(PartyLeader[MyPartyIndex[client]] == client)
				{
					ExitAction = StringToInt(ExplodedInfo[1]);
				}
			}
		}
		
		Party_ClientExit(client, false, ExitAction);
	}
	else if(action == MenuAction_Cancel)
	{
		if(select == MenuCancel_ExitBack)
		{
			Command_PartyMain(client);
		}
	}
	else if(action == MenuAction_End)	CloseHandle(menu);
}


/**********************************************************************************************
엑스레이 글로우 관련 함수
***********************************************************************************************/
public void PrepareToSetupGlow(any client)
{
	// Validate client on delayed callback
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		char model[PLATFORM_MAX_PATH];
	
		int team = GetClientTeam(client);
		
		// Retrieve current player model
		char skinadrs[128];
		int CustomSkinIndex = CPS_GetSkin(client);
		
		DDS_GetItemInfo(DDS_GetUserItemID(client, team), 3, skinadrs);
		if(CPS_HasSkin(client) && (DDS_GetUserItemID(client, team) > 0) && DDS_GetItemUse(team) && CustomSkinIndex != INVALID_ENT_REFERENCE)
		{
			CreatePlayerModelProp(client, CustomSkinIndex, skinadrs);
		}
		else
		{
			GetClientModel(client, model, sizeof(model));
			CreatePlayerModelProp(client, client, model);
		}

		// Validate skin entity by SDKHookEx native return
		if (SDKHookEx(g_iPlayerGlowObject[client], SDKHook_SetTransmit, OnSetTransmit))
		{
			if(client == Party_GetPartyLeader(Party_GetClientPartyIndex(client)))
				SetupGlow(g_iPlayerGlowObject[client], 63, 63, 255, 255);
			else
				SetupGlow(g_iPlayerGlowObject[client], 127, 127, 255, 255);
		}
	}
}


void RemoveSkin(int client)
{
	if(IsValidEntity(g_iPlayerGlowObject[client]))
	{
		AcceptEntityInput(g_iPlayerGlowObject[client], "Kill");
	}
	
	g_iPlayerGlowObject[client] = INVALID_ENT_REFERENCE;
}

#define EF_BONEMERGE                (1 << 0)
#define EF_NOSHADOW                 (1 << 4)
#define EF_NORECEIVESHADOW          (1 << 6)
#define EF_PARENT_ANIMATES          (1 << 9)
int CreatePlayerModelProp(int client, int targetEnt, char[] sModel)
{
	RemoveSkin(client);
	int Ent = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(Ent, "model", sModel);
	DispatchKeyValue(Ent, "disablereceiveshadows", "1");
	DispatchKeyValue(Ent, "disableshadows", "1");
	DispatchKeyValue(Ent, "solid", "0");
	DispatchKeyValue(Ent, "spawnflags", "1");
	SetEntProp(Ent, Prop_Send, "m_CollisionGroup", 11);
	DispatchSpawn(Ent);
	SetEntProp(Ent, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_NOSHADOW|EF_PARENT_ANIMATES);
	
	SetVariantString("!activator");
	AcceptEntityInput(Ent, "SetParent", targetEnt, Ent, 0);
	
	SetVariantString("primary");
	AcceptEntityInput(Ent, "SetParentAttachment", Ent, Ent, 0);
	
	SetEntPropEnt(Ent, Prop_Send, "m_hOwnerEntity", client);
	
//	SetEntityRenderMode(Ent, RENDER_NONE);
	SetEntityRenderMode(Ent, RENDER_TRANSALPHA);
	SetEntityRenderColor(Ent, 255, 255, 255, 0);
	
	g_iPlayerGlowObject[client] = EntIndexToEntRef(Ent);
	return Ent;
}

void SetupGlow(int entity, int r, int g, int b, int a, bool glow=true)
{
	static int offset;

	// Get sendprop offset for prop_dynamic_override
	if (!offset && (offset = GetEntSendPropOffs(entity, "m_clrGlow")) == -1)
	{
		LogError("Unable to find property offset: \"m_clrGlow\"!");
		return;
	}

	// Enable glow for custom skin
	if(glow)
		SetEntProp(entity, Prop_Send, "m_bShouldGlow", true, true);
	else
		SetEntProp(entity, Prop_Send, "m_bShouldGlow", false, true);

	// So now setup given glow colors for the skin
	SetEntData(entity, offset, r, _, true);    // Red
	SetEntData(entity, offset + 1, g, _, true); // Green
	SetEntData(entity, offset + 2, b, _, true); // Blue
	SetEntData(entity, offset + 3, a, _, true); // Alpha
}

public Action OnSetTransmit(int entity, int client)
{
	if(!IsValidPlayer(client))
		return Plugin_Stop;
	
	// 숨겨진 가짜 플레이어 모델이 본인 꺼라면 보여주지 않는다.
	if (entity == EntRefToEntIndex(g_iPlayerGlowObject[client]))
		return Plugin_Stop;
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	if(!IsValidPlayer(owner))
		return Plugin_Stop;
	
	if(!IsClientZombie(owner) && !IsClientZombie(client))
	{
		if(Party_GetClientPartyIndex(owner) > -1 && Party_GetClientPartyIndex(client) > -1 && Party_GetClientPartyIndex(owner) == Party_GetClientPartyIndex(client))
		{
			return Plugin_Continue;
		}
	}
	
	return Plugin_Stop;
}

/**********************************************************************************************
엑스레이 글로우 관련 함수 끝
***********************************************************************************************/

/**
 * 클라이언트를 리더로 하여 파티를 생성한다.
 * 
 * @param client 			클라이언트 인덱스
 * @param PartyName			파티 이름
 * @param PrivateParty		비공개 파티 여부
 * @param FreeToJoin		자유 가입 가능 여부
 * @param notify			파티 생성 사실을 client에게 알릴지의 여부
 * @return					새 파티의 인덱스
 */
stock int Party_Create(int client, const char szTempPartyName[256], bool bPrivateParty=false, bool bFreeToJoin=true, bool bNotify=true)
{
	int PartyIndex = MatchUseablePartyIndex();
	
	if(PartyIndex != -1)
	{
		PartyLeader[PartyIndex] = client;
		PartyMembers[PartyIndex][0] = client;
		MyPartyIndex[client] = PartyIndex;
		IsActivatedParty[PartyIndex] = true;
		PartyName[PartyIndex] = szTempPartyName;
		IsPrivateParty[PartyIndex] = bPrivateParty;
		IsFreeToJoinParty[PartyIndex] = bFreeToJoin;
		
		PrepareToSetupGlow(client);
		
		#if defined _DEBUG_
			PrintToServer("[BST Zombie] Party Created(Host: %i -> Party: %i)", client, PartyIndex);
		#endif
		
		if (bNotify)
		{
			//PrintToChat(client, "\x01[\x04Party\x01] \x04- \x04%s \x01파티가 생성되었습니다. (%s 파티 | 자유 가입 %s)", ExplodedInfo[0], (IsPrivateParty[PartyIndex]) ? "비공개" : "공개", (IsFreeToJoinParty[PartyIndex]) ? "허용" : "비허용");
			PrintToChat(client, "\x01[\x04Party\x01] \x04- \x01파티가 생성되었습니다.");
			PrintToChat(client, "\x03파티명\x01: \x04%s", PartyName[PartyIndex]);
			PrintToChat(client, "\x03공개 파티 여부\x01:\x04 %s", (IsPrivateParty[PartyIndex]) ? "비공개" : "공개");
			PrintToChat(client, "\x03자유 가입\x01:\x04 %s", (IsFreeToJoinParty[PartyIndex]) ? "허용" : "비허용");
		}
	}
	
	return PartyIndex;
}

/**
 * 클라이언트를 파티에 입장시킨다.
 * 
 * @param client 			클라이언트 인덱스
 * @param PIndex 			가입시키려는 파티 인덱스
 * @noreturn				
 */
stock void Party_ClientJoin(int client, int PIndex)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] Party_ClientJoin(%i -> %i)", client, PIndex);
	#endif
	
	if (!IsPartyControlTime())	return;
	
	if(IsActivatedParty[PIndex])
	{
		int EmptyPosition;
		EmptyPosition = GetEmptyPositionInParty(PIndex);
		
		MyPartyIndex[client] = PIndex;
		PartyMembers[PIndex][EmptyPosition] = client;
		PrintToChat(client, "\x01[\x04Party\x01] \x04- \x01\x04%s \x01에 참가하셨습니다.", PartyName[PIndex]);
		
		char CName[32];
		GetClientName(client, CName, sizeof(CName));
		
		PrintToChatMembers(PIndex, "\x01[\x04Party\x01] \x04- \x01\x04%s \x01님이 파티에 참가하셨습니다.", CName);
		
		PrepareToSetupGlow(client);
	}
	else
	{
		PrintToChat(client, "\x01[\x04Party\x01] \x04- \x01파티 참가 과정에서 오류가 발생했습니다. (Party Number: %i)", PIndex);
	}
}

/**
 * 클라이언트를 파티에서 퇴장시킨다.
 * 
 * @param client 			클라이언트 인덱스
 * @param Kicked			해당 클라이언트가 강제로 추방당하는 상황이라면 true, 아니라면 false
 * @param ExitAction		클라이언트가 파티 리더일 시, 이후 파티 상황에 대한 설정, (-1 = 파티 해산, 0 = 파티 해산(인원이 없을 때) 혹은 랜덤 위임, 1+ = 해당 유저에게 리더 위임)
 * @param Broadcast			파티 멤버에게 알릴 것인가? 알린다면 true, 아니라면 false
 * @noreturn				
 */
stock void Party_ClientExit(int client, bool Kicked=false, int ExitAction=0, bool Broadcast=true)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] Party_ClientExit(%i)", client);
	#endif
	
	// 탈퇴 처리에 영향을 미치지 않는 변수 초기화
	InputNewPartyName[client] = false;
	
	Party_ValidateGlowObject(MyPartyIndex[client]);
	
	if(-1 < MyPartyIndex[client] && MyPartyIndex[client] < MAX_PARTY)
	{		
		char PrintMsgCs[256], PrintMsgPs[256], PrintMsgAction[256];
		
		int PIndex = MyPartyIndex[client];
		
		if(!Kicked)
			Format(PrintMsgCs, sizeof(PrintMsgCs), "\x01[\x04Party\x01] \x04- \x01파티에서 나가셨습니다.");
		else
			Format(PrintMsgCs, sizeof(PrintMsgCs), "\x01[\x04Party\x01] \x04- \x01파티에서 추방 당하셨습니다.");
		
		char CName[32];
		GetClientName(client, CName, sizeof(CName));
		
		if(!Kicked)
			Format(PrintMsgPs, sizeof(PrintMsgPs), "\x01[\x04Party\x01] \x04- \x01\x04%s \x01님이 파티에서 나가셨습니다.", CName);
		else
			Format(PrintMsgPs, sizeof(PrintMsgPs), "\x01[\x04Party\x01] \x04- \x01\x04%s \x01님이 파티에서 추방 당하셨습니다.", CName);
		
		bool Disbanding = false;
		if(PartyLeader[PIndex] == client)
		{			
			if(ExitAction == -1)
			{
				Format(PrintMsgAction, sizeof(PrintMsgAction), "\x01[\x04Party\x01] \x04- \x01파티장이 파티에서 나갔으므로 파티가 해산됩니다.");
				Party_Disband(PIndex);
			}
			else if(ExitAction == 0)
			{
				if(CountPartyMembers(PIndex, false) <= 0)
				{
					Format(PrintMsgAction, sizeof(PrintMsgAction), "\x01[\x04Party\x01] \x04- \x01파티장이 파티에서 나갔으므로 파티가 해산됩니다.");
					Disbanding = true;
				}
				else
				{
					int RandomTarget = GetRandomMember(PIndex, false);
					
					if(MyPartyIndex[client] == MyPartyIndex[RandomTarget])
					{
						if(RandomTarget > 0 && RandomTarget <= MaxClients && IsClientInGame(RandomTarget))
						{
							Party_LeaderSwap(client, RandomTarget, false);
							
							char LeaderName[32];
							GetClientName(RandomTarget, LeaderName, sizeof(LeaderName));
							
							Format(PrintMsgAction, sizeof(PrintMsgAction), "\x01[\x04Party\x01] \x04- \x01파티장이 파티에서 나갔으므로 \x03%s \x01님이 새로운 리더가 됩니다.", LeaderName);
						}
						else
						{
							Format(PrintMsgAction, sizeof(PrintMsgAction), "\x01[\x04Party\x01] \x04- \x01파티장이 파티에서 나갔으므로 파티가 해산됩니다.");
							Disbanding = true;
						}
					}
					else
					{
						Format(PrintMsgAction, sizeof(PrintMsgAction), "\x01[\x04Party\x01] \x04- \x01파티장이 파티에서 나갔으므로 파티가 해산됩니다.");
						Disbanding = true;
					}
				}
			}
			else if(ExitAction > 0)
			{
				int Target = ExitAction;
				if(MyPartyIndex[client] == MyPartyIndex[Target])
				{
					if(Target > 0 && Target <= MaxClients && IsClientInGame(Target))
					{
						Party_LeaderSwap(client, Target, false);
						
						char LeaderName[32];
						GetClientName(Target, LeaderName, sizeof(LeaderName));
						
						Format(PrintMsgAction, sizeof(PrintMsgAction), "\x01[\x04Party\x01] \x04- \x01파티장이 파티에서 나갔으므로 \x03%s \x01님이 새로운 리더가 됩니다.", LeaderName);
					}
					else
					{
						Format(PrintMsgAction, sizeof(PrintMsgAction), "\x01[\x04Party\x01] \x04- \x01파티장이 파티에서 나갔으므로 파티가 해산됩니다.");
						Disbanding = true;
					}
				}
				else
				{
					Format(PrintMsgAction, sizeof(PrintMsgAction), "\x01[\x04Party\x01] \x04- \x01파티장이 파티에서 나갔으므로 파티가 해산됩니다.");
					Disbanding = true;
				}
			}
		}
		
		MyPartyIndex[client] = -1;
		int Position = GetClientPositionInParty(client, PIndex);
		PartyMembers[PIndex][Position] = -1;
		
		Party_SortPosition(PIndex);
		if(CountPartyMembers(PIndex) <= 0)
		{
			Disbanding = true;
		}
		
		PrintToChat(client, PrintMsgCs);
		if(Broadcast)
		{
			PrintToChatMembers(PIndex, PrintMsgPs);
		}
		PrintToChatMembers(PIndex, PrintMsgAction);
		
		if(Disbanding)
		{
			Party_Disband(PIndex);
		}
	}
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] Party_ClientExitPost(%i)", client);
	#endif
}

/**
 * 클라이언트의 파티 인덱스를 가져온다.
 * 
 * @param client 			클라이언트 인덱스
 * @return					클라이언트의 파티 인덱스
 */
stock int Party_GetClientPartyIndex(int client)
{
	return MyPartyIndex[client];
}

/**
 * 파티의 리더를 얻어낸다.
 * 
 * @param PIndex 			파티 인덱스
 * @return					파티의 리더 인덱스
 */
stock int Party_GetPartyLeader(int PIndex)
{
	if(0 <= PIndex && PIndex < MAX_PARTY)
		return PartyLeader[PIndex];
	else
		return -1;
}

/**
 * 클라이언트가 파티의 이름을 바꾸는 과정에서 채팅을 입력하는 대기 상태인지 체크한다.
 * 
 * @param client 			클라이언트 인덱스
 * @return					클라이언트의 채팅 입력 대기 상태의 여부
 */
stock bool Party_IsClientChangingPartyName(int client)
{
	return InputNewPartyName[client];
}

/**
 * 파티의 이름을 변경한다.
 * 
 * @param PIndex 			파티 인덱스
 * @param PName 			바꿀 이름
 * @param Broadcast 			변경 사실을 파티 멤버에게 알리려면 true, 아니면 false
 * @noreturn
 */
stock void Party_ChangeName(int PIndex, const char[] PName, bool Broadcast=true, bool IsManual)
{
	if(PIndex > -1 && PIndex <= MAX_PARTY)
	{
		Format(PartyName[PIndex], sizeof(PartyName[]), "%s", PName);
		
		if(Broadcast)
			PrintToChatMembers(PIndex, "\x01[\x04Party\x01] \x04- \x01파티명이 \x04%s \x01(으)로 바뀌었습니다.", PName);
			
		if(IsManual)
			InputNewPartyName[PartyLeader[PIndex]] = false;
	}
}

/**
 * 파티의 멤버 배열을 정리한다.
 * 
 * @param PIndex 			파티 인덱스
 * @noreturn
 */
stock void Party_SortPosition(int PIndex)
{
	for(int i;i < MAX_PARTY_MEMBER;i++)
	{
		int EmptyPosition = GetEmptyPositionInParty(PIndex);
		if(EmptyPosition < i)
		{
			if(PartyMembers[PIndex][i] > 0)
			{
				PartyMembers[PIndex][EmptyPosition] = PartyMembers[PIndex][i];
				PartyMembers[PIndex][i] = -1;
			}
		}
	}
}

/**
 * 파티의 리더와 멤버의 자리를 바꾼다
 * 
 * @param Leader 			현재 리더 인덱스
 * @param Target 			새 리더가 될 멤버 인덱스
 * @param Broadcast 		변경 사실을 파티 멤버에게 알리려면 true, 아니면 false
 * @noreturn
 */
stock void Party_LeaderSwap(int Leader, int Target, bool Broadcast=true)
{
	if(MyPartyIndex[Leader] > -1 && MyPartyIndex[Target] > -1)
	{
		if(PartyLeader[MyPartyIndex[Leader]] == Leader && PartyLeader[MyPartyIndex[Target]] == Leader)
		{
			PartyLeader[MyPartyIndex[Leader]] = Target;
			
			int Leader_Position, Target_Position;
			
			Leader_Position = GetClientPositionInParty(Leader);
			Target_Position = GetClientPositionInParty(Target);
			
			int Temp_Leader_Index = PartyMembers[MyPartyIndex[Leader]][Leader_Position];
			int Temp_Target_Index = PartyMembers[MyPartyIndex[Target]][Target_Position];
			
			if(Temp_Leader_Index != -1 && Temp_Target_Index != -1)
			{
				PartyMembers[MyPartyIndex[Leader]][Leader_Position] = Temp_Target_Index;
				PartyMembers[MyPartyIndex[Target]][Target_Position] = Temp_Leader_Index;
			}
			
			char LeaderName[32], TargetName[32];
			
			GetClientName(Leader, LeaderName, sizeof(LeaderName));
			GetClientName(Target, TargetName, sizeof(TargetName));
			
			// 파티 이름에 파티장의 이름이 있다면 바꿔준다.
			// 이 과정은 Party_ChangeName() 함수를 거치지 않는다.
			if(StrContains(PartyName[MyPartyIndex[Target]], LeaderName) != -1)
				ReplaceString(PartyName[MyPartyIndex[Target]], sizeof(PartyName[]), LeaderName, TargetName);
				
			if(Broadcast)
				PrintToChatMembers(MyPartyIndex[Target], "\x01[\x04Party\x01] \x04- \x01파티장이 \x04%s \x01님으로 바뀌었습니다.", TargetName);
				
			if(IsValidEntity(g_iPlayerGlowObject[Leader]))
			{
				SetupGlow(g_iPlayerGlowObject[Leader], 127, 127, 255, 255);
			}
			if(IsValidEntity(g_iPlayerGlowObject[Target]))
			{
				SetupGlow(g_iPlayerGlowObject[Target], 31, 31, 255, 255);
			}
			
			if(!IsPlayerAlive(Target))
			{
				PrintToChatMembers(MyPartyIndex[Target], "%s\x03파티장\x01인 \x03%N\x01님이 좀비로 감염되셨습니다!", PREFIX, Target);
				PrintToChatMembers(MyPartyIndex[Target], "%s\x03파티장\x01이 죽어 사기력이 저하되었습니다.", PREFIX);
				
				Party_DestroyMorale(MyPartyIndex[Target], 1676);
			}
		}
	}
}

/**
 * 파티를 해산시킨다.
 * 
 * @param PIndex 			파티 인덱스
 * @noreturn
 */
stock Party_Disband(PIndex)
{
	PartyLeader[PIndex] = -1;
	for(int i;i < MAX_PARTY_MEMBER;i++)
	{
		if(PartyMembers[PIndex][i] > 0)
			MyPartyIndex[PartyMembers[PIndex][i]] = -1;
		PartyMembers[PIndex][i] = -1;
	}
	PartyName[PIndex] = NULL_STRING;
	IsActivatedParty[PIndex] = false;
	IsPrivateParty[PIndex] = false;
}

void Party_Reset()
{
	ClearArray(QuickPartyMatchList);
	for(int i;i <= MaxClients;i++)
	{
		MyPartyIndex[i] = -1;
		InputNewPartyName[i] = false;
	}
	for(int i;i < MAX_PARTY;i++)
	{
		PartyLeader[i] = -1;
		PartyName[i] = NULL_STRING;
		IsActivatedParty[i] = false;
		IsPrivateParty[i] = false;
		IsFreeToJoinParty[i] = false;
		for(int m;m < MAX_PARTY_MEMBER;m++)
			PartyMembers[i][m] = -1;
	}
}

/**
 * 파티 제어(참가 및 초대, 파티장 위임)이 가능한 시간인가?
 * 
 * @return					파티 조작이 가능한 시간이라면 true, 아니라면 false
 */
stock bool IsPartyControlTime()
{
	#if defined PARTY_CONTROL_LOCK_TIME
		return (GetRoundTime(false) < PARTY_CONTROL_LOCK_TIME || IsWarmupPeriod());
	#else
		return true;
	#endif
}

/**
 * 활성화 또는 비활성화된 파티 갯수를 얻어낸다.
 * 
 * @param Joined 			활성화된 파티 갯수를 얻어내려면 true, 반대라면 false
 * @return					파티의 갯수
 */
stock int CountParties(bool Activated)
{
	int Count;
	for(int i;i < MAX_PARTY;i++)
	{
		if(Activated)
		{
			if(IsActivatedParty[i])
			{
				Count++;
			}
		}
		else
		{
			if(!IsActivatedParty[i])
			{
				Count++;
			}
		}
	}
	
	return Count;
}

/**
 * 파티에 가입되었거나 가입되지 않은 클라이언트 수를 얻어낸다.
 * 
 * @param Joined 			파티에 가입된 클라이언트 수를 얻어내려면 true, 반대라면 false
 * @return					클라이언트의 수
 */
stock int CountClients(bool Joined)
{
	int Count;
	for(int i = 1;i < MaxClients;i++)
	{
		if(Joined)
		{
			if(IsClientInGame(i) && i > 0 && i <= MaxClients)
			{
				if(MyPartyIndex[i] > -1)
				{
					Count++;
				}
			}
		}
		else
		{
			if(IsClientInGame(i) && i > 0 && i <= MaxClients)
			{
				if(MyPartyIndex[i] <= -1)
				{
					Count++;
				}
			}
		}
	}
	
	return Count;
}

/**
 * 파티 멤버의 수를 얻어낸다.
 * 
 * @param PIndex 			파티 인덱스
 * @param IncLeader 		파티의 리더를 포함할 것인가, 포함한다면 true, 포함하지 않는다면 false
 * @return					해당 파티의 멤버 수
 */
stock CountPartyMembers(int PIndex, bool IncLeader=true)
{
	if(PIndex < 0 && PIndex >= MAX_PARTY)
		return -1;
	
	int Count;
	for(int i;i < MAX_PARTY_MEMBER;i++)
	{
		if(PartyMembers[PIndex][i] > 0 && IsClientInGame(PartyMembers[PIndex][i]))
		{
			if(IncLeader)
			{
				Count++;
			}
			else
			{
				if(PartyLeader[PIndex] != PartyMembers[PIndex][i])
				{
					Count++;
				}
			}
		}
	}
	
	return Count;
}

/**
 * 파티 내에서 클라이언트의 위치를 얻어낸다.
 *
 * @param client			클라이언트 인덱스
 * @param PIndex			파티 인덱스
 * @return					클라이언트의 파티 내부에서의 위치
 */
stock int GetClientPositionInParty(int client, int PIndex = -1)
{
	int Position;
	if(PIndex == -1)	PIndex = MyPartyIndex[client];
	if(PIndex > -1)
	{
		for(int i;i < MAX_PARTY_MEMBER;i++)
		{
			if(PartyMembers[PIndex][i] == client)
			{
				Position = i;
				break;
			}
		}
	}
	else
	{
		Position = -1;
	}
	
	return Position;
}

/**
 * 사용가능한 파티 인덱스 자리를 얻어낸다.
 * 
 * @return					파티 변수의 빈 배열 인덱스 번호 찾을 수 없다면 -1을 리턴한다.
 */
stock int MatchUseablePartyIndex()
{
	for(int i;i < MAX_PARTY;i++)
	{
		if(!IsActivatedParty[i] && PartyLeader[i] <= 0)
		{
			return i;
		}
	}
	
	return -1;
}

/**
 * 파티 내에서 비어있는 배열위치를 얻어낸다.
 * 
 * @param PIndex 			파티 인덱스
 * @return					파티원 변수의 빈 배열 인덱스 번호
 */
stock int GetEmptyPositionInParty(int PIndex)
{
	int EmptyPosition;
	bool ExistEmptyPosition = false;
	for(int i;i < MAX_PARTY_MEMBER;i++)
	{
		if(PartyMembers[PIndex][i] <= 0)
		{
			EmptyPosition = i;
			ExistEmptyPosition = true;
			break;
		}
	}
	
	if(!ExistEmptyPosition)
		EmptyPosition = -1;
	
	return EmptyPosition;
}

/**
 * 파티 내부의 아무 멤버를 얻어낸다.
 * 
 * @param PIndex 			파티 인덱스
 * @param IncLeader 		파티의 리더를 포함할 것인가, 포함한다면 true, 포함하지 않는다면 false
 * @return					임의 멤버의 인덱스
 */
stock int GetRandomMember(int PIndex, bool IncLeader=true)
{
	int[] clients = new int[MaxClients + 1];
	int clientCount;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(MyPartyIndex[i] == PIndex)
			{
				if(IncLeader)
				{
					clients[clientCount++] = i;
				}
				else
				{
					if(PartyLeader[PIndex] != i)
					{
						clients[clientCount++] = i;
					}
				}
			}
		}
	}
	
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];	
}

/**
 * 해당 파티 내부에 속한 모든 멤버의 채팅창에 문자를 출력시킨다.
 *
 * @param PIndex		파티 인덱스
 * @param format		Formatting rules.
 * @param ...			Variable number of format parameters.
 * @noreturn
 */
stock void PrintToChatMembers(int PIndex, const char[] format, any:...)
{	
	if(PIndex > -1 && PIndex < MAX_PARTY)
	{
		char buffer[192];
		
		for(int i; i < MAX_PARTY_MEMBER; i++)
		{
			if(PartyMembers[PIndex][i] > 0)
			{
				if(IsClientInGame(PartyMembers[PIndex][i]))
				{
					SetGlobalTransTarget(PartyMembers[PIndex][i]);
					VFormat(buffer, sizeof(buffer), format, 3);
					PrintToChat(PartyMembers[PIndex][i], "%s", buffer);
				}
			}
		}
	}
}

void MatchQuickParty()
{
	if(GetArraySize(QuickPartyMatchList) > 0)
	{
		for (int i = 0; i < GetArraySize(QuickPartyMatchList); i++)
		{
			int client = GetClientOfUserId(GetArrayCell(QuickPartyMatchList, i));
			if(MatchClientToParty(client))
			{
				EraseClientOnList(client, false);
			}
		}
	}
}

// 클라이언트 빠른 매칭 시도
// 파티 매칭에 성공했다면 true, 실패했으면 false
bool MatchClientToParty(int client)
{
	if (!IsPartyControlTime())
		return false;
	
	// 이미 파티가 있다!?
	if(MyPartyIndex[client] > -1)
	{
		EraseClientOnList(client, false);
	}
	
	bool foundParty = false;
	
	for(int i=0; i < MAX_PARTY; i++)
	{
		if(IsActivatedParty[i] && PartyLeader[i] > 0)
		{
			if(!IsPrivateParty[i] && IsFreeToJoinParty[i])
			{
				int MemberCount = CountPartyMembers(i);
				
				// 빈자리가 있을 때
				if(MemberCount < MAX_PARTY_MEMBER)
				{
					Party_ClientJoin(client, i);
					foundParty = true;
					break;
				}
			}
		}
	}
	
	if(!foundParty)
	{
		// 들어갈 수 있는 파티가 없으므로 파티를 만든다.
		// 빈 파티 자리가 있을 때
		if(CountParties(false) > 0)
		{
			char DefaultPName[256], Name[32];
							
			GetClientName(client, Name, sizeof(Name));
			Format(DefaultPName, sizeof(DefaultPName), "%s%s", Name, PARTY_DEFAULT_NAME_SUFFIX);
			if(Party_Create(client, DefaultPName) != -1)
			{
				foundParty = true;
			}
		}
	}
	
	return foundParty;
}

void ListQuickParty(int client)
{
	int userID = GetClientUserId(client);
	EraseClientOnList(client, false);

	PushArrayCell(QuickPartyMatchList, userID);
	
	// 이 함수는 빠른 파티 참가를 신청할 때에만 호출된다.
	// 어레이에 적용한 뒤 파티 제어가 가능하다면 바로 체크해준다.
	if (IsPartyControlTime())
	{
		if(MatchClientToParty(client))
		{
			EraseClientOnList(client, false);
		}
	}
}

void EraseClientOnList(int client, bool notify=false)
{
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] EraseClientOnList(%i)", client);
	#endif
	
	if(IsClientListedOnQuickPartyMatching(client))
	{
		int userID = GetClientUserId(client);
		
		int index = FindValueInArray(QuickPartyMatchList, userID);
		if(index != -1)
		{
			RemoveFromArray(QuickPartyMatchList, index);
		}
		
		if(IsValidClient(client) && notify)
			PrintToChat(client, "\x01[\x04Party\x01] \x04- \x04빠른 파티 참가 신청이 취소되었습니다.");
	}
	
	#if defined _DEBUG_
		PrintToServer("[BST Zombie] EraseClientOnListPost(%i)", client);
	#endif
}

stock bool IsClientListedOnQuickPartyMatching(int client)
{
	return (FindValueInArray(QuickPartyMatchList, GetClientUserId(client)) != -1);
}

stock int GetQuickMatchListCount()
{
	return GetArraySize(QuickPartyMatchList);
}