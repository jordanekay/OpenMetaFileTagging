//
//  QSObject+OpenMeta.m
//  OpenMetaFileTagging
//
//  Created by Rob McBroom on 2013/02/13.
//

#import "QSObject+OpenMeta.h"
#import "OpenMetaHandler.h"

@implementation QSObject (OpenMeta)

+ (QSObject *)openMetaTagWithName:(NSString *)tagName
{
    NSString *tagID = [NSString stringWithFormat:@"%@:%@", OPENMETA_TAG, tagName];
    // try to get an existing tag from the catalog
    QSObject *tag = [self objectWithIdentifier:tagID];
    if (!tag) {
        // create a new tag object from scratch
        tag = [self objectWithName:tagName];
        [tag setIdentifier:tagID];
        [tag setObject:tagName forType:OPENMETA_TAG];
        [tag setPrimaryType:OPENMETA_TAG];
    }
    return tag;
}

@end
