//
//  Utility.h
//  Protools music extractor
//
//  Created by Hens Zimmerman on 3/12/12.
//  Copyright (c) 2012 HZ37Land. All rights reserved.
//

// Stuff that needs to be used in different places and I would like
// to implement it only once.

#import <Foundation/Foundation.h>

extern NSString* const HZ_FileDropped;

@interface Utility : NSObject

+ (NSString*) framesToHMSF: (NSInteger) frames IncludeFrames: (BOOL) includeFrames Framerate: (NSInteger) frameRate;

@end

/*
 
Kassa 8-12-2007.txt

00:01:35:24	01 Hijack.mp3
00:00:20:11	07 Chico's Groove.mp3
00:01:14:06	16 Track 16.aif
00:01:15:03	Isabelle Comes Back.mp3
00:00:32:21	Lives In The Balance.mp3

*/

