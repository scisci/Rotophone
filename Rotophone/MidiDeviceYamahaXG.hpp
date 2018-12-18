//
//  MidiDeviceYamahaXG.hpp
//  Rotophone
//
//  Created by z on 12/13/18.
//  Copyright © 2018 Scientific Sciences. All rights reserved.
//

#ifndef MidiDeviceYamahaXG_h
#define MidiDeviceYamahaXG_h

#include "MidiCore.hpp"


struct XGVoice {
  int program_num;
  int bank_num;
};


static const XGVoice kXGGrandPno = {0, 0};
static const XGVoice kXGGrandPnoK = {0, 1};

static const XGVoice kXGGtNylonGtr = {24, 0};
static const XGVoice kXGGtNylonGt2 = {24, 16};
static const XGVoice kXGGtNylonGt3 = {24, 25};
static const XGVoice kXGGtVelGtHrm = {24, 43};
static const XGVoice kXGGtUkulele = {24, 96};
static const XGVoice kXGGtSteelGtr = {24, 0};
static const XGVoice kXGGtSteelGt2 = {24, 0};
static const XGVoice kXGGt12StrGtr = {24, 0};
static const XGVoice kXGGtNylnStl = {24, 0};
static const XGVoice kXGGtStlBody = {24, 0};
static const XGVoice kXGGtMandolin = {24, 0};
static const XGVoice kXGGtJazz = {24, 0};
static const XGVoice kXGGtGtr = {24, 0};
static const XGVoice kXGGtMelloGtr = {24, 0};
static const XGVoice kXGGtJazzAmp = {24, 0};
static const XGVoice kXGGtPdlSteel = {24, 0};
static const XGVoice kXGGtCleanGtr = {24, 0};
static const XGVoice kXGGtChorusGt = {24, 0};
static const XGVoice kXGGtMidTGtr = {24, 0};
static const XGVoice kXGGtMidTGtSt = {24, 0};
static const XGVoice kXGGtMuteGtr = {24, 0};
static const XGVoice kXGGtFunkGtr1 = {24, 0};
static const XGVoice kXGGtMuteStlG = {24, 0};
static const XGVoice kXGGtFunkGtr2 = {24, 0};
static const XGVoice kXGGtJazz1 = {24, 0};
static const XGVoice kXGGtMan = {24, 0};
static const XGVoice kXGGtMuDstGt = {24, 0};
static const XGVoice kXGGtOvrdrive = {24, 0};
static const XGVoice kXGGtGtPinch = {24, 0};
static const XGVoice kXGGtDistGtr = {24, 0};
static const XGVoice kXGGtDstRthmG = {24, 0};
static const XGVoice kXGGtDistGtr2 = {30, 24}; // good
static const XGVoice kXGGtDistGtr3 = {24, 0};
static const XGVoice kXGGtPowerGt2 = {24, 0};
static const XGVoice kXGGtPowerGt1 = {24, 0};
static const XGVoice kXGGtDst5ths = {24, 0};
static const XGVoice kXGGtFeedbkGt = {24, 0};
static const XGVoice kXGGtFeedbkG2 = {24, 0};
static const XGVoice kXGGtRckRthm2 = {24, 0};
static const XGVoice kXGGtRckRthm1 = {24, 0};
static const XGVoice kXGGtGtrHarmo = {24, 0};
static const XGVoice kXGGtGtFeedbk = {24, 0};
static const XGVoice kXGGtGtrHrmo2 = {24, 0};

static const XGVoice kXGEnStrings1 = {48, 0};
static const XGVoice kXGEnSStrngs = {48, 0};
static const XGVoice kXGEnSlow = {48, 0};
static const XGVoice kXGEnStr = {48, 0};
static const XGVoice kXGEnArcoStr = {48, 0};
static const XGVoice kXGEn60sStrng = {48, 0};
static const XGVoice kXGEnOrchestr = {48, 0};
static const XGVoice kXGEnOrchstr2 = {48, 0};
static const XGVoice kXGEnTremOrch = {48, 0};
static const XGVoice kXGEnVeloStr = {48, 0};
static const XGVoice kXGEnStrings2 = {48, 0};
static const XGVoice kXGEnSSlwStr = {48, 0};
static const XGVoice kXGEnLegatoSt = {48, 0};
static const XGVoice kXGEnWarm = {48, 0};
static const XGVoice kXGEnStrPlus = {48, 0};
static const XGVoice kXGEnKingdom = {48, 0};
static const XGVoice kXGEn70s = {48, 0};
static const XGVoice kXGEnStr1 = {48, 0};
static const XGVoice kXGEnStrings3 = {48, 0};
static const XGVoice kXGEnSynStr1 = {48, 0};
static const XGVoice kXGEnReso = {48, 0};
static const XGVoice kXGEnStr2 = {48, 0};
static const XGVoice kXGEnSyn = {48, 0};
static const XGVoice kXGEnStr4 = {48, 0};
static const XGVoice kXGEnSynPlus = {48, 0};
static const XGVoice kXGEnStr5 = {48, 0};
static const XGVoice kXGEnSynStr2 = {48, 0};
static const XGVoice kXGEnChoirAah = {48, 0};
static const XGVoice kXGEnSChoir = {48, 0};
static const XGVoice kXGEnChAahs2 = {48, 0};
static const XGVoice kXGEnMelChoir = {48, 0};
static const XGVoice kXGEnChoirStr = {48, 0};
static const XGVoice kXGEnVoiceOoh = {48, 0};
static const XGVoice kXGEnSynVoice = {48, 0};
static const XGVoice kXGEnSynVoice2 = {48, 0};
static const XGVoice kXGEnChoral = {48, 0};
static const XGVoice kXGEnAnaVoice = {48, 0};
static const XGVoice kXGEnOrchHit = {48, 0};
static const XGVoice kXGEnOrchHit2 = {48, 0};
static const XGVoice kXGEnImpact = {48, 0};
static const XGVoice kXGEnBass = {48, 0};
static const XGVoice kXGEnHit = {48, 0};
static const XGVoice kXGEn6th = {48, 0};
static const XGVoice kXGEnHit1 = {48, 0};
static const XGVoice kXGEn6thHit = {48, 0};
static const XGVoice kXGEnPlus = {48, 0};
static const XGVoice kXGEnEuro = {48, 0};
static const XGVoice kXGEnHit2 = {48, 0};
static const XGVoice kXGEnEuroHit = {48, 0};

static const XGVoice kXGFxRain = {91, 0};
static const XGVoice kXGFxClaviPad = {91, 0};
static const XGVoice kXGFxHrmoRain = {91, 0};
static const XGVoice kXGFxAfrcnWnd = {91, 0};
static const XGVoice kXGFxCarib = {91, 0};
static const XGVoice kXGFxSoundTrk = {91, 0};
static const XGVoice kXGFxPrologue = {91, 0};
static const XGVoice kXGFxAncestrl = {91, 0};
static const XGVoice kXGFxCrystal = {91, 0};
static const XGVoice kXGFxSynDrCmp = {98, 12}; // good
static const XGVoice kXGFxPopcorn = {91, 0};
static const XGVoice kXGFxTinyBell = {91, 0};
static const XGVoice kXGFxRndGlock = {91, 0};
static const XGVoice kXGFxGlockChi = {91, 0};
static const XGVoice kXGFxClearBel = {91, 0};
static const XGVoice kXGFxChorBell = {91, 0};
static const XGVoice kXGFxSynMalet = {91, 0};
static const XGVoice kXGFxSftCryst = {91, 0};
static const XGVoice kXGFxLoudGlok = {91, 0};
static const XGVoice kXGFxChrsBel = {91, 0};
static const XGVoice kXGFxVibeBell = {91, 0};
static const XGVoice kXGFxDigiBell = {91, 0};
static const XGVoice kXGFxAirBells = {91, 0};
static const XGVoice kXGFxBellHarp = {91, 0};
static const XGVoice kXGFxGamelmba = {91, 0};
static const XGVoice kXGFxAtmosphr = {91, 0};
static const XGVoice kXGFxWarmAtms = {91, 0};
static const XGVoice kXGFxHollwRls = {91, 0};
static const XGVoice kXGFxNylon = {91, 0};
static const XGVoice kXGFxEP = {91, 0};
static const XGVoice kXGFxNylnHarp = {91, 0};
static const XGVoice kXGFxHarp = {91, 0};
static const XGVoice kXGFxVox = {91, 0};
static const XGVoice kXGFxAtmosPad = {91, 0};
static const XGVoice kXGFxPlanet = {99, 67}; //good
static const XGVoice kXGFxBright = {91, 0};
static const XGVoice kXGFxFantaBel = {91, 0};
static const XGVoice kXGFxSmokey = {91, 0};
static const XGVoice kXGFxGoblins = {91, 0};
static const XGVoice kXGFxGobSynth = {91, 0};
static const XGVoice kXGFxCreeper = {91, 0};
static const XGVoice kXGFxRing = {91, 0};
static const XGVoice kXGFxPad = {91, 0};
static const XGVoice kXGFxRitual = {91, 0};
static const XGVoice kXGFxToHeaven = {91, 0};
static const XGVoice kXGFxNight = {91, 0};
static const XGVoice kXGFxGlisten = {91, 0};
static const XGVoice kXGFxBelChoir = {91, 0};
static const XGVoice kXGFxEchoes = {91, 0};
static const XGVoice kXGFxEchoes1 = {91, 0};
static const XGVoice kXGFx2 = {91, 0};
static const XGVoice kXGFxEcho = {91, 0};
static const XGVoice kXGFxPan = {91, 0};
static const XGVoice kXGFxEchoBell = {91, 0};
static const XGVoice kXGFxBig = {91, 0};
static const XGVoice kXGFxPan1 = {91, 0};
static const XGVoice kXGFxSynPiano = {91, 0};
static const XGVoice kXGFxCreation = {91, 0};
static const XGVoice kXGFxStarDust = {91, 0};
static const XGVoice kXGFxResoPan = {91, 0};
static const XGVoice kXGFxSciFi = {91, 0};
static const XGVoice kXGFxStarz = {91, 0};


#endif /* MidiDeviceYamahaXG_h */
