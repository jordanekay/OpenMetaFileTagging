//
//  OpenMeta_File_TaggingAction.m
//  OpenMeta File Tagging
//
//  Created by Jordan Kay on 2/5/12.
//

#import "OpenMetaHandler.h"
#import "OpenMetaFileTaggingAction.h"

#define ADD_TAGS_ACTION @"OpenMetaAddTags"
#define REMOVE_TAGS_ACTION @"OpenMetaRemoveTags"
#define SET_TAGS_ACTION @"OpenMetaSetTags"

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
        QSObject *tag = [QSObject objectWithType:OPENMETA_TAG value:tagName name:tagName];
        [tag setIdentifier:tagName];
        [tags addObject:tag];
    }
    return tags;
}

- (QSObject *)showTagsForFiles:(QSObject *)files
{
    NSArray *tags = [self tagsForFiles:files];
    [[QSReg preferredCommandInterface] showArray:tags];
    return nil;
}

- (QSObject *)addToFiles:(QSObject *)files tagList:(QSObject *)tagList
{
    for(QSObject *file in [files splitObjects]) {
        NSArray *tagNames = [[tagList name] componentsSeparatedByString:@", "];
        [[OpenMetaHandler sharedHandler] addTags:tagNames toFile:[file objectForType:NSFilenamesPboardType]];
    }
    return nil;
}

- (QSObject *)removeFromFiles:(QSObject *)files tags:(QSObject *)tags
{
    NSMutableArray *tagNames = [NSMutableArray array];
    for(QSObject *tag in [tags splitObjects]) {
        [tagNames addObject:[tag name]];
    }
    for(QSObject *file in [files splitObjects]) {
        [[OpenMetaHandler sharedHandler] removeTags:tagNames fromFile:[file objectForType:NSFilenamesPboardType]];
    }
    return nil;
}

- (QSObject *)setToFiles:(QSObject *)files tagList:(QSObject *)tagList
{
    for(QSObject *file in [files splitObjects]) {
        NSArray *tags = [[tagList name] componentsSeparatedByString:@", "];
        [[OpenMetaHandler sharedHandler] setTags:tags forFile:[file objectForType:NSFilenamesPboardType]];
    }
    return nil;
}

- (QSObject *)clearTagsFromFiles:(QSObject *)files
{
    [self setToFiles:files tagList:nil];
    return nil;
}

- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)files 
{ 
    NSArray *indirectObjects;
    if([action isEqualToString:REMOVE_TAGS_ACTION]) {
        indirectObjects = [self tagsForFiles:files];
    } else {
        NSString *currentValue = @"";
        if([action isEqualToString:SET_TAGS_ACTION]) {
            currentValue = [[self sharedTagNamesForFiles:files] componentsJoinedByString:@", "];
        }
        indirectObjects = [NSArray arrayWithObject:[QSObject textProxyObjectWithDefaultValue:currentValue]]; 
    }
    return indirectObjects;
} 

@end
