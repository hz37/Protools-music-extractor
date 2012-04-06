//
//  Track.m
//  Protools music extractor
//
//  Created by Hens Zimmerman on 3/6/12.
//  Copyright (c) 2012 HZ37Land. All rights reserved.
//

// Holds the information of a single track from the Protools session.
// A Track object will be stored in an array to represent the entire 
// Protools session.

#import "Track.h"

@implementation Track

@synthesize trackName;
@synthesize isMono;

// Construct with a track name.

- (id) initWithName: (NSString*) name Mono: (BOOL) mono
{
    if (self = [super init]) 
    {
        // Default to not selected.
        
        state = 0;
        
        // Store name.
        
        trackName = name;
        
        // Store mono or stereo.
        
        isMono = mono;
    }
    
    return self;
}


// Return value as an BOOL.

- (BOOL) boolValue
{
    return state ? TRUE : FALSE;
}


// Return value as an integer.

- (NSInteger) integerValue
{
    return state;
}


// Return value as an NSNumber.

- (NSNumber*) numberValue
{
    return [[NSNumber alloc] initWithInteger:state];
}


// Set value with a bool argument.

- (void) setBoolValue: (BOOL) newState
{
    state = newState ? 1 : 0;
}


// Set value with an integer argument.

- (void) setIntegerValue: (NSInteger) newState
{
    state = newState ? 1 : 0;
}

@end
