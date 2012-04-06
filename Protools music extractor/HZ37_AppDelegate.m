//
//  HZ37_AppDelegate.m
//  Protools music extractor
//
//  Created by Hens Zimmerman on 3/6/12.
//  Copyright (c) 2012 HZ37Land. All rights reserved.
//

#import "HZ37_AppDelegate.h"
#import "MiniUniverse.h"
#import "PrintView.h"
#import "ProtoolsData.h"
#import "Utility.h"

@implementation HZ37_AppDelegate

@synthesize hudLabelFilename;
@synthesize hudLabelFrameRate;
@synthesize hudLabelTrackCount;
@synthesize hudLabelSampleRate;
@synthesize hudLabelRegionCount;
@synthesize ignoreShorterCheckBox;
@synthesize ignoreShorterStepper;
@synthesize infoPanel;
@synthesize miniUniverse;
@synthesize startSelectionSlider;
@synthesize stopSelectionSlider;
@synthesize tcSetStart;
@synthesize tcSetStop;
@synthesize outputTable;
@synthesize outputTableScrollView;
@synthesize preferencesPanel;
@synthesize ignoreExtensionCheckbox;
@synthesize ignoreNewCheckBox;
@synthesize ignoreFadeCheckBox;
@synthesize suppressFramesCheckBox;
@synthesize combineSimilarCheckBox;
@synthesize tracksTable;
@synthesize window = _window;


// Keys for user settings.

NSString* const HZ_IgnoreStringDataAfterExtensionKey = @"IgnoreStringDataAfterExtension";
NSString* const HZ_IgnoreStringDataAfterNewKey = @"IgnoreStringDataAfterNew";
NSString* const HZ_IgnoreFadesKey = @"IgnoreFades";
NSString* const HZ_SuppressFramesKey = @"SuppressFrames";
NSString* const HZ_CombineSimilarKey = @"CombineSimilar";
NSString* const HZ_IgnoreShorterKey = @"IgnoreShorter";
NSString* const HZ_IgnoreShorterThanKey = @"IgnoreShorterThan";
NSString* const HZ_SortOnName = @"SortOnName";


// File selected from recent files menu item.

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    // Check if it still exists.
    
    NSFileManager* fileManager = [[NSFileManager alloc] init];
    
    if ([fileManager fileExistsAtPath:filename]) {
        [self processFileWithName:filename];
        
        return YES;
    }
    
    // Remove from recent menu items.
    
    return NO;
    
}


// IDE generated function.

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Set defaults. We cannot do this during init because at that point the nib interface
    // has not been unarchived yet.
    
    [self loadUserSettings];
        
#if DEBUG
    NSLog(@"DEBUGGING STILL ON");
#endif
    
}


// Just before closing, we save the user settings to disk.

- (void) applicationWillTerminate:(NSNotification *)notification
{
    // Save user settings to disk.
    
    [self saveUserSettings];
}


// User changes selection in mini universe.

- (IBAction)changeSelectionStart:(id)sender 
{
    NSInteger selectionStart = [startSelectionSlider integerValue];
    NSInteger selectionStop = [stopSelectionSlider integerValue];
             
    if (selectionStart > selectionStop) 
    {
        [stopSelectionSlider setIntegerValue:selectionStart];
        [self changeSelectionStop:sender];
    }
                                
    // Update objects who need to know about this.
    
    [miniUniverse setSelectionStart:selectionStart];
    [protoolsData setSelectionStart:selectionStart];

    // Update timecode display.
    
    NSString* tc = [Utility framesToHMSF:selectionStart IncludeFrames:TRUE Framerate:[protoolsData frameRate]];
    
    if (tc != nil) 
    {
        [tcSetStart setStringValue:tc];
    }

    // Display output table.
    
    [self generateAndDisplayOutput];
}


// User changes selection in mini universe.

- (IBAction)changeSelectionStop:(id)sender 
{
    NSInteger selectionStart = [startSelectionSlider integerValue];
    NSInteger selectionStop = [stopSelectionSlider integerValue];
    
    if (selectionStart > selectionStop) 
    {
        [startSelectionSlider setIntegerValue:selectionStop];
        [self changeSelectionStart:sender];
    }
    
    // Update objects who need to know about this.
    
    [miniUniverse setSelectionStop:selectionStop];
    [protoolsData setSelectionStop:selectionStop];
    
    // Update timecode display.
    
    NSString* tc = [Utility framesToHMSF:selectionStop IncludeFrames:TRUE Framerate:[protoolsData frameRate]];
    
    
    if (tc != nil) 
    {
        [tcSetStop setStringValue:tc];
    }
    
    // Display output table.
    
    [self generateAndDisplayOutput];
}


// Close the preferences panel.

- (IBAction)closePreferences:(id)sender 
{
    // Return to normal event handling 
    
    [NSApp endSheet:preferencesPanel];
    
    // Hide the sheet
    
    [preferencesPanel orderOut:sender];
}


// User clicks checkbox in preferences to request to
// combine similar regions or not.

- (IBAction)combineSimilar:(id)sender 
{
    [protoolsData setCombineSimilar:[sender state]];

    // Display output table.
    
    [self generateAndDisplayOutput];
}


// App delegate gets deallocated. Time to unregister our notification
// according to Hillegass.

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


// User hits delete key (this is actually a menu item with a keyboard equivalent).
// If we have selected entries in the output table, those will be deleted.

- (IBAction)deleteEntries:(id)sender 
{
    // Get selections from output table.
    
    [protoolsData deleteRows:[outputTable selectedRowIndexes]];

    // In this case, we can't regenerate the table because
    // it would re-enter everything we have just deleted.
    
    [outputTable reloadData];
    
    // Deselect.
    
    [outputTable deselectAll:sender];
    
    // Also display amount of regions in hud window.
    
    NSInteger count = [protoolsData regionUsageCount];
    
    [hudLabelRegionCount setStringValue:[[NSString alloc] initWithFormat:@"%ld file%@ selected", count, count == 1 ? @"" : @"s"]];
}


// Deselect all tracks in tracks checkboxes table.

- (IBAction)deselectAllTracks:(id)sender 
{
    NSInteger count = [protoolsData trackCount];
    
    for (NSInteger idx = 0; idx < count; ++idx) 
    {
        [protoolsData setTrackState:FALSE AtIndex:idx];
    }
    
    [tracksTable reloadData];

    // Display output table.
    
    [self generateAndDisplayOutput];
}


// When user has changed something, table with output needs to be redrawn.

- (void) generateAndDisplayOutput
{
    [protoolsData generateListing];
    [outputTable reloadData];
    
    // Also display amount of regions in hud window.
    
    NSInteger count = [protoolsData regionUsageCount];
    
    [hudLabelRegionCount setStringValue:[[NSString alloc] initWithFormat:@"%ld file%@ selected", count, count == 1 ? @"" : @"s"]];
}


// User clicks checkbox in preferences to request to
// ignore string data after extensions or not.

- (IBAction)ignoreExtension: (id) sender 
{
    [protoolsData setIgnoreStringDataAfterExtension:[sender state]];

    // Display output table.
    
    [self generateAndDisplayOutput];
}


// User clicks checkbox in preferences to request to
// ignore fades or not.

- (IBAction)ignoreFade:(id)sender 
{
    [protoolsData setIgnoreFade:[sender state]];

    // Display output table.
    
    [self generateAndDisplayOutput];
}


// User clicks checkbox in preferences to request to
// ignore regions shorter than a certain amount or not.

- (IBAction)ignoreShorter:(id)sender 
{
    [protoolsData setIgnoreShorter:[sender state]];

    // Display output table.
    
    [self generateAndDisplayOutput];
}


// User clicks stepper in preferences to request to
// ignore regions shorter than a certain amount or not.

- (IBAction)ignoreShorterStepped: (id) sender 
{
    NSInteger newValue = [sender integerValue];
    
    // Update interface in Preferences pane.
    
    NSString* newTitle = [[NSString alloc] initWithFormat:@"Ignore regions shorter than %ld second%@", newValue, (newValue > 1) ? @"s" : @""];
    
    [ignoreShorterCheckBox setTitle:newTitle];
    
    // Delegate to MODEL.
    
    [protoolsData setIgnoreShorterThan:newValue];

    // Display output table.
    
    [self generateAndDisplayOutput];
}


// User clicks checkbox in preferences to request to
// ignore string data after ".new" or not.

- (IBAction)ignoreNew:(id)sender 
{
    [protoolsData setIgnoreStringDataAfterNew:[sender state]];

    // Display output table.
    
    [self generateAndDisplayOutput];
}


// SELECTOR called when notification center receives a filedropped message from
// miniuniverse nsview.

- (void) handleFileDropped: (NSNotification*) note
{
    NSArray* files = [note object];
    NSString* fileName = [files objectAtIndex:0];
    
    // Is it a .txt file?
    
    NSRange r = [fileName rangeOfString:@".txt"];
    
    if (r.location == NSNotFound) 
    {
        NSRunAlertPanel(@"Error", @"I only read files that end with .txt", @"I see", nil, nil);
    }
    else
    {
        [self processFileWithName:fileName];
    }
}


// Object initializer. Do stuff that needs to be done once at program creation.

- (id) init
{
    if(self = [super init])
    {
        // Instantiate single MODEL object.
        
        protoolsData = [[ProtoolsData alloc] init];
        
        // Register as an observer for file dropped message from miniUniverse view.
        
        NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
        
        [nc addObserver:self selector:@selector(handleFileDropped:) name:HZ_FileDropped object:nil];
   }
    
    return self;
}


// Load the user preferences/settings from disk.

- (void) loadUserSettings
{
    // Register user defaults.
    
    NSMutableDictionary* defaultValues = [NSMutableDictionary dictionary];
    
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:HZ_IgnoreStringDataAfterExtensionKey];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:HZ_IgnoreStringDataAfterNewKey];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:HZ_IgnoreFadesKey];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:HZ_SuppressFramesKey];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:HZ_CombineSimilarKey];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:HZ_IgnoreShorterKey];
    [defaultValues setObject:[NSNumber numberWithInteger:1] forKey:HZ_IgnoreShorterThanKey];
    [defaultValues setObject:[NSNumber numberWithInteger:1] forKey:HZ_SortOnName];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
    
    // Restore user preferences.
    
    NSUserDefaults* userDefaults  = [NSUserDefaults standardUserDefaults];
    
    BOOL value;

    value = [userDefaults boolForKey:HZ_IgnoreStringDataAfterExtensionKey];
    [protoolsData setIgnoreStringDataAfterExtension:value];
    [ignoreExtensionCheckbox setState:value];
    
    value = [userDefaults boolForKey:HZ_IgnoreStringDataAfterNewKey];
    [protoolsData setIgnoreStringDataAfterNew:value];
    [ignoreNewCheckBox setState:value];
    
    value = [userDefaults boolForKey:HZ_IgnoreFadesKey];
    [protoolsData setIgnoreFade:value];
    [ignoreFadeCheckBox setState:value];

    value = [userDefaults boolForKey:HZ_SuppressFramesKey];
    suppressFramesInOutput = value;
    [suppressFramesCheckBox setState:value];

    value = [userDefaults boolForKey:HZ_CombineSimilarKey];
    [protoolsData setCombineSimilar:value];
    [combineSimilarCheckBox setState:value];

    value = [userDefaults boolForKey:HZ_IgnoreShorterKey];
    [protoolsData setIgnoreShorter:value];
    [ignoreShorterCheckBox setState:value];
    
    value = [userDefaults boolForKey:HZ_SortOnName];
    [protoolsData setSortOnName:value];
    
    NSInteger iValue = [userDefaults integerForKey:HZ_IgnoreShorterThanKey];
    [ignoreShorterStepper setIntegerValue:iValue];
    [self ignoreShorterStepped:ignoreShorterStepper];
}


// Populate table with rows. Required function for datasource of NSTableView.

- (NSInteger) numberOfRowsInTableView: (NSTableView*) tableView
{
    if (tableView == tracksTable) 
    {
        return [protoolsData trackCount];
    }
    else
    {
        // As long as this program has only two tables, there's no need
        // to do another evaluation.
        
        return [protoolsData regionUsageCount];
    }
    
    // Default return value that should not happen.
    
    return 0;
}


// openFile is called by the menu or the Open... button in the interface.
// It passes the fileName to processFile which further knows what to with it.

- (IBAction) openFile: (id) sender 
{
    // Create an NSOpenPanel and let user select a file or bail out.
    
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    
    // Set some values for our newly created panel.
    
    [panel setPrompt:@"Open Protools text export"];
    
    // A Protools text export is always of the *.txt kind.
    
    NSArray* allowedFileTypes = [NSArray arrayWithObject:@"txt"];
    
    [panel setAllowedFileTypes:allowedFileTypes];
    
    // Now run the panel.
    
    NSInteger returnValue = [panel runModal];
    
    if (returnValue != NSOKButton) {
        // User cancelled action. Let's get out of here.
        
        return;
    }
    
    // User selected a file.
    
    NSURL* url = [panel URL];
    
    // Further process the file.
    
    [self processFileWithName:[url path]];
}


// Display preferences sheet. HZ37_AppDelegate is also the delegate for the preferencesPanel (i.e. ~sheet).

- (IBAction)openPreferences:(id)sender 
{
    [NSApp beginSheet:preferencesPanel modalForWindow:[self window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}


// Implement standard Print... menu. Woohoo! Also prints to PDF!

/*
 
KNOWN BUG:
 
This is printed the console in OSX 10.7.3 when printing:
 
Mar 17 07:13:53 Hens-Zimmermans-MacBook-Pro.local Protools music extractor[721] <Error>: kCGErrorIllegalArgument: _CGSFindSharedWindow: WID -1
Mar 17 07:13:53 Hens-Zimmermans-MacBook-Pro.local Protools music extractor[721] <Error>: kCGErrorFailure: Set a breakpoint @ CGErrorBreakpoint() to catch errors as they are logged.
Mar 17 07:13:53 Hens-Zimmermans-MacBook-Pro.local Protools music extractor[721] <Error>: kCGErrorIllegalArgument: CGSSetWindowShadowAndRimParametersWithStretch: Invalid window 0xffffffff

From Apple forums it appears this is an OSX issue and not something
 to worry about right now.
 
*/

- (IBAction)print:(id)sender 
{
    if ([protoolsData regionUsageCount] == 0) 
    {
        NSRunAlertPanel(@"Warning:", @"There is nothing to print", @"Of course", nil, nil);
        return;
    }
    
    NSString* title = [protoolsData getTitle];

    PrintView* printView = [[PrintView alloc] initWithRegionUsages:[protoolsData getRegionUsagesRaw] IncludeFrames:!suppressFramesInOutput FrameRate:[protoolsData getFrameRate] Title:title];
    
    NSPrintInfo *currInfo = [NSPrintInfo sharedPrintInfo];
    
    NSPrintOperation* printOp = [NSPrintOperation printOperationWithView:printView printInfo:currInfo];
    
    [printOp setJobTitle:title];
    
    [printOp runOperation];
    
}


// processFileWithName gets its output from the Open... button, the menu or
// even the recent files menu item. It assumes the file exists and passes control
// to the appropriate function in the ProtoolsData object (MODEL) which knows
// what to do with it.

- (void) processFileWithName: (NSString*) fileName
{
    // Remember in recent files menu.

    NSURL* url = [NSURL fileURLWithPath:fileName];
    [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:url];

    // Let protoolsData MODEL do the parsing.
    
    [protoolsData loadFileWithName:fileName];
    
    // Now that the file is parsed, we can update our interface.
    
    [tracksTable reloadData];
    [self updateMiniUniverse];
    [self updateInfoWindow];
    
    // Update timecode displays.
    
    NSInteger sessionStart, sessionStop;
    
    [protoolsData getSessionBoundaries:&sessionStart SessionEnd:&sessionStop];
    
    [tcSetStart setStringValue:[Utility framesToHMSF:sessionStart IncludeFrames:TRUE Framerate:[protoolsData frameRate]]];
    [tcSetStop setStringValue:[Utility framesToHMSF:sessionStop IncludeFrames:TRUE Framerate:[protoolsData frameRate]]];

    // Display table.
    
    [self generateAndDisplayOutput];
}


// User requests to copy generated output to pasteboard.

- (IBAction)saveToPasteboard:(id)sender 
{
    if ([protoolsData regionUsageCount] == 0) 
    {
        NSRunAlertPanel(@"Warning:", @"There is nothing to copy", @"Of course", nil, nil);
        return;
    }
    
    NSPasteboard* pasteBoard = [NSPasteboard generalPasteboard];
    
    [pasteBoard clearContents];
    [pasteBoard setString:[protoolsData getRegionUsages:!suppressFramesInOutput] forType:NSPasteboardTypeString];
        
}


// User requests to copy generated output to a textfile.

- (IBAction)saveToFile:(id)sender 
{
    if ([protoolsData regionUsageCount] == 0) 
    {
        NSRunAlertPanel(@"Warning:", @"There is nothing to save", @"Of course", nil, nil);
        return;
    }
    
    NSSavePanel* savePanel = [NSSavePanel savePanel];
	
	[savePanel setTitle:@"Save as *.txt file"];
    [savePanel setAllowedFileTypes:[NSArray arrayWithObjects:@"txt", nil]];
    
    if ([savePanel runModal] == NSOKButton) 
    {
        NSString* listing = [protoolsData getRegionUsages:!suppressFramesInOutput];
        [listing writeToURL:[savePanel URL] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}


// Save user preferences/settings to disk.

- (void) saveUserSettings
{
    NSUserDefaults* userDefaults  = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setValue:[NSNumber numberWithBool:[ignoreExtensionCheckbox state]] forKey:HZ_IgnoreStringDataAfterExtensionKey];
    [userDefaults setValue:[NSNumber numberWithBool:[ignoreNewCheckBox state]] forKey:HZ_IgnoreStringDataAfterNewKey];
    [userDefaults setValue:[NSNumber numberWithBool:[ignoreFadeCheckBox state]] forKey:HZ_IgnoreFadesKey];
    [userDefaults setValue:[NSNumber numberWithBool:[suppressFramesCheckBox state]] forKey:HZ_SuppressFramesKey];
    [userDefaults setValue:[NSNumber numberWithBool:[combineSimilarCheckBox state]] forKey:HZ_CombineSimilarKey];
    [userDefaults setValue:[NSNumber numberWithBool:[ignoreShorterCheckBox state]] forKey:HZ_IgnoreShorterKey];
    [userDefaults setValue:[NSNumber numberWithBool:sortOnName] forKey:HZ_SortOnName];
    [userDefaults setValue:[NSNumber numberWithInteger:[ignoreShorterStepper integerValue]] forKey:HZ_IgnoreShorterThanKey];
}


// Select all M(usic) tracks in tracks checkboxes table.
// David Klooker's convention for naming music tracks,
// e.g. M1, M2, M3.1.

- (IBAction) selectAllMTracks: (id) sender 
{
    NSInteger count = [protoolsData trackCount];
    
    for (NSInteger idx = 0; idx < count; ++idx) 
    {
        // We limit our search to tracknames that start with an 'M'
        // followed directly by at least one number.
        
        NSString* trackName = [protoolsData trackNameAtIndex:idx];
        NSScanner* scanner = [[NSScanner alloc] initWithString:trackName];
        
        if ([scanner scanString:@"M" intoString:nil] && [scanner scanInteger:nil]) 
        {
            [protoolsData setTrackState:TRUE AtIndex:idx];
        }
    }
    
    [tracksTable reloadData];
    
    // Display output table.
    
    [self generateAndDisplayOutput];
}


// Select all STEREO tracks in tracks checkboxes table.

- (IBAction) selectAllStereoTracks: (id) sender 
{
    NSInteger count = [protoolsData trackCount];
    
    for (NSInteger idx = 0; idx < count; ++idx) 
    {
        // Hunt for "(Stereo" in the trackname.
        // In case AVID ever changes the case of this string,
        // we do a case insensitive search.
        
        NSString* trackName = [protoolsData trackNameAtIndex:idx];
        NSRange range = [[trackName lowercaseString] rangeOfString:@"(stereo)"];
        
        if (range.location != NSNotFound) 
        {
            [protoolsData setTrackState:TRUE AtIndex:idx];
        }
    }
    
    [tracksTable reloadData];

    // Display output table.
    
    [self generateAndDisplayOutput];
}


// Select all tracks in tracks checkboxes table.

- (IBAction) selectAllTracks: (id) sender 
{
    NSInteger count = [protoolsData trackCount];
    
    for (NSInteger idx = 0; idx < count; ++idx) 
    {
        [protoolsData setTrackState:TRUE AtIndex:idx];
    }
    
    [tracksTable reloadData];

    // Display output table.
    
    [self generateAndDisplayOutput];
}


// Handy shortcut button to select the whole session in the miniUniverse again.
// Can also be called with Apple-A shortcut.

- (IBAction)selectWholeSession:(id)sender 
{
    NSInteger sessionStart, sessionStop;
    
    [protoolsData getSessionBoundaries:&sessionStart SessionEnd:&sessionStop];
    
    // Do nothing if no file was loaded or an error occurred or an empty file was loaded.
    
    if (sessionStop <= sessionStart) \
    {
        return;
    }
    
    [startSelectionSlider setIntegerValue: sessionStart];
    [stopSelectionSlider setIntegerValue: sessionStop];
    
    [miniUniverse setSelectionStart:sessionStart];
    [miniUniverse setSelectionStop:sessionStop];
    
    [protoolsData setSelectionStart: sessionStart];
    [protoolsData setSelectionStop: sessionStop];
    
    [tcSetStart setStringValue:[Utility framesToHMSF:sessionStart IncludeFrames:TRUE Framerate:[protoolsData frameRate]]];
    [tcSetStop setStringValue:[Utility framesToHMSF:sessionStop IncludeFrames:TRUE Framerate:[protoolsData frameRate]]];

    // Display output table.
    
    [self generateAndDisplayOutput];
}


// Show some basic file information in a HUD window
// or hide it when it is currently visible.

- (IBAction)showInfo:(id)sender 
{
    if ([infoPanel isVisible]) 
    {
        [infoPanel orderOut:sender];
    }
    else
    {
        // Open HUD window just below the mouse position.
        
        NSPoint mousePos = [NSEvent mouseLocation];
        
        mousePos.x -= 30;
        mousePos.y -= 30;
        
        [infoPanel setFrameTopLeftPoint:mousePos];
        [infoPanel orderFront:sender];
    }
}


// User clicks checkbox in preferences to request to
// suppress frames in output or not.

- (IBAction)suppressFrames:(id)sender 
{
    suppressFramesInOutput = [sender state];

    // Display output table.
    
    [self generateAndDisplayOutput];
}


// User clicked on a column header of the output table.
// We take that as a suggestion to sort the table on that column.

- (void) tableView: (NSTableView*) tableView didClickTableColumn: (NSTableColumn*) tableColumn
{
    if ([[tableColumn identifier] isEqualToString:@"regionName"])
    {
        [protoolsData setSortOnName:TRUE];
        sortOnName = TRUE;
    }
    else if ([[tableColumn identifier] isEqualToString:@"timeUsed"])
    {
        [protoolsData setSortOnName:FALSE];
        sortOnName = FALSE;
    }

    // Display output table.
    
    [self generateAndDisplayOutput];
}


// Get the value for a table cell. Required function for datasource of NSTableView.

- (id) tableView: (NSTableView*) tableView objectValueForTableColumn: (NSTableColumn*) tableColumn row: (int) row
{
    if (tableView == tracksTable) 
    {
        if ([[tableColumn identifier] isEqualToString:@"checkBoxes"]) 
        {
            return [protoolsData trackStateAtIndex:row];
        }
        else
        {
            return [protoolsData trackNameAtIndex:row];
        }
    }
    else
    {
        // As long as there are only two tables, we can skip the "else if"
        // eval. The else case is the output table.

        if ([[tableColumn identifier] isEqualToString:@"regionName"])
        {
            return [protoolsData regionUsageNameAtIndex:row];
        }
        else
        {
            NSInteger frames = [protoolsData regionUsageTimeAtIndex:row];
            return [Utility framesToHMSF:frames IncludeFrames:!suppressFramesInOutput Framerate:[protoolsData frameRate]];
        }
    }
    
    // Default return value that should never happen.
    
    return NULL;
}


// The corresponding method for setting the value. Required function for datasource of NSTableView.

- (void) tableView: (NSTableView*) tableView setObjectValue: (id) anObject forTableColumn: (NSTableColumn*) tableColumn row: (NSInteger) row
{
    if( [[tableColumn identifier] isEqualToString:@"checkBoxes"] ) 
    {
        [protoolsData setTrackState:[anObject boolValue] AtIndex:row];

        // Display output table.
        
        [self generateAndDisplayOutput];
    }
}


// User has entered a timecode to start selection manually. This can be utter garbage
// which we need to pretty profile into a frame offset.

- (IBAction)tcInChanged:(id)sender 
{
    [startSelectionSlider setIntegerValue: [self textToFrames:[sender stringValue]]];
    
    [self changeSelectionStart: sender];
}


// User has entered a timecode to end selection manually. This can be utter garbage
// which we need to pretty profile into a frame offset.

- (IBAction)tcOutChanged:(id)sender 
{
    [stopSelectionSlider setIntegerValue: [self textToFrames:[sender stringValue]]];
    
    [self changeSelectionStop: sender];
}


// When a user types something into the timecode editors, we attempt to guess
// what kind of timecode this was and convert it to frames.

- (NSInteger) textToFrames: (NSString*) text
{
    // Reduce to nothing but numbers and truncate at 8 digits.

    NSInteger digitsCounted = 0;

    NSInteger h = 0;
    NSInteger m = 0;
    NSInteger s = 0;
    NSInteger f = 0;
                        
    NSInteger len = [text length];

    for (NSInteger idx = len - 1; idx >= 0; --idx) 
    {
        char c = [text characterAtIndex:idx];
        NSInteger num = c - '0';
        
        if(isdigit(c))
        {
            ++digitsCounted;
            
            switch (digitsCounted) 
            {
                case 1:
                    f += num;
                    break;
                case 2:
                    f+= (10 * num);
                    break;
                case 3:
                    s += num;
                    break;
                case 4:
                    s += (10 * num);
                    break;
                case 5:
                    m += num;
                    break;
                case 6:
                    m += (10 * num);
                    break;
                case 7:
                    h += num;
                    break;
                case 8:
                    h += (10 * num);
                    break;
            }
        }
    }
    
    // Convert hmsf to frames.
    
    NSInteger frameRate = [protoolsData frameRate];
    
    return f + (frameRate * s) + (frameRate * 60 * m) + (frameRate * 3600 * h);
}


// Update file information in HUD window. This is a floating non modal window,
// so a user can leave it open and open a different Protools file in the main
// window. In such a case, the info window should show the new information.

- (void) updateInfoWindow
{
    // Truncate samplerate.
    
    NSInteger sampleRate = [protoolsData sampleRate];
    NSString* shortFileName = [[protoolsData sessionFileName] lastPathComponent];
    
    [hudLabelFilename setStringValue:shortFileName];
    [hudLabelTrackCount setStringValue:[[NSString alloc] initWithFormat:@"%ld tracks", [protoolsData trackCount]]];
    [hudLabelFrameRate setStringValue:[[NSString alloc] initWithFormat:@"%ld frames per second", [protoolsData frameRate]]];
    [hudLabelSampleRate setStringValue:[[NSString alloc] initWithFormat:@"%ld Hz", sampleRate]];
}


// When a new file has been loaded, a new mini representation of the session needs to be drawn in
// the MiniUniverse view. The sliders above and below the view also need to be updated to represent
// the new session boundaries.

- (void) updateMiniUniverse
{
    NSInteger sessionStart, sessionStop;
    
    [protoolsData getSessionBoundaries:&sessionStart SessionEnd:&sessionStop];
    
    // Redraw the mini universe.
    
    [miniUniverse redrawUniverseWith:[protoolsData getRegions] Tracks:[protoolsData getTracks] SessionStart:sessionStart SessionStop:sessionStop];
    
    // Update the selection sliders.
    
    [startSelectionSlider setMinValue:sessionStart];
    [startSelectionSlider setMaxValue:sessionStop];
    [startSelectionSlider setIntegerValue:sessionStart];
    
    [stopSelectionSlider setMinValue:sessionStart];
    [stopSelectionSlider setMaxValue:sessionStop];
    [stopSelectionSlider setIntegerValue:sessionStop];
    
    // Tell Protools data MODEL object about the new selection.
    
    [protoolsData setSelectionStart:sessionStart];
    [protoolsData setSelectionStop:sessionStop];
}


@end
