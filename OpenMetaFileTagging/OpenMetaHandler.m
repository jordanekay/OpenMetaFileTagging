//
//  OpenMeta.m
//  OpenMeta File Tagging
//
//  Created by Jordan Kay on 2/7/12.
//

#import "OpenMetaHandler.h"
#import <sys/xattr.h>

NSString *const kOpenmetaFileNameKey = @"name";
NSString *const kOpenmetaTagKeyword = @"kMDItemOMUserTags";
NSString *const kOpenmetaTagXAttrKeyword = @"com.apple.metadata:kMDItemOMUserTags";

@implementation OpenMetaHandler

+ (OpenMetaHandler *)sharedHandler
{
    static dispatch_once_t once;
    static OpenMetaHandler *sharedHandler;
    dispatch_once(&once, ^{ 
        sharedHandler = [[self alloc] init]; 
    });
    return sharedHandler;
}

- (NSSet *)allTagNames
{
    NSString *queryString = [NSString stringWithFormat:@"%@ == *", kOpenmetaTagKeyword];
    NSArray *types = [NSArray arrayWithObject:kOpenmetaTagKeyword];
    
    NSMutableSet *tags = [NSMutableSet set];
    [self _runQuery:queryString forTypes:types usingBlock:[self _addTagNamesBlock:tags]];
    return tags;
}

- (NSArray *)filesWithTagList:(NSString *)tagList
{
    if (!tagList) {
        return nil;
    }
    NSString *queryString = [self _queryStringForTagList:tagList];
    NSArray *types = [NSArray arrayWithObjects:(NSString *)kMDItemPath, (NSString *)kMDItemFSName, nil];
    
    NSMutableSet *files = [NSMutableSet set];
    [self _runQuery:queryString forTypes:types usingBlock:[self _addFileBlock:files]];
    NSSortDescriptor *descriptor = [[[NSSortDescriptor alloc] initWithKey:kOpenmetaFileNameKey ascending:YES] autorelease];
    return [files sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
}

- (NSArray *)relatedTagNamesForTagList:(NSString *)tagList
{
    NSString *queryString = [self _queryStringForTagList:tagList];
    NSArray *types = [NSArray arrayWithObject:kOpenmetaTagKeyword];
    
    NSMutableSet *relatedTagNames = [NSMutableSet set];
    [self _runQuery:queryString forTypes:types usingBlock:[self _addTagNamesBlock:relatedTagNames]];
    return [relatedTagNames allObjects];
}

- (NSArray *)filesAndRelatedTagsForTagList:(NSString *)tagList
{
    if (!tagList) {
        return nil;
    }
    NSMutableArray *objects = [NSMutableArray arrayWithArray:[self filesWithTagList:tagList]];
    NSMutableArray *relatedTags = [NSMutableArray array];
    
    NSArray *tagNames = [self tagsFromString:tagList];
    NSArray *relatedTagNames = [self relatedTagNamesForTagList:tagList];
    for(NSString *tagName in relatedTagNames) {
        if(![tagNames containsObject:tagName]) {
            NSString *tagListString = [tagList stringByAppendingFormat:@", %@", tagName];
            QSObject *tag = [QSObject objectWithName:tagName];
            [tag setObject:tagName forType:OPENMETA_TAG];
            [tag setDetails:tagListString];
            [tag setObject:tagListString forCache:OPENMETA_TAG_LIST];
            [tag setIdentifier:[NSString stringWithFormat:@"%@:%@", OPENMETA_TAG_TRANSIENT, tagName]];
            [tag setPrimaryType:OPENMETA_TAG];
            [relatedTags addObject:tag];
        }
    }
    
    NSSortDescriptor *descriptor = [[[NSSortDescriptor alloc] initWithKey:kOpenmetaFileNameKey ascending:YES] autorelease];
    [objects addObjectsFromArray:[relatedTags sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]]];
    return objects;
}

- (NSArray *)tagNamesForFile:(NSString *)filePath
{
    NSArray *tagNames = [self _valueForKey:kOpenmetaTagXAttrKeyword atPath:filePath];
    return tagNames;
}

- (void)addTags:(NSArray *)tags toFile:(NSString *)filePath
{
    NSMutableArray *allTags = [NSMutableArray arrayWithArray:[self tagNamesForFile:filePath]];
    [allTags addObjectsFromArray:tags];
    [self setTags:allTags forFile:filePath];
}

- (void)removeTags:(NSArray *)tags fromFile:(NSString *)filePath
{
    NSMutableArray *allTags = [NSMutableArray arrayWithArray:[self tagNamesForFile:filePath]];
    [allTags removeObjectsInArray:tags];
    [self setTags:allTags forFile:filePath];
}

- (void)setTags:(NSArray *)tags forFile:(NSString *)filePath
{
    [self _setValue:tags forKey:kOpenmetaTagXAttrKeyword atPath:filePath];
}

- (NSArray *)tagsFromString:(NSString *)tagList
{
    // get tags separated by ','
    NSArray *rawTags = [tagList componentsSeparatedByString:@","];
    // return tags without leading and trailing whitespace
    return [rawTags arrayByPerformingSelector:@selector(stringByTrimmingCharactersInSet:) withObject:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

#pragma mark MDQuery

- (NSString *)_queryStringForTagList:(NSString *)tagList
{
    NSArray *tagNames = [self tagsFromString:tagList];
    NSMutableArray *clauses = [NSMutableArray array];
    for(NSString *tagName in tagNames) {
        [clauses addObject:[NSString stringWithFormat:@"%@ == '%@'", kOpenmetaTagKeyword, tagName]];
    }
    return [clauses componentsJoinedByString:@" && "];
}

- (void)_runQuery:(NSString *)queryString forTypes:(NSArray *)types usingBlock:(OpenMetaQueryBlock)block
{
    MDQueryRef query = MDQueryCreate(NULL, (CFStringRef)queryString, (CFArrayRef)types, NULL);
    BOOL queryRan = MDQueryExecute(query, kMDQuerySynchronous);
    if(queryRan) {
        CFIndex count = MDQueryGetResultCount(query);
        for(CFIndex i = 0; i < count; i++) {
            if(block) {
                block(query, i);                
            }
        }
    }
    CFRelease(query);
}

- (OpenMetaQueryBlock)_addTagNamesBlock:(NSMutableSet *)tags
{
    return [[^(MDQueryRef query, CFIndex i) {
        CFArrayRef tagNames = MDQueryGetAttributeValueOfResultAtIndex(query, (CFStringRef)kOpenmetaTagKeyword, i);
        if(tagNames != NULL) {
            for(NSString *tagName in (NSArray *)tagNames) {
                [tags addObject:tagName];
            }
        }
    } copy] autorelease];
}

- (OpenMetaQueryBlock)_addFileBlock:(NSMutableSet *)files
{
    return [[^(MDQueryRef query, CFIndex i) {
        MDItemRef item = (MDItemRef)MDQueryGetResultAtIndex(query, i);
        NSString *name = (NSString*)MDItemCopyAttribute(item, kMDItemFSName);
        NSString *path = (NSString*)MDItemCopyAttribute(item, kMDItemPath);
        QSObject *file = [QSObject objectWithType:NSFilenamesPboardType value:path name:name];
        [files addObject:file];
    } copy] autorelease];
}

#pragma mark xattr

- (id)_valueForKey:(NSString *)key atPath:(NSString *)path
{
    NSString *value = nil;
    size_t dataSize = getxattr([path fileSystemRepresentation], [key UTF8String], NULL, ULONG_MAX, 0, 0);
    if(dataSize < ULONG_MAX) {
        NSMutableData *data = [NSMutableData dataWithLength:dataSize];
        getxattr([path fileSystemRepresentation], [key UTF8String], [data mutableBytes], [data length], 0, 0);
        NSPropertyListFormat outFormat = NSPropertyListXMLFormat_v1_0;
        value = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:&outFormat errorDescription:nil];
    }
    return value;
}

- (void)_setValue:(id)value forKey:(NSString *)key atPath:(NSString* )path
{
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:value format:NSPropertyListXMLFormat_v1_0 errorDescription:nil];
    setxattr([path fileSystemRepresentation], [key UTF8String], [data bytes], [data length], 0, 0);
}

@end
