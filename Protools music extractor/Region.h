//
//  Region.h
//  Protools music extractor
//
//  Created by Hens Zimmerman on 3/6/12.
//  Copyright (c) 2012 HZ37Land. All rights reserved.
//

// A Region object represents a Protools region. Every region is part of a track,
// has a name, a starting and ending point, a duration and is either stereo or mono.
// A Region object will be stored in an array to represents the entire session
// in terms of regions.

#import <Foundation/Foundation.h>

@interface Region : NSObject
{
    // Full region name as read from Protools session.
    
    NSString* name;
    
    // Track name (D1, D2, M1 (Stereo), etc.) as read from Protools session.
    
    NSString* trackName;
    
    // Frame at which the region begins.
    
    NSInteger startFrame;
    
    // Frame at which the region ends.
    
    NSInteger stopFrame;
    
    // Length of region in frames.
    
    NSInteger length;
    
    // Whether or not the region is mono or stereo.
    
    BOOL isMono;
}

@property (readwrite, copy) NSString* name;
@property (readwrite, copy) NSString* trackName;
@property (readwrite) NSInteger startFrame;
@property (readwrite) NSInteger stopFrame;
@property (readwrite) NSInteger length;
@property (readwrite) BOOL isMono;

- (id) initWithName: (NSString*) theName TrackName: (NSString*) theTrackName StartFrame: (NSInteger) theStartFrame StopFrame: (NSInteger) theStopFrame Length: (NSInteger) theLength IsMono: (BOOL) theIsMono;

@end
