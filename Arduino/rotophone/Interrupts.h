#ifndef Rotophone_Interrupts_h
#define Rotophone_Interrupts_h

class ProximityHandler {
public:
  virtual void handleProximity() = 0;
};


class ProximityInterrupt {
public:
  ProximityInterrupt()
  :handler_(NULL)
  {}
  
  void setHandler(ProximityHandler *handler) {
    if (handler == handler_) {
      return;
    }

    ProximityHandler* last = handler_;
    handler_ = handler;

    if (last == NULL) {
      attachProximity();
    } else if (handler_ == NULL) {
      detachProximity();
    }
  }

  void fireProximity() {
    if (handler_ != NULL) {
      handler_->handleProximity();
    }
  }

protected:
  virtual void attachProximity() = 0;
  virtual void detachProximity() = 0;
  ProximityHandler* handler_;
};

#endif // Rotophone_Interrupts_h
