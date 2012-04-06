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


// Delete entries from the regionUsages array.
// This is a way to clean up the list with superfluous shit (like sound effects)
// before printing it or saving it. The output table supports multi select
// and the indices of all the selected items are passed to this function.

- (void) deleteRows: (NSIndexSet*) indices
{
    // Amount we have to subtract every time when an object's been removed.
    
    NSUInteger __block subtractor = 0;
    
    [indices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) 
    {
        [regionUsages removeObjectAtIndex:idx - subtractor];
        
        // When we delete a region, the indices decrement from that point onwards.
        
        ++subtractor;
    }];
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
    
    NSArray* extensionToIgnore = [[NSArray alloc] initWithObjects:@".aif", @".mp3", @".m4a", @".wav", nil];
    
    //
    // PASS ONE: REDUCE ON NAMES.
    //
    
    for (Region* region in regions) 
    {
        // If track is not selected, skip it.
        
        if ([[tracksLUT objectForKey:[region trackName]] boolValue] == FALSE) 
        {
            continue;
            //
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
        
        NSString* regionName = [region name];
        
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
            // See if we already have this region. If so add times together.
            
            NSInteger count = [regionUsages count];
            
            for (NSInteger idx = 0; idx < count; ++idx) 
            {
                RegionUsage* regionUsage = [regionUsages objectAtIndex:idx];
                
                if ([regionUsage.getName isEqualToString:regionName]) 
                {
                    // Add existing length to current length.
                    
                    regionLength += regionUsage.getLength;
                    
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
        // 3) We do combine similar regiond and the existing object was found, added and deleted.
        
        RegionUsage* regionUsage = [[RegionUsage alloc] initWith:regionName LengthInFrames:regionLength];
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
        
        // Remove those items in reverse orser so our index values dodn't get messed up.
        
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


// Return session filename.

- (NSString*) getTitle
{
    return [sessionFileName lastPathComponent];
}


// Return tracks as immutable array so it can be passed to
// miniUniverse which needs to draw with it.

- (NSArray*) getTracks
{
    return tracks;
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
            }
            else if([element1 isEqualToString: @"SAMPLE RATE:"])
            {
                sampleRate = [element2 doubleValue];
            }
        }
        
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
        NSRunAlertPanel(@"Error", @"File wasn't read properly", @"Too bad", nil, nil);

        [self reset];
    }
}


// Return amount of rows in output table.

- (NSInteger) regionUsageCount
{
    return [regionUsages count];
}


// App delegate requests regionUsage name for display in table.

- (NSString*) regionUsageNameAtIndex: (NSInteger) index
{
    RegionUsage* regionUsage = [regionUsages objectAtIndex:index];
    
    return [regionUsage getName];
}


// App delegate requests regionUsage time used for display in table.

- (NSInteger) regionUsageTimeAtIndex: (NSInteger) index
{
    RegionUsage* regionUsage = [regionUsages objectAtIndex:index];
    
    return [regionUsage getLength];
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
    Track* track = [tracks objectAtIndex:index];
    
    return [track trackName];
}


// Return track state (i.e. selected or not) of track at index. Needs to be NSNumber* for table that uses it.

- (NSNumber*) trackStateAtIndex: (NSInteger) index;
{
    Track* track = [tracks objectAtIndex:index];
    
    return [track numberValue];
}


@end
