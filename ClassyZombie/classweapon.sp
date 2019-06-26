#define WEAPON_COUNT 19+1

char g_strWeaponName[WEAPON_COUNT][32];
int g_iWeaponClass[WEAPON_COUNT] = 0;
int g_iWeaponPrice[WEAPON_COUNT] = 0;
int g_iWeaponClipSize[WEAPON_COUNT] = 0;
int g_iWeaponReserveAmmo[WEAPON_COUNT] = 0;

public AddingWeapon()
{
	// 보병(기동성)
	CreateWeapons(1, "famas", 1, 800, 200);
	CreateWeapons(2, "ak47", 1, 2000, 180);
	CreateWeapons(3, "m4a1_silencer", 1, 3000, 160);
	CreateWeapons(4, "m4a1", 1, 3000, 240);
	
	// 보병(정확성)
	CreateWeapons(5, "aug", 2, 800, 210);
	CreateWeapons(6, "sg556", 2, 3000, 600);

	// 보병(화력성)
	CreateWeapons(7, "nova", 3, 800, 24);
	CreateWeapons(8, "mag7", 3, 3000, 45);
	CreateWeapons(9, "xm1014", 3, 3000, 49);
	CreateWeapons(10, "p90", 3, 4000, 400);
	CreateWeapons(11, "m249", 3, 10000, 250);

	// 저격병
	CreateWeapons(12, "ssg08", 4, 0, 150);
	CreateWeapons(13, "awp", 4, 3000, 100);
	CreateWeapons(14, "scar20", 4, 8000, 160);

	// 지원병
	CreateWeapons(15, "mp9", 5, 0, 270);
	CreateWeapons(16, "mp7", 5, 1600, 360);
	CreateWeapons(17, "bizon", 5, 3000, 576);
	
	// 의무병
	CreateWeapons(18, "ump45", 6, 0, 200);
	CreateWeapons(19, "mac10", 6, 3000, 330);
}

//무기 관련 변수 생성
public void CreateWeapons(int WeaponID, char strWeaponName[32], int Temp_Weapon_Class, int Temp_Weapon_Price, int Temp_Weapon_SAmmo)
{
	g_strWeaponName[WeaponID] = strWeaponName;
	g_iWeaponClass[WeaponID] = Temp_Weapon_Class;
	g_iWeaponPrice[WeaponID] = Temp_Weapon_Price;
	g_iWeaponClipSize[WeaponID] = CacheClipSize(strWeaponName);
	g_iWeaponReserveAmmo[WeaponID] = Temp_Weapon_SAmmo;
}

/*
// 조건문 내부에서 클래스네임을 얻어내 만약의 경우, 실패하는 것을 방지한다.
	if (GetEdictClassname(weapon, classname, sizeof(classname)))
	{
		// 무기 클래스네임을 실제에 맞도록 바꾼다.
		switch (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
		{
			case 60: classname = "weapon_m4a1_silencer";
			case 61: classname = "weapon_usp_silencer";
			case 63: classname = "weapon_cz75a";
		}
*/

// CacheClipSize(classname[7]);
stock int CacheClipSize(const char[] sz_item)
{
	if  (StrEqual(sz_item, "mag7", false))
		return 5;
		
	else if  (StrEqual(sz_item, "xm1014", false) || StrEqual(sz_item, "sawedoff", false))
		return 7;
		
	else if  (StrEqual(sz_item, "m3", false) || StrEqual(sz_item, "nova", false))
		return 8;
		
	else if  (StrEqual(sz_item, "ssg08", false) || StrEqual(sz_item, "awp", false))
		return 10;
		
	else if  (StrEqual(sz_item, "g3sg1", false) || StrEqual(sz_item, "scar20", false) || StrEqual(sz_item, "m4a1_silencer", false))
		return 20;
		
	else if  (StrEqual(sz_item, "famas", false) || StrEqual(sz_item, "ump45", false))
		return 25;
		
	// ak47,  aug,  m4a1,  sg553,  mac10,  mp7,  mp9
	else if  (StrEqual(sz_item, "ak47", false) || StrEqual(sz_item, "m4a1", false) || StrEqual(sz_item, "aug", false) || StrEqual(sz_item, "sg556", false)
		|| StrEqual(sz_item, "mac10", false) || StrEqual(sz_item, "mp7", false) || StrEqual(sz_item, "mp9", false))
		return 30;
		
	else if  (StrEqual(sz_item, "galil", false))
		return 35;
		
	else if  (StrEqual(sz_item, "p90", false))
		return 50;
		
	else if  (StrEqual(sz_item, "bizon", false))
		return 64;
		
	else if  (StrEqual(sz_item, "m249", false))
		return 100;
		
	else if  (StrEqual(sz_item, "negev", false))
		return 150;
		
	else if  (StrEqual(sz_item, "deagle", false))
		return 7;
		
	else if  (StrEqual(sz_item, "usp_silencer", false) || StrEqual(sz_item, "weapon_cz75a", false))
		return 12;
		
	else if  (StrEqual(sz_item, "p228", false) || StrEqual(sz_item, "hkp2000", false) || StrEqual(sz_item, "p250", false))
		return 13;
		
	else if (StrEqual(sz_item, "glock", false) || StrEqual(sz_item, "fiveseven", false))
		return 20;
		
	else if (StrEqual(sz_item, "elite", false))
		return 30;
		
	else if (StrEqual(sz_item, "tec9", false))
		return 24;
		
	return -1;
}