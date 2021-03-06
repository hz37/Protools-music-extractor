//
//  RegionUsage.m
//  Protools music extractor
//
//  Created by Hens Zimmerman on 3/6/12.
//  Copyright (c) 2012 HZ37Land. All rights reserved.
//

// A RegionUsage object represents the output of the program. which will be saved
// to a file or represented in a table (or both). A RegionUsage object has a name
// and a length. RegionObjects will be collected in an array to represent the
// output of the program, based on user choices.

#import "RegionUsage.h"

@implementation RegionUsage

// Sort on name. Required function if we want to put RegionUsage objects in
// an NSMutableArray and sort it on name.

- (NSComparisonResult) compareName: (RegionUsage*) f
{
    return [name caseInsensitiveCompare:[f getName]];
}


// Sort on length. Required function if we want to put RegionUsage objects in
// an NSMutableArray and sort it on length.

- (NSComparisonResult) compareLength: (RegionUsage*) f
{
    return [self getLength] > [f getLength];
}


// Construct with values passed. Calls super init and returns self.

- (id) initWith: (NSString*) theName OriginalNames: (NSArray*) theOriginalNames LengthInFrames: (NSInteger) theLength
{
    if (self = [super init]) 
    {
        name = theName;
        originalNames = [[NSMutableArray alloc] initWithArray:theOriginalNames];
        length = theLength;
    }
    
    return self;
}


// Return length in frames.

- (NSInteger) getLength
{
    return length;
}


// Return region name.

- (NSString*) getName
{
    return name;
}


// Return the original (untruncated, uncombined) name(s) of this region.
// There can be one or more original names, hence the array.

- (NSArray*) getOriginalNames
{
    return originalNames;
}


// User provides a new name for this region out of discomfort
// about the generated name.

- (void) setName: (NSString*) newName
{
    name = newName;
}

@end
