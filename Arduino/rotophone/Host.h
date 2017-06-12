#ifndef Rotophone_Host_h
#define Rotophone_Host_h

#define HEART_BEAT_INTERVAL 5000
#define HANDSHAKE_INTERVAL 15000


#include "EventQueue.h"
#include "Serial.h"

class Host {
public:
  Host(EventQueue *eventQueue, CommandDispatcher* dispatcher)
  :lastHeartBeat_(0),
   lastHandshake_(0),
   startTime_(0),
   handshakeID_(-1),
   eventQueue_(eventQueue),
   dispatcher_(dispatcher)
  {}

  void handleHandshakeCmd(HandshakeCommand *cmd) {
    unsigned long now = millis();

    int handshakeID = ((HandshakeCommand *)cmd)->handshakeID;
    bool requiresResponse = handshakeID_ != handshakeID;
    handshakeID_ = handshakeID;
    lastHandshake_ = now;
    startTime_ = now;

    if (requiresResponse) {
      // Emit it back
      dispatcher_->dispatchGenericCommand(kFoundHostCmd);
    }
  }

  bool isConnected() {
    return handshakeID_ > -1;
  }

  int handshakeID() {
    return handshakeID_;
  }

  unsigned long startTime() {
    return startTime_;
  }

  void run(unsigned long now) {
    // Dispatch the handshake signal if we have a host
    if (handshakeID_ > -1 && now - lastHeartBeat_ > HEART_BEAT_INTERVAL) {
      lastHeartBeat_ = now;
      eventQueue_->addHeartBeatEvent();
    }

    if (handshakeID_ > -1 && now - lastHandshake_ > HANDSHAKE_INTERVAL) {
      lastHeartBeat_ = 0;
      lastHandshake_ = 0;
      handshakeID_ = -1;
      Serial.println("Lost connection.");
      dispatcher_->dispatchGenericCommand(kLostHostCmd);
    }
  }

private:
  unsigned long lastHeartBeat_;
  unsigned long lastHandshake_;
  unsigned long startTime_;
  int handshakeID_;
  EventQueue *eventQueue_;
  CommandDispatcher *dispatcher_;
};


#endif // #Rotophone_Host_h
