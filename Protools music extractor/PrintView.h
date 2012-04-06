//
//  PrintView.h
//  Protools music extractor
//
//  Created by Hens Zimmerman on 3/13/12.
//  Copyright (c) 2012 HZ37Land. All rights reserved.
//

// Taken mostly from Hillegass' book, chapter about printing.

#import <Cocoa/Cocoa.h>

@interface PrintView : NSView
{
    NSArray* regionUsages;
    NSMutableDictionary* attributes;
    float lineHeight;
    NSRect pageRect;
    NSInteger linesPerPage;
    NSInteger currentPage;
    BOOL includeFrames;
    NSInteger frameRate;
    NSString* title;
    NSInteger pageCount;
}

- (id) initWithRegionUsages: (NSArray*) _regionUsages IncludeFrames: (BOOL) _includeFrames FrameRate: (NSInteger) _frameRate Title: (NSString*) _title;

@end
