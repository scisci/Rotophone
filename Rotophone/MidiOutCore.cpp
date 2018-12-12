//
//  MidiOutCore.cpp
//  Rotophone
//
//  Created by z on 12/10/18.
//  Copyright © 2018 Scientific Sciences. All rights reserved.
//

#include "MidiOutCore.hpp"


// This function was submitted by Douglas Casey Tucker and apparently
// derived largely from PortMidi.
static CFStringRef EndpointName( MIDIEndpointRef endpoint, bool isExternal )
{
  CFMutableStringRef result = CFStringCreateMutable( NULL, 0 );
  CFStringRef str;

  // Begin with the endpoint's name.
  str = NULL;
  MIDIObjectGetStringProperty( endpoint, kMIDIPropertyName, &str );
  if ( str != NULL ) {
    CFStringAppend( result, str );
    CFRelease( str );
  }

  MIDIEntityRef entity = 0;
  MIDIEndpointGetEntity( endpoint, &entity );
  if ( entity == 0 )
    // probably virtual
    return result;

  if ( CFStringGetLength( result ) == 0 ) {
    // endpoint name has zero length -- try the entity
    str = NULL;
    MIDIObjectGetStringProperty( entity, kMIDIPropertyName, &str );
    if ( str != NULL ) {
      CFStringAppend( result, str );
      CFRelease( str );
    }
  }
  // now consider the device's name
  MIDIDeviceRef device = 0;
  MIDIEntityGetDevice( entity, &device );
  if ( device == 0 )
    return result;

  str = NULL;
  MIDIObjectGetStringProperty( device, kMIDIPropertyName, &str );
  if ( CFStringGetLength( result ) == 0 ) {
      CFRelease( result );
      return str;
  }
  if ( str != NULL ) {
    // if an external device has only one entity, throw away
    // the endpoint name and just use the device name
    if ( isExternal && MIDIDeviceGetNumberOfEntities( device ) < 2 ) {
      CFRelease( result );
      return str;
    } else {
      if ( CFStringGetLength( str ) == 0 ) {
        CFRelease( str );
        return result;
      }
      // does the entity name already start with the device name?
      // (some drivers do this though they shouldn't)
      // if so, do not prepend
        if ( CFStringCompareWithOptions( result, /* endpoint name */
             str /* device name */,
             CFRangeMake(0, CFStringGetLength( str ) ), 0 ) != kCFCompareEqualTo ) {
        // prepend the device name to the entity name
        if ( CFStringGetLength( result ) > 0 )
          CFStringInsert( result, 0, CFSTR(" ") );
        CFStringInsert( result, 0, str );
      }
      CFRelease( str );
    }
  }
  return result;
}

// This function was submitted by Douglas Casey Tucker and apparently
// derived largely from PortMidi.
static CFStringRef ConnectedEndpointName( MIDIEndpointRef endpoint )
{
  CFMutableStringRef result = CFStringCreateMutable( NULL, 0 );
  CFStringRef str;
  OSStatus err;
  int i;

  // Does the endpoint have connections?
  CFDataRef connections = NULL;
  int nConnected = 0;
  bool anyStrings = false;
  err = MIDIObjectGetDataProperty( endpoint, kMIDIPropertyConnectionUniqueID, &connections );
  if ( connections != NULL ) {
    // It has connections, follow them
    // Concatenate the names of all connected devices
    nConnected = CFDataGetLength( connections ) / sizeof(MIDIUniqueID);
    if ( nConnected ) {
      const SInt32 *pid = (const SInt32 *)(CFDataGetBytePtr(connections));
      for ( i=0; i<nConnected; ++i, ++pid ) {
        MIDIUniqueID id = EndianS32_BtoN( *pid );
        MIDIObjectRef connObject;
        MIDIObjectType connObjectType;
        err = MIDIObjectFindByUniqueID( id, &connObject, &connObjectType );
        if ( err == noErr ) {
          if ( connObjectType == kMIDIObjectType_ExternalSource  ||
              connObjectType == kMIDIObjectType_ExternalDestination ) {
            // Connected to an external device's endpoint (10.3 and later).
            str = EndpointName( (MIDIEndpointRef)(connObject), true );
          } else {
            // Connected to an external device (10.2) (or something else, catch-
            str = NULL;
            MIDIObjectGetStringProperty( connObject, kMIDIPropertyName, &str );
          }
          if ( str != NULL ) {
            if ( anyStrings )
              CFStringAppend( result, CFSTR(", ") );
            else anyStrings = true;
            CFStringAppend( result, str );
            CFRelease( str );
          }
        }
      }
    }
    CFRelease( connections );
  }
  if ( anyStrings )
    return result;

  CFRelease( result );

  // Here, either the endpoint had no connections, or we failed to obtain names
  return EndpointName( endpoint, false );
}


//*********************************************************************//
//  API: OS-X
//  Class Definitions: MidiOutCore
//*********************************************************************//

MidiOutCore :: MidiOutCore( const std::string &clientName )
:connected_(false),
 client_(0),
 endpoint_(0)
{
  // Set up our client.
  CFStringRef name = CFStringCreateWithCString( NULL, clientName.c_str(), kCFStringEncodingASCII );
  OSStatus result = MIDIClientCreate(name, NULL, NULL, &client_ );
  CFRelease( name );
  if ( result != noErr ) {
    throw "MidiInCore::initialize: error creating OS-X MIDI client object";
  }
}

MidiOutCore :: ~MidiOutCore( void )
{
  // Close a connection if it exists.
  MidiOutCore::closePort();

  // Cleanup.
  MIDIClientDispose(client_);
  if (endpoint_) MIDIEndpointDispose(endpoint_);
}


unsigned int MidiOutCore :: getPortCount()
{
  CFRunLoopRunInMode( kCFRunLoopDefaultMode, 0, false );
  return MIDIGetNumberOfDestinations();
}

std::string MidiOutCore :: getPortName( unsigned int portNumber )
{
  CFStringRef nameRef;
  MIDIEndpointRef portRef;
  char name[128];

  std::string stringName;
  CFRunLoopRunInMode( kCFRunLoopDefaultMode, 0, false );
  if ( portNumber >= MIDIGetNumberOfDestinations() ) {
    throw "MidiOutCore::getPortName: the 'portNumber' argument is invalid";
  }

  portRef = MIDIGetDestination( portNumber );
  nameRef = ConnectedEndpointName(portRef);
  CFStringGetCString( nameRef, name, sizeof(name), kCFStringEncodingUTF8 );
  CFRelease( nameRef );
  
  return stringName = name;
}

void MidiOutCore :: openPort( unsigned int portNumber, const std::string &portName )
{
  if ( connected_ ) {
    throw "MidiOutCore::openPort: a valid connection already exists!";
  }

  CFRunLoopRunInMode( kCFRunLoopDefaultMode, 0, false );
  unsigned int nDest = MIDIGetNumberOfDestinations();
  if (nDest < 1) {
    throw "MidiOutCore::openPort: no MIDI output destinations found!";
  }

  if ( portNumber >= nDest ) {
    throw "MidiOutCore::openPort: the 'portNumber' argument is invalid";
  }

  MIDIPortRef port;
  CFStringRef portNameRef = CFStringCreateWithCString( NULL, portName.c_str(), kCFStringEncodingASCII );
  OSStatus result = MIDIOutputPortCreate( client_,
                                          portNameRef,
                                          &port );
  CFRelease( portNameRef );
  if ( result != noErr ) {
    throw "MidiOutCore::openPort: error creating OS-X MIDI output port.";
  }

  // Get the desired output port identifier.
  MIDIEndpointRef destination = MIDIGetDestination( portNumber );
  if ( destination == 0 ) {
    MIDIPortDispose( port );
    throw "MidiOutCore::openPort: error getting MIDI output destination reference.";
  }

  // Save our api-specific connection information.
  port_ = port;
  destinationID_ = destination;
  connected_ = true;
}

void MidiOutCore :: closePort( void )
{
  if (endpoint_) {
    MIDIEndpointDispose( endpoint_ );
    endpoint_ = 0;
  }

  if (port_) {
    MIDIPortDispose(port_);
    port_ = 0;
  }

  connected_ = false;
}


void MidiOutCore :: openVirtualPort( const std::string &portName )
{
  if (endpoint_ ) {
    throw "MidiOutCore::openVirtualPort: a virtual output port already exists!";
  }

  // Create a virtual MIDI output source.
  MIDIEndpointRef endpoint;
  CFStringRef portNameRef = CFStringCreateWithCString( NULL, portName.c_str(), kCFStringEncodingASCII );
  OSStatus result = MIDISourceCreate( client_,
                                      portNameRef,
                                      &endpoint );
  CFRelease( portNameRef );
  
  if ( result != noErr ) {
    throw "MidiOutCore::initialize: error creating OS-X virtual MIDI source.";
  }

  // Save our api-specific connection information.
  endpoint_ = endpoint;
}

// Merges the second list into the first
void MidiOutCore::PacketListMerge(MIDIPacketList *dst, ByteCount dst_size, MIDIPacketList *lhs, MIDIPacketList *rhs)
{
  UInt32 lhs_count = lhs->numPackets;
  UInt32 rhs_count = rhs->numPackets;
  
  MIDIPacket *lhs_packet = lhs_count > 0 ? &lhs->packet[0] : nullptr;
  MIDIPacket *rhs_packet = rhs_count > 0 ? &rhs->packet[0] : nullptr;
  
  MIDIPacket *cursor = MIDIPacketListInit(dst);
  while (lhs_count || rhs_count) {
    if (lhs_count && (!rhs_count || lhs_packet->timeStamp <= rhs_packet->timeStamp)) {
      cursor = MIDIPacketListAdd(dst, dst_size, cursor, lhs_packet->timeStamp, lhs_packet->length, lhs_packet->data);
      lhs_packet = MIDIPacketNext(lhs_packet);
      --lhs_count;
    } else if (rhs_count) {
      cursor = MIDIPacketListAdd(dst, dst_size, cursor, rhs_packet->timeStamp, rhs_packet->length, rhs_packet->data);
      rhs_packet = MIDIPacketNext(rhs_packet);
      --rhs_count;
    }
  }
}

MIDIPacket* MidiOutCore :: PacketListAdd(MIDIPacketList *pktlist, ByteCount listSize, MIDIPacket *packet, MIDITimeStamp time, ByteCount nData, const Byte *data)
{
  ByteCount remainingBytes = nData;
  while (remainingBytes && packet) {
    ByteCount bytesForPacket = remainingBytes > 65535 ? 65535 : remainingBytes; // 65535 = maximum size of a MIDIPacket
    const Byte* dataStartPtr = (const Byte *) &data[nData - remainingBytes];
    packet = MIDIPacketListAdd( pktlist, listSize, packet, time, bytesForPacket, dataStartPtr);
    remainingBytes -= bytesForPacket;
  }
  
  return packet;
}

void MidiOutCore::SendPacketList(MIDIPacketList *packet_list)
{
  // Send to any destinations that may have connected to us.
  if (endpoint_) {
    OSStatus result = MIDIReceived(endpoint_, packet_list);
    if ( result != noErr ) {
      throw "MidiOutCore::sendMessage: error sending MIDI to virtual destinations.";
    }
  }

  // And send to an explicit destination port if we're connected.
  if (connected_) {
    OSStatus result = MIDISend( port_, destinationID_, packet_list);
    if ( result != noErr ) {
      throw "MidiOutCore::sendMessage: error sending MIDI message to port.";
    }
  }
}


void MidiOutCore :: sendMessage( const unsigned char *message, size_t size )
{
  // We use the MIDISendSysex() function to asynchronously send sysex
  // messages.  Otherwise, we use a single CoreMidi MIDIPacket.
  unsigned int nBytes = static_cast<unsigned int> (size);
  if ( nBytes == 0 ) {
    throw "MidiOutCore::sendMessage: no data in message argument!";
  }

  MIDITimeStamp timeStamp = AudioGetCurrentHostTime();

  if ( message[0] != 0xF0 && nBytes > 3 ) {
    throw "MidiOutCore::sendMessage: message format problem ... not sysex but > 3 bytes?";
  }

  Byte buffer[nBytes+(sizeof(MIDIPacketList))];
  ByteCount listSize = sizeof(buffer);
  MIDIPacketList *packetList = (MIDIPacketList*)buffer;
  MIDIPacket *packet = MIDIPacketListInit( packetList );
  
  packet = MidiOutCore::PacketListAdd(packetList, listSize, packet, timeStamp, nBytes, &message[0]);
/*
  ByteCount remainingBytes = nBytes;
  while (remainingBytes && packet) {
    ByteCount bytesForPacket = remainingBytes > 65535 ? 65535 : remainingBytes; // 65535 = maximum size of a MIDIPacket
    const Byte* dataStartPtr = (const Byte *) &message[nBytes - remainingBytes];
    packet = MIDIPacketListAdd( packetList, listSize, packet, timeStamp, bytesForPacket, dataStartPtr);
    remainingBytes -= bytesForPacket;
  }
*/
  if ( !packet ) {
    throw "MidiOutCore::sendMessage: could not allocate packet list";
  }

  SendPacketList(packetList);
}
