//
//  ProtoolsData.m
//  Protools music extractor
//
//  Created by Hens Zimmerman on 3/6/12.
//  Copyright (c) 2012 HZ37Land. All rights reserved.
//

// This is the MODEL class that parses the Protools text export file
// and holds all the track and region data.

#import "ProtoolsData.h"
#import "Region.h"
#import "RegionUsage.h"
#import "Track.h"
#import "Utility.h"

@implementation ProtoolsData

@synthesize frameRate;
@synthesize sampleRate;
@synthesize sessionFileName;

// Default values as consts.

NSInteger const HZ37_defaultFrameRate = 0;
double const HZ37_defaultSampleRate = 0.0;


// Give the user a way to manually select and combine regions of which she
// is sure they all just refer to the same file (but somehow were mangled
// by Protools).

- (void) combineManually: (NSIndexSet*) indices
{
    // We'll try to find a new name common to all selected regions.
    
    NSString* __block newName = @"__init__";
    
    // But since these might have wildly different names, we'll
    // default to the first in case there is no match.
    
    NSString* __block fallbackName ;
    
    // Tally all the times of these together.
    
    NSInteger __block newLength = 0;

    // We'll take the first occurence as the new start time.
    // This is sort'a random, but we'll have to draw it somewhere in
    // the mini universe.
    
    NSInteger __block newStartFrame;
    
    // We'll also assume they are on the same track as the first occurence
    // and have the same amount of channels.
    
    NSString* __block newTrackName;
    BOOL __block newIsMono;
    
    [indices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) 
     {
         RegionUsage* ru = [regionUsages objectAtIndex:idx];
         NSString* regionName = [ru getName];
         NSArray* regionNames = [ru getOriginalNames];
         
         if ([newName isEqualToString:@"__init__"]) 
         {
             // First one, so let's initialize some fields.
             
             newName = regionName;
             fallbackName = regionName;
             
             // These now require three different loop lookups,
             // so if this function gets slow, combine those into one
             // traverse through the regions container.
             
             newStartFrame = [self getEarliestStartFrame:regionNames];
             newTrackName = [self getTrack:regionNames];
             newIsMono = [self getIsMono:regionNames];
         }
         else
         {
             // See if we can find a common part between the region names.
             
             newName = [self greatestCommonStringFrom:newName And:regionName];
             
             // See if this region has an earlier start time.
             
             NSInteger regionStartFrame = [self getEarliestStartFrame:regionNames];
             
             if (regionStartFrame < newStartFrame) 
             {
                 newStartFrame = regionStartFrame;
             }
         }
         
         // Remove all regions that we have found in the regionNames container
         // and add their lengths to our new length.
         
         for (NSString* name in regionNames) 
         {
             newLength += [self removeRegionWithName:name];
         }
     }];
    
    // If we don't have a bit of common region name, fall back on first name.
    
    if ([newName length] == 0) 
    {
        newName = fallbackName;
    }
    
    // Now we can add this manually combined "region" back to the regions container.
    
    // Instantiate a new Region object with the above.
    
    Region* region = [[Region alloc] initWithName:newName TrackName:newTrackName StartFrame:newStartFrame StopFrame:(newStartFrame + newLength) Length:newLength IsMono:newIsMono];
    
    // Add it to container that holds all region data.
    
    [regions addObject:region];
}


// This is a way to clean up the list with superfluous shit (like sound effects)
// before printing it or saving it. The output table supports multi select
// and the indices of all the selected items are passed to this function.

- (void) deleteRows: (NSIndexSet*) indices
{
    [indices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) 
     {
         RegionUsage* ru = [regionUsages objectAtIndex:idx];
         NSString* regionName = [ru getName];
         
         NSPredicate* predicate = [NSPredicate predicateWithFormat:@"NOT name BEGINSWITH %@", regionName];
         [regions filterUsingPredicate:predicate];
     }];
}


// User provides a new name for an existing region.

- (void) edit: (NSString*) name At: (NSInteger) index
{
    RegionUsage* regionUsage = [regionUsages objectAtIndex:index];

    [regionUsage setName:name];
}


// Convert HH:MM:SS:FF to separate NSIntegers.

- (BOOL) extractHMSF:(NSString*) inputString Hours: (NSInteger*) h Mins: (NSInteger*) m Secs: (NSInteger*) s Frames: (NSInteger*) f 
{
    NSArray* separatedItems = [inputString componentsSeparatedByString:@":"];
    
    if ([separatedItems count] == 4) 
    {
        *h = [[separatedItems objectAtIndex:0] integerValue];
        *m = [[separatedItems objectAtIndex:1] integerValue];
        *s = [[separatedItems objectAtIndex:2] integerValue];
        *f = [[separatedItems objectAtIndex:3] integerValue];
        
        return TRUE;
    }
    
    return FALSE;
}


// Here's where the actual work gets done. Based on user choices, the loaded data from the Protools session will be
// filtered down to a simple list of names with total running times.

- (void) generateListing
{
    // Empty previous version of this list.
    
    [regionUsages removeAllObjects];
    
    // Build a lookup table of the current tracks and their selection states.
    
    NSMutableDictionary* tracksLUT = [[NSMutableDictionary alloc] init];
    
    for (Track* track in tracks) 
    {
        NSNumber* state = [[NSNumber alloc] initWithBool:[track boolValue]];
        [tracksLUT setObject:state forKey:[track trackName]];
    }
    
    // These are extensions after which we can ignore string data.
    
    NSArray* extensionToIgnore = [[NSArray alloc] initWithObjects:@".aif", @".cda", @".mp3", @".m4a", @".wav", nil];
    
    //
    // PASS ONE: REDUCE ON NAMES.
    //
    
    for (Region* region in regions) 
    {
        // If track is not selected, skip it.
        
        if ([[tracksLUT objectForKey:[region trackName]] boolValue] == FALSE) 
        {
            continue;
        }
        
        // If region starts before user selection or ends after user selection,
        // We need to skip or truncate it.
        
        NSInteger regionStartFrame = [region startFrame];
        NSInteger regionStopFrame = [region stopFrame];
        
        if (regionStartFrame < selectionStart) 
        {
            regionStartFrame = selectionStart;
        }
        
        if (regionStopFrame > selectionStop) 
        {
            regionStopFrame = selectionStop;
        }
        
        NSInteger regionLength = regionStopFrame - regionStartFrame;
        
        if (regionLength <= 0) 
        {
            continue;
        }
        
        // Get the name.
        
        NSString* regionName = [region name];
        
        // Store it in a container that might grow with more names in case we find similar regions.
        
        NSMutableArray* regionNames = [[NSMutableArray alloc] initWithObjects:regionName, nil];
        
        // If so desired, regions that start with "Fade" can be skipped.
        // Probably only semi-dangerous if a song is called "Fade to Grey" by Visage.
        
        if (ignoreFade) 
        {
            NSRange range = [regionName rangeOfString:@"Fade"];
            
            if (range.location == 0) 
            {
                continue;
            }
        }
        
        // Chop off after extension if so desired.
        
        if (ignoreStringDataAfterExtension) 
        {
            for (NSString* ext in extensionToIgnore) 
            {
                NSRange suffixRange = [regionName rangeOfString:ext options:(NSCaseInsensitiveSearch | NSBackwardsSearch)];
                
                if (suffixRange.location != NSNotFound) 
                {
                    regionName = [regionName substringToIndex:suffixRange.location + 4];
                }
            }
        }
        
        // Chop off after .new if so desired. This is something Protools does for files that
        // somehow have created a new version of themselves.
        
        if (ignoreStringDataAfterNew) 
        {
            NSRange suffixRange = [regionName rangeOfString:@".new" options:(NSCaseInsensitiveSearch | NSBackwardsSearch)];
            
            if (suffixRange.location != NSNotFound) 
            {
                regionName = [regionName substringToIndex:suffixRange.location + 4];
            }
        }
        
        // If a string ends with .L (after all, we are watching channel 1 of stereo tracks
        // and Protools splits files into .L and .R), we chop this off. This isn't even a setting.
        
        NSRange endsWithDotLRange = [regionName rangeOfString:@".L" options:(NSCaseInsensitiveSearch | NSBackwardsSearch)];
        NSInteger lengthMinusTwo = [regionName length] - 2;
        
        if (endsWithDotLRange.location == lengthMinusTwo) 
        {
            regionName = [regionName substringToIndex:lengthMinusTwo];
        }
        
        // Add or combine it.
        
        if (combineSimilar) 
        {
            // See if we already have this region. If so add times and names together.
            
            NSInteger count = [regionUsages count];
            
            for (NSInteger idx = 0; idx < count; ++idx) 
            {
                RegionUsage* regionUsage = [regionUsages objectAtIndex:idx];
                
                if ([regionUsage.getName isEqualToString:regionName]) 
                {
                    // Add existing length to current length.
                    
                    regionLength += regionUsage.getLength;
                    
                    // Add its name(s) to our collection.
                    
                    [regionNames addObjectsFromArray:[regionUsage getOriginalNames]];
                    
                    // Delete the existing object.
                    
                    [regionUsages removeObjectAtIndex:idx];
                    
                    // Get out of loop cause we're done.
                    
                    break;
                }
            } 
        }
        
        // Now we can add a new object for all three situations that may have occurred:
        //
        // 1) We don't combine similar regions.
        // 2) We do combine similar regions but no existing object was found.
        // 3) We do combine similar regions and the existing object was found, added and deleted.
        
        RegionUsage* regionUsage = [[RegionUsage alloc] initWith:regionName OriginalNames:regionNames LengthInFrames:regionLength];
        [regionUsages addObject:regionUsage];
    }
    
    //
    // PASS TWO: REMOVE ITEMS THAT ARE TOO SHORT.
    //
    
    if (ignoreShorter) 
    {
        NSMutableArray* indices = [[NSMutableArray alloc] init];
        
        NSInteger threshold = ignoreShorterThan * frameRate;
        NSInteger count = [regionUsages count];
        
        for (NSInteger idx = 0; idx < count; ++idx) 
        {
            RegionUsage* r = [regionUsages objectAtIndex:idx];
            
            if (r.getLength < threshold) 
            {
                NSNumber* n = [[NSNumber alloc] initWithInteger:idx];
                [indices addObject:n];
            }
        }
        
        // Remove those items in reverse order so our index values don't get messed up.
        
        count = [indices count];
        
        for (NSInteger idx = count - 1; idx >= 0; --idx) 
        {
            NSNumber* n = [indices objectAtIndex:idx];
            
            [regionUsages removeObjectAtIndex:[n integerValue]];
        }
     }
    
    
    // Sort the output.
    
    if (sortOnName) 
    {
        [regionUsages sortUsingSelector:@selector(compareName:)];
    }
    else
    {
        [regionUsages sortUsingSelector:@selector(compareLength:)];
    }
}


// Return current framerate.

- (NSInteger) getFrameRate
{
    return frameRate;
}


// Helper function for combineManually. Returns the isMono of
// a region with from regionNames.

- (BOOL) getIsMono: (NSArray*) regionNames
{
    // We assume the first element is representative for all the regions.
    
    NSString* regionName = [regionNames objectAtIndex:0];
    
    for (Region* r in regions) 
    {
        if ([[r name] isEqualToString:regionName]) 
        {
            return [r isMono];
        }
    }
    
    return TRUE;
}


// Return regions as immutable array so it can be passed to
// miniUniverse which needs to draw with it.   

- (NSArray*) getRegions
{
    return regions;
}


// Return current contents of regionUsages as a string.
// Parameter specifies if we want to see frames in our output.

- (NSString*) getRegionUsages: (BOOL) includeFrames;

{
    if ([regionUsages count] == 0) 
    {
        return @"Empty";
    }
    
    NSMutableString* list = [[NSMutableString alloc] initWithString:[sessionFileName lastPathComponent]];
    [list appendString:@"\n\n"];
    
    for (RegionUsage* regionUsage in regionUsages) 
    {
        NSString* timeRunning = [Utility framesToHMSF:[regionUsage getLength] IncludeFrames:includeFrames Framerate:frameRate];
        [list appendFormat:@"%@\t%@\n", timeRunning, [regionUsage getName]];
    }
    
    return list;
}


// For PrintView, return the regionUsages array in its raw form.
// TODO: Abstract this away in some form, so PrintView doesn't need to
// know about framerates and RegionUsage objects.

- (NSArray*) getRegionUsagesRaw
{
    return regionUsages;
}


// Pass session boundaries so they can be passed to miniUniverse.

- (void) getSessionBoundaries: (NSInteger*) sessionStart SessionEnd: (NSInteger*) sessionEnd
{
    *sessionStart = startFrame;
    *sessionEnd = stopFrame;
}


// Helper function for combineManually. Returns the earliest startframe of all the regions in regionNames.

- (NSInteger) getEarliestStartFrame: (NSArray*) regionNames
{
    // Start pessimistic.
    
    NSInteger returnValue = NSIntegerMax;
    
    for (NSString* regionName in regionNames) 
    {
        for (Region* r in regions) 
        {
            if ([[r name] isEqualToString:regionName])
            {
                NSInteger sf = [r startFrame];
                
                if (sf < returnValue) 
                {
                    returnValue = sf;
                }
            }
        }
    }
    
    return returnValue;
}


// Return session filename.

- (NSString*) getTitle
{
    return [sessionFileName lastPathComponent];
}


// Helper function for combineManually. Returns the track of
// a region with from regionNames.

- (NSString*) getTrack: (NSArray*) regionNames
{
    // We guess the first element is representative of all elements.
    
    NSString* regionName = [regionNames objectAtIndex:0];
    
    for (Region* r in regions) 
    {
        if ([[r name] isEqualToString:regionName]) 
        {
            return [r trackName];
        }
    }
    
    return @"";
}


// Return tracks as immutable array so it can be passed to
// miniUniverse which needs to draw with it.

- (NSArray*) getTracks
{
    return tracks;
}


// Helper function for combineManually. Returns the longest string that's
// common for s1 and s2, as evaulated from the start. Case insensitive.

- (NSString*) greatestCommonStringFrom: (NSString*) s1 And: (NSString*) s2
{
    NSUInteger len = MIN ([s1 length], [s2 length]);
    NSUInteger idx;
    
    for (idx = 0; idx < len; ++idx) 
    {
        if ([[s1 lowercaseString] characterAtIndex:idx] != [[s2 lowercaseString] characterAtIndex:idx]) 
        {
            break;
        }
    }
     
    return [s1 substringToIndex:idx];
}


// Standard object constructor. Called once at program start.
// Used to perform default actions once at program start.

- (id) init
{
    if (self = [super init]) {
        // Allocate memory for collections.
        
        regions = [[NSMutableArray alloc] init];
        regionUsages = [[NSMutableArray alloc] init];
        tracks = [[NSMutableArray alloc] init];
        
        // Set internals to known default state.
        
        [self reset];
    }
    
    return self;
}

/*

 OLD CODE that assumed tab delimitation, which broke with Protools 10.2.0
 
// loadFileWithName loads the Protools text export file and parses it into
// separate elements.

- (void) loadFileWithName: (NSString*) fileName
{
    // Check if file exists.
    
    NSFileManager* fileManager = [NSFileManager new];
    
    if (![fileManager fileExistsAtPath:fileName]) 
    {
        NSRunAlertPanel(@"Error", @"File not found", @"Too bad", nil, nil);
        
        return;
    }
    
    // Erase existing data.
    
    [self reset];
    
    // Read entire contents of file into an NSString.
    // NSASCIIStringEncoding turned out to work for Protools text exports
    // (used to be NSUTF8StringEncoding which failed for some files).
    
    NSError* error;
    
    NSString* stringFromFileAtPath = [[NSString alloc]
                                      initWithContentsOfFile:fileName
                                      encoding:NSASCIIStringEncoding
                                      error:&error];   
    
    if (stringFromFileAtPath == nil) 
    {
        NSRunAlertPanel(@"Error", @"File could not be read", @"Too bad", nil, nil);
        
        return;
    }
    
    // File was read. Now we go through it line by line.
    
    sessionFileName = fileName;
    
    NSArray* lines = [stringFromFileAtPath componentsSeparatedByString:@"\n"];
    
    // Going though the file sequentially we move from track to track.
    // trackName will remember the current track we are parsing.
    
    NSString* trackName;
    
    for (NSString* line in lines) 
    {
        // A track can be either mono in stereo in this implementation.
        
        BOOL isMono;
        
        // File is tab delimited. Depending on the amount of items on a line
        // we can say what kind of data was read.
        
        NSArray* lineElements = [line componentsSeparatedByString:@"\t"];
        
        NSInteger lineElementsCount  = [lineElements count];
        
        if (lineElementsCount == 2) 
        {
            NSString* element1 = [lineElements objectAtIndex:0];
            NSString* element2 = [lineElements objectAtIndex:1];
            
            if ([element1 isEqualToString: @"TRACK NAME:"]) 
            {
                trackName = [element2 stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                
                // Is it a mono track?
                
                NSRange range = [element2 rangeOfString:@"(Stereo)"];
                isMono = (range.location == NSNotFound);
                
                // Keep this track in our tracks container.
                
                [tracks addObject: [[Track alloc] initWithName:trackName Mono:isMono]];
                
            }
            else if([element1 isEqualToString: @"TIME CODE FORMAT:"] || [element1 isEqualToString: @"TIMECODE FORMAT:"])
            {
                frameRate = [element2 integerValue]; 
//                NSLog(@"TC SCANNED %ld", frameRate);
            }
            else if([element1 isEqualToString: @"SAMPLE RATE:"])
            {
                sampleRate = [element2 doubleValue];
            }
        }
        
        // PROTOOLS < 10.2.0 HAD 6 ELEMENTS PER LINE
        // We are only interested in regions at channel 1. In the case of mono regions, that's all
        // we get anyway. In the case if stereo items: the region on channel 2 has the same name
        // and we want to count them once.
        
        else if ((lineElementsCount == 6) && ([@"1" isEqualToString:[lineElements objectAtIndex:0]])) 
        {
            
            // Gather info we need to construct a Region object.
            // TODO: This section could do with more error checking.
            
            NSString* regionName = [lineElements objectAtIndex:2];
            
            NSInteger hours, minutes, seconds, frames;
            
            [self extractHMSF:[lineElements objectAtIndex:3] Hours:&hours Mins:&minutes Secs:&seconds Frames:&frames];
            NSInteger regionStartFrame = (3600 * frameRate * hours + 60 * frameRate * minutes + frameRate * seconds + frames);
            
            [self extractHMSF:[lineElements objectAtIndex:4] Hours:&hours Mins:&minutes Secs:&seconds Frames:&frames];
            NSInteger regionStopFrame = (3600 * frameRate * hours + 60 * frameRate * minutes + frameRate * seconds + frames);
            
            [self extractHMSF:[lineElements objectAtIndex:5] Hours:&hours Mins:&minutes Secs:&seconds Frames:&frames];
            NSInteger regionLength = (3600 * frameRate * hours + 60 * frameRate * minutes + frameRate * seconds + frames);
            
            // Instantiate a new Region object with the above.
            
            Region* region = [[Region alloc] initWithName:regionName TrackName:trackName StartFrame:regionStartFrame StopFrame:regionStopFrame Length:regionLength IsMono:isMono];
                        
            // Add it to container that holds all region data.
            
            [regions addObject:region];
            
            // See if we need to update our session limits.
            
            startFrame = MIN(regionStartFrame, startFrame);
            stopFrame = MAX(regionStopFrame, stopFrame);
        }
        
        // PROTOOLS >= 10.2.0 HAS 7 ELEMENTS PER LINE
        // We are only interested in regions at channel 1. In the case of mono regions, that's all
        // we get anyway. In the case if stereo items: the region on channel 2 has the same name
        // and we want to count them once.
        
        else if ((lineElementsCount == 7) && ([@"1" isEqualToString:[lineElements objectAtIndex:0]])) 
        {
            // Gather info we need to construct a Region object.
            // TODO: This section could do with more error checking.
            
            NSString* regionName = [lineElements objectAtIndex:2];
            
            NSLog(@"REGION [%@]", regionName);
            
            NSInteger hours, minutes, seconds, frames;
            
            [self extractHMSF:[lineElements objectAtIndex:3] Hours:&hours Mins:&minutes Secs:&seconds Frames:&frames];
            NSInteger regionStartFrame = (3600 * frameRate * hours + 60 * frameRate * minutes + frameRate * seconds + frames);
            
            [self extractHMSF:[lineElements objectAtIndex:4] Hours:&hours Mins:&minutes Secs:&seconds Frames:&frames];
            NSInteger regionStopFrame = (3600 * frameRate * hours + 60 * frameRate * minutes + frameRate * seconds + frames);
            
            [self extractHMSF:[lineElements objectAtIndex:5] Hours:&hours Mins:&minutes Secs:&seconds Frames:&frames];
            NSInteger regionLength = (3600 * frameRate * hours + 60 * frameRate * minutes + frameRate * seconds + frames);
            
            // There now is a state element. If this states "Muted", we ignore this region (because it has been muted)
            
            if ([[lineElements objectAtIndex:6] isEqualToString:@"Unmuted"]) 
            {
                // Instantiate a new Region object with the above.
                
                Region* region = [[Region alloc] initWithName:regionName TrackName:trackName StartFrame:regionStartFrame StopFrame:regionStopFrame Length:regionLength IsMono:isMono];
                
                // Add it to container that holds all region data.
                
                [regions addObject:region];
                
                // See if we need to update our session limits.
                
                startFrame = MIN(regionStartFrame, startFrame);
                stopFrame = MAX(regionStopFrame, stopFrame);
            }
        }
    }
    
    // In the odd case of an empty session (one with no regions), we haven't updated
    // our session boundaries so they are still at extreme values.
    
    if ([regions count] == 0) 
    {
        startFrame = stopFrame = 0;
    }
    
 */
    
    // A last check if all went fine.
    
//    if (frameRate /* still */ == HZ37_defaultFrameRate || sampleRate /* still */ == HZ37_defaultSampleRate) 
  //  {
    //    NSRunAlertPanel(@"Error", @"File wasn't read properly", @"Too bad", nil, nil);

      //  [self reset];
    //}
//}


// loadFileWithName loads the Protools text export file and parses it into
// separate elements. NEW CODE 20-06-2012 which uses regular expressions.

- (bool) loadFileWithName: (NSString*) fileName
{
    // Check if file exists.
    
    NSFileManager* fileManager = [NSFileManager new];
    
    if (![fileManager fileExistsAtPath:fileName]) 
    {
        NSRunAlertPanel(@"Error", @"File not found", @"Too bad", nil, nil);
        
        return false;
    }
    
    // Erase existing data.
    
    [self reset];
    
    // Read entire contents of file into an NSString.
    // NSASCIIStringEncoding turned out to work for Protools text exports
    // (used to be NSUTF8StringEncoding which failed for some files).
    
    NSError* error;
    
    NSString* stringFromFileAtPath = [[NSString alloc]
                                      initWithContentsOfFile:fileName
                                      encoding:NSASCIIStringEncoding
                                      error:&error];   
    
    if (stringFromFileAtPath == nil) 
    {
        NSRunAlertPanel(@"Error", @"File could not be read", @"Too bad", nil, nil);
        
        return false;
    }
    
    // File was read. Now we go through it line by line.
    
    sessionFileName = fileName;
    
    NSArray* lines = [stringFromFileAtPath componentsSeparatedByString:@"\n"];
    
    // Going though the file sequentially we move from track to track.
    // trackName will remember the current track we are parsing.
    
    NSString* trackName;
    
    // Tracks are either mono or stereo (we do not implement surround sound yet).
    
    BOOL isMono;
    
    // TODO: Move regexp compilation to here (does not need to be done every time in the loop).
    
    for (NSString* line in lines) 
    {
        NSError* error = nil;
        NSRange lineRange = NSMakeRange(0, [line length]);
        
        // Check if this line has the samplerate.
        // E.g.
        // SAMPLE RATE:	48000.000000
        
        if (sampleRate == /* still */ HZ37_defaultSampleRate) 
        {
            NSRegularExpression* sampleRateRegEx = [NSRegularExpression regularExpressionWithPattern:@"^SAMPLE\\s*RATE:\\s+(\\d+)\\.\\d+$" options:NSRegularExpressionCaseInsensitive error:&error];
            
            NSTextCheckingResult* sampleRateMatch = [sampleRateRegEx firstMatchInString:line options:0 range:lineRange];
            
            if ([sampleRateMatch numberOfRanges] == 2) 
            {
                NSString* sampleRateString = [line substringWithRange:[sampleRateMatch rangeAtIndex:1]];
                sampleRate = [sampleRateString doubleValue];
            }
        }

        // Check if this line has the framerate.
        // E.g.
        // TIMECODE FORMAT:	25 Frame
        
        if (frameRate == /* still */ HZ37_defaultFrameRate)
        {
            NSRegularExpression* frameRateRegEx = [NSRegularExpression regularExpressionWithPattern:@"^TIME\\s*CODE\\s*FORMAT:\\s+(\\d+)\\s+.*$" options:NSRegularExpressionCaseInsensitive error:&error];
            
            NSTextCheckingResult* frameRateMatch = [frameRateRegEx firstMatchInString:line options:0 range:lineRange];
            
            if ([frameRateMatch numberOfRanges] == 2) 
            {
                NSString* frameRateString = [line substringWithRange:[frameRateMatch rangeAtIndex:1]];
                frameRate = [frameRateString doubleValue];
            }
        }
        
        // Check for trackname.
        // E.g.
        // TRACK NAME:	Dst (Stereo)
        
        NSRegularExpression* stereoTrackRegEx = [NSRegularExpression regularExpressionWithPattern:@"^TRACK\\s*NAME:\\s+(.*)\\b\\(Stereo\\)$" options:NSRegularExpressionCaseInsensitive error:&error];
        
        NSTextCheckingResult* stereoTrackMatch = [stereoTrackRegEx firstMatchInString:line options:0 range:lineRange];
        
        if ([stereoTrackMatch numberOfRanges] == 2) 
        {
            isMono = FALSE;
            trackName = [line substringWithRange:[stereoTrackMatch rangeAtIndex:1]];
            [tracks addObject:[[Track alloc] initWithName:trackName Mono:isMono]];
        }
        else
        {
            // If that failed, it might be worth to check for a mono track.
            
            NSRegularExpression* monoTrackRegEx = [NSRegularExpression regularExpressionWithPattern:@"^TRACK\\s*NAME:\\s+(.*)$" options:NSRegularExpressionCaseInsensitive error:&error];
            
            NSTextCheckingResult* monoTrackMatch = [monoTrackRegEx firstMatchInString:line options:0 range:lineRange];
            
            if ([monoTrackMatch numberOfRanges] == 2) 
            {
                isMono = TRUE;
                trackName = [line substringWithRange:[monoTrackMatch rangeAtIndex:1]];
                [tracks addObject:[[Track alloc] initWithName:trackName Mono:isMono]];
            }
        }
        
        // Check for the < Protools version 10.2.0 6 field format.
        
        NSRegularExpression* regEx6 = [NSRegularExpression 
                                      regularExpressionWithPattern:@"^1\\s+\\d+\\s+(.*)\\b\\s+(\\d{2}:\\d{2}:\\d{2}:\\d{2})\\s+(\\d{2}:\\d{2}:\\d{2}:\\d{2})\\s+(\\d{2}:\\d{2}:\\d{2}:\\d{2})$" options:NSRegularExpressionCaseInsensitive 
                                      error:&error];
        
        NSTextCheckingResult* match6 = [regEx6 firstMatchInString:line options:0 /* was NSRegularExpressionCaseInsensitive */ range:lineRange];
        
        if ([match6 numberOfRanges] == 5) 
        {
            NSString* regionName = [line substringWithRange:[match6 rangeAtIndex:1]];
            
            NSInteger hours, minutes, seconds, frames;
            
            [self extractHMSF:[line substringWithRange:[match6 rangeAtIndex:2]] Hours:&hours Mins:&minutes Secs:&seconds Frames:&frames];
            
            NSInteger regionStartFrame = (3600 * frameRate * hours + 60 * frameRate * minutes + frameRate * seconds + frames);
            
            [self extractHMSF:[line substringWithRange:[match6 rangeAtIndex:3]] Hours:&hours Mins:&minutes Secs:&seconds Frames:&frames];
            
            NSInteger regionStopFrame = (3600 * frameRate * hours + 60 * frameRate * minutes + frameRate * seconds + frames);
            
            [self extractHMSF:[line substringWithRange:[match6 rangeAtIndex:4]] Hours:&hours Mins:&minutes Secs:&seconds Frames:&frames];
            
            NSInteger regionLength = (3600 * frameRate * hours + 60 * frameRate * minutes + frameRate * seconds + frames);
            
            // Instantiate a new Region object with the above.
            
            Region* region = [[Region alloc] initWithName:regionName TrackName:trackName StartFrame:regionStartFrame StopFrame:regionStopFrame Length:regionLength IsMono:isMono];
            
            // Add it to container that holds all region data.
            
            [regions addObject:region];
            
            // See if we need to update our session limits.
            
            startFrame = MIN(regionStartFrame, startFrame);
            stopFrame = MAX(regionStopFrame, stopFrame);
        }
       
        // Check for the >= Protools version 10.2.0 7 field format.
        // If such a line specifies "Muted" (as opposed to "Unmuted") we can safely skip it
        // because the user has actively muted it. This regex just won't match it, so we
        // don't have to test for it.
        
        NSRegularExpression* regEx7 = [NSRegularExpression 
                                       regularExpressionWithPattern:@"^1\\s+\\d+\\s+(.*)\\b\\s+(\\d{2}:\\d{2}:\\d{2}:\\d{2})\\s+(\\d{2}:\\d{2}:\\d{2}:\\d{2})\\s+(\\d{2}:\\d{2}:\\d{2}:\\d{2})\\s+Unmuted$" options:NSRegularExpressionCaseInsensitive 
                                       error:&error];
        
        NSTextCheckingResult* match7 = [regEx7 firstMatchInString:line options:0 range:lineRange];
        
        if ([match7 numberOfRanges] == 5) 
        {
            NSString* regionName = [line substringWithRange:[match7 rangeAtIndex:1]];
            
            NSInteger hours, minutes, seconds, frames;
            
            [self extractHMSF:[line substringWithRange:[match7 rangeAtIndex:2]] Hours:&hours Mins:&minutes Secs:&seconds Frames:&frames];
            
            NSInteger regionStartFrame = (3600 * frameRate * hours + 60 * frameRate * minutes + frameRate * seconds + frames);
            
            [self extractHMSF:[line substringWithRange:[match7 rangeAtIndex:3]] Hours:&hours Mins:&minutes Secs:&seconds Frames:&frames];
            
            NSInteger regionStopFrame = (3600 * frameRate * hours + 60 * frameRate * minutes + frameRate * seconds + frames);
            
            [self extractHMSF:[line substringWithRange:[match7 rangeAtIndex:4]] Hours:&hours Mins:&minutes Secs:&seconds Frames:&frames];
            
            NSInteger regionLength = (3600 * frameRate * hours + 60 * frameRate * minutes + frameRate * seconds + frames);
            
            // Instantiate a new Region object with the above.
            
            Region* region = [[Region alloc] initWithName:regionName TrackName:trackName StartFrame:regionStartFrame StopFrame:regionStopFrame Length:regionLength IsMono:isMono];
            
            // Add it to container that holds all region data.
            
            [regions addObject:region];
            
            // See if we need to update our session limits.
            
            startFrame = MIN(regionStartFrame, startFrame);
            stopFrame = MAX(regionStopFrame, stopFrame);
        }
    }
    
    // In the odd case of an empty session (one with no regions), we haven't updated
    // our session boundaries so they are still at extreme values.
    
    if ([regions count] == 0) 
    {
        startFrame = stopFrame = 0;
    }
    
    // A last check if all went fine.
    
    if (frameRate /* still */ == HZ37_defaultFrameRate || sampleRate /* still */ == HZ37_defaultSampleRate) 
    {
        [self reset];
        
        NSRunAlertPanel(@"Error", @"File wasn't read properly", @"Too bad", nil, nil);
        
        return false;
    }
    
    return true;
}


// Return amount of rows in output table.

- (NSInteger) regionUsageCount
{
    return [regionUsages count];
}


// App delegate requests regionUsage name for display in table.

- (NSString*) regionUsageNameAtIndex: (NSInteger) index
{
    // Bounds check.
    
    if (index > [regionUsages count] - 1)
    {
        return nil;
    }
    
    RegionUsage* regionUsage = [regionUsages objectAtIndex:index];
    
    //NSLog(@"name [%@] len [%ld]", [regionUsage getName], [regionUsage getLength]);
    
    return [regionUsage getName];
}


// App delegate requests regionUsage time used for display in table.

- (NSInteger) regionUsageTimeAtIndex: (NSInteger) index
{
    // Bounds check.
    
    if (index > [regionUsages count] - 1)
    {
        return 0;
    }

    RegionUsage* regionUsage = [regionUsages objectAtIndex:index];
    
    return [regionUsage getLength];
}


// Internal helper function for combineManually() method.
// Removes a single region from the regions container
// and returns the length.

- (NSInteger) removeRegionWithName: (NSString*) name
{   
    NSInteger lengthToReturn = 0;

    NSInteger count = [regions count];
    
    NSInteger idx = 0;
    
    for (idx = 0; idx < count; ++idx) 
    {
        Region* r = [regions objectAtIndex:idx];
        
        if ([[r name] isEqualToString:name]) 
        {
            lengthToReturn = [r length];
            break;
        }
    }
    
    // Done scanning. If we are not out of bounds, delete this item.
    
    if (idx < count) 
    {
        [regions removeObjectAtIndex:idx];
        //NSLog(@"REM: [%ld][%@]", idx, name);
    }
    
    return lengthToReturn; 
}


// When a user loads a new Protools text export file, reset should be called
// to remove existing data from containers. Reset also resets other object vars
// to default (pessimistic) values.

- (void) reset
{
    [regions removeAllObjects];
    [tracks removeAllObjects];
    
    frameRate = HZ37_defaultFrameRate;
    sampleRate = HZ37_defaultSampleRate;
    startFrame = NSIntegerMax;
    stopFrame = NSIntegerMin;
    sessionFileName = @"Nothing loaded";
}


// Delegate tells us whether or not we should combine similar regions.

- (void) setCombineSimilar: (BOOL) newState
{
    combineSimilar = newState;
}


// Delegate tells us whether or not we should ignore regions that start with "fade".
// This makes sense, because these are actual fades.

- (void) setIgnoreFade: (BOOL) newState
{
    ignoreFade = newState;
}


// Delegate tells us whether or not we should ignore regions that are shorter than a certain length.
// See function immediately below here for the time.

- (void) setIgnoreShorter: (BOOL) newState
{
    ignoreShorter = newState;
}


// Delegate tells us whether or not we should ignore regions that are shorter than a certain length.
// See function immediately above here for the yes or no of this situation.

- (void) setIgnoreShorterThan: (NSInteger) newState
{
    ignoreShorterThan = newState;
}


// Delegate tells us whether or not we should ignore string data after extension.

- (void) setIgnoreStringDataAfterExtension: (BOOL) newState
{
    ignoreStringDataAfterExtension = newState;
}


// Delegate tells us whether or not we should ignore string data after .new.
// Protools tags this information on some regions.

- (void) setIgnoreStringDataAfterNew: (BOOL) newState
{
    ignoreStringDataAfterNew = newState;
}


// User selects a portion of the session to be included in the output
// as opposed to using the whole session.

- (void) setSelectionStart: (NSInteger) newValue
{
    selectionStart = newValue;
}


// User selects a portion of the session to be included in the output
// as opposed to using the whole session.

- (void) setSelectionStop: (NSInteger) newValue
{
    selectionStop = newValue;
}


// User requests to sort on name (TRUE) or time (FALSE) in output data.

- (void) setSortOnName: (BOOL) value
{
    sortOnName = value;
}


// Set the track state from a checkbox in an NSTable.

- (void) setTrackState: (BOOL) toValue AtIndex: (NSInteger) index
{
    // Bounds check;
    
    if (index > [tracks count] - 1)
    {
        return;
    }
    
    Track* track = [tracks objectAtIndex:index];
    
    [track setBoolValue:toValue];
}


// Return amount of tracks read.

- (NSInteger) trackCount
{
    return [tracks count];
}


// Return the trackName at index.

- (NSString*) trackNameAtIndex: (NSInteger) index
{
    // Bounds check;
    
    if (index > [tracks count] - 1)
    {
        return nil;
    }

    Track* track = [tracks objectAtIndex:index];
    
    return [track trackName];
}


// Return track state (i.e. selected or not) of track at index. Needs to be NSNumber* for table that uses it.

- (NSNumber*) trackStateAtIndex: (NSInteger) index;
{
    // Bounds check;
    
    if (index > [tracks count] - 1)
    {
        return nil;
    }
    
    Track* track = [tracks objectAtIndex:index];
    
    return [track numberValue];
}


@end
