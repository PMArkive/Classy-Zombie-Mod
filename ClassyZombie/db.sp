/*
"BSTZombie"
{
	"driver"			"default"
	"host"				"localhost"
	"database"			"bst_zombie_db"
	"user"				"DB 유저 네임"
	"pass"				"DB 유저 패스워드"
	//"timeout"			"0"
	"port"			"3306"
}
*/

/*
	DDS의 DB 시스템과는 관련없는 좀비모드의 독립적인 데이터를 관리한다.
	이곳에서 관리하는 데이터: 레벨
*/
Handle db = null;

#define LEVEL_TABLE_NAME	"bst_zombie_db_level"

void DB_OnPluginStart()
{
	SQL_TConnect(LoadSQLBase, "BSTZombie");
}

void DB_OnClientPostAdminCheck(int client)
{
	LoadClientData(client);
}

public void LoadSQLBase(Handle owner, Handle hndl, char[] error, any data)
{
	char query[1024];
	if (hndl == null)
	{
		PrintToServer("[BST Zombie] Failed to connect to database: %s", error);
		return;
	}
	else
	{
		db = hndl;
		
		#if defined _DEBUG_
			PrintToServer("[BST Zombie] Database Init. (CONNECTED)");
		#endif

		// 테이블이 없을 때 생성해준다.
		Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `%s` (`AuthId` VARCHAR(32) NOT NULL default '', `Name` VARCHAR(32) NOT NULL default '', `ClassLevel1` INT(8) NOT NULL default '-1', `ClassLevel2` INT(8) NOT NULL default '-1', `ClassLevel3` INT(8) NOT NULL default '-1', `ClassLevel4` INT(8) NOT NULL default '-1', `ClassLevel5` INT(8) NOT NULL default '-1', `ClassLevel6` INT(8) NOT NULL default '-1', `ClassLevel7` INT(8) NOT NULL default '-1', `ClassLevel8` INT(8) NOT NULL default '-1') COLLATE='utf8_general_ci' ENGINE=InnoDB;", LEVEL_TABLE_NAME);
		SQL_TQuery(db, SQLErrorCheckCallback, query, 0, DBPrio_High);
	}

	// 문자열을 UTF-8로 지정하고 테이블을 체크함.
	FormatEx(query, sizeof(query), "SET NAMES \"UTF8\"");
	SQL_TQuery(db, SQLErrorCheckCallback, query, 0);
	
	// LEVEL_TABLE_NAME이 들어가는 테이블을 다 뿌리도록 함.
	FormatEx(query, sizeof(query), "SHOW TABLES LIKE '%s';", LEVEL_TABLE_NAME);
	SQL_TQuery(db, SQLErrorCheckCallback, query, 0);
}

// 쿼리용 설정 로드
void LoadClientData(int client)
{
	if(!IsFakeClient(client))
	{
		char steamId[32];
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
		
		if (db != INVALID_HANDLE)
		{
			#if defined _DEBUG_
				PrintToServer("[BST Zombie] Action:LoadClientData (%s)", steamId);
			#endif
			
			char query[256];
			FormatEx(query, sizeof(query), "SELECT * FROM %s WHERE AuthId = '%s'", LEVEL_TABLE_NAME, steamId);
			
			SQL_TQuery(db, SQLUserLoad, query, client, DBPrio_High);
		}
	}
}

public void SQLUserLoad(Handle owner, Handle hndl, char[] error, any client)
{
	char name[32];
	
	GetClientName(client, name, sizeof(name));

	char steamId[32];
	GetClientAuthId(client, AuthId_Steam2, steamId, 32);

	ReplaceString(name, sizeof(name), "'", "");
	ReplaceString(name, sizeof(name), "<", "");
	ReplaceString(name, sizeof(name), "\"", "");

	// 유저 정보를 찾음
	if(SQL_FetchRow(hndl))
	{
		for (int i = 0; i < sizeof(g_iClassLevel[]); i++)
		{
			g_iClassLevel[client][i] = SQL_FetchInt(hndl, i+2);
		}
		
		// 데이터를 불러온다.
		/*
		g_iClassLevel[client][0] = SQL_FetchInt(hndl, 2); // 1번째 클래스 레벨
		g_iClassLevel[client][1] = SQL_FetchInt(hndl, 3); // 2번째 클래스 레벨
		g_iClassLevel[client][2] = SQL_FetchInt(hndl, 4); // 3번째 클래스 레벨
		g_iClassLevel[client][3] = SQL_FetchInt(hndl, 5); // 4번째 클래스 레벨
		g_iClassLevel[client][4] = SQL_FetchInt(hndl, 6); // 5번째 클래스 레벨
		g_iClassLevel[client][5] = SQL_FetchInt(hndl, 7); // 6번째 클래스 레벨
		g_iClassLevel[client][6] = SQL_FetchInt(hndl, 8); // 7번째 클래스 레벨
		g_iClassLevel[client][7] = SQL_FetchInt(hndl, 9); // 8번째 클래스 레벨
		*/
		
		// 유저의 최신 정보를 업데이트 시켜준다.
		char buffer[512];
		FormatEx(buffer, sizeof(buffer), "UPDATE %s SET Name = '%s' WHERE AuthId = '%s'", LEVEL_TABLE_NAME, name, GetTime(), steamId);
		#if defined _DEBUG_
			PrintToServer("[BST Zombie] SQLUserLoad (%s)", steamId);
		#endif
		// 에러 체크용 콜백
		SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	}
	else // 유저 정보를 찾을 수 없음
	{
		// 유저 데이터를 새로 만들어준다.
		char buffer[256];
		FormatEx(buffer, sizeof(buffer), "INSERT INTO %s (AuthId, Name) VALUES('%s', '%s')", LEVEL_TABLE_NAME, steamId, name);
		#if defined _DEBUG_
			PrintToServer("[BST Zombie] SQLUserLoad (%s)", steamId);
		#endif
		// 에러 체크용 콜백
		SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	}
	g_bUserDataLoaded[client] = true;
}

void SaveClientData(int client)
{
	if (!IsFakeClient(client) && g_bUserDataLoaded[client])
	{		
		if (db != INVALID_HANDLE)
		{
			char steamId[32];
			GetClientAuthId(client, AuthId_Steam2, steamId, 32);

			char query[256];
			Format(query, sizeof(query), "SELECT * FROM %s WHERE AuthId = '%s'", LEVEL_TABLE_NAME, steamId);
			#if defined _DEBUG_
				PrintToServer("[BST Zombie] SaveClientData (%s)", steamId);
			#endif

			Handle dataPack = CreateDataPack();
			WritePackCell(dataPack, client);
			WritePackString(dataPack, steamId);

			SQL_TQuery(db, SQLUserSave, query, dataPack);
		}
	}
}

public void SQLUserSave(Handle owner, Handle hndl, char[] error, Handle dataPack)
{
	ResetPack(dataPack);
	int client = ReadPackCell(dataPack);
	char steamId[32];
	ReadPackString(dataPack, steamId, sizeof(steamId));
	delete dataPack;

	if(hndl == INVALID_HANDLE)
	{
		LogError(error);
		PrintToServer("Last Connect SQL Error: %s", error);
		return;
	}

	if(SQL_FetchRow(hndl)) 
	{
		char buffer[512];
		Format(buffer, sizeof(buffer), "UPDATE %s SET ClassLevel1 = '%i', ClassLevel2 = '%i', ClassLevel3 = '%i', ClassLevel4 = '%i', ClassLevel5 = '%i', ClassLevel6 = '%i', ClassLevel7 = '%i', ClassLevel8 = '%i' WHERE AuthId = '%s'", LEVEL_TABLE_NAME, g_iClassLevel[client][0], g_iClassLevel[client][1], g_iClassLevel[client][2], g_iClassLevel[client][3], g_iClassLevel[client][4], g_iClassLevel[client][5], g_iClassLevel[client][6], g_iClassLevel[client][7], steamId);
		
		#if defined _DEBUG_
			PrintToServer("[BST Zombie] SQLUserSave (%s)", buffer);
		#endif

		SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	}

}

public void SQLErrorCheckCallback(Handle owner, Handle hndl, char[] error, any data)
{
	if(!StrEqual(NULL_STRING, error))
	{
		PrintToServer("Last Connect SQL Error: %s", error);
	}
}