//
//  OpenMetaFileTaggingSource.m
//  OpenMeta File Tagging
//
//  Created by Jordan Kay on 2/5/12.
//

#import "OpenMetaHandler.h"
#import "OpenMetaFileTaggingSource.h"
#import "QSObject+OpenMeta.h"

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
        QSObject *tag = [QSObject openMetaTagWithName:tagName];
        [tags addObject:tag];
    }
    return tags;
}

- (BOOL)loadChildrenForObject:(QSObject *)object
{
    NSMutableArray *children = [NSMutableArray array];
    // check for transient tag when navigating
    NSString *tagListString = [object objectForCache:OPENMETA_TAG_LIST];
    if (!tagListString) {
        // a normal tag from the catalog
        tagListString = [object objectForType:OPENMETA_TAG];
    }
    [children addObjectsFromArray:[[OpenMetaHandler sharedHandler] filesAndRelatedTagsForTagList:tagListString]];
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
