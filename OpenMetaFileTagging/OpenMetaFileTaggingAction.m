//
//  OpenMeta_File_TaggingAction.m
//  OpenMeta File Tagging
//
//  Created by Jordan Kay on 2/5/12.
//

#import "OpenMetaHandler.h"
#import "OpenMetaFileTaggingAction.h"
#import "QSObject+OpenMeta.h"

#define ADD_TAGS_ACTION @"OpenMetaAddTags"
#define REMOVE_TAGS_ACTION @"OpenMetaRemoveTags"
#define SET_TAGS_ACTION @"OpenMetaSetTags"
#define OPENMETA_CATALOG_PRESET @"QSPresetOpenMetaTags"

@implementation OpenMetaFileTaggingAction

- (NSArray *)sharedTagNamesForFiles:(QSObject *)files
{
    NSMutableSet *tagNames = [NSMutableSet set];
    for(QSObject *object in [files splitObjects]) {
        NSSet *nextTags = [NSSet setWithArray:[[OpenMetaHandler sharedHandler] tagNamesForFile:[object objectForType:NSFilenamesPboardType]]];
        if([tagNames count]) {
            [tagNames intersectSet:nextTags];
        } else {
            [tagNames addObjectsFromArray:[nextTags allObjects]];
        }
    }
    return [tagNames allObjects];
}

- (NSArray *)tagsForFiles:(QSObject *)files
{
    NSMutableArray *tags = [NSMutableArray array];
    NSArray *tagNames = [self sharedTagNamesForFiles:files];
    for(NSString *tagName in tagNames) {
        QSObject *tag = [QSObject openMetaTagWithName:tagName];
        [tags addObject:tag];
    }
    return tags;
}

- (QSObject *)showTagsForFiles:(QSObject *)files
{
    NSArray *tags = [self tagsForFiles:files];
    [[QSReg preferredCommandInterface] showArray:[NSMutableArray arrayWithArray:tags]];
    return nil;
}

- (QSObject *)addToFiles:(QSObject *)files tagList:(QSObject *)tagList
{
    NSArray *tagsToAdd = [self tagObjectsFromMixedObject:tagList];
    NSArray *tagNames = [tagsToAdd arrayByPerformingSelector:@selector(objectForType:) withObject:OPENMETA_TAG];
    for(QSObject *file in [files splitObjects]) {
        [[OpenMetaHandler sharedHandler] addTags:tagNames toFile:[file objectForType:NSFilenamesPboardType]];
    }
    [self addCatalogTags:tagList];
    return nil;
}

- (QSObject *)removeFromFiles:(QSObject *)files tags:(QSObject *)tags
{
    NSMutableArray *tagNames = [NSMutableArray array];
    for(QSObject *tag in [tags splitObjects]) {
        [tagNames addObject:[tag objectForType:OPENMETA_TAG]];
    }
    for(QSObject *file in [files splitObjects]) {
        [[OpenMetaHandler sharedHandler] removeTags:tagNames fromFile:[file objectForType:NSFilenamesPboardType]];
    }
    [self updateTagsOnDisk];
    return nil;
}

- (QSObject *)setToFiles:(QSObject *)files tagList:(QSObject *)tagList
{
    NSArray *tagsToSet = [self tagObjectsFromMixedObject:tagList];
    NSArray *tagNames = [tagsToSet arrayByPerformingSelector:@selector(objectForType:) withObject:OPENMETA_TAG];
    OpenMetaHandler *OMHandler = [OpenMetaHandler sharedHandler];
    for(QSObject *file in [files splitObjects]) {
        [OMHandler setTags:tagNames forFile:[file objectForType:NSFilenamesPboardType]];
    }
    [self addCatalogTags:tagList];
    return nil;
}

- (QSObject *)clearTagsFromFiles:(QSObject *)files
{
    [self setToFiles:files tagList:nil];
    [self updateTagsOnDisk];
    return nil;
}

- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)files 
{ 
    if([action isEqualToString:REMOVE_TAGS_ACTION]) {
        // offer to remove tags common to all selected files
        NSMutableArray *tagsInCommon = [NSMutableArray array];
        for (NSString *tagName in [self sharedTagNamesForFiles:files]) {
            QSObject *tag = [QSObject openMetaTagWithName:tagName];
            [tagsInCommon addObject:tag];
        }
        return tagsInCommon;
    } else {
        NSArray *allTags = [QSLib scoredArrayForType:OPENMETA_TAG];
        if (![allTags count]) {
            // no existing tags - text entry mode
            return [NSArray arrayWithObject:[QSObject textProxyObjectWithDefaultValue:@"tag name"]];
        }
        if([action isEqualToString:SET_TAGS_ACTION]) {
            // offer to set any known tag
            return allTags;
        } else if ([action isEqualToString:ADD_TAGS_ACTION]) {
            // offer to add tags not already assigned to the selected files
            NSMutableSet *allTagNames = [NSMutableSet setWithArray:[allTags arrayByPerformingSelector:@selector(objectForType:) withObject:OPENMETA_TAG]];
            NSSet *tagsInCommon = [NSSet setWithArray:[self sharedTagNamesForFiles:files]];
            [allTagNames minusSet:tagsInCommon];
            NSMutableArray *newTags = [NSMutableArray array];
            for (NSString *tagName in allTagNames) {
                QSObject *tag = [QSObject openMetaTagWithName:tagName];
                [newTags addObject:tag];
            }
            return newTags;
        }
    }
    return nil;
} 

- (void)addCatalogTags:(QSObject *)tags
{
    // only rescan the catalog if the action created a new tag
    NSMutableArray *tagNames = [[tags splitObjects] arrayByPerformingSelector:@selector(objectForType:) withObject:OPENMETA_TAG];
    NSArray *allTags = [[QSLib arrayForType:OPENMETA_TAG] mutableCopy];
    NSArray *allTagNames = [allTags arrayByPerformingSelector:@selector(objectForType:) withObject:OPENMETA_TAG];
    [tagNames removeObjectsInArray:allTagNames];
    if ([tagNames count]) {
        // at least one new tag - rescan
        [self updateTagsOnDisk];
    }
}

- (void)updateTagsOnDisk
{
    // wait a few seconds for changes to appear in the filesystem
    sleep(4);
    // rescan the catalog entry
    [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryInvalidated object:OPENMETA_CATALOG_PRESET];
}

- (NSArray *)tagObjectsFromMixedObject:(QSObject *)inputTags
{
    // we could get tags from the catalog, or tags typed by hand
    // so turn them all into tag objects and combine them
    NSMutableSet *tagObjects = [NSMutableSet set];
    for (QSObject *tag in [inputTags splitObjects]) {
        if ([[tag primaryType] isEqualToString:OPENMETA_TAG]) {
            [tagObjects addObject:tag];
        } else {
            // tags typed by hand
            // could be one tag per string, or several in one comma-delimited string
            NSArray *tagNames = [[OpenMetaHandler sharedHandler] tagsFromString:[tag stringValue]];
            for (NSString *tagName in tagNames) {
                QSObject *manualTag = [QSObject openMetaTagWithName:tagName];
                [tagObjects addObject:manualTag];
            }
        }
    }
    return [tagObjects allObjects];
}

@end
