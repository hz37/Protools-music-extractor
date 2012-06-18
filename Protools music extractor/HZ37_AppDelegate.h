//
//  HZ37_AppDelegate.h
//  Protools music extractor
//
//  Created by Hens Zimmerman on 3/6/12.
//  Copyright (c) 2012 HZ37Land. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MiniUniverse;
@class ProtoolsData;

@interface HZ37_AppDelegate : NSObject <NSApplicationDelegate>
{
    // Pointer to (single) MODEL object.
    
    ProtoolsData* protoolsData;
    __weak MiniUniverse *miniUniverse;
    
    // User setting concerning frames in output table.
    
    BOOL suppressFramesInOutput;
    
    // Sort order is remembered.
    
    BOOL sortOnName;
}

@property (weak) IBOutlet NSTableView *tracksTable;
@property (assign) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet NSPanel *infoPanel;
@property (weak) IBOutlet NSTextField *hudLabelFilename;
@property (weak) IBOutlet NSTextField *hudLabelTrackCount;
@property (weak) IBOutlet NSTextField *hudLabelSampleRate;
@property (weak) IBOutlet NSTextField *hudLabelRegionCount;
@property (weak) IBOutlet NSTextField *hudLabelFrameRate;
@property (unsafe_unretained) IBOutlet NSPanel *preferencesPanel;
@property (weak) IBOutlet NSButton *ignoreExtensionCheckbox;
@property (weak) IBOutlet NSButton *ignoreNewCheckBox;
@property (weak) IBOutlet NSButton *ignoreFadeCheckBox;
@property (weak) IBOutlet NSButton *suppressFramesCheckBox;
@property (weak) IBOutlet NSButton *combineSimilarCheckBox;
@property (weak) IBOutlet NSButton *ignoreShorterCheckBox;
@property (weak) IBOutlet NSStepper *ignoreShorterStepper;
@property (weak) IBOutlet MiniUniverse *miniUniverse;
@property (weak) IBOutlet NSSlider *startSelectionSlider;
@property (weak) IBOutlet NSSlider *stopSelectionSlider;
@property (weak) IBOutlet NSTextField *tcSetStart;
@property (weak) IBOutlet NSTextField *tcSetStop;
@property (weak) IBOutlet NSTableView *outputTable;
@property (weak) IBOutlet NSScrollView *outputTableScrollView;
@property (weak) IBOutlet NSMenuItem *combineMenuItem;

- (IBAction) changeSelectionStart: (id) sender;
- (IBAction) changeSelectionStop: (id) sender;
- (IBAction) closePreferences: (id) sender;
- (IBAction) combineManually:(id)sender;
- (IBAction) combineSimilar: (id) sender;
- (IBAction)deleteEntries:(id)sender;
- (IBAction) deselectAllTracks: (id) sender;
- (void) generateAndDisplayOutput;
- (void) handleFileDropped: (NSNotification*) note;
- (IBAction) ignoreExtension: (id) sender;
- (IBAction) ignoreFade: (id) sender;
- (IBAction) ignoreShorter: (id) sender;
- (IBAction) ignoreShorterStepped: (id) sender;
- (IBAction) ignoreNew: (id) sender;
- (void) loadUserSettings;
- (IBAction) openFile: (id) sender;
- (IBAction) openPreferences: (id) sender;
- (IBAction) print: (id) sender;
- (void) processFileWithName: (NSString*) fileName;
- (IBAction) saveToPasteboard:(id)sender;
- (IBAction) saveToFile:(id)sender;
- (void) saveUserSettings;
- (IBAction) selectAllMTracks: (id) sender;
- (IBAction) selectAllStereoTracks: (id) sender;
- (IBAction) selectAllTracks: (id) sender;
- (IBAction) selectWholeSession: (id) sender;
- (IBAction) showInfo: (id) sender;
- (IBAction) suppressFrames: (id) sender;
- (IBAction) tcInChanged: (id) sender;
- (IBAction) tcOutChanged: (id) sender;
- (NSInteger) textToFrames: (NSString*) text;
- (void) updateInfoWindow;
- (void) updateMiniUniverse;

@end
