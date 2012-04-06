//
//  MiniUniverse.m
//  Protools music extractor
//
//  Created by Hens Zimmerman on 3/10/12.
//  Copyright (c) 2012 HZ37Land. All rights reserved.
//

#import "MiniUniverse.h"
#import "Region.h"
#import "Track.h"
#import "Utility.h"

@implementation MiniUniverse

// Color elements as constants so they can be edited in one place.

// * * * * * * * BEGIN COLOR CONSTANTS * * * * * * * 

// Selected background color.

CGFloat const HZ37_SelectedBackgroundRed     = 0.0;
CGFloat const HZ37_SelectedBackgroundGreen   = 0.0;
CGFloat const HZ37_SelectedBackgroundBlue    = 0.5;

// Deselected background color.

CGFloat const HZ37_DeselectedBackgroundRed   = 0.0;
CGFloat const HZ37_DeselectedBackgroundGreen = 0.0;
CGFloat const HZ37_DeselectedBackgroundBlue  = 0.0;

// Alpha.

CGFloat const HZ37_Alpha = 1.0;

// Region on even track.

CGFloat const HZ37_EvenTrackRed   = 0.1;
CGFloat const HZ37_EvenTrackGreen = 0.9;
CGFloat const HZ37_EvenTrackBlue  = 0.1;

// Region on odd track.

CGFloat const HZ37_OddTrackRed    = 0.1;
CGFloat const HZ37_OddTrackGreen  = 0.7;
CGFloat const HZ37_OddTrackBlue   = 1.0;

// Deselected region on even track.

CGFloat const HZ37_DeselectedEvenTrackRed   = 0.2;
CGFloat const HZ37_DeselectedEvenTrackGreen = 0.2;
CGFloat const HZ37_DeselectedEvenTrackBlue  = 0.2;

// Deselected region on odd track.

CGFloat const HZ37_DeselectedOddTrackRed    = 0.4;
CGFloat const HZ37_DeselectedOddTrackGreen  = 0.4;
CGFloat const HZ37_DeselectedOddTrackBlue   = 0.4;

// * * * * * * * END COLOR CONSTANTS * * * * * * * *


// User drags a file (or more) from Finder onto this view.
// This code taken almost verbatim from Apple developer documentation.

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>) sender 
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) 
    {
        if (sourceDragMask & NSDragOperationLink) 
        {
            return NSDragOperationLink;
        } else if (sourceDragMask & NSDragOperationCopy) 
        {
            return NSDragOperationCopy;
        }
    }
    
    return NSDragOperationNone;
}


// IDE generated function.

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here, according to IDE.
    
    // Compute width in frames. All our session and selection variables are in frames (as in frames per second)
    // and these need to be converted to pixels.
    
    CGFloat frameWidth = sessionStopFrame - sessionStartFrame;
    
    if (frameWidth == 0.0) 
    {
        // Avoid div 0.
        
        return;
    }
    
    CGFloat selectionStartPixel = (width * (selectionStart - sessionStartFrame)) / frameWidth;
    CGFloat selectionEndPixel = (width * (selectionStop - sessionStartFrame)) / frameWidth;
    
    // Left portion (deselected).
    
    NSRect r0 = NSMakeRect(0, 0, selectionStartPixel, height);
    [deselectedRenderBuffer drawInRect:r0 fromRect:r0 operation:NSCompositeSourceOver fraction:1.0];
    
    // Middle portion (selected).
    
    NSRect r1 = NSMakeRect(selectionStartPixel, 0, selectionEndPixel, height);
    [renderBuffer drawInRect:r1 fromRect:r1 operation:NSCompositeSourceOver fraction:1.0];
    
    // Right portion (deselected).
    
    NSRect r2 = NSMakeRect(selectionEndPixel, 0, width, height);
    [deselectedRenderBuffer drawInRect:r2 fromRect:r2 operation:NSCompositeSourceOver fraction:1.0];
}


// IDE generated function, called once at program start.

- (id)initWithFrame: (NSRect) frame
{
    self = [super initWithFrame:frame];
    
    if (self) 
    {
        // Remember dimensions of frame for later computations.
        
        width = frame.size.width;
        height = frame.size.height;
        
        // Setup buffers to do background drawing onto.
        
        renderBuffer = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
        deselectedRenderBuffer = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
        
        // Let this mini universe be the logical place where a
        // user can drop a protools text export from the Finder.
        
        [self registerForDraggedTypes:[NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
    }
    
    return self;
}


// Dragging file(s) from finder onto this view. Code adapted from example by Apple.

- (BOOL)performDragOperation:(id <NSDraggingInfo>) sender 
{
    NSPasteboard *pboard;

    pboard = [sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) 
    {
        NSArray* files = [pboard propertyListForType:NSFilenamesPboardType];

        if ([files count] > 1) 
        {
            NSRunAlertPanel(@"Sorry!", @"I accept only one file at a time", @"I see", nil, nil);
            return NO;
        }
        
        // Post this file to notification center so AppDelegate can handle it further.
        
        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        
        [nc postNotificationName:HZ_FileDropped object:files];
    }
    
    return YES;
}


// When a new file is loaded, this function is called to draw the new session to the View.

- (void) redrawUniverseWith: (NSArray*) regions Tracks: (NSArray*) tracks SessionStart: (NSInteger) sessionStart SessionStop: (NSInteger) sessionStop
{
    // Avoid div by zero.
    
    if (sessionStop == sessionStart) 
    {
        return;
    }
    
    // Start with no selection.
    
    selectionStart = sessionStart;
    selectionStop = sessionStop;
    
    // Remember for later.
    
    sessionStartFrame = sessionStart;
    sessionStopFrame = sessionStop;
    
    // Clear the selected and deselected buffers to their respective background colors.
    
    [renderBuffer lockFocus];
    
    NSColor* c = [NSColor colorWithSRGBRed:HZ37_SelectedBackgroundRed green:HZ37_SelectedBackgroundGreen blue:HZ37_SelectedBackgroundBlue alpha:HZ37_Alpha];
    
    [c set];
    [c setFill];
    
    NSRect r = NSMakeRect(0.0, 0.0, width, height);
    
    NSBezierPath* p =[NSBezierPath bezierPathWithRect:r];
    
    [p fill];
    
    [renderBuffer unlockFocus];
    
    // And the same for the deselected buffer.
    
    [deselectedRenderBuffer lockFocus];
    
    c = [NSColor colorWithSRGBRed:HZ37_DeselectedBackgroundRed green:HZ37_DeselectedBackgroundGreen blue:HZ37_DeselectedBackgroundBlue alpha:HZ37_Alpha];
    
    [c set];
    [c setFill];
    [p fill];
    
    [deselectedRenderBuffer unlockFocus];
    
    // Compute coordinates for the regions we're about to draw.
        
    CGFloat framesPerPixel = (sessionStop - sessionStart) / width;
    
    NSInteger trackCount = [tracks count];
    
    CGFloat h = height / trackCount;
    
    // Tracks x and width will be computed on a per region basis, but the y coordinate of every region
    // is a function of the track it belongs to. We'll build a lookup table for this from the track array.
    
    NSMutableDictionary* yCoordLookupTable = [[NSMutableDictionary alloc] init];
    
    // We also create a lookup table to recall if a region lives on an odd or even track (for coloring).
    
    NSMutableDictionary* oddEvenLookupTable = [[NSMutableDictionary alloc] init];
    
    for (NSInteger idx = 0; idx < trackCount; ++idx) 
    {
        Track* track = [tracks objectAtIndex:idx];
        
        NSNumber* y = [[NSNumber alloc] initWithDouble:(trackCount - idx - 1) * h];
        [yCoordLookupTable setObject:y forKey:track.trackName];
        
        NSNumber* odd = [[NSNumber alloc] initWithInteger:(idx % 2) ? 1 : 0];
        [oddEvenLookupTable setObject: odd forKey:track.trackName];
    }
    
    // Now we'll draw each and every region, both on the selected and the deselected buffers.
    
    for (Region* region in regions) 
    {
        // X coordinate and width.
        
        CGFloat x = (region.startFrame - sessionStartFrame) / framesPerPixel;
        CGFloat w = (region.stopFrame - region.startFrame) / framesPerPixel;
        
        NSNumber* yNumber = [yCoordLookupTable objectForKey:[region trackName]];
        CGFloat y = [yNumber doubleValue];
        NSNumber* oddNumber = [oddEvenLookupTable objectForKey:[region trackName]];
        BOOL odd = [oddNumber boolValue];
        
        // Now we have all the information we need to draw the region.
        
        [renderBuffer lockFocus];
        
        NSColor* c = 0;
        
        if(odd)
        {
            c = [NSColor colorWithSRGBRed:HZ37_OddTrackRed green:HZ37_OddTrackGreen blue:HZ37_OddTrackBlue alpha:HZ37_Alpha];
        }
        else
        {
            c = [NSColor colorWithSRGBRed:HZ37_EvenTrackRed green:HZ37_EvenTrackGreen blue:HZ37_EvenTrackBlue alpha:HZ37_Alpha];
        }
        
        [c set];
        [c setFill];
        
        NSRect r = NSMakeRect(x, y, w, h);
        NSBezierPath* p = [NSBezierPath bezierPathWithRect:r];
        
        [p fill];
        
        [renderBuffer unlockFocus];
        
        // Also add it to the deselected buffer.
        
        [deselectedRenderBuffer lockFocus];
        
        if(odd)
        {
            c = [NSColor colorWithSRGBRed:HZ37_DeselectedOddTrackRed green:HZ37_DeselectedOddTrackGreen blue:HZ37_DeselectedOddTrackBlue alpha:HZ37_Alpha];
        }
        else
        {
            c = [NSColor colorWithSRGBRed:HZ37_DeselectedEvenTrackRed green:HZ37_DeselectedEvenTrackGreen blue:HZ37_DeselectedEvenTrackBlue alpha:HZ37_Alpha];
        }
        
        [c set];
        [c setFill];
        
        [p fill];
        
        [deselectedRenderBuffer unlockFocus];
    }
    
    // Make it visible.
    
    [self display];
}


// User has changed selection.

- (void) setSelectionStart: (NSInteger) frame
{
    selectionStart = frame;
    
    // Redraw immediately.
    
    [self display];
}


// User has changed selection.

- (void) setSelectionStop: (NSInteger) frame
{
    selectionStop = frame;
    
    // Redraw immediately.
    
    [self display];
}


@end
