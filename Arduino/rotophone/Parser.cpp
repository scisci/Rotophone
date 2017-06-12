#include "Parser.h"


CommandParser* GenericCommandParserFactory::getParser(uint8_t cmd) {
  switch (cmd) {
    case kSetModeCmd:
      return &setModeParser_;
     case kSetPosCmd:
      return &setPosParser_;
     case kHandshakeCmd:
      return &handshakeParser_;
     case kLoadCmd:
      dataParser_.begin(cmd);
      return &dataParser_;
     case kZeroCmd:
     case kSaveCmd:
      genericParser_.begin(cmd);
      return &genericParser_;
     default: return NULL;
  }
}


int parserStatus(uint16_t expected, uint8_t *buf, uint16_t size) {
  if (size == expected + 1) {
    if (buf[expected] != kSerialTrailer) {
      return -1;
    }

    return 0; // Done
  }

  return expected + 1 - size;
}

int SetModeCommandParser::parse(CommandDispatcher *dispatcher, uint8_t *buf, uint16_t size) {
  int status = parserStatus(1, buf, size);
  if (status == 0) {
    dispatcher->dispatchSetModeCommand(buf[0]);
  }
  return status;
}

int HandshakeCommandParser::parse(CommandDispatcher *dispatcher, uint8_t *buf, uint16_t size) {
  int status = parserStatus(1, buf, size);
  if (status == 0) {
    dispatcher->dispatchHandshakeCommand(buf[0]);
  }
  return status;
}

int SetPosCommandParser::parse(CommandDispatcher *dispatcher, uint8_t *buf, uint16_t size) {
  int status = parserStatus(2, buf, size);
  if (status == 0) {
    dispatcher->dispatchSetPosCommand(buf[0] << 8 | buf[1]);
  }
  return status;
}

int GenericCommandParser::parse(CommandDispatcher *dispatcher, uint8_t *buf, uint16_t size) {
  int status = parserStatus(0, buf, size);
  if (status == 0) {
    dispatcher->dispatchGenericCommand(type_);
  }
  return status;
}

int DataCommandParser::parse(CommandDispatcher *dispatcher, uint8_t *buf, uint16_t size) {
  if (size == 0) {
    return 1;
  }
  // buf[0] contains the number of payload bytes, including the size and checksum fields
  int status = parserStatus(buf[0], buf, size);
  Serial.print("Parsing bytes 0 -");
  Serial.print(size);
  Serial.print(" result is ");
  Serial.print(status);
  Serial.println();
  if (status == 0) {
    // We need at least 1 byte + count, + checksum + semicolon;
    if (size < 4) {
      Serial.println("not enough bytes");
      return -1;
    }
    // We now could check the checksum, add from byte 1 through to before the ;
    uint8_t checksum = 0;
    for (int i = 1; i < size - 2; i++) {
      checksum += buf[i];
    }
    if (checksum != buf[size - 2]) {
      Serial.print("checksum failed! got ");
      Serial.print((int)checksum);
      Serial.print(" expected ");
      Serial.print((int)buf[size - 2]);
      Serial.println();
      return -1;
    }

    // The full size minus, first count byte, last semicolon, last checksum
    dispatcher->dispatchDataCommand(type_, &buf[1], size - 3);
  }
  return status;
}
