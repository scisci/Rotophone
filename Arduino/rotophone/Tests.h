#ifndef Rotophone_Tests_h
#define Rotophone_Tests_h

#include "Serial.h"
#include "EventQueue.h"
#include "Parser.h"
#include "Settings.h"



class SerialTester : public Stream {
public:
  SerialTester()
  :bufSize_(0),
   pos_(0) {}

  virtual int available() {
    return bufSize_ - pos_;
  }

  virtual int read() {
    if (pos_ >= bufSize_) {
      return -1;
    }

    return buf_[pos_++];
  }

  virtual int peek() {
    if (pos_ >= bufSize_) {
      return -1;
    }

    return buf_[pos_];
  }

  virtual void flush() {
    //?
  }

  virtual size_t write(uint8_t b) {
    buf_[bufSize_++] = b;
    return 1;
  }

  void reset() {
    bufSize_ = 0;
    pos_ = 0;
  }

private:
friend class Tests;
  uint8_t buf_[64];
  uint16_t bufSize_;
  uint16_t pos_;
};


class MockCommandHandler : public CommandHandler {
  public:
  MockCommandHandler(Stepper *stepper)
  :stepper_(stepper)
  {}
  
  virtual int handleCommand(Command *cmd) {
    if (cmd->type() == kSetPosCmd) {
      stepper_->setPosition(((SetPosCommand *)cmd)->pos);
      return COMMAND_HANDLED;
    }

    return COMMAND_UNHANDLED;
  }
  private:
  Stepper *stepper_;
};


class MockDataCommandHandler : public CommandHandler {
  public:
  MockDataCommandHandler()
  {}
  
  virtual int handleCommand(Command *cmd) {
    if (cmd->type() == kLoadCmd) {
      dataSize = ((DataCommand *)cmd)->dataSize;
      if (dataSize <= 128) {
        for (int i = 0; i < dataSize; i++) {
          data[i] = ((DataCommand *)cmd)->data[i];
        }
      }
      return COMMAND_HANDLED;
    }

    return COMMAND_UNHANDLED;
  }

  uint8_t data[128];
  uint8_t dataSize;
};





class MockSettingsCommandHandler : public CommandHandler {
  public:
  MockSettingsCommandHandler(Settings* settings)
  :settings_(settings)
  {}
  
  virtual int handleCommand(Command *cmd) {
    if (cmd->type() == kLoadCmd) {
      if (settings_->loadData((DataCommand *)cmd) < 0) {
        Serial.println("Error loading data");
      } else {
        Serial.println("Loaded data.");
      }
      return COMMAND_HANDLED;
    }

    return COMMAND_UNHANDLED;
  }

  private:
  Settings* settings_;
};

class Tests {
public:

   void testDataCommands() {
    Serial.println("testDataCommands() start");
    SerialTester tester;
    GenericCommandParserFactory parserFactory;
    MockDataCommandHandler commandHandler;
    CommandDispatcher dispatcher;
    dispatcher.pushCommandHandler(&commandHandler);
    SerialReader reader(&tester, &dispatcher, &parserFactory);

    tester.write(kSerialHeader);
    tester.write(kLoadCmd);
    tester.write(5);
    tester.write(100);
    tester.write(200);
    tester.write(230);
    tester.write(18);
    tester.write(kSerialTrailer);

    reader.read();

    if (commandHandler.data[0] != 100 ||
      commandHandler.data[1] != 200 ||
      commandHandler.data[2] != 230 ||
      commandHandler.dataSize != 3) {
        Serial.println("Error, load command data wrong");
      }
    Serial.println("testDataCommands() end");
   }


   void testLoadSave(Stepper* stepper) {
    Serial.println("testLoadSave() start");
    SerialTester tester;
    GenericCommandParserFactory parserFactory;
    
    Settings settings(stepper);
    MockSettingsCommandHandler commandHandler(&settings);
    CommandDispatcher dispatcher;
    dispatcher.pushCommandHandler(&commandHandler);
    SerialReader reader(&tester, &dispatcher, &parserFactory);

    int16_t offset = -230;
    tester.write(kSerialHeader);
    tester.write(kLoadCmd);
    uint8_t b = 0;
    uint8_t checksum = 0;
    tester.write(5);
    tester.write(b = DATA_VERSION);
    checksum += b;
    tester.write(b = (offset >> 8));
    checksum += b;
    tester.write(b = offset);
    checksum += b;
    tester.write(checksum);
    tester.write(kSerialTrailer);

    reader.read();


    int16_t zeroOffset = stepper->zeroOffset();
    Serial.print("Zero offset should be -230, got ");
    Serial.print(zeroOffset);
    Serial.println();

    stepper->setZeroOffset(1234);

    Serial.print("Zero offset should be 1234, got ");
    Serial.print(stepper->zeroOffset());
    Serial.println();

    EventQueue eventQueue;
    settings.saveData(&eventQueue);
    stepper->setZeroOffset(3219);

    Serial.print("Zero offset should be 3219, got ");
    Serial.print(stepper->zeroOffset());
    Serial.println();

    tester.reset();
    eventQueue.dispatchStream(&tester, eventQueue.size());
    // Patch the command name
    tester.buf_[1] = kLoadCmd;
    reader.read();

    Serial.print("Zero offset should be 1234, got ");
    Serial.print(stepper->zeroOffset());
    Serial.println();
    
    Serial.println("testLoadSave() end");
   }


   
   void testRead(Stepper *stepper) {
    
    Serial.println("testRead() start");
    
    SerialTester tester;
    GenericCommandParserFactory parserFactory;
    MockCommandHandler commandHandler(stepper);
    CommandDispatcher dispatcher;
    dispatcher.pushCommandHandler(&commandHandler);
    SerialReader reader(&tester, &dispatcher, &parserFactory);


    uint16_t pos = 512;
        tester.write(kSerialHeader);
    tester.write(kSetPosCmd);
  
    tester.write(pos >> 8);
    tester.write(pos);
    tester.write(kSerialTrailer);
  
    
  
     pos = 102;
    tester.write(kSerialHeader);
    tester.write(kSetPosCmd);
    tester.write(pos >> 8);
    tester.write(pos);
    tester.write(kSerialTrailer);
  
    reader.read();
  
    // Should go to 348
    long target = stepper->accelStepper()->targetPosition();
    Serial.print("target should be at 348, got ");
    Serial.print(target);
    Serial.println();

    

    stepper->runToPosition();

    uint16_t param = stepper->positionParam(stepper->stepCount());
    Serial.print("param should be at 102, got ");
    Serial.print(param);
    Serial.println();


     pos = 999;
    tester.write(kSerialHeader);
    tester.write(kSetPosCmd);
    tester.write(pos >> 8);
    tester.write(pos);
    tester.write(kSerialTrailer);

    reader.read();

    target = stepper->accelStepper()->targetPosition();
    Serial.print("target should be at -85, got ");
    Serial.print(target);
    Serial.println();
    
  
    Serial.println("testRead() end");
  }


  void testEventQueue() {

    EventQueue eventQueue;
    Serial.println("testEventQueue() start");
  
    uint8_t* q = eventQueue.internalQueue();
    
    uint8_t testBuffer[] = {
      kSerialHeader,
      kErrEvent,
      12345 >> 8,
      12345 & 0xFF,
      kSerialTrailer
    };

    uint16_t offset = eventQueue.start();
    bool result = eventQueue.addErrorEvent(12345);
    if (!result) {
      Serial.println("Failed to add error");
    }

    for (int i = 0; i < 5; i++) {
      if (q[i] != testBuffer[i]) {
        Serial.print("Incorrect buffer at position ");
        Serial.print(i);
        Serial.print(". Should be ");
        Serial.print((int)testBuffer[i]);
        Serial.print(" but got ");
        Serial.print((int)q[i]);
        Serial.print("!\n");
      }
    }
  
    for (int i = 0; i < 24; i++) {
      result = eventQueue.addErrorEvent(12345);
      if (!result) {
         Serial.println("Failed to add error");
      }
    }
  
    // We now should be at position 125, if we add an error it would overflow
    result = eventQueue.addErrorEvent(12345);
    if (result) {
      Serial.println("add error when buffer full succeeded!, should have failed");
    }
  
  
    // Lets write out once
    int available = eventQueue.dispatch(EVENT_QUEUE_NONBLOCK);
  
    if (eventQueue.size() != 125 - available) {
      Serial.print("after dump, event queue size is ");
      Serial.print(eventQueue.size());
      Serial.print(" but should be ");
      Serial.print((int)125 - available);
      Serial.println(" \n");
    }
  
    result = eventQueue.addErrorEvent(12345);
    if (!result) {
      Serial.println("Failed to add error");
    }
  
    // Our event queue position should have wrapped around now
    // and should be ending at position 2
    eventQueue.addErrorEvent(23456);
    testBuffer[2] = 23456 >> 8;
    testBuffer[3] = 23456 & 0xFF;
  
    for (int i = 0; i < 5; i++) {
      if (q[i + 2] != testBuffer[i]) {
        Serial.print("Incorrect buffer, should be ");
        Serial.print((int)testBuffer[i]);
        Serial.print(" but got ");
        Serial.print((int)q[i]);
        Serial.print("!\n");
      }
    }
    
  
    Serial.println("testEventQueue() end");
  }
};




#endif // Rotophone_Tests_h

