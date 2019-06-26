int g_Ent[MAXPLAYERS + 1] = INVALID_ENT_REFERENCE;

public Action Cmd_UseRocketItem(int client, int args)
{
	Action result;
	
	char iteminfo[8];
	// 아이템 인덱스의 아이템 항목을 가져온다.
	DDS_GetItemInfo(g_iItemIndices[Rocket], 2, iteminfo);
	int iItemCode = StringToInt(iteminfo);
	
	result = DDS_OnClientSetItemPre(client, iItemCode, g_iItemIndices[Rocket]);
	
	if(result == Plugin_Continue)
	{
		// 마지막으로 아이템 삭제
		DDS_SimpleRemoveItem(client, g_iItemIndices[Rocket], 1);
	}
	
	return Plugin_Stop;
}

public Action Launch(Handle timer, any:client)
{
	if (IsClientInGame(client))
	{
		float vVel[3];
			
		vVel[0] = 0.0;
		vVel[1] = 0.0;
		vVel[2] = 1000.0;
		
		AttachFlame(client);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
		SetEntityMoveType(client, MOVETYPE_FLY);
		SetEntityGravity(client, 0.0);
		CreateTimer(0.1, ValidateRocketGravity, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
			
	return Plugin_Handled;
}

public Action ValidateRocketGravity(Handle timer, any client)
{
	if (IsValidPlayer(client))
	{
		float vVel[3];
			
		vVel[0] = 0.0;
		vVel[1] = 0.0;
		vVel[2] = 1000.0;
		
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
		
		SetEntityMoveType(client, MOVETYPE_FLY);
		SetEntityGravity(client, 0.0);
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action Detonate(Handle timer, any client)
{
	if (IsValidPlayer(client))
	{		
		float setmin = 0.0, setmax = 10000.0;
		float ranfloat, ranper;
		
		SetEntityRenderColor(client, 255, 255, 255, 255);
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		
		ranfloat = MathGetRandomFloat(setmin, setmax);
		ranper = (ranfloat / setmax) * 100.0;
		if (ranper <= 80.0) // 확률이 50% 일 때
		{
			float ClientOrigin[3];
			GetClientAbsOrigin(client, ClientOrigin);
			
			int g_ent = CreateEntityByName("env_explosion");
			DispatchKeyValue(g_ent, "iMagnitude", "2000");
			DispatchKeyValue(g_ent, "iRadiusOverride", "15");
			DispatchSpawn(g_ent);
			TeleportEntity(g_ent, ClientOrigin, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(g_ent, "Explode");
			CreateTimer(3.0, KillExplosion, EntIndexToEntRef(g_ent), TIMER_FLAG_NO_MAPCHANGE);
			SetEntityGravity(client, 0.0);
			ForcePlayerSuicide(client);
			
			TE_SetupSparks(ClientOrigin, NULL_VECTOR, 300, 5000);
			TE_SendToAll();
			for (int i = 1; i <= 5; i++)
			{
				float pos[3];
				pos[0] = MathGetRandomFloat(-50.0, 50.0);
				pos[1] = MathGetRandomFloat(-50.0, 50.0);
				pos[2] = MathGetRandomFloat(-50.0, 50.0);
				AddVectors(ClientOrigin, pos, pos);
				TE_SetupExplosion(pos, g_iExplosion, 10.0, 1, 0, 600, 5000);
				TE_SendToAll(float(i) / 10);
				TE_SetupSparks(pos, NULL_VECTOR, 300, 5000);
				TE_SendToAll(float(i) / 10);
			}
		}
		else
		{
			KickClient(client, "나로호 탈출 성공!");
		}
		
		g_Ent[client] = INVALID_ENT_REFERENCE;
	}
	return Plugin_Handled;
}

public Action KillExplosion(Handle timer, any ent)
{
	ent = EntRefToEntIndex(ent);
	if (IsValidEntity(ent))
	{
		char classname[256];
		GetEdictClassname(ent, classname, sizeof(classname));
		if (StrEqual(classname, "env_explosion", false))
		{
			RemoveEdict(ent);
		}
	}
}

AttachFlame(ent)
{
	char flame_name[128];
	Format(flame_name, sizeof(flame_name), "RocketFlame%i", ent);
	
	char tName[128];
	
	int flame = CreateEntityByName("env_steam");
	if (IsValidEdict(flame))
	{
		float pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] += 30;
		
		float angles[3];
		angles[0] = 90.0;
		angles[1] = 0.0;
		angles[2] = 0.0;
		
		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);
		
		DispatchKeyValue(flame, "targetname", flame_name);
		DispatchKeyValue(flame, "parentname", tName);
		DispatchKeyValue(flame, "SpawnFlags", "1");
		DispatchKeyValue(flame, "Type", "0");
		DispatchKeyValue(flame, "InitialState", "1");
		DispatchKeyValue(flame, "Spreadspeed", "10");
		DispatchKeyValue(flame, "Speed", "800");
		DispatchKeyValue(flame, "Startsize", "10");
		DispatchKeyValue(flame, "EndSize", "250");
		DispatchKeyValue(flame, "Rate", "15");
		DispatchKeyValue(flame, "JetLength", "400");
		DispatchKeyValue(flame, "RenderColor", "180 71 8");
		DispatchKeyValue(flame, "RenderAmt", "180");
		DispatchSpawn(flame);
		TeleportEntity(flame, pos, angles, NULL_VECTOR);
		SetVariantString(tName);
		AcceptEntityInput(flame, "SetParent", flame, flame, 0);
		
		CreateTimer(13.2, DeleteFlame, EntIndexToEntRef(flame), TIMER_FLAG_NO_MAPCHANGE);
		
		g_Ent[ent] = flame;
	}
}

public Action DeleteFlame(Handle timer, any ent)
{
	ent = EntRefToEntIndex(ent);
	if (IsValidEntity(ent))
    {
        char classname[256];
        GetEdictClassname(ent, classname, sizeof(classname));
        if (StrEqual(classname, "env_steam", false))
        {
            RemoveEdict(ent);
        }
    }
}