//
//  RegionUsage.h
//  Protools music extractor
//
//  Created by Hens Zimmerman on 3/6/12.
//  Copyright (c) 2012 HZ37Land. All rights reserved.
//

// A RegionUsage object represents the output of the program. which will be saved
// to a file or represented in a table (or both). A RegionUsage object has a name
// and a length. RegionObjects will be collected in an array to represent the
// output of the program, based on user choices.

#import <Foundation/Foundation.h>

@interface RegionUsage : NSObject
{
    // Region name as filtered down by ProtoolsData MODEL.
    // This can be a more readable condensed version of what
    // was actually read from the Protools session, i.e. stripped of extraneous shit.
    // Several regions can also be combined by ProtoolsData and added together under
    // a single name.
    
    NSString* name;
    
    // Length in frames. Possibly added from different regions (see comment above).
    
    NSInteger length;
}

- (NSComparisonResult) compareName: (RegionUsage*) f;
- (NSComparisonResult) compareLength: (RegionUsage*) f;
- (id) initWith: (NSString*) theName LengthInFrames: (NSInteger) theLength;
- (NSInteger) getLength;
- (NSString*) getName;

@end
