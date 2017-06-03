#ifndef Rotophone_Parser_h
#define Rotophone_Parser_h


#include "Serial.h"




class SetModeCommandParser : public CommandParser {
public:
  virtual int parse(CommandDispatcher *dispatcher, uint8_t *buf, uint16_t size);
};

class HandshakeCommandParser : public CommandParser {
public:
  virtual int parse(CommandDispatcher *dispatcher, uint8_t *buf, uint16_t size);
};


class SetPosCommandParser : public CommandParser {
public:
  virtual int parse(CommandDispatcher *dispatcher, uint8_t *buf, uint16_t size);
};

class GenericCommandParser : public CommandParser {
public:
  GenericCommandParser()
  :type_(0)
  {}
  
  void begin(uint8_t type) {
    type_ = type;
  }

  virtual int parse(CommandDispatcher *dispatcher, uint8_t *buf, uint16_t size);

private:
  uint8_t type_;
};

class DataCommandParser : public CommandParser {
  public:
  DataCommandParser()
  :type_(0)
  {}

  void begin(uint8_t type) {
    type_ = type;
  }

  virtual int parse(CommandDispatcher *dispatcher, uint8_t *buf, uint16_t size);

 private:
 uint8_t type_;
};



class GenericCommandParserFactory : public CommandParserFactory {
public:
  GenericCommandParserFactory()
  {}

  virtual CommandParser* getParser(uint8_t cmd);

private:
  SetModeCommandParser setModeParser_;
  HandshakeCommandParser handshakeParser_;
  SetPosCommandParser setPosParser_;
  GenericCommandParser genericParser_;
  DataCommandParser dataParser_;

};





#endif // Rotophone_Parser_h
