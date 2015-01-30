//
//  Track.h
//  Protools music extractor
//
//  Created by Hens Zimmerman on 3/6/12.
//  Copyright (c) 2012 HZ37Land. All rights reserved.
//

// Holds the information of a single track from the Protools session.
// A Track object will be stored in an array to represent the entire 
// Protools session.

#import <Foundation/Foundation.h>

@interface Track : NSObject
{
    // The name of the track. D1, D2, M1 (Stereo), etc.
    
    NSString* trackName;
    
    // The selection state of this track. Either 0 or 1.
    
    NSInteger state;
    
    // Is this a mono track or a stereo track.
    
    BOOL isMono;
}

@property (readwrite, copy) NSString* trackName;
@property (readwrite) BOOL isMono;

- (id) initWithName: (NSString*) name Mono: (BOOL) mono;
- (BOOL) boolValue;
- (NSInteger) integerValue;
- (NSNumber*) numberValue;
- (void) setBoolValue: (BOOL) newState;
- (void) setIntegerValue: (NSInteger) newState;

@end
