//
//  OpenMeta.h
//  OpenMeta File Tagging
//
//  Created by Jordan Kay on 2/7/12.
//

#import <Foundation/Foundation.h>

#define OPENMETA_TAG @"OpenMetaTag"
#define OPENMETA_TAG_TRANSIENT @"OpenMetaTransientTag"
#define OPENMETA_TAG_LIST @"OpenMetaTagList"

typedef void(^ OpenMetaQueryBlock)(MDQueryRef query, CFIndex i);

@interface OpenMetaHandler : NSObject

+ (OpenMetaHandler *)sharedHandler;
- (NSSet *)allTagNames;
- (NSArray *)filesWithTagList:(NSString *)tagList;
- (NSArray *)relatedTagNamesForTagList:(NSString *)tagList;
- (NSArray *)filesAndRelatedTagsForTagList:(NSString *)tagList;
- (NSArray *)tagNamesForFile:(NSString *)filePath;
- (void)addTags:(NSArray *)tags toFile:(NSString *)filePath;
- (void)removeTags:(NSArray *)tags fromFile:(NSString *)filePath;
- (void)setTags:(NSArray *)tags forFile:(NSString *)filePath;
- (NSArray *)tagsFromString:(NSString *)tagList;

@end
