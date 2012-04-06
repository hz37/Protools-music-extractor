//
//  Region.m
//  Protools music extractor
//
//  Created by Hens Zimmerman on 3/6/12.
//  Copyright (c) 2012 HZ37Land. All rights reserved.
//

// A Region object represents a Protools region. Every region is part of a track,
// has a name, a starting and ending point, a duration and is either stereo or mono.
// A Region object will be stored in an array to represents the entire session
// in terms of regions.

#import "Region.h"

@implementation Region

@synthesize name;
@synthesize trackName;
@synthesize startFrame;
@synthesize stopFrame;
@synthesize length;
@synthesize isMono;

// Create a Region object with all values given. Calls super init and returns self.

- (id) initWithName: (NSString*) theName TrackName: (NSString*) theTrackName StartFrame: (NSInteger) theStartFrame StopFrame: (NSInteger) theStopFrame Length: (NSInteger) theLength IsMono: (BOOL) theIsMono
{
    self = [super init];
    
    name = theName;
    trackName = theTrackName;
    startFrame = theStartFrame;
    stopFrame = theStopFrame;
    length = theLength;
    isMono = theIsMono;
    
    return self;
}

@end
