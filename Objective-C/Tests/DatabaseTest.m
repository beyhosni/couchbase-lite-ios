//
//  DatabaseTest.m
//  CouchbaseLite
//
//  Created by Pasin Suriyentrakorn on 1/10/17.
//  Copyright © 2017 Couchbase. All rights reserved.
//

#import "CBLTestCase.h"
#import "CBLInternal.h"


@interface DatabaseTest : CBLTestCase

@end

@implementation DatabaseTest


- (void) testCreate {
    NSError* error;
    NSString* dir = [NSTemporaryDirectory() stringByAppendingPathComponent: @"CouchbaseLite"];
    [CBLDatabase deleteDatabase: @"db" inDirectory: dir error: nil];
    
    CBLDatabaseOptions* options = [CBLDatabaseOptions defaultOptions];
    options.directory = dir;
    CBLDatabase* db = [[CBLDatabase alloc] initWithName: @"db" options: options error: &error];
    AssertNotNil(db, @"Couldn't open db: %@", error);
    Assert([db.path.lastPathComponent hasSuffix: @".cblite2"]);
    AssertEqualObjects(db.name, @"db");

    Assert([db close: &error], @"Couldn't close db: %@", error);
    AssertNil(db.path);
    Assert([CBLDatabase deleteDatabase: @"db" inDirectory: dir error: &error],
           @"Couldn't delete closed database: %@", error);
}


- (void) testDelete {
    Assert(self.db.path);
    Assert([[NSFileManager defaultManager] fileExistsAtPath: self.db.path]);
    
    NSError* error;
    NSString* path = self.db.path;
    Assert([self.db deleteDatabase: &error], @"Couldn't delete db: %@", error);
    AssertNil(self.db.path);
    AssertFalse([[NSFileManager defaultManager] fileExistsAtPath: path]);
}


- (void) testCreateDocument {
    CBLDocument* doc = [self.db document];
    AssertNotNil(doc);
    AssertNotNil(doc.documentID);
    Assert(doc.documentID.length > 0);
    AssertEqual(doc.database, self.db);
    AssertFalse(doc.exists);
    AssertFalse(doc.isDeleted);
    AssertNil(doc.properties);
    
    CBLDocument* doc1 = [self.db documentWithID: @"doc1"];
    AssertNotNil(doc1);
    AssertEqualObjects(doc1.documentID, @"doc1");
    AssertEqual(doc1.database, self.db);
    AssertFalse(doc1.exists);
    AssertFalse(doc1.isDeleted);
    AssertNil(doc1.properties);
}


- (void) testDocumentExists {
    AssertFalse([self.db documentExists: @"doc1"]);
    
    NSError* error;
    CBLDocument* doc1 = [self.db documentWithID: @"doc1"];
    Assert([doc1 save: &error], @"Error saving: %@", error);
    Assert([self.db documentExists: @"doc1"]);
    AssertNil(doc1.properties);
}


- (void) testInBatchSuccess {
    NSError* error;
    BOOL success = [self.db inBatch: &error do: ^{
        for (int i = 0; i < 10; i++) {
            NSString* docId = [NSString stringWithFormat:@"doc%d", i];
            CBLDocument* doc = [self.db documentWithID: docId];
            [doc save: nil];
        }
    }];
    Assert(success, @"Error in batch: %@", error);
    for (int i = 0; i < 10; i++) {
        NSString* docId = [NSString stringWithFormat:@"doc%d", i];
        Assert([self.db documentExists: docId]);
    }
}


@end
