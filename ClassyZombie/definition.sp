//#include "BSTZombie/files.sp"

EngineVersion g_Game; // 게임 체크

int g_offsCollision;
int g_offsPunchAngleVel;

int g_iRedCrossCache;

int g_nBeamEntModel;

// for dds
#define CRATE_ID	17
#define COMMON_ID	18
#define EXPENDABLE_ID	19

#define CSGO_HEGRENADE_AMMO 14
#define CSGO_FLASH_AMMO 15
#define CSGO_SMOKE_AMMO 16
#define INCENDERY_AND_MOLOTOV_AMMO 17
#define	DECOY_AMMO 18

#define CLASS_MAX_LEVEL	10 // 최대 레벨

#define INFECTION_DAMAGE_MULTIPLIER	0.25 // 감염 데미지의 배율 조정.
#define INFECTION_DAMAGE_INTERVAL	3.0 // 감염 데미지를 입는 시간 간격. (초)

#define ZOMBIE_SELECTION_TIME		45 // 초단위, 좀비 선택 이전 주어지는 시간.

#define ZOMBIE_MAX_HEALTH			20000 // 좀비가 가질 수 있는 최대 체력
#define ZOMBIE_HEALTH_PER_HUMAN		3000 // 숙주좀비의 인간 명 수 당 체력
#define ZOMBIE_HEAL_AMOUNT_PER_KILL	500	// 좀비가 인간을 잡을 때 마다 회복 및 한정되는 최대 체력(피통)의 증가량

#define REWARD_CASH_INFECT_HUMAN	200 // 인간 감염 보상
#define REWARD_CASH_KILL_ZOMBIE		800 // 좀비 킬 보상
#define REWARD_CASH_ROUND_WIN		1200 // 라운드 승리 보상

#define HUMAN_INFECTION_REWARD		1	// 인간을 좀비화시켰을때 주어지는 킬 포인트의 양
#define HOST_ZOMBIE_KILL_REWARD		3	// 숙주 좀비를 잡았을 때 주어지는 킬 포인트의 양
#define SPECIAL_ZOMBIE_KILL_REWARD	2	// 변종 좀비를 잡았을 때 주어지는 킬 포인트의 양
#define NORMAL_ZOMBIE_KILL_REWARD	1	// 일반 좀비를 잡았을 때 주어지는 킬 포인트의 양
#define HUMAN_SURVIVE_REWARD		1	// 인간 생존 성공 보상

#define REWARD_VOUCHER_3_4_SURVIVE			1
#define REWARD_VOUCHER_ALL_SURVIVE			3

#define SKILL_BOARD_MAX_HEIGHT	8.0

#define AmmoCrateModel "models/items/boxmrounds.mdl"//models/Items/ammocrate_smg1.mdl
#define AmmoCrateModelSize	1.0
#define AmmoCrateAmmoSize	300
#define AmmoSetSound "items/ammocrate_open.wav"
#define AmmoPickupSound "items/ammo_pickup.wav"
#define AmmoEquipmentSound "items/ammopickup.wav"
#define HealingSound "items/medshot4.wav"

#define BarricadeModel "models/props/de_house/step_wood_a.mdl"

#define ARMS_HOST_ZOMBIE	"models/player/colateam/zombie1/arms.mdl"
//#define ARMS_JUMP_ZOMBIE	"models/player/custom/hunter/hunterarms.mdl"
//#define ARMS_GAS_ZOMBIE		"models/player/colateam/zombie1/arms.mdl"
#define ARMS_SPECIAL_ZOMBIE	"models/player/colateam/zombie1/arms.mdl"
#define ARMS_NORMAL_ZOMBIE	"models/player/custom/hunter/hunterarms.mdl"

#define MODEL_SUPPLY_CRATE	"models/props_crates/static_crate_40.mdl"

#define SOUND_BECOME_SPECIAL_ZOMBIE	"ui/beep22.wav"

// 전체 변수
bool g_bGameStarted = false;
bool g_bRoundEnded = false;
bool g_bHostSelectionTime = false;
int g_iHostZombie = -1;
int g_iGasZombie = -1;
int g_iJumpZombie = -1;

int g_iExplosion = 0;
int g_nAliveT = 0;
int g_nAliveCT = 0;

// 개인 변수
bool g_bThirdPerson[MAXPLAYERS + 1];
float g_flForceFirstPersonTime[MAXPLAYERS + 1];
bool g_bUserDataLoaded[MAXPLAYERS + 1];
int g_fButtonFlags[MAXPLAYERS + 1];
bool g_bSuppressDamageSound[MAXPLAYERS + 1];
int g_iPendingTeamNumber[MAXPLAYERS + 1];
int g_nBulletPenetrationCount[MAXPLAYERS + 1];
bool g_bShouldCollide[MAXPLAYERS + 1] = { true, ... };
char g_szDefaultArmsModel[MAXPLAYERS + 1][128];
ListenOverride g_iListenOverride[MAXPLAYERS + 1][MAXPLAYERS + 1];

// 좀비모드 동작에 필요한 개인 변수
bool g_bIsZombie[MAXPLAYERS + 1] = false;
int g_iVoiceCharacter[MAXPLAYERS + 1] =  { -1, ... };

int g_iFirstPenetertor[MAXPLAYERS + 1] = {-1, ...};
int g_iLastPenetertor[MAXPLAYERS + 1] = {-1, ...};
int g_nPenetrationCount[MAXPLAYERS + 1];

float g_flFirstInfectionTime[MAXPLAYERS + 1];
float g_flLastVirusDamagedTime[MAXPLAYERS + 1];

float g_vecSpawnPoint[MAXPLAYERS + 1][3]; // 스폰 시 각 플레이어들의 스폰 위치를 저장하여 이후 ztele 위치로 이용한다.
int g_nZteleCount[MAXPLAYERS + 1];

int g_nIncendiaryAmmo[MAXPLAYERS + 1];
int g_nExplosiveAmmo[MAXPLAYERS + 1];
int g_nArmorPiercingAmmo[MAXPLAYERS + 1];

// 좀비 관련 개인 변수
float g_flZombieRecoverTime[MAXPLAYERS + 1];
float g_flZombieBlockTime[MAXPLAYERS + 1];
float g_flHostZombieSkillTimer; // 숙주좀비 스킬 타이머 변수
float g_flGasZombieSkillTimer; // 변종좀비(가스) 스킬 타이머 변수
float g_flJumpZombieSkillTimer; // 변종좀비(도약) 스킬 타이머 변수

// 클래스 관련 개인 변수
int g_iClassId[MAXPLAYERS + 1];
int g_iPendingClassId[MAXPLAYERS + 1]; // 게임 도중 클래스를 바꾸려 할 때, 클래스 변경을 보류시킴

//대안, int형으로 개인변수 만든 다음, true 대신 EntRef를 통해 지급한 주총 레퍼런스를 담아,
//주총 엔티티가 없다면...
bool g_bWeaponCheck[MAXPLAYERS+1] = {false, ...};

// DB와 연동되는 클래스 개인 변수
int g_iClassLevel[MAXPLAYERS + 1][8];

// 스킬 관련 개인 변수
int g_iAmmoCrateClipAmount[MAXPLAYERS + 1]; // 클라이언트가 보유하고 있는, 탄약통에 들어가는 탄약량

int g_iBoardAmount[MAXPLAYERS + 1];
int g_iBoardOnPlaceControl[MAXPLAYERS + 1];
//int g_iBoardEntity[MAXPLAYERS + 1][2]; // new var
float g_flBoardHeight[MAXPLAYERS + 1];

char g_szConstClassName[][32] = 
{
	"없음",
	"보병(기동성)",	
	"보병(정확성)",
	"보병(화력성)",
	"저격병",
	"지원병",
	"의무병",
	"베테랑"
};

/****************** 모델/스킨 관련 설정 *****************/
#define MODEL_HOST_ZOMBIE	"models/player/kuristaja/walker/walker.mdl"
#define MODEL_JUMP_ZOMBIE	"models/player/pmodels/fast_zombie/fast_zombie.mdl"
#define MODEL_GAS_ZOMBIE	"models/player/mapeadores/morell/ghoul/ghoulfix.mdl"

char CommonZombieModels[][128] = 
{
	"models/player/kuristaja/zombies/bman/bman.mdl",
	"models/player/kuristaja/zombies/gozombie/gozombie.mdl",
	"models/player/kuristaja/zombies/police/police.mdl",
	"models/player/kuristaja/zombies/zpz/zpz.mdl",
	"models/player/kuristaja/zombies/skinny/skinny.mdl"
};

/****************** 아이템/상점 관련 설정 *****************/

enum ITEMINDICES
{
	Voucher,
	SupplyCrate,
	GiftBox,
	LightBox,
	SkinBox,
	SpecialSkinBox,
	HatBox,
	SupplyMoney,
	Parachute,
	Rocket,
	HalloweenBox,
	SentryGun
}
int g_iItemIndices[ITEMINDICES] =  { 0, ... };