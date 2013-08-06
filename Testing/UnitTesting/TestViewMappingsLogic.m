#import "TestViewMappingsLogic.h"
#import "YapDatabaseViewChangePrivate.h"
#import "YapDatabaseViewMappingsPrivate.h"


@implementation TestViewMappingsLogic

static NSMutableArray *changes;
static YapDatabaseViewMappings *mappings;
static YapDatabaseViewMappings *originalMappings;

static YapDatabaseViewSectionChange* (^SectionOp)(NSArray*, NSUInteger) = ^(NSArray *sChanges, NSUInteger index){
	
	return (YapDatabaseViewSectionChange *)[sChanges objectAtIndex:index];
};

static YapDatabaseViewRowChange* (^RowOp)(NSArray*, NSUInteger) = ^(NSArray *rChanges, NSUInteger index){
	
	return (YapDatabaseViewRowChange *)[rChanges objectAtIndex:index];
};

+ (void)initialize
{
	static BOOL initialized = NO;
	if (!initialized)
	{
		initialized = YES;
		changes = [NSMutableArray array];
		mappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[@""] view:@"view"];
	}
}

- (void)tearDown
{
	[changes removeAllObjects];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Hard Range: Insert
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test1A
{
	YapDatabaseViewRangeOptions *rangeOpts =
	    [YapDatabaseViewRangeOptions fixedRangeWithLength:20 offset:0 from:YapDatabaseViewBeginning];
	
	[mappings updateWithCounts:@{ @"":@(40) }];
	[mappings setRangeOptions:rangeOpts forGroup:@""];
	originalMappings = [mappings copy];
	
	// Insert item in the middle of the range
	
	[changes addObject:[YapDatabaseViewRowChange insertKey:@"key" inGroup:@"" atIndex:2]];
	
	[mappings updateWithCounts:@{ @"":@(41) }];
	
	// Fetch changeset
	
	NSArray *rowChanges = nil;
	
	[YapDatabaseViewChange getSectionChanges:NULL
	                              rowChanges:&rowChanges
	                    withOriginalMappings:originalMappings
	                           finalMappings:mappings
	                             fromChanges:changes];
	
	// Verify
	
	STAssertTrue(RowOp(rowChanges, 0).type == YapDatabaseViewChangeInsert, @"");
	STAssertTrue(RowOp(rowChanges, 0).finalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 0).finalIndex == 2, @"");
	
	STAssertTrue(RowOp(rowChanges, 1).type == YapDatabaseViewChangeDelete, @"");
	STAssertTrue(RowOp(rowChanges, 1).originalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 1).originalIndex == 19, @"");
}

- (void)test1B
{
	YapDatabaseViewRangeOptions *rangeOpts =
	    [YapDatabaseViewRangeOptions fixedRangeWithLength:20 offset:0 from:YapDatabaseViewBeginning];
	
	[mappings updateWithCounts:@{ @"":@(40) }];
	[mappings setRangeOptions:rangeOpts forGroup:@""];
	originalMappings = [mappings copy];

	// Insert item at the beginning of the range
	
	[changes addObject:[YapDatabaseViewRowChange insertKey:@"key" inGroup:@"" atIndex:0]];
	
	[mappings updateWithCounts:@{ @"":@(41) }];
	
	// Fetch changeset
	
	NSArray *rowChanges = nil;
	
	[YapDatabaseViewChange getSectionChanges:NULL
	                              rowChanges:&rowChanges
	                    withOriginalMappings:originalMappings
	                           finalMappings:mappings
	                             fromChanges:changes];
	
	// Verify
	
	STAssertTrue(RowOp(rowChanges, 0).type == YapDatabaseViewChangeInsert, @"");
	STAssertTrue(RowOp(rowChanges, 0).finalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 0).finalIndex == 0, @"");
	
	STAssertTrue(RowOp(rowChanges, 1).type == YapDatabaseViewChangeDelete, @"");
	STAssertTrue(RowOp(rowChanges, 1).originalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 1).originalIndex == 19, @"");
}

- (void)test1C
{
	YapDatabaseViewRangeOptions *rangeOpts =
	    [YapDatabaseViewRangeOptions fixedRangeWithLength:20 offset:0 from:YapDatabaseViewBeginning];
	
	[mappings updateWithCounts:@{ @"":@(40) }];
	[mappings setRangeOptions:rangeOpts forGroup:@""];
	originalMappings = [mappings copy];
	
	// Insert item at the end of the range
	
	[changes addObject:[YapDatabaseViewRowChange insertKey:@"key" inGroup:@"" atIndex:19]];
	
	[mappings updateWithCounts:@{ @"":@(41) }];
	
	// Fetch changeset
	
	NSArray *rowChanges = nil;
	
	[YapDatabaseViewChange getSectionChanges:NULL
	                              rowChanges:&rowChanges
	                    withOriginalMappings:originalMappings
	                           finalMappings:mappings
	                             fromChanges:changes];
	
	// Verify
	
	STAssertTrue(RowOp(rowChanges, 0).type == YapDatabaseViewChangeInsert, @"");
	STAssertTrue(RowOp(rowChanges, 0).finalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 0).finalIndex == 19, @"");
	
	STAssertTrue(RowOp(rowChanges, 1).type == YapDatabaseViewChangeDelete, @"");
	STAssertTrue(RowOp(rowChanges, 1).originalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 1).originalIndex == 19, @"");
}

- (void)test1D
{
	YapDatabaseViewRangeOptions *rangeOpts =
	    [YapDatabaseViewRangeOptions fixedRangeWithLength:20 offset:0 from:YapDatabaseViewBeginning];
	
	[mappings updateWithCounts:@{ @"":@(40) }];
	[mappings setRangeOptions:rangeOpts forGroup:@""];
	originalMappings = [mappings copy];
	
	// Insert item outside the range
	
	[changes addObject:[YapDatabaseViewRowChange insertKey:@"key" inGroup:@"" atIndex:20]];
	
	[mappings updateWithCounts:@{ @"":@(41) }];
	
	// Fetch changeset
	
	NSArray *rowChanges = nil;
	
	[YapDatabaseViewChange getSectionChanges:NULL
	                              rowChanges:&rowChanges
	                    withOriginalMappings:originalMappings
	                           finalMappings:mappings
	                             fromChanges:changes];
	
	// Verify
	
	STAssertTrue([rowChanges count] == 0, @"");
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Hard Range: Delete
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test2A
{
	YapDatabaseViewRangeOptions *rangeOpts =
	    [YapDatabaseViewRangeOptions fixedRangeWithLength:20 offset:0 from:YapDatabaseViewBeginning];
	
	[mappings updateWithCounts:@{ @"":@(40) }];
	[mappings setRangeOptions:rangeOpts forGroup:@""];
	originalMappings = [mappings copy];
	
	// Delete item in the middle of the range
	
	[changes addObject:[YapDatabaseViewRowChange deleteKey:@"key" inGroup:@"" atIndex:2]];
	
	[mappings updateWithCounts:@{ @"":@(39) }];
	
	// Fetch changeset
	
	NSArray *rowChanges = nil;
	
	[YapDatabaseViewChange getSectionChanges:NULL
	                              rowChanges:&rowChanges
	                    withOriginalMappings:originalMappings
	                           finalMappings:mappings
	                             fromChanges:changes];
	
	// Verify
	
	STAssertTrue(RowOp(rowChanges, 0).type == YapDatabaseViewChangeDelete, @"");
	STAssertTrue(RowOp(rowChanges, 0).originalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 0).originalIndex == 2, @"");
	
	STAssertTrue(RowOp(rowChanges, 1).type == YapDatabaseViewChangeInsert, @"");
	STAssertTrue(RowOp(rowChanges, 1).finalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 1).finalIndex == 19, @"");
}

- (void)test2B
{
	YapDatabaseViewRangeOptions *rangeOpts =
	    [YapDatabaseViewRangeOptions fixedRangeWithLength:20 offset:0 from:YapDatabaseViewBeginning];
	
	[mappings updateWithCounts:@{ @"":@(40) }];
	[mappings setRangeOptions:rangeOpts forGroup:@""];
	originalMappings = [mappings copy];
	
	// Delete item in the beginning of the range
	
	[changes addObject:[YapDatabaseViewRowChange deleteKey:@"key" inGroup:@"" atIndex:0]];
	
	[mappings updateWithCounts:@{ @"":@(39) }];
	
	// Fetch changeset
	
	NSArray *rowChanges = nil;
	
	[YapDatabaseViewChange getSectionChanges:NULL
	                              rowChanges:&rowChanges
	                    withOriginalMappings:originalMappings
	                           finalMappings:mappings
	                             fromChanges:changes];
	
	// Verify
	
	STAssertTrue(RowOp(rowChanges, 0).type == YapDatabaseViewChangeDelete, @"");
	STAssertTrue(RowOp(rowChanges, 0).originalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 0).originalIndex == 0, @"");
	
	STAssertTrue(RowOp(rowChanges, 1).type == YapDatabaseViewChangeInsert, @"");
	STAssertTrue(RowOp(rowChanges, 1).finalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 1).finalIndex == 19, @"");
}

- (void)test2C
{
	YapDatabaseViewRangeOptions *rangeOpts =
	    [YapDatabaseViewRangeOptions fixedRangeWithLength:20 offset:0 from:YapDatabaseViewBeginning];
	
	[mappings updateWithCounts:@{ @"":@(40) }];
	[mappings setRangeOptions:rangeOpts forGroup:@""];
	originalMappings = [mappings copy];
	
	// Delete item at the end of the range
	
	[changes addObject:[YapDatabaseViewRowChange deleteKey:@"key" inGroup:@"" atIndex:19]];
	
	[mappings updateWithCounts:@{ @"":@(39) }];
	
	// Fetch changeset
	
	NSArray *rowChanges = nil;
	
	[YapDatabaseViewChange getSectionChanges:NULL
	                              rowChanges:&rowChanges
	                    withOriginalMappings:originalMappings
	                           finalMappings:mappings
	                             fromChanges:changes];
	
	// Verify
	
	STAssertTrue(RowOp(rowChanges, 0).type == YapDatabaseViewChangeDelete, @"");
	STAssertTrue(RowOp(rowChanges, 0).originalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 0).originalIndex == 19, @"");
	
	STAssertTrue(RowOp(rowChanges, 1).type == YapDatabaseViewChangeInsert, @"");
	STAssertTrue(RowOp(rowChanges, 1).finalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 1).finalIndex == 19, @"");
}

- (void)test2D
{
	YapDatabaseViewRangeOptions *rangeOpts =
	    [YapDatabaseViewRangeOptions fixedRangeWithLength:20 offset:0 from:YapDatabaseViewBeginning];
	
	[mappings updateWithCounts:@{ @"":@(40) }];
	[mappings setRangeOptions:rangeOpts forGroup:@""];
	originalMappings = [mappings copy];
	
	// Delete item outside the range
	
	[changes addObject:[YapDatabaseViewRowChange deleteKey:@"key" inGroup:@"" atIndex:20]];
	
	[mappings updateWithCounts:@{ @"":@(39) }];
	
	// Fetch changeset
	
	NSArray *rowChanges = nil;
	
	[YapDatabaseViewChange getSectionChanges:NULL
	                              rowChanges:&rowChanges
	                    withOriginalMappings:originalMappings
	                           finalMappings:mappings
	                             fromChanges:changes];
	
	// Verify
	
	STAssertTrue([rowChanges count] == 0, @"");
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Hard Range: Insert, Insert, ...
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test3A
{
	YapDatabaseViewRangeOptions *rangeOpts =
	    [YapDatabaseViewRangeOptions fixedRangeWithLength:20 offset:0 from:YapDatabaseViewBeginning];
	
	[mappings updateWithCounts:@{ @"":@(40) }];
	[mappings setRangeOptions:rangeOpts forGroup:@""];
	originalMappings = [mappings copy];
	
	// Insert multiple items inside the range
	
	[changes addObject:[YapDatabaseViewRowChange insertKey:@"key1" inGroup:@"" atIndex:10]];
	[changes addObject:[YapDatabaseViewRowChange insertKey:@"key2" inGroup:@"" atIndex:10]];
	
	[mappings updateWithCounts:@{ @"":@(42) }];
	
	// Fetch changeset
	
	NSArray *rowChanges = nil;
	
	[YapDatabaseViewChange getSectionChanges:NULL
	                              rowChanges:&rowChanges
	                    withOriginalMappings:originalMappings
	                           finalMappings:mappings
	                             fromChanges:changes];
	
	// Verify
	
	STAssertTrue(RowOp(rowChanges, 0).type == YapDatabaseViewChangeInsert, @"");
	STAssertTrue(RowOp(rowChanges, 0).finalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 0).finalIndex == 11, @"");
	
	STAssertTrue(RowOp(rowChanges, 1).type == YapDatabaseViewChangeInsert, @"");
	STAssertTrue(RowOp(rowChanges, 1).finalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 1).finalIndex == 10, @"");
	
	STAssertTrue(RowOp(rowChanges, 2).type == YapDatabaseViewChangeDelete, @"");
	STAssertTrue(RowOp(rowChanges, 2).originalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 2).originalIndex == 19, @"");
	
	STAssertTrue(RowOp(rowChanges, 3).type == YapDatabaseViewChangeDelete, @"");
	STAssertTrue(RowOp(rowChanges, 3).originalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 3).originalIndex == 18, @"");
}

- (void)test3B
{
	YapDatabaseViewRangeOptions *rangeOpts =
	    [YapDatabaseViewRangeOptions fixedRangeWithLength:20 offset:0 from:YapDatabaseViewBeginning];
	
	[mappings updateWithCounts:@{ @"":@(40) }];
	[mappings setRangeOptions:rangeOpts forGroup:@""];
	originalMappings = [mappings copy];
	
	// Insert multiple items at the beginning of the range
	
	[changes addObject:[YapDatabaseViewRowChange insertKey:@"key1" inGroup:@"" atIndex:0]];
	[changes addObject:[YapDatabaseViewRowChange insertKey:@"key2" inGroup:@"" atIndex:0]];
	
	[mappings updateWithCounts:@{ @"":@(42) }];
	
	// Fetch changeset
	
	NSArray *rowChanges = nil;
	
	[YapDatabaseViewChange getSectionChanges:NULL
	                              rowChanges:&rowChanges
	                    withOriginalMappings:originalMappings
	                           finalMappings:mappings
	                             fromChanges:changes];
	
	// Verify
	
	STAssertTrue(RowOp(rowChanges, 0).type == YapDatabaseViewChangeInsert, @"");
	STAssertTrue(RowOp(rowChanges, 0).finalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 0).finalIndex == 1, @"");
	
	STAssertTrue(RowOp(rowChanges, 1).type == YapDatabaseViewChangeInsert, @"");
	STAssertTrue(RowOp(rowChanges, 1).finalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 1).finalIndex == 0, @"");
	
	STAssertTrue(RowOp(rowChanges, 2).type == YapDatabaseViewChangeDelete, @"");
	STAssertTrue(RowOp(rowChanges, 2).originalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 2).originalIndex == 19, @"");
	
	STAssertTrue(RowOp(rowChanges, 3).type == YapDatabaseViewChangeDelete, @"");
	STAssertTrue(RowOp(rowChanges, 3).originalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 3).originalIndex == 18, @"");
}

- (void)test3C
{
	YapDatabaseViewRangeOptions *rangeOpts =
	    [YapDatabaseViewRangeOptions fixedRangeWithLength:20 offset:0 from:YapDatabaseViewBeginning];
	
	[mappings updateWithCounts:@{ @"":@(40) }];
	[mappings setRangeOptions:rangeOpts forGroup:@""];
	originalMappings = [mappings copy];
	
	// Insert multiple items at the end of the range
	
	[changes addObject:[YapDatabaseViewRowChange insertKey:@"key1" inGroup:@"" atIndex:18]];
	[changes addObject:[YapDatabaseViewRowChange insertKey:@"key2" inGroup:@"" atIndex:18]];
	
	[mappings updateWithCounts:@{ @"":@(42) }];
	
	// Fetch changeset
	
	NSArray *rowChanges = nil;
	
	[YapDatabaseViewChange getSectionChanges:NULL
	                              rowChanges:&rowChanges
	                    withOriginalMappings:originalMappings
	                           finalMappings:mappings
	                             fromChanges:changes];
	
	// Verify
	
	STAssertTrue(RowOp(rowChanges, 0).type == YapDatabaseViewChangeInsert, @"");
	STAssertTrue(RowOp(rowChanges, 0).finalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 0).finalIndex == 19, @"");
	
	STAssertTrue(RowOp(rowChanges, 1).type == YapDatabaseViewChangeInsert, @"");
	STAssertTrue(RowOp(rowChanges, 1).finalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 1).finalIndex == 18, @"");
	
	STAssertTrue(RowOp(rowChanges, 2).type == YapDatabaseViewChangeDelete, @"");
	STAssertTrue(RowOp(rowChanges, 2).originalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 2).originalIndex == 19, @"");
	
	STAssertTrue(RowOp(rowChanges, 3).type == YapDatabaseViewChangeDelete, @"");
	STAssertTrue(RowOp(rowChanges, 3).originalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 3).originalIndex == 18, @"");
}

- (void)test3D
{
	YapDatabaseViewRangeOptions *rangeOpts =
	    [YapDatabaseViewRangeOptions fixedRangeWithLength:20 offset:0 from:YapDatabaseViewBeginning];
	
	[mappings updateWithCounts:@{ @"":@(40) }];
	[mappings setRangeOptions:rangeOpts forGroup:@""];
	originalMappings = [mappings copy];
	
	// Insert multiple items at the end of the range, some of them end out outside the range
	
	[changes addObject:[YapDatabaseViewRowChange insertKey:@"key1" inGroup:@"" atIndex:18]];
	[changes addObject:[YapDatabaseViewRowChange insertKey:@"key2" inGroup:@"" atIndex:18]];
	[changes addObject:[YapDatabaseViewRowChange insertKey:@"key3" inGroup:@"" atIndex:18]];
	[changes addObject:[YapDatabaseViewRowChange insertKey:@"key4" inGroup:@"" atIndex:18]];
	
	[mappings updateWithCounts:@{ @"":@(44) }];
	
	// Fetch changeset
	
	NSArray *rowChanges = nil;
	
	[YapDatabaseViewChange getSectionChanges:NULL
	                              rowChanges:&rowChanges
	                    withOriginalMappings:originalMappings
	                           finalMappings:mappings
	                             fromChanges:changes];
	
	// Verify
	
	STAssertTrue(RowOp(rowChanges, 0).type == YapDatabaseViewChangeInsert, @"");
	STAssertTrue(RowOp(rowChanges, 0).finalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 0).finalIndex == 19, @"");
	
	STAssertTrue(RowOp(rowChanges, 1).type == YapDatabaseViewChangeInsert, @"");
	STAssertTrue(RowOp(rowChanges, 1).finalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 1).finalIndex == 18, @"");
	
	STAssertTrue(RowOp(rowChanges, 2).type == YapDatabaseViewChangeDelete, @"");
	STAssertTrue(RowOp(rowChanges, 2).originalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 2).originalIndex == 19, @"");
	
	STAssertTrue(RowOp(rowChanges, 3).type == YapDatabaseViewChangeDelete, @"");
	STAssertTrue(RowOp(rowChanges, 3).originalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 3).originalIndex == 18, @"");
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Hard Range: Delete, Delete, ...
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)test4A
{
	YapDatabaseViewRangeOptions *rangeOpts =
	    [YapDatabaseViewRangeOptions fixedRangeWithLength:20 offset:0 from:YapDatabaseViewBeginning];
	
	[mappings updateWithCounts:@{ @"":@(40) }];
	[mappings setRangeOptions:rangeOpts forGroup:@""];
	originalMappings = [mappings copy];
	
	// Delete multiple items inside the range
	
	[changes addObject:[YapDatabaseViewRowChange deleteKey:@"key1" inGroup:@"" atIndex:10]];
	[changes addObject:[YapDatabaseViewRowChange deleteKey:@"key2" inGroup:@"" atIndex:10]];
	
	[mappings updateWithCounts:@{ @"":@(38) }];
	
	// Fetch changeset
	
	NSArray *rowChanges = nil;
	
	[YapDatabaseViewChange getSectionChanges:NULL
	                              rowChanges:&rowChanges
	                    withOriginalMappings:originalMappings
	                           finalMappings:mappings
	                             fromChanges:changes];
	
	// Verify
	
	STAssertTrue(RowOp(rowChanges, 0).type == YapDatabaseViewChangeDelete, @"");
	STAssertTrue(RowOp(rowChanges, 0).originalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 0).originalIndex == 10, @"");
	
	STAssertTrue(RowOp(rowChanges, 1).type == YapDatabaseViewChangeDelete, @"");
	STAssertTrue(RowOp(rowChanges, 1).originalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 1).originalIndex == 11, @"");
	
	STAssertTrue(RowOp(rowChanges, 2).type == YapDatabaseViewChangeInsert, @"");
	STAssertTrue(RowOp(rowChanges, 2).finalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 2).finalIndex == 19, @"");
	
	STAssertTrue(RowOp(rowChanges, 3).type == YapDatabaseViewChangeInsert, @"");
	STAssertTrue(RowOp(rowChanges, 3).finalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 3).finalIndex == 18, @"");
}

- (void)test4B
{
	YapDatabaseViewRangeOptions *rangeOpts =
	    [YapDatabaseViewRangeOptions fixedRangeWithLength:20 offset:0 from:YapDatabaseViewBeginning];
	
	[mappings updateWithCounts:@{ @"":@(40) }];
	[mappings setRangeOptions:rangeOpts forGroup:@""];
	originalMappings = [mappings copy];
	
	// Delete multiple items at the beginning of the range
	
	[changes addObject:[YapDatabaseViewRowChange deleteKey:@"key1" inGroup:@"" atIndex:0]];
	[changes addObject:[YapDatabaseViewRowChange deleteKey:@"key2" inGroup:@"" atIndex:0]];
	
	[mappings updateWithCounts:@{ @"":@(38) }];
	
	// Fetch changeset
	
	NSArray *rowChanges = nil;
	
	[YapDatabaseViewChange getSectionChanges:NULL
	                              rowChanges:&rowChanges
	                    withOriginalMappings:originalMappings
	                           finalMappings:mappings
	                             fromChanges:changes];
	
	// Verify
	
	STAssertTrue(RowOp(rowChanges, 0).type == YapDatabaseViewChangeDelete, @"");
	STAssertTrue(RowOp(rowChanges, 0).originalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 0).originalIndex == 0, @"");
	
	STAssertTrue(RowOp(rowChanges, 1).type == YapDatabaseViewChangeDelete, @"");
	STAssertTrue(RowOp(rowChanges, 1).originalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 1).originalIndex == 1, @"");
	
	STAssertTrue(RowOp(rowChanges, 2).type == YapDatabaseViewChangeInsert, @"");
	STAssertTrue(RowOp(rowChanges, 2).finalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 2).finalIndex == 19, @"");
	
	STAssertTrue(RowOp(rowChanges, 3).type == YapDatabaseViewChangeInsert, @"");
	STAssertTrue(RowOp(rowChanges, 3).finalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 3).finalIndex == 18, @"");
}

- (void)test4C
{
	YapDatabaseViewRangeOptions *rangeOpts =
	    [YapDatabaseViewRangeOptions fixedRangeWithLength:20 offset:0 from:YapDatabaseViewBeginning];
	
	[mappings updateWithCounts:@{ @"":@(40) }];
	[mappings setRangeOptions:rangeOpts forGroup:@""];
	originalMappings = [mappings copy];
	
	// Delete multiple items at the end of the range
	
	[changes addObject:[YapDatabaseViewRowChange deleteKey:@"key1" inGroup:@"" atIndex:19]];
	[changes addObject:[YapDatabaseViewRowChange deleteKey:@"key2" inGroup:@"" atIndex:18]];
	
	[mappings updateWithCounts:@{ @"":@(38) }];
	
	// Fetch changeset
	
	NSArray *rowChanges = nil;
	
	[YapDatabaseViewChange getSectionChanges:NULL
	                              rowChanges:&rowChanges
	                    withOriginalMappings:originalMappings
	                           finalMappings:mappings
	                             fromChanges:changes];
	
	// Verify
	
	STAssertTrue(RowOp(rowChanges, 0).type == YapDatabaseViewChangeDelete, @"");
	STAssertTrue(RowOp(rowChanges, 0).originalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 0).originalIndex == 19, @"");
	
	STAssertTrue(RowOp(rowChanges, 1).type == YapDatabaseViewChangeDelete, @"");
	STAssertTrue(RowOp(rowChanges, 1).originalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 1).originalIndex == 18, @"");
	
	STAssertTrue(RowOp(rowChanges, 2).type == YapDatabaseViewChangeInsert, @"");
	STAssertTrue(RowOp(rowChanges, 2).finalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 2).finalIndex == 19, @"");
	
	STAssertTrue(RowOp(rowChanges, 3).type == YapDatabaseViewChangeInsert, @"");
	STAssertTrue(RowOp(rowChanges, 3).finalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 3).finalIndex == 18, @"");
}

- (void)test4D
{
	YapDatabaseViewRangeOptions *rangeOpts =
	    [YapDatabaseViewRangeOptions fixedRangeWithLength:20 offset:0 from:YapDatabaseViewBeginning];
	
	[mappings updateWithCounts:@{ @"":@(40) }];
	[mappings setRangeOptions:rangeOpts forGroup:@""];
	originalMappings = [mappings copy];
	
	// Delete multiple items at the end of the range, and some outside the range
	
	[changes addObject:[YapDatabaseViewRowChange deleteKey:@"key1" inGroup:@"" atIndex:18]];
	[changes addObject:[YapDatabaseViewRowChange deleteKey:@"key2" inGroup:@"" atIndex:18]];
	[changes addObject:[YapDatabaseViewRowChange deleteKey:@"key3" inGroup:@"" atIndex:18]];
	[changes addObject:[YapDatabaseViewRowChange deleteKey:@"key4" inGroup:@"" atIndex:18]];
	
	[mappings updateWithCounts:@{ @"":@(36) }];
	
	// Fetch changeset
	
	NSArray *rowChanges = nil;
	
	[YapDatabaseViewChange getSectionChanges:NULL
	                              rowChanges:&rowChanges
	                    withOriginalMappings:originalMappings
	                           finalMappings:mappings
	                             fromChanges:changes];
	
	// Verify
	
	STAssertTrue(RowOp(rowChanges, 0).type == YapDatabaseViewChangeDelete, @"");
	STAssertTrue(RowOp(rowChanges, 0).originalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 0).originalIndex == 18, @"");
	
	STAssertTrue(RowOp(rowChanges, 1).type == YapDatabaseViewChangeDelete, @"");
	STAssertTrue(RowOp(rowChanges, 1).originalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 1).originalIndex == 19, @"");
	
	STAssertTrue(RowOp(rowChanges, 2).type == YapDatabaseViewChangeInsert, @"");
	STAssertTrue(RowOp(rowChanges, 2).finalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 2).finalIndex == 19, @"");
	
	STAssertTrue(RowOp(rowChanges, 3).type == YapDatabaseViewChangeInsert, @"");
	STAssertTrue(RowOp(rowChanges, 3).finalSection == 0, @"");
	STAssertTrue(RowOp(rowChanges, 3).finalIndex == 18, @"");
}

@end
