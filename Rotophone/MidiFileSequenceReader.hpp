//
//  MidiFileSequenceReader.hpp
//  Rotophone
//
//  Created by z on 12/7/18.
//  Copyright © 2018 Scientific Sciences. All rights reserved.
//

#ifndef MidiFileSequenceReader_hpp
#define MidiFileSequenceReader_hpp

#include "MidiFileIn.hpp"
#include "MidiCore.hpp"

class MidiFileSequenceReader {
public:
  MidiFileSequenceReader(std::string file_name);
  std::vector<MidiTrack> ReadAllTracks(double timescale) const;
  
private:
  std::string filename_;
};

#endif /* MidiFileSequenceReader_hpp */
