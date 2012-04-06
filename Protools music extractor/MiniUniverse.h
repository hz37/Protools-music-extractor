//
//  MiniUniverse.h
//  Protools music extractor
//
//  Created by Hens Zimmerman on 3/10/12.
//  Copyright (c) 2012 HZ37Land. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MiniUniverse : NSView
{
    // Offscreen image we draw the selected mini universe/session on.
    
    NSImage* renderBuffer;
    
    // Offscreen image we draw the deselected mini universe/session on.
    
    NSImage* deselectedRenderBuffer;
    
    // Remember width and height of NSView frame.
    
    CGFloat width, height;
    
    // Remember session start and stop frames.
    
    NSInteger sessionStartFrame, sessionStopFrame;
    
    // Remember selection start and end frames.
    
    NSInteger selectionStart, selectionStop;
}

- (void) redrawUniverseWith: (NSArray*) regions Tracks: (NSArray*) tracks SessionStart: (NSInteger) sessionStart SessionStop: (NSInteger) sessionStop;
- (void) setSelectionStart: (NSInteger) frame;
- (void) setSelectionStop: (NSInteger) frame;

@end
