// 센트리건 거리
static const float DISTANCE = 600.0;
// 비지블 관련
static const float TRACE_TOLERANCE = 10.0;

public Action Cmd_UseSentryGunItem(int client, int args)
{
	Action result;
	
	char iteminfo[8];
	// 아이템 인덱스의 아이템 항목을 가져온다.
	DDS_GetItemInfo(g_iItemIndices[SentryGun], 2, iteminfo);
	int iItemCode = StringToInt(iteminfo);
	
	result = DDS_OnClientSetItemPre(client, iItemCode, g_iItemIndices[SentryGun]);
	
	if(result == Plugin_Continue)
	{
		// 마지막으로 아이템 삭제
		DDS_SimpleRemoveItem(client, g_iItemIndices[SentryGun], 1);
	}
	
	return Plugin_Stop;
}

void SpawnSentryGun(int client)
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vAngleVector[3], Float:vSpawnOrigin[3], Float:flSpawnDistanceForward;
	GetClientAbsOrigin(client, vOrigin);
	GetClientEyeAngles(client, vAngle);
	// 아래위 앵글 값 제거
	vAngle[0] = 0.0;
	// 왼쪽 오른쪽 앵글 제거(원래 있어선 안됨)
	vAngle[2] = 0.0;
		
	flSpawnDistanceForward = 32.0;
	GetAngleVectors(vAngle, vAngleVector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vAngleVector, vAngleVector);
	ScaleVector(vAngleVector, flSpawnDistanceForward);
	AddVectors(vOrigin, vAngleVector, vSpawnOrigin);
	vSpawnOrigin[2] += 4.0;
	
	new ent = CreateEntityByName("prop_dynamic_override");
	
	if(!IsValidEntity(ent))
		return;
	
	SetEntityModel(ent, "models/chicken/chicken.mdl"); // models/Combine_Scanner.mdl
	DispatchKeyValue(ent, "StartDisabled", "false");
	DispatchSpawn(ent);
	AcceptEntityInput(ent, "TurnOn", ent, ent, 0);
	AcceptEntityInput(ent, "EnableCollision");
	SetEntityMoveType(ent, MOVETYPE_NOCLIP);
	DispatchKeyValue(ent, "spawnflags", "8");
	new Rand = GetRandomInt(1, 2);
	if(Rand == 1)
		SetVariantString("flap"); // inspect1
	else if(Rand == 2)
		SetVariantString("flap_falling"); // inspect2
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0);
	CreateTimer(1.35, SetIdleAnimation, EntIndexToEntRef(ent), TIMER_FLAG_NO_MAPCHANGE); // 3.35
	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
	SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(client));
	
	TeleportEntity(ent, vSpawnOrigin, vAngle, NULL_VECTOR);
	
	CreateTimer(180.0, RemoveSentryTimer, EntIndexToEntRef(ent), TIMER_FLAG_NO_MAPCHANGE);
	
	HookEntityThink(ent, OnSentryThink, 0.1);
//	UnhookSingleEntityOutput(entity, "OnUser2", OnSentryThink);
}

public Action:SetIdleAnimation(Handle:timer, any:ent)
{
	ent = EntRefToEntIndex(ent);
	if(IsValidEdict(ent))
	{
		SetVariantString("idle01"); // idle
		AcceptEntityInput(ent, "SetAnimation", -1, -1, 0);
	}
}

static bool bIgnoreSentryBulletTrace[MAXPLAYERS + 1] = {false, ...};

public OnSentryThink(const String:output[], Sentry, activator, Float:delay)
{
	AcceptEntityInput(Sentry, "FireUser1");
	
	new target;
	new Float:pos[3], Float:targetpos[3], Float:targetdist;
	GetEntPropVector(Sentry, Prop_Send, "m_vecOrigin", pos);
	
	float angSentryAngle[3], vecSentryAngleVectorForward[3], vecSentryAngleVectorUp[3];
	GetEntPropVector(Sentry, Prop_Send, "m_angRotation", angSentryAngle);
	
	// 센트리의 각도를 기준으로 위치를 적용해주자
	GetAngleVectors(angSentryAngle, vecSentryAngleVectorForward, NULL_VECTOR, vecSentryAngleVectorUp);
	NormalizeVector(vecSentryAngleVectorForward, vecSentryAngleVectorForward);
	NormalizeVector(vecSentryAngleVectorUp, vecSentryAngleVectorUp);
	
	// 업벡터, 위로 16칸 밀기.
	ScaleVector(vecSentryAngleVectorUp, 16.0);
	AddVectors(pos, vecSentryAngleVectorUp, pos);
	
	// 포워드벡터, 앞으로 8칸 밀기.
	ScaleVector(vecSentryAngleVectorForward, 8.0);
	AddVectors(pos, vecSentryAngleVectorForward, pos);
	
	int[] clients = new int[MaxClients];
	int size = GetClientsInRange(pos, RangeType_Visibility, clients, MaxClients);
	
	for(new i = 0; i < size; i++)
	{
		//GetEntProp(Sentry, Prop_Send, "m_iTeamNum") != GetClientTeam(clients[i])
		if(IsValidClient(clients[i]) && IsPlayerAlive(clients[i]) && IsClientZombie(clients[i]))
		{
			if(IsTargetInSightRange(Sentry, clients[i], 360.0, DISTANCE, true, false))
			{
				GetClientAbsOrigin(clients[i], targetpos);
			    
				new Float:dist = GetVectorDistance(pos, targetpos);
			
				// 측정한 거리가 만약 설정한 range 보다 낮거나 같으면 체크
				// TODO: DEBUG 거리고치자 나중에...
				if (dist <= DISTANCE)
				{
					// 처음 수행
					if (targetdist == 0.0)
					{
						targetdist = dist;
						target = clients[i];
					}
					// 처음 이후
					else
					{
						// 더 가까운 상대를 찾는다.
						if (targetdist > dist)
						{
							targetdist = dist;
							target = clients[i];
						}
					}
				}
			}
		}
	}
	
	if(IsValidPlayer(target))
	{
		// 타겟의 아이포지션을 구한 뒤, 두 포인트를 이용해 벡터를 생성
		// 생성한 벡터의 각도를 구한다.
		// 결국 두 포인트의 각도를 구함.
		float vecTargetPos[3], vecEndPoint[3];
		GetClientAbsOrigin(target, vecTargetPos);
		
		vecTargetPos[2] += 32.0;
		
		float mins[3], maxs[3];
		GetClientMins(target, mins);
		GetClientMaxs(target, maxs);
		
		vecTargetPos[0] += GetRandomFloat(mins[0], maxs[0])/2;
		vecTargetPos[1] += GetRandomFloat(mins[1], maxs[1])/2;
		vecTargetPos[2] += GetRandomFloat(mins[2], maxs[2])/4;
		
		if(IsVisibleTo(pos, vecTargetPos))
		{
			int owner = GetEntPropEnt(Sentry, Prop_Data, "m_hOwnerEntity");
			
			float vector[3], angles[3];
			MakeVectorFromPoints(pos, vecTargetPos, vector);
			GetVectorAngles(vector, angles);
			
			SetViewAngle(Sentry, vecTargetPos);
				
			SetVariantString("bounce"); // retract
			AcceptEntityInput(Sentry, "SetAnimation", -1, -1, 0);
			CreateTimer(0.25, SetIdleAnimation, Sentry); // 0.75
			
			float damage = 3.0;
			
			SDKHooks_TakeDamage(target, Sentry, IsValidClient(owner) ? owner:0, damage, DMG_BULLET, -1, vector, vecTargetPos);
			PushPlayerBack(Sentry, target, damage * 5.0);
			
			TE_SetupEffect_CSBlood(vecTargetPos, angles, damage, target);
			TE_SendToAll();
			
			bIgnoreSentryBulletTrace[target] = true;
			
			TR_TraceRayFilter(pos, angles, MASK_SHOT, RayType_Infinite, ___TE_FilterNoPlayers);
			if(TR_DidHit())
			{
				int iHitEntity = TR_GetEntityIndex();
				TR_GetEndPosition(vecEndPoint);
				TE_SetupEffect_Impact(vecEndPoint, pos, 0, DMG_BULLET, TR_GetHitGroup(), iHitEntity);
				TE_SendToAll();
				
				if(iHitEntity > 0 && IsValidEdict(iHitEntity))
				{
					//
					if(!IsValidPlayer(iHitEntity))
					{
						if(GetEntProp(iHitEntity, Prop_Send, "m_iTeamNum") != GetEntProp(Sentry, Prop_Send, "m_iTeamNum"))
						{
							SDKHooks_TakeDamage(iHitEntity, Sentry, IsValidClient(owner) ? owner:0, damage, DMG_BULLET, -1, vector, vecEndPoint);
							
							// 프롭 피직스 관련 엔티티만 밀어준다.
							// 안그러면 이상한게밀림.. (문 같은거)
							char szClassname[64];
							GetEdictClassname(iHitEntity, szClassname, sizeof(szClassname));
							if(StrContains(szClassname, "prop_physics") != -1)
								PushPlayerBack(Sentry, iHitEntity, damage * 5.0);
						}
					}
					else
					{
						if(IsClientZombie(iHitEntity))
						{
							SDKHooks_TakeDamage(iHitEntity, Sentry, IsValidClient(owner) ? owner:0, damage, DMG_BULLET, -1, vector, vecEndPoint);
							
							// 플레이어에게 넉백 효과
							PushPlayerBack(Sentry, iHitEntity, damage * 5.0);
							
							// 피 분출 이펙트 생성
							TE_SetupEffect_CSBlood(vecEndPoint, angles, damage, iHitEntity);
							TE_SendToAll();
						}
					}
				}
			}
			
			int beamcolor[4] = {192, 192, 255, 255};
			
			if(GetVectorDistance(pos, vecTargetPos) > GetVectorDistance(pos, vecEndPoint))
				TE_SetupBeamPoints(pos, vecTargetPos, g_nBeamEntModel, 0, 0, 0, 0.1, 0.5, 0.5, 1, 0.0, beamcolor, 0);
			else
				TE_SetupBeamPoints(pos, vecEndPoint, g_nBeamEntModel, 0, 0, 0, 0.1, 0.5, 0.5, 1, 0.0, beamcolor, 0);
				
			TE_SendToAll();
			
			char SentryShotSoundPath[128];
			Format(SentryShotSoundPath, sizeof(SentryShotSoundPath), "ambient/creatures/chicken_panic_0%d.wav", GetRandomInt(1, 2));
			EmitSoundToAllAny(SentryShotSoundPath, Sentry, SNDCHAN_AUTO, SNDLEVEL_SCREAMING, _, _, _, _, _, _, true);
			
	//		TE_SetupEffect_Bullet(Sentry, pos, angles);
	//		TE_SendToAll();
		}
	}
}

stock TE_SetupEffect_Impact(const Float:endpos[3], const Float:startpos[3], surfaceprop, damagetype, hitbox, entindex)
{
	TE_Start("EffectDispatch");
	if(GetEngineVersion() < Engine_CSGO)
	{
		TE_WriteFloatArray("m_vOrigin[0]", endpos, 3);
		TE_WriteFloatArray("m_vStart[0]", startpos, 3);
	}
	else
	{
		TE_WriteFloatArray("m_vOrigin.x", endpos, 3);
		TE_WriteFloatArray("m_vStart.x", startpos, 3);
	}
	TE_WriteNum("m_nHitBox", hitbox);
	TE_WriteNum("m_nSurfaceProp", surfaceprop);
	TE_WriteNum("m_nDamageType", damagetype);
	TE_WriteNum("entindex", entindex);
	TE_WriteNum("m_iEffectName", GetEffectIndex("Impact"));
}

public bool ___TE_FilterNoPlayers(entity, contentsMask)
{
	if(entity > 0 && entity <= MaxClients)
	{
		if(bIgnoreSentryBulletTrace[entity])
		{
			bIgnoreSentryBulletTrace[entity] = false;
			return false;
		}
		else
		{
			// 이후에 IsClientZombie로 바꿀 것!!
			// 변경 완료
			if(IsClientZombie(entity))
				return true;
			else
				return false;
		}
	}
	return true;
}

stock TE_SetupEffect_Bullet(int client, const float endpos[3], const float angle[3])
{
	TE_Start("Shotgun Shot");
	TE_WriteVector("m_vecOrigin", endpos);
	TE_WriteFloat("m_vecAngles[0]", angle[0]);
	TE_WriteFloat("m_vecAngles[1]", angle[1]);
	TE_WriteNum("m_iWeaponID", 26);
	TE_WriteNum("m_iMode", 0);
	TE_WriteNum("m_iSeed", GetRandomInt(0, 255));
	TE_WriteNum("m_iPlayer", client-1);
	TE_WriteFloat("m_fInaccuracy", 0.0);
	TE_WriteFloat("m_fSpread", 0.0);
	TE_WriteNum("m_nItemDefIndex", 26);
	TE_WriteNum("m_iSoundType", 1);
}

public bool:Callback_HullCheck(entity, contentsMask, any:Missile)
{
	new owner = GetEntPropEnt(Missile, Prop_Data, "m_hOwnerEntity");
	return ((entity != Missile) && (entity != owner));
}

public Action RemoveSentryTimer(Handle timer, int entity)
{
	entity = EntRefToEntIndex(entity);
	
	if(IsValidEdict(entity))
	{
		RemoveEntity(entity);
		
		char SentryDeathSoundPath[128];
		Format(SentryDeathSoundPath, sizeof(SentryDeathSoundPath), "ambient/creatures/chicken_death_0%d.wav", GetRandomInt(1, 3));
		EmitSoundToAllAny(SentryDeathSoundPath, entity, SNDCHAN_AUTO, SNDLEVEL_SCREAMING, _, _, _, _, _, _, true);
	}
}

stock bool:IsTargetInSightRange(client, target, Float:angle=90.0, Float:distance=0.0, bool:heightcheck=true, bool:negativeangle=false)
{
	if(angle > 360.0 || angle < 0.0)
		ThrowError("Angle Max : 360 & Min : 0. %d isn't proper angle.", angle);
	/*
	if(!(IsValidClient(client) && IsPlayerAlive(client)))
		ThrowError("Client is not Alive.");
	if(!(IsValidClient(target) && IsPlayerAlive(target)))
		ThrowError("Target is not Alive.");
	*/
	
	decl Float:clientpos[3], Float:targetpos[3], Float:anglevector[3], Float:targetvector[3], Float:resultangle, Float:resultdistance;
	
	if(IsValidClient(client))
		GetClientEyeAngles(client, anglevector);
	else
		GetEntPropVector(client, Prop_Send, "m_angRotation", anglevector);
	
	anglevector[0] = anglevector[2] = 0.0;
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	if(negativeangle)
		NegateVector(anglevector);

	if(IsValidClient(client))
		GetClientAbsOrigin(client, clientpos);
	else
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientpos);
	
	if(IsValidClient(target))
		GetClientAbsOrigin(target, targetpos);
	else
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetpos);
	
	if(heightcheck && distance > 0)
		resultdistance = GetVectorDistance(clientpos, targetpos);
	clientpos[2] = targetpos[2] = 0.0;
	MakeVectorFromPoints(clientpos, targetpos, targetvector);
	NormalizeVector(targetvector, targetvector);
	
	resultangle = RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector)));
	
	if(resultangle <= angle/2)	
	{
		if(distance > 0)
		{
			if(!heightcheck)
				resultdistance = GetVectorDistance(clientpos, targetpos);
			if(distance >= resultdistance)
				return true;
			else
				return false;
		}
		else
			return true;
	}
	else
		return false;
}

public bool:Callback_IsEntitiesInViewcone(iEntity, mask) 
{ 
    if(IsValidEntity(iEntity))
    {
	    return false;
    }
    
    return true; 
}

stock RemoveEntity(const entity)
{
	return AcceptEntityInput(entity, "KillHierarchy");
}

stock SetViewAngle( Client, Float:EntityVec[3], bool:negativeangle=false )
{
	new Float:setVeiwAngle[3], Float:ClinetVec[3];
	new Float:distancex, Float:distancey, Float:distancez, Float:wherex, Float:wherey, Float:wherez;
	new Float:phi, Float:sinyaw, Float:sinpitch, Float:arcangleyaw, Float:arcanglepitch, Float:distanceyaw, Float:distancepitch;
	if(IsValidClient(Client))
		GetClientAbsOrigin(Client, ClinetVec);
	else
		GetEntPropVector(Client, Prop_Send, "m_vecOrigin", ClinetVec);
	EntityVec[2] + 55;
	phi = 3.1415926535897932;
	wherex = EntityVec[1] - ClinetVec[1];
	wherey = ClinetVec[0] - EntityVec[0];
	wherez = ClinetVec[2] - EntityVec[2];
	distancex = wherex;
	distancey = wherey;
	distancez = wherez;
	if( distancex < 0 )
		distancex = 0 - wherex;
	if( distancey < 0 )
		distancey = 0 - wherey;
	if( distancez < 0 )
		distancez = 0 - wherez;
	distanceyaw = SquareRoot((distancex*distancex)+(distancey*distancey));
	distancepitch = GetVectorDistance(ClinetVec, EntityVec);
	sinyaw = (wherex/distanceyaw);
	sinpitch = (distanceyaw/distancepitch);
	arcangleyaw = ArcCosine(sinyaw)*(180/phi);
	arcanglepitch = ArcCosine(sinpitch)*(180/phi);
	if( wherex >= 0 )
	{
		if( wherey <= 0 )
			setVeiwAngle[1] = (90-arcangleyaw);
		else
			setVeiwAngle[1] = (90+arcangleyaw);
	}
	else
	{
		if( wherey <= 0 )
			setVeiwAngle[1] = (90-arcangleyaw);
		else
			setVeiwAngle[1] = (arcangleyaw-270);
	}
	if( wherez <= 0 )
		setVeiwAngle[0] = (0-arcanglepitch);
	else
		setVeiwAngle[0] = (arcanglepitch);
	setVeiwAngle[2] = 0.0;
	//SetClientViewEntity(Client, setVeiwAngle);
	
	if(negativeangle)
		NegateVector(setVeiwAngle);
	
	TeleportEntity(Client, NULL_VECTOR, setVeiwAngle, NULL_VECTOR);
}

//엔티티가 충돌 가능한 물체인지를 검사한다!

stock bool:IsEntityCollidable2(entity, bool:includeplayer = true, bool:includehostage = true, bool:includeprojectile = true){
	
	decl String:classname[64];
	GetEdictClassname(entity, classname, 64);
	
	if((StrEqual(classname, "player", false) && includeplayer) || (StrEqual(classname, "hostage_entity", false) && includehostage)
		||StrContains(classname, "physics", false) != -1 || StrContains(classname, "prop", false) != -1
		|| StrContains(classname, "door", false)  != -1 || StrContains(classname, "weapon", false)  != -1
		|| StrContains(classname, "break", false)  != -1 || ((StrContains(classname, "projectile", false)  != -1) && includeprojectile)
		|| StrContains(classname, "brush", false)  != -1 || StrContains(classname, "button", false)  != -1
		|| StrContains(classname, "physbox", false)  != -1 || StrContains(classname, "plat", false)  != -1
		|| StrEqual(classname, "func_conveyor", false) || StrEqual(classname, "func_fish_pool", false)
		|| StrEqual(classname, "func_guntarget", false) || StrEqual(classname, "func_lod", false)
		|| StrEqual(classname, "func_monitor", false) || StrEqual(classname, "func_movelinear", false)
		|| StrEqual(classname, "func_reflective_glass", false) || StrEqual(classname, "func_rotating", false)
		|| StrEqual(classname, "func_tanktrain", false) || StrEqual(classname, "func_trackautochange", false)
		|| StrEqual(classname, "func_trackchange", false) || StrEqual(classname, "func_tracktrain", false)
		|| StrEqual(classname, "func_train", false) || StrEqual(classname, "func_traincontrols", false)
		|| StrEqual(classname, "func_vehicleclip", false) || StrEqual(classname, "func_traincontrols", false)
		|| StrEqual(classname, "func_water", false) || StrEqual(classname, "func_water_analog", false)){
		
		return true;
		
	}
	
	return false;
	
}

bool IsVisibleTo(Float:position[3], Float:targetposition[3])
{
    decl Float:vAngles[3], Float:vLookAt[3];
    
    MakeVectorFromPoints(position, targetposition, vLookAt); // compute vector from start to target
    GetVectorAngles(vLookAt, vAngles); // get angles from vector for trace
    
    // execute Trace
    Handle trace = TR_TraceRayFilterEx(position, vAngles, MASK_VISIBLE, RayType_Infinite, _TraceFilter);
    
    new bool:isVisible = false;
    if (TR_DidHit(trace))
    {
        decl Float:vStart[3];
        TR_GetEndPosition(vStart, trace); // retrieve our trace endpoint
        
        if ((GetVectorDistance(position, vStart, false) + TRACE_TOLERANCE) >= GetVectorDistance(position, targetposition))
        {
            isVisible = true; // if trace ray lenght plus tolerance equal or bigger absolute distance, you hit the target
        }
    }
    else
    {
        LogError("Tracer Bug: Trace did not hit anything, WTF");
        isVisible = true;
    }
    CloseHandle(trace);
    
    return isVisible;
}

public bool _TraceFilter(entity, contentsMask)
{
	if (!entity || !IsValidEntity(entity) || IsValidPlayer(entity)) // dont let WORLD, or invalid entities be hit
	{
		return false;
	}
	
	char szClassname[64];
	GetEdictClassname(entity, szClassname, sizeof(szClassname));
	if(StrEqual(szClassname, "prop_dynamic"))
		return false;
	
	return true;
}

stock TE_SetupEffect_CSBlood(const Float:pos[3], const Float:dir[3], float amount, entindex)
{
	TE_Start("EffectDispatch");
	if(GetEngineVersion() < Engine_CSGO)
		TE_WriteFloatArray("m_vOrigin[0]", pos, 3);
	else
		TE_WriteFloatArray("m_vOrigin.x", pos, 3);
	TE_WriteVector("m_vNormal", dir);
	TE_WriteFloat("m_flScale", 1.0);
	TE_WriteFloat("m_flMagnitude", amount);
	TE_WriteNum("entindex", entindex);
	
	// DispatchEffect
	TE_WriteNum("m_iEffectName", GetEffectIndex("csblood"));
}