// 게임을 진행하기위해 필요한 최소 인원
#define MIN_PLAYER_TO_PLAY 2

public Action BlockWarmupNoticeTextMsg(UserMsg msg_id, Handle pb, const int[] players, int playersNum, bool reliable, bool init) 
{
	char buffer[40]; 
	PbReadString(pb, "params", buffer, sizeof(buffer), 0);
	
//	PrintToServer("OMG! IT'S TEXT MSG!, %i\n%s", PbReadInt(pb, "msg_dst"), buffer);
	
	if(PbReadInt(pb, "msg_dst") == 3) 
	{
		// 준비시간이 다 되면 게임이 시작된다는 메세지를 없앤다.
		if(StrEqual(buffer, "#SFUI_Notice_Match_Will_Start_Chat", false))
		{
			if(GetPlayerCount() < MIN_PLAYER_TO_PLAY)
			{
				#if defined _DEBUG_
					PrintToServer("[BST Zombie] BlockWarmupNoticeTextMsg()");
				#endif
				return Plugin_Handled;
			}
		} 
	}
	return Plugin_Continue;
}

bool g_bRestartChecked = false;

public void OnGameFrame()
{
	// 준비 시간일 때
	if(IsWarmupPeriod())
	{
		GameRules_SetProp("m_numGlobalGiftsGiven", -1, 1);
		GameRules_SetProp("m_numGlobalGifters", -1, 1);
		GameRules_SetProp("m_numGlobalGiftsPeriodSeconds", -1, 1);
		if(GetPlayerCount() < MIN_PLAYER_TO_PLAY)
		{
			PrintHintTextToAll("최소 <font color='#0fff0f'>%i</font>명 이상이어야 플레이가 가능합니다.", MIN_PLAYER_TO_PLAY);
			SetWarmupStartTime(GetGameTime()+0.5);
			return;
		}
			
		// 채택!
		if(GetRestartRoundTime() > 0.0)
		{
			if(!g_bRestartChecked)
			{
				if(GetWarmupLeftTime() < 0.0)
				{
					g_bRestartChecked = true;
					PrintToChatAll("준비 시간 종료! %i초 뒤 게임 시작!", RoundToNearest(GetRestartRoundTime()-GetGameTime()));
				}
			}
		}
		else
		{
			if(g_bRestartChecked)	g_bRestartChecked = false;
		}
		float flWarmupLeftTime = GetWarmupLeftTime();
		if(flWarmupLeftTime > 0)
			PrintHintTextToAll("지금은 준비 시간입니다: <font color='#0fff0f'>%.1f</font>", flWarmupLeftTime);
		else
			PrintHintTextToAll("준비 시간이 끝났습니다.\n<font color='#ffff0f'>%.1f</font>초 뒤 게임을 시작합니다.", GetRestartRoundTime()-GetGameTime());
	}
	else // 준비 시간이 아닐 때
	{
		if(!g_bGameStarted && g_bHostSelectionTime)
		{
			float flSelectionTime = GetRoundStartTime() + ZOMBIE_SELECTION_TIME;
			float flGameTime = GetGameTime();
			// 아직 선택 시간이 끝나지 않은 경우.
			if(flSelectionTime > flGameTime)
			{
				// 미리 선택된 좀비가 나가거나 한 경우.
				if(!IsValidPlayer(g_iHostZombie) || g_iHostZombie == -1){
					SelectHostZombie();
					return;
				}
				PrintCenterTextAdmin(false, "좀비 바이러스 발병까지 <font color='#ff3f3f'>%.1f</font>초", flSelectionTime-flGameTime);
				if(IsValidClient(g_iHostZombie))
					PrintCenterTextAdmin(true, "좀비 바이러스 발병까지 <font color='#ff3f3f'>%.1f</font>초\n<font color='#ff3f3f'>%N</font>님이 숙주입니다!", flSelectionTime-flGameTime, g_iHostZombie);
			}
			else
			{
				SetGame();
			}
		}
		if(GetRoundLeftTime() <= 0)
		{
			if(!g_bRoundEnded)
			{
				// 대테러리스트 승리, 라운드 시간이 끝남!
				// TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO
				// 좀비를 모두 죽였을 때에는 아래 HumanWin() 함수, 생존한 인간 보상 함수가 발동하지 않는다.
				// 추후에 추가할 때에는 이쪽의 호출부를 이식하여 round_end 훅으로 이동하도록 한다.
				// TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO
				HumanWin();
				CS_TerminateRound(GetConVarFloat(FindConVar("mp_round_restart_delay")), CSRoundEnd_CTWin);
				g_bRoundEnded = true;
			}
		}
	}
}


/*******************************************************
 S T O C K  F U N C T I O N S
*******************************************************/
/**
 * 현재 라운드가 준비 시간인지 아닌지를 알아냅니다.
 * 
 * @return		현재 준비 시간이라면 true, 아니라면 false.
 */
stock bool IsWarmupPeriod()
{
	return view_as<bool>(GameRules_GetProp("m_bWarmupPeriod"));
}

/**
 * 강제로 라운드 상태를 준비시간으로 설정합니다.
 * 
 * @noreturn
 */
stock void StartWarmup()
{
	// 체크하지 않을경우 라운드 무한반복에 빠질 수 있다.
	if(!IsWarmupPeriod())
	{
		ServerCommand("mp_warmup_start");
//		GameRules_SetProp("m_bWarmupPeriod", 1);
//		SetWarmupStartTime(GetGameTime()+0.5);
	}
}

/**
 * 게임 준비 시간의 시작 시간을 얻어냅니다.
 *
 * @return		게임 준비 시간의 시작 시간(GameTime 기준)
 */
stock float GetWarmupStartTime()
{
	return GameRules_GetPropFloat("m_fWarmupPeriodStart");
}

/**
 * 게임 준비 시간의 종료 시간을 얻어냅니다.
 *
 * @return		게임 준비 시간이 종료되는 시간(GameTime 기준)
 */
stock float GetWarmupEndTime()
{
	return (GetWarmupStartTime() + GetConVarFloat(FindConVar("mp_warmuptime")));
}

/**
 * 남은 게임 준비 시간을 얻어냅니다.
 *
 * @return		남은 게임 준비 시간(실수 초 단위)
 */
stock float GetWarmupLeftTime()
{
	return (GetWarmupEndTime() - GetGameTime());
}

/**
 * 게임 준비 시간이 시작된 시간을 강제로 설정합니다.
 * 게임 준비 시간을 다시 시작하거나, 준비 시간을 늘릴때 이용합니다.
 *
 * @noreturn
 */
stock void SetWarmupStartTime(float time)
{
	GameRules_SetPropFloat("m_fWarmupPeriodStart", time, _, true);
}

/**
 * 게임 준비 시간의 종료 시간을 강제로 설정합니다.
 *
 * @noreturn
 */
stock void SetWarmupEndTime(float time)
{
	GameRules_SetPropFloat("m_fWarmupPeriodEnd", time, _, true);
}

/**
 * 게임을 다시 시작합니다.
 *
 * @param time		게임을 다시 시작하기까지의 딜레이.
 *
 * @noreturn
 */
stock void RestartRound(float time)
{
	GameRules_SetPropFloat("m_flRestartRoundTime", GetGameTime() + time);
}

/**
 * 게임을 [다시] 시작하는 시간을 구합니다.
 *
 * @return 		게임이 [다시] 시작되는 시간. (GameTime 기준)
 */
stock float GetRestartRoundTime()
{
	return GameRules_GetPropFloat("m_flRestartRoundTime");
}

/**
 * 라운드가 시작된 시간을 구합니다.
 *
 * @return		라운드의 시작 시간. (GameTime 기준)
 */
stock float GetRoundStartTime()
{
	return GameRules_GetPropFloat("m_fRoundStartTime");
}

/**
 * 라운드의 남은 시간을 구해냅니다.
 *
 * @return		라운드의 남은 시간. (실수 초 단위)
 */
stock float GetRoundLeftTime()
{
	return ((GetConVarFloat(FindConVar("mp_roundtime"))*60 - (GetGameTime() - GetRoundStartTime())));
}

/**
 * 한 라운드의 시간을 구해냅니다.
 *
 * @param afterFreezeTime		라운드의 시간에 프리즈 타임을 포함한다면 true, 아니라면 false.
 *
 * @return		라운드의 시간. (실수 초 단위)
 */
stock float GetRoundTime(bool afterFreezeTime=false)
{
	int freezeTimeLength = 0;
	if(afterFreezeTime)
		freezeTimeLength = GetConVarInt(FindConVar("mp_freezetime"));
	return ((GetGameTime()+freezeTimeLength) - GetRoundStartTime());
}

/**
 * 라운드가 다시 시작되는 딜레이를 얻어냅니다.
 *
 * @return		라운드가 다시 시작되는 딜레이. (실수 초 단위)
 */
stock float GetRoundRestartDelay()
{
	return GetConVarFloat(FindConVar("mp_round_restart_delay"));
}