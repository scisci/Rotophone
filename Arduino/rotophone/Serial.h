#ifndef Rotophone_Serial_h
#define Rotophone_Serial_h

#include "Protocol.h"
#include "Pins.h"
#if ARDUINO >= 100
#include <Arduino.h>
#else
#include <WProgram.h>
#endif



#define SERIAL_RX_MAX_CMD_SIZE 64

#define COMMAND_HANDLED 0
#define COMMAND_UNHANDLED -1


class Command {
public:
  Command(uint8_t type)
  :type_(type)
  {}
  
  uint8_t type() {
    return type_;
  }

protected:
  uint8_t type_;
};

class CommandHandler {
public:
  virtual int handleCommand(Command *command) = 0;
};
 

class SetModeCommand : public Command {
public:
  SetModeCommand()
  :Command(kSetModeCmd),
   mode(0)
  {}

  uint8_t mode;
};


class HandshakeCommand : public Command {
public:
  HandshakeCommand()
  :Command(kHandshakeCmd),
   handshakeID(0)
  {}
  
  uint8_t handshakeID;
};


class SetPosCommand : public Command {
public:
  SetPosCommand()
  :Command(kSetPosCmd),
   pos(0)
  {}

  uint16_t pos;
};

class GenericCommand : public Command {
public:
  GenericCommand()
  :Command(0)
  {}

  void setType(uint8_t type) {
    type_ = type;
  }
};

class DataCommand : public Command {
public:
  DataCommand()
  :Command(0),
   dataSize(0),
   data(NULL)
  {}

  void setTypeAndData(uint8_t type, uint8_t* buf, uint16_t bufSize) {
    type_ = type;
    data = buf;
    dataSize = bufSize;
  }

  uint8_t* data;
  uint16_t dataSize;
};




class CommandDispatcher {
public:
  CommandDispatcher()
  :commandHandlerCount_(0){}

  
  void pushCommandHandler(CommandHandler *handler) {
    commandHandlers_[commandHandlerCount_++] = handler;
  }

  void popCommandHandler(CommandHandler *handler) {
    for (int i = commandHandlerCount_ - 1; i >= 0; --i) {
      if (commandHandlers_[i] == handler) {
        commandHandlerCount_ = i;
        break;
      }
    }
  }

  int dispatchCommand(Command *cmd) {
    // Pass on to handler
    for (int i = commandHandlerCount_ - 1; i >= 0; --i) {
      if (commandHandlers_[i]->handleCommand(cmd) == COMMAND_HANDLED) {
        return COMMAND_HANDLED;
      }
    }

    return COMMAND_UNHANDLED;
  }

  int dispatchSetModeCommand(uint8_t mode) {
    setModeCommand_.mode = mode;
    return dispatchCommand(&setModeCommand_);
  }

  int dispatchSetPosCommand(uint16_t pos) {
    setPosCommand_.pos = pos;
    return dispatchCommand(&setPosCommand_);
  }

  int dispatchHandshakeCommand(uint8_t handshakeID) {
    handshakeCommand_.handshakeID = handshakeID;
    return dispatchCommand(&handshakeCommand_);
  }

  int dispatchGenericCommand(uint8_t type) {
    genericCommand_.setType(type);
    return dispatchCommand(&genericCommand_);
  }

  int dispatchDataCommand(uint8_t type, uint8_t *data, uint16_t size) {
    dataCommand_.setTypeAndData(type, data, size);
    return dispatchCommand(&dataCommand_);
  }

private:
  CommandHandler *commandHandlers_[8];
  uint8_t commandHandlerCount_;

  SetPosCommand setPosCommand_;
  HandshakeCommand handshakeCommand_;
  SetModeCommand setModeCommand_;
  GenericCommand genericCommand_;
  DataCommand dataCommand_;
};


class CommandParser {
public:
  virtual int parse(CommandDispatcher *dispatcher, uint8_t *buffer, uint16_t size) = 0;
};

class CommandParserFactory {
public:
  virtual CommandParser* getParser(uint8_t cmd) = 0;
};


class SerialReader {
public:
  SerialReader(Stream *reader, CommandDispatcher *dispatcher, CommandParserFactory* factory)
  :reader_(reader),
   commandDispatcher_(dispatcher),
   commandParser_(NULL),
   commandParserFactory_(factory),
   serialRxPos_(0),
   serialRxCmd_(0)
  {}

  void setCommandParserFactory(CommandParserFactory *factory) {
    commandParserFactory_ = factory;
  }


  
  
  void read() {
    int b;
    
    while ((b = reader_->read()) != -1) {
      if (serialRxPos_ > 1) {
        serialRxBuffer_[serialRxPos_++] = b;
        if (commandParser_ == NULL) {
          // Should never get here, but just in case
          serialRxPos_ = 0;
        } else {
          int res = commandParser_->parse(commandDispatcher_, &serialRxBuffer_[2], serialRxPos_ - 2);
          if (res <= 0) {
            // Done or error
            serialRxPos_ = 0;
            commandParser_ = NULL;
            if (res == 0) {
              continue;
            } else {
//#ifdef TESTS
              Serial.println("Error parsing.");
//#endif
            }
          } else {
            continue;
          }
        }
      }
  
      if (serialRxPos_ == 1) {
        if (commandParserFactory_ != NULL &&
            (commandParser_ = commandParserFactory_->getParser(b)) != NULL) {
          serialRxBuffer_[serialRxPos_++] = serialRxCmd_ = b;
          continue;
        }
        
        serialRxPos_ = 0;
      }
      
      if (serialRxPos_ == 0) {
        if (b == kSerialHeader) {
          serialRxBuffer_[serialRxPos_++] = b;
        }
      }
    }
  }

private:
  Stream *reader_;
  CommandParser *commandParser_;
  CommandParserFactory *commandParserFactory_;
  CommandDispatcher *commandDispatcher_;
  uint8_t serialRxPos_;
uint8_t serialRxCmd_;

uint8_t serialRxBuffer_[SERIAL_RX_MAX_CMD_SIZE];

};


#endif // Rotophone_Serial_h
