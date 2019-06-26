//Version 2.5

//Parachute Model
#define PARACHUTE_MODEL		"parachute_carbon"

//Parachute Textures
#define PARACHUTE_PACK		"pack_carbon"
#define PARACHUTE_TEXTURE	"parachute_carbon"

char path_model[256];
char path_pack[256];
char path_texture[256];

bool isfallspeed[MAXPLAYERS+1];

bool inUse[MAXPLAYERS+1];
bool hasPara[MAXPLAYERS+1];
int Parachute_Ent[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};

#define LINEAR	1 // 0: disables linear fallspeed -1: enables it
#define FALL_SPEED	100 // speed of the fall when you use the parachute
#define DECREASE 50 // 0: dont use Realistic velocity-decrease - x: sets the velocity-decrease.

void Para_OnPluginStart()
{	
	InitModel();
}

void InitModel(){
	Format(path_model,255,"models/parachute/%s",PARACHUTE_MODEL);
	Format(path_pack,255,"materials/models/parachute/%s",PARACHUTE_PACK);
	Format(path_texture,255,"materials/models/parachute/%s",PARACHUTE_TEXTURE);
}

void Para_OnMapStart()
{
	char path[256];
	
	strcopy(path,255,path_model);
	StrCat(path, 255, ".mdl");
	PrecacheModel(path,true);

	strcopy(path,255,path_model);
	StrCat(path, 255, ".dx80.vtx");
	AddFileToDownloadsTable(path);

	strcopy(path,255,path_model);
	StrCat(path, 255, ".dx90.vtx");
	AddFileToDownloadsTable(path);

	strcopy(path,255,path_model);
	StrCat(path, 255, ".mdl");
	AddFileToDownloadsTable(path);

	strcopy(path,255,path_model);
	StrCat(path, 255, ".sw.vtx");
	AddFileToDownloadsTable(path);
	
	strcopy(path,255,path_model);
	StrCat(path, 255, ".vvd");
	AddFileToDownloadsTable(path);

	strcopy(path,255,path_model);
	StrCat(path, 255, ".xbox.vtx");
	AddFileToDownloadsTable(path);

	strcopy(path,255,path_pack);
	StrCat(path, 255, ".vmt");
	AddFileToDownloadsTable(path);
	
	strcopy(path,255,path_pack);
	StrCat(path, 255, ".vtf");
	AddFileToDownloadsTable(path);
	
	strcopy(path,255,path_texture);
	StrCat(path, 255, ".vmt");
	AddFileToDownloadsTable(path);
	
	strcopy(path,255,path_texture);
	StrCat(path, 255, ".vtf");
	AddFileToDownloadsTable(path);
}

void Para_OnClientPutInServer(int client)
{
	inUse[client] = false;
	hasPara[client] = false;
	Parachute_Ent[client] = INVALID_ENT_REFERENCE;
}

void Para_OnClientDisconnect(int client)
{
	CloseParachute(client);
}

void Para_OnPlayerDeath(int client)
{
	EndPara(client);
}

void StartPara(int client,bool open)
{
	float velocity[3];
	float fallspeed;
	
	if(hasPara[client])
	{
		fallspeed = FALL_SPEED*(-1.0);
		
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
		if(velocity[2] >= fallspeed){
			isfallspeed[client] = true;
		}
		if(velocity[2] < 0.0) {
			if(isfallspeed[client] && LINEAR == 0){
			}
			else if((isfallspeed[client] && LINEAR == 1) || DECREASE == 0.0){
				velocity[2] = fallspeed;
			}
			else{
				velocity[2] = velocity[2] + DECREASE;
			}
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
			SetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
			SetEntityGravity(client,0.1);
			
			// 첫 실행때,
			if(open)
			{
				OpenParachute(client);
			}
		}
	}
}

void EndPara(int client)
{
	SetEntityGravity(client,1.0);
	inUse[client]=false;
	hasPara[client]=false;
	CloseParachute(client);
}

void OpenParachute(int client){
	char path[256];
	strcopy(path,255,path_model);
	StrCat(path, 255, ".mdl");
	
	Parachute_Ent[client] = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(Parachute_Ent[client],"model",path);
	SetEntityMoveType(Parachute_Ent[client], MOVETYPE_NOCLIP);
	DispatchSpawn(Parachute_Ent[client]);
	
	TeleportParachute(client);
}

void TeleportParachute(int client){
	if(IsValidEntity(Parachute_Ent[client])){
		float Client_Origin[3];
		float Client_Angles[3];
		float Parachute_Angles[3] = {0.0, 0.0, 0.0};
		GetClientAbsOrigin(client,Client_Origin);
		GetClientAbsAngles(client,Client_Angles);
		Parachute_Angles[1] = Client_Angles[1];
		TeleportEntity(Parachute_Ent[client], Client_Origin, Parachute_Angles, NULL_VECTOR);
	}
}

void CloseParachute(int client){
	if(IsValidEntity(Parachute_Ent[client])){
		RemoveEdict(Parachute_Ent[client]);
	}
	Parachute_Ent[client] = INVALID_ENT_REFERENCE;
}

bool CanUseParachuteCheck(int client)
{
	float speed[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", speed);
	
	int cl_flags = GetEntityFlags(client);
	
	if (speed[2] >= 0 || (cl_flags & FL_ONGROUND) || (cl_flags & FL_INWATER))return false;
	
	return true;
}

void Para_OnRunCmd(int client, int buttons)
{
	if (IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
	{
		if (buttons & IN_SPEED && CanUseParachuteCheck(client))
		{
			// 낙하산 사용 중이 아닐 때
			if(!hasPara[client])
			{				
				// 낙하산 갯수 구한 뒤 체크
				int iParachuteCount = DDS_GetClientItemCount(client, g_iItemIndices[Parachute]);
				if(iParachuteCount > 0)
				{
					// 낙하산 하나 삭제
					DDS_SimpleRemoveItem(client, g_iItemIndices[Parachute], 1);
					// 낙하산 사용 설정
					hasPara[client] = true;
					PrintToChat(client, "%s\x04낙하산\x01을 소비했습니다. \x01남은 낙하산: \x04%i\x01개 ", PREFIX, iParachuteCount-1);
				}
			}
			// 낙하산 사용 설정이 true일 때
			else
			{
				// 낙하산 펼치기 시작
				if (!inUse[client])
				{
					inUse[client] = true;
					isfallspeed[client] = false;
					StartPara(client, true);
				}
				// 낙하산 펼친 뒤의 설정
				StartPara(client,false);
				TeleportParachute(client);
			}
		}
		else
		{
			if (inUse[client])
			{
				inUse[client] = false;
				EndPara(client);
			}
		}
		if(!CanUseParachuteCheck(client))
		{
			EndPara(client);
		}
	}
}