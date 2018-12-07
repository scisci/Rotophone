//
//  MidiFileSequenceReader.cpp
//  Rotophone
//
//  Created by z on 12/7/18.
//  Copyright © 2018 Scientific Sciences. All rights reserved.
//

#include "MidiFileSequenceReader.hpp"
#include "MidiCore.hpp"

MidiFileSequenceReader::MidiFileSequenceReader(std::string filename)
:filename_(filename)
{}

std::vector<MidiTrack> MidiFileSequenceReader::ReadAllTracks(double timescale) const
{
  MidiFileIn file(filename_);
  
  const int num_tracks = file.getNumberOfTracks();

  MidiMessageSequenceBuilder builder;
  
  std::vector<MidiTrack> all_tracks;
  std::vector<unsigned char> buffer;
  for (int i = 0; i < num_tracks; ++i) {
    int64_t ticks = 0;
    while (true) {
      ticks += file.getNextMidiEvent(&buffer, i);
      if (buffer.empty()) {
        all_tracks.push_back(MidiTrack(0, builder.Duration(), builder.Build()));
        break;
      }
      const double tick_sec = file.getTickSeconds(i);
      int64_t timestamp = timescale * ticks * tick_sec;
      builder.AddEvent(timestamp, MidiMessage(buffer));
    }
  }
  return all_tracks;
};
