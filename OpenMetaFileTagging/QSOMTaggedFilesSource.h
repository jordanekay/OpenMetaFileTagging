//
//  QSOMTaggedFilesSource.h
//  OpenMetaFileTagging
//
//  Created by Rob McBroom on 2013/02/18.
//

@interface QSOMTaggedFilesSource : QSObjectSource {
    NSTokenField *tagsTokenField;
}

@property (assign) IBOutlet NSTokenField *tagsTokenField;

@end
