//
//  OpenMetaFileTaggingSource.m
//  OpenMeta File Tagging
//
//  Created by Jordan Kay on 2/5/12.
//

#import "OpenMetaHandler.h"
#import "OpenMetaFileTaggingSource.h"

#define OPENMETA_TAG_ICON [QSResourceManager imageNamed:@"OpenMetaTagIcon"]

@implementation OpenMetaFileTaggingSource

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry
{
    // always rescan to pick up recent changes
    return NO;
}

- (NSArray *)objectsForEntry:(NSDictionary *)entry
{
    NSSet *tagNames = [[OpenMetaHandler sharedHandler] allTagNames];
    NSMutableArray *tags = [NSMutableArray array];
    for(NSString *tagName in tagNames) {
        QSObject *tag = [QSObject objectWithName:tagName];
        [tag setIdentifier:tagName];
        [tag setObject:tagName forType:OPENMETA_TAG];
        [tag setPrimaryType:OPENMETA_TAG];
        [tags addObject:tag];
    }
    return tags;
}

- (BOOL)loadChildrenForObject:(QSObject *)object
{
    NSMutableArray *children = [NSMutableArray array];
    [children addObjectsFromArray:[[OpenMetaHandler sharedHandler] filesAndRelatedTagsForTagList:[object objectForType:OPENMETA_TAG]]];
    [object setChildren:children];
    return YES;
}

- (BOOL)objectHasChildren:(QSObject *)object
{
    return YES;
}

- (NSImage *)iconForEntry:(NSDictionary *)entry
{
    return OPENMETA_TAG_ICON;
}

- (void)setQuickIconForObject:(QSObject *)object
{
    [object setIcon:OPENMETA_TAG_ICON];
}

- (BOOL)loadIconForObject:(QSObject *)object
{
    [self setQuickIconForObject:object];
    return YES;
}

@end
