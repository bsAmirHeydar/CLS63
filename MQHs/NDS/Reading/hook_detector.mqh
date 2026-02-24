#ifndef __NDS_HOOK_DETECTOR_MQH__
#define __NDS_HOOK_DETECTOR_MQH__

#include "..\\Core\\nds_entities.mqh"
#include "..\\Core\\nds_config.mqh"
#include "hook_engine.mqh"

class NdsHookDetector
  {
private:
   NdsHookEngine      m_engine;

public:
   void              Configure(const string symbol,const NdsConfig &cfg)
      {
      m_engine.Configure(symbol,cfg);
      }

   NdsHookState      Detect(const ENUM_TIMEFRAMES tf) const
      {
      return m_engine.DetectLatest(tf);
      }
  };

#endif
