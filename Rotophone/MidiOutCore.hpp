//
//  MidiOutCore.hpp
//  Rotophone
//
//  Created by z on 12/10/18.
//  Copyright © 2018 Scientific Sciences. All rights reserved.
//

#ifndef MidiOutCore_hpp
#define MidiOutCore_hpp

#include <string>


// OS-X CoreMIDI header files.
#include <CoreMIDI/CoreMIDI.h>
#include <CoreAudio/HostTime.h>
#include <CoreServices/CoreServices.h>



class MidiOutCore
{
 public:
  MidiOutCore( const std::string &clientName=std::string("CoreMidiOut") );
  ~MidiOutCore( void );
  void openPort( unsigned int portNumber, const std::string &portName=std::string( "CoreMidiOutPort" )  );
  void openVirtualPort( const std::string &portName );
  void closePort( void );
  unsigned int getPortCount( void );
  std::string getPortName( unsigned int portNumber );
  void sendMessage( const unsigned char *message, size_t size );
  void SendPacketList(MIDIPacketList *packet_list);
  static MIDIPacket* PacketListAdd(MIDIPacketList *pktlist, ByteCount listSize, MIDIPacket *curPacket, MIDITimeStamp time, ByteCount nData, const Byte *data);
  static void PacketListMerge(MIDIPacketList *dst, ByteCount dst_size, MIDIPacketList *lhs, MIDIPacketList *rhs);
private:
  bool connected_;
  MIDIClientRef client_;
  MIDIPortRef port_;
  MIDIEndpointRef endpoint_;
  MIDIEndpointRef destinationID_;
  
};


#endif /* MidiOutCore_hpp */
