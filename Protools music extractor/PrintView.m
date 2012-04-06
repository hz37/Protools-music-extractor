//
//  PrintView.m
//  Protools music extractor
//
//  Created by Hens Zimmerman on 3/13/12.
//  Copyright (c) 2012 HZ37Land. All rights reserved.
//

// Taken mostly from Hillegass' book, chapter about printing.

#import "PrintView.h"
#import "RegionUsage.h"
#import "Utility.h"

@implementation PrintView


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) 
    {
        // Initialization code here.
    }
    
    return self;
}


- (id) initWithRegionUsages: (NSArray*) _regionUsages IncludeFrames:(BOOL)_includeFrames FrameRate:(NSInteger)_frameRate Title: (NSString *) _title
{
    // Call the superclass' designated initializer with some dummy frame.
    
    self = [super initWithFrame:NSMakeRect(0.0, 0.0, 700.0, 700.0)];
    
    if (self) 
    {
        regionUsages = [_regionUsages copy];
        includeFrames = _includeFrames;
        frameRate = _frameRate;
        title = _title;
        
        // Attributes of text to be printed.
        
        attributes = [[NSMutableDictionary alloc] init];
        NSFont* font = [NSFont fontWithName:@"Helvetica" size:12.0];
        lineHeight = [font capHeight] * 1.7;
        [attributes setObject:font forKey:NSFontAttributeName];
    }
    
    return self;
}


#pragma mark Pagination

- (BOOL) knowsPageRange:(NSRangePointer)range
{
    NSPrintOperation* po = [NSPrintOperation currentOperation];
    NSPrintInfo* printInfo = [po printInfo];
    
    // Where can I draw?
    
    pageRect = [printInfo imageablePageBounds];
    NSRect newFrame;
    newFrame.origin = NSZeroPoint;
    newFrame.size = [printInfo paperSize];
    [self setFrame:newFrame];
    
    // How many lines per page?
    // Subtract 2 for title and whiteline.

    linesPerPage = (pageRect.size.height / lineHeight) - 2;
    
    // Pages are 1-based.
    
    range->location = 1;
    
    // How many pages will it take?
    
    pageCount = [regionUsages count] / linesPerPage;
    
    if ([regionUsages count] % linesPerPage) 
    {
        ++pageCount;
    }
    
    range->length = pageCount;
    
    return YES;
}


- (NSRect) rectForPage:(NSInteger)page
{
    // Note the current page.
    
    currentPage = page - 1;
    
    // Return the same page rect every time.
    
    return pageRect;
}


#pragma mark Drawing

// The origin of the view is at the upper left.

- (BOOL) isFlipped
{
    return YES;
}


- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    
    NSRect nameRect = NSMakeRect(0, 0, 0, 0);
    NSRect timeRect;
    
    timeRect.size.height = nameRect.size.height = lineHeight;
    nameRect.origin.x = pageRect.origin.x;
    nameRect.size.width = 400.0;
    timeRect.origin.x = NSMaxX(nameRect);
    timeRect.size.width = 100.0;
    
    // Print the title on every page.
    
    nameRect.origin.y = pageRect.origin.y;
    [[NSString stringWithFormat:@"%@ - page %ld of %ld", title, currentPage + 1, pageCount] drawInRect:nameRect withAttributes:attributes];

    // Next print all the lines.
    
    for (NSInteger i = 0; i < linesPerPage; ++i) 
    {
        NSInteger index = (currentPage * linesPerPage) + i;
        
        if (index >= [regionUsages count]) 
        {
            break;
        }

        CGFloat y = pageRect.origin.y + (/* title */ 2 * lineHeight) + (i * lineHeight);
        
        // Draw rect to alternate between lines.
        
        if (index % 2) 
        {
            NSRect box = NSMakeRect(0.0, y, (nameRect.size.width + timeRect.size.width), lineHeight);
            NSBezierPath* boxPath = [NSBezierPath bezierPathWithRect:box];
            NSColor* boxColor = [NSColor colorWithSRGBRed:0.1 green:0.1 blue:0.1 alpha:0.1];
            [boxColor set];
            [boxPath fill];
        }
        
        // Draw line.
        
        RegionUsage* r = [regionUsages objectAtIndex:index];
        
        nameRect.origin.y = y;
        [[r getName] drawInRect:nameRect withAttributes:attributes];
        
        timeRect.origin.y = y;
        
        NSString* time = [Utility framesToHMSF:[r getLength] IncludeFrames:includeFrames Framerate:frameRate];
        [time drawInRect:timeRect withAttributes:attributes];
    }
}

@end
