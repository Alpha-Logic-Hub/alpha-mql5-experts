//+------------------------------------------------------------------+
//| Core Definitions — structs, enums, constants                     |
//+------------------------------------------------------------------+

struct Zone {
   double   top;
   double   bottom;
   datetime startTime;
   double   initialCVD;
   bool     active;
   bool     traded;
   string   objName;
};

enum ENUM_MARKET_SESSION {
   SESSION_ASIA,
   SESSION_LONDON,
   SESSION_NY,
   SESSION_OFF
};

#define MAGIC_SMC    InpMagicNumber
#define MAGIC_SR     InpMagicNumber + 1
#define MAGIC_SHARK  InpMagicNumber + 2
