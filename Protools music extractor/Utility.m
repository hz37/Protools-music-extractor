//
//  Utility.m
//  Protools music extractor
//
//  Created by Hens Zimmerman on 3/12/12.
//  Copyright (c) 2012 HZ37Land. All rights reserved.
//

// Stuff that needs to be used in different places and I would like
// to implement it only once.

#import "Utility.h"

NSString* const HZ_FileDropped = @"HZFileDropped";

@implementation Utility

// Convert frames to HH:MM:SS:FF based on framerate.
// User can specifiy whether or not frames should be included in output.

+ (NSString*) framesToHMSF: (NSInteger) frames IncludeFrames: (BOOL) includeFrames Framerate: (NSInteger) frameRate
{
    // Avoid divide by zero.
    
    if (frameRate == 0) 
    {
        return nil;
    }
    
    NSInteger h = frames / (3600 * frameRate);
    frames -= (h * 3600 * frameRate);
    NSInteger m = frames / (60 * frameRate);
    frames -= (m * 60 * frameRate);
    NSInteger s = frames / frameRate;
    frames %= frameRate;
    
    if (frames < 0) 
    {
        frames = 0;
    }
    
    if (includeFrames) 
    {
        return [NSString stringWithFormat:@"%.2ld:%.2ld:%.2ld:%.2ld", h, m, s, frames];     
    }
    else
    {
        // Round frames.
        
        if(frameRate % 2)
        {
            // Avoid off by 1 in rounding, e.g. for PAL 25 fps
            
            --frames;
        }
        
        if (frames >= (frameRate / 2)) 
        {
            ++s;
        }
        
        return [NSString stringWithFormat:@"%.2ld:%.2ld:%.2ld", h, m, s];     
    }
}

@end
