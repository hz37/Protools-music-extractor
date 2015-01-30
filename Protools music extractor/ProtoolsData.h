//
//  ProtoolsData.h
//  Protools music extractor
//
//  Created by Hens Zimmerman on 3/6/12.
//  Copyright (c) 2012 HZ37Land. All rights reserved.
//

// This is the MODEL class that parses the Protools text export file
// and holds all the track and region data.

#import <Foundation/Foundation.h>

@interface ProtoolsData : NSObject
{
    // Collection of all regions from a Protools session.
    // This array is updated when a new file is read from disk.
    
    NSMutableArray* regions;
    
    // Collection of filtered region usage (names with times) based on
    // user choices. This is the extraction from the regions collection
    // and is changed all the time when a user works with the interface.
    
    NSMutableArray* regionUsages;
    
    // Collection of tracks, read from a Protools session text file.
    // This array is also used to store user selections in terms of
    // which track to use in the output and which not.
    
    NSMutableArray* tracks;
    
    // Framerate in frames per second (25 in almost all cases for PAL sessions).
    
    NSInteger frameRate;
    
    // Current session's samplerate in Hz.
    
    double sampleRate;
    
    // While scanning the Protools text export, we try to find the earliest
    // and latest frame used by the session so the interface can scale itself.
    
    NSInteger startFrame;
    NSInteger stopFrame;
    
    // We remember the filename because it can be queried for.
    
    NSString* sessionFileName;
    
    // User preferences that tell us what should be filtered in the output.

    BOOL ignoreFade;
    BOOL ignoreShorter;
    NSInteger ignoreShorterThan;
    BOOL ignoreStringDataAfterExtension;
    BOOL ignoreStringDataAfterNew;
    BOOL combineSimilar;
    NSInteger selectionStart;
    NSInteger selectionStop;
    
    // Output data can be sorted either on name or time.
    
    BOOL sortOnName;
}

@property (readwrite) NSInteger frameRate;
@property (readwrite) double sampleRate;
@property (readwrite, copy) NSString* sessionFileName;

- (void) combineManually: (NSIndexSet*) indices;
- (void) deleteRows: (NSIndexSet*) indices;
- (void) edit: (NSString*) name At: (NSInteger) index;
- (BOOL) extractHMSF:(NSString*) inputString Hours: (NSInteger*) h Mins: (NSInteger*) m Secs: (NSInteger*) s Frames: (NSInteger*) f;
- (void) generateListing;
- (NSInteger) getFrameRate;
- (BOOL) getIsMono: (NSArray*) regionNamea;
- (NSString*) getRegionUsages: (BOOL) includeFrames;
- (NSArray*) getRegionUsagesRaw;
- (NSArray*) getRegions;
- (void) getSessionBoundaries: (NSInteger*) sessionStart SessionEnd: (NSInteger*) sessionEnd;
- (NSInteger) getEarliestStartFrame: (NSArray*) regionNames;
- (NSString*) getTitle;
- (NSString*) getTrack: (NSArray*) regionNames;
- (NSArray*) getTracks;
- (NSString*) greatestCommonStringFrom: (NSString*) s1 And: (NSString*) s2;
- (bool) loadFileWithName: (NSString*) fileName;
- (NSInteger) regionUsageCount;
- (NSString*) regionUsageNameAtIndex: (NSInteger) index;
- (NSInteger) regionUsageTimeAtIndex: (NSInteger) index;
- (NSInteger) removeRegionWithName: (NSString*) name;
- (void) reset;
- (void) setCombineSimilar: (BOOL) newState;
- (void) setIgnoreFade: (BOOL) newState;
- (void) setIgnoreShorter: (BOOL) newState;
- (void) setIgnoreShorterThan: (NSInteger) newState;
- (void) setIgnoreStringDataAfterExtension: (BOOL) newState;
- (void) setIgnoreStringDataAfterNew: (BOOL) newState;
- (void) setSelectionStart: (NSInteger) newValue;
- (void) setSelectionStop: (NSInteger) newValue;
- (void) setSortOnName: (BOOL) value;
- (void) setTrackState: (BOOL) toValue AtIndex: (NSInteger) index;
- (NSInteger) trackCount;
- (NSString*) trackNameAtIndex: (NSInteger) index;
- (NSNumber*) trackStateAtIndex: (NSInteger) index;

@end
