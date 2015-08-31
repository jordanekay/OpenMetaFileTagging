//
//  QSOMTaggedFilesSource.m
//  OpenMetaFileTagging
//
//  Created by Rob McBroom on 2013/02/18.
//

#import "QSOMTaggedFilesSource.h"
#import "OpenMetaHandler.h"

@implementation QSOMTaggedFilesSource
@synthesize tagsTokenField;

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry
{
    // always rescan
    return NO;
}

- (NSArray *)objectsForEntry:(NSDictionary *)theEntry
{
    NSDictionary *settings = [theEntry objectForKey:kItemSettings];
    NSString *tagList = [[settings objectForKey:@"tags"] componentsJoinedByString:@","];
    return [[OpenMetaHandler sharedHandler] filesWithTagList:tagList];
}

#pragma mark Catalog Entry UI

- (BOOL)isVisibleSource
{
    return YES;
}

- (NSImage *) iconForEntry:(NSDictionary *)theEntry
{
    return OPENMETA_TAG_ICON;
}

- (NSView *)settingsView
{
    if (![super settingsView]) {
        [NSBundle loadNibNamed:NSStringFromClass([self class]) owner:self];
    }
    return [super settingsView];
}

- (void)populateFields
{
    NSMutableDictionary *settings = [[self currentEntry] objectForKey:kItemSettings];
    [tagsTokenField setObjectValue:[settings objectForKey:@"tags"]];
}

#pragma mark Token Field Delegate

- (NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger *)selectedIndex
{
    NSArray *knownTags = [[[OpenMetaHandler sharedHandler] allTagNames] allObjects];
    NSArray *completions = [knownTags filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginswith[cd] %@", substring]];
    return completions;
}

- (void)controlTextDidEndEditing:(NSNotification *)notif
{
    NSMutableDictionary *settings = [[self currentEntry] objectForKey:kItemSettings];
	if (!settings) {
		settings = [NSMutableDictionary dictionaryWithCapacity:1];
		[[self currentEntry] setObject:settings forKey:kItemSettings];
	}
    [settings setObject:[tagsTokenField objectValue] forKey:@"tags"];
	[[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChangedNotification object:[self currentEntry]];
    [[self selection] scanAndCache];
}

@end
