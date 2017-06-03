#ifndef Rotophone_Protocol_h
#define Rotophone_Protocol_h

extern const unsigned char kSerialHeader;
extern const unsigned char kSerialTrailer;

#define kSetPositionBound 0x400 // 1024 This must be a power of 2!, this is def instead of const so it can be optimized

typedef enum {
  kErrEvent = 'E',
  kHandshakeEvent = 'H',
  kHeartBeatEvent = '*',
  kCurModeEvent = 'M',
  kCurPosEvent = 'P',
  kSaveEvent = 'S'
} TxEvent;

typedef enum {
  kModeCompleteCmd = 'c',
  kHandshakeCmd = 'H',
  kLoadCmd = 'L',
  kSetModeCmd = 'M',
  kSetPosCmd = 'P',
  kSaveCmd = 'S',
  kZeroCmd = 'Z'
} RxCmd;

typedef enum {
  kModeUnknown = 0,
  kModeStartup = 1,
  kModeIdle = 2,
  kModeRun = 3,
  kModeCalibrate = 4,
  kModeLowPower = 5
} ModeType;

typedef enum {
  kErrCodeNone,
  kErrCodeNotReady,
  kErrCodeInvalidMode,
  kErrCodeNeedsCalibration,
  kErrCodeCalibrationFailed,
  kErrCodeZeroWhileMoving,
  kErrCodeStartupAfterLowPower,
  kErrIncorrectDataFormat
} ErrCode;

#endif // Rotophone_Protocol_h
