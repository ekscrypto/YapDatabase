#import "YapDatabaseViewChange.h"
#import "YapDatabaseViewChangePrivate.h"
#import "YapDatabaseViewMappingsPrivate.h"


@implementation YapDatabaseViewSectionChange {

/* From YapDatabaseViewChangePrivate.h :

@public
	
	NSString *group; // immutable
	BOOL isReset;    // immutable
	
	YapDatabaseViewChangeType type; // mutable during consolidation
	
	NSUInteger originalSection; // mutable during pre-processing
	NSUInteger finalSection;    // mutable during pre-processing
*/
}

@synthesize type = type;
@synthesize group = group;

+ (YapDatabaseViewSectionChange *)insertGroup:(NSString *)group
{
	YapDatabaseViewSectionChange *op = [[YapDatabaseViewSectionChange alloc] init];
	op->type = YapDatabaseViewChangeInsert;
	op->group = group;
	op->isReset = NO;
	op->originalSection = op->finalSection = NSNotFound;
	
	return op;
}

+ (YapDatabaseViewSectionChange *)deleteGroup:(NSString *)group
{
	YapDatabaseViewSectionChange *op = [[YapDatabaseViewSectionChange alloc] init];
	op->type = YapDatabaseViewChangeDelete;
	op->group = group;
	op->isReset = NO;
	op->originalSection = op->finalSection = NSNotFound;
	
	return op;
}

+ (YapDatabaseViewSectionChange *)resetGroup:(NSString *)group
{
	YapDatabaseViewSectionChange *op = [[YapDatabaseViewSectionChange alloc] init];
	op->type = YapDatabaseViewChangeDelete;
	op->group = group;
	op->isReset = YES;
	op->originalSection = op->finalSection = NSNotFound;
	
	return op;
}

- (id)copyWithZone:(NSZone *)zone
{
	YapDatabaseViewSectionChange *op = [[YapDatabaseViewSectionChange alloc] init];
	op->type = type;
	op->group = group;
	op->isReset = isReset;
	op->originalSection = originalSection;
	op->finalSection = finalSection;
	
	return op;
}

- (NSUInteger)index
{
	if (type == YapDatabaseViewChangeInsert)
		return finalSection;
	else
		return originalSection;
}

- (NSString *)description
{
	if (type == YapDatabaseViewChangeInsert)
	{
		if (finalSection == NSNotFound)
		{
			// Internal style (for debugging the processAndConsolidateOperations method)
			return [NSString stringWithFormat:
			    @"<YapDatabaseViewSectionChange: Insert group(%@)", group];
		}
		else
		{
			// External style (for debugging UITableView & UICollectionView updates)
			return [NSString stringWithFormat:
			    @"<YapDatabaseViewSectionChange: Insert section(%lu) group(%@)>",
			        (unsigned long)finalSection, group];
		}
	}
	else // if (type == YapDatabaseViewChangeDelete)
	{
		if (originalSection == NSNotFound)
		{
			// Internal style (for debugging the processAndConsolidateOperations method)
			return [NSString stringWithFormat:
			    @"<YapDatabaseViewSectionChange: Delete group(%@)", group];
		}
		else
		{
			// External style (for debugging UITableView & UICollectionView updates)
			return [NSString stringWithFormat:
			    @"<YapDatabaseViewSectionChange: Delete section(%lu) group(%@)>",
			        (unsigned long)originalSection, group];
		}
	}
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation YapDatabaseViewRowChange {

/* From YapDatabaseViewChangePrivate.h :

@public
	
	id key; // immutable
	
	NSString *originalGroup; // immutable
	NSString *finalGroup;    // mutable during consolidation
	
	YapDatabaseViewChangeType type; // mutable during consolidation
	int columns;                    // mutable during consolidation
	
	NSUInteger opOriginalIndex;  // immutable
	NSUInteger opFinalIndex;     // immutable
	
	NSUInteger originalIndex; // mutable during processing
	NSUInteger finalIndex;    // mutable during processing
	
	NSUInteger originalSection; // mutable during pre-processing
	NSUInteger finalSection;    // mutable during pre-processing
*/
}

@synthesize type = type;
@synthesize modifiedColumns = columns;
@synthesize originalGroup = originalGroup;
@synthesize finalGroup = finalGroup;
@synthesize originalIndex = originalIndex;
@synthesize finalIndex = finalIndex;
@synthesize originalSection = originalSection;
@synthesize finalSection = finalSection;

- (NSIndexPath *)indexPath
{
	if (type == YapDatabaseViewChangeInsert) {
		return nil; // <-- You should be using newIndexPath
	}
	else
	{
	  #if TARGET_OS_IPHONE
		return [NSIndexPath indexPathForRow:originalIndex inSection:originalSection];
	  #else
		NSUInteger indexes[] = {originalSection, originalIndex};
		return [NSIndexPath indexPathWithIndexes:indexes length:2];
	  #endif
	}
}

- (NSIndexPath *)newIndexPath
{
	if (type == YapDatabaseViewChangeDelete || type == YapDatabaseViewChangeUpdate) {
		return nil; // <-- You should be using indexPath
	}
	else {
	#if TARGET_OS_IPHONE
		return [NSIndexPath indexPathForRow:finalIndex inSection:finalSection];
	#else
		NSUInteger indexes[] = {finalSection, finalIndex};
		return [NSIndexPath indexPathWithIndexes:indexes length:2];
	#endif
	}
}

- (id)copyWithZone:(NSZone *)zone
{
	YapDatabaseViewRowChange *op = [[YapDatabaseViewRowChange alloc] init];
	op->key = key;
	op->originalGroup = originalGroup;
	op->finalGroup = finalGroup;
	op->type = type;
	op->columns = columns;
	op->opOriginalIndex = opOriginalIndex;
	op->opFinalIndex = opFinalIndex;
	op->originalIndex = originalIndex;
	op->finalIndex = finalIndex;
	op->originalSection = originalSection;
	op->finalSection = finalSection;
	
	return op;
}

+ (YapDatabaseViewRowChange *)insertKey:(id)key inGroup:(NSString *)group atIndex:(NSUInteger)index
{
	YapDatabaseViewRowChange *op = [[YapDatabaseViewRowChange alloc] init];
	op->type = YapDatabaseViewChangeInsert;
	op->key = key;
	op->columns = YapDatabaseViewChangeColumnObject | YapDatabaseViewChangeColumnMetadata;
	
	op->originalGroup = nil;                                 // invalid in insert type
	op->originalIndex = op->opOriginalIndex = NSUIntegerMax; // invalid in insert type
	
	op->finalGroup = group;
	op->finalIndex = op->opFinalIndex = index;
	
	op->originalSection = op->finalSection = NSNotFound;
	
	return op;
}

+ (YapDatabaseViewRowChange *)deleteKey:(id)key inGroup:(NSString *)group atIndex:(NSUInteger)index
{
	YapDatabaseViewRowChange *op = [[YapDatabaseViewRowChange alloc] init];
	op->type = YapDatabaseViewChangeDelete;
	op->key = key;
	op->columns = YapDatabaseViewChangeColumnObject | YapDatabaseViewChangeColumnMetadata;
	
	op->originalGroup = group;
	op->originalIndex = op->opOriginalIndex = index;
	
	op->finalGroup = nil;                              // invalid in delete type
	op->finalIndex = op->opFinalIndex = NSUIntegerMax; // invalid in delete type
	
	op->originalSection = op->finalSection = NSNotFound;
	
	return op;
}

+ (YapDatabaseViewRowChange *)updateKey:(id)key columns:(int)flags inGroup:(NSString *)group atIndex:(NSUInteger)index
{
	YapDatabaseViewRowChange *op = [[YapDatabaseViewRowChange alloc] init];
	op->type = YapDatabaseViewChangeUpdate;
	op->key = key;
	op->columns = flags;
	
	op->originalGroup = group;
	op->originalIndex = op->opOriginalIndex = index;
	
	op->finalGroup = group;
	op->finalIndex = op->opFinalIndex = index;
	
	op->originalSection = op->finalSection = NSNotFound;
	
	return op;
}

- (NSString *)description
{
	if (type == YapDatabaseViewChangeInsert)
	{
		if (finalSection == NSNotFound)
		{
			// Internal style (for debugging the processAndConsolidateOperations method)
			return [NSString stringWithFormat:
			    @"<YapDatabaseViewRowChange: Insert pre(~ -> %lu) post(~ -> %lu) group(%@) key(%@)",
			        (unsigned long)opFinalIndex, (unsigned long)finalIndex, finalGroup, key];
		}
		else
		{
			// External style (for debugging UITableView & UICollectionView updates)
			return [NSString stringWithFormat:
			    @"<YapDatabaseViewRowChange: Insert indexPath(nil) newIndexPath(%lu, %lu) group(%@) key(%@)>",
			        (unsigned long)finalSection, (unsigned long)finalIndex, finalGroup, key];
		}
	}
	else if (type == YapDatabaseViewChangeDelete)
	{
		if (originalSection == NSNotFound)
		{
			// Internal style (for debugging the processAndConsolidateOperations method)
			return [NSString stringWithFormat:
			    @"<YapDatabaseViewRowChange: Delete pre(%lu -> ~) post(%lu -> ~) group(%@) key(%@)",
			        (unsigned long)opOriginalIndex, (unsigned long)originalIndex, originalGroup, key];
		}
		else
		{
			// External style (for debugging UITableView & UICollectionView updates)
			return [NSString stringWithFormat:
			    @"<YapDatabaseViewRowChange: Delete indexPath(%lu, %lu) newIndexPath(nil) group(%@) key(%@)>",
			        (unsigned long)originalSection, (unsigned long)originalIndex, originalGroup, key];
		}
	}
	else if (type == YapDatabaseViewChangeMove)
	{
		if (originalSection == NSNotFound && finalSection == NSNotFound)
		{
			// Internal style (for debugging the processAndConsolidateOperations method)
			return [NSString stringWithFormat:
				@"<YapDatabaseViewRowChange: Move pre(%lu -> %lu) post(%lu -> %lu) group(%@ -> %@) key(%@)",
					(unsigned long)opOriginalIndex, (unsigned long)opFinalIndex,
					(unsigned long)originalIndex,   (unsigned long)finalIndex,
					originalGroup, finalGroup, key];
		}
		else
		{
			// External style (for debugging UITableView & UICollectionView updates)
			return [NSString stringWithFormat:
				@"<YapDatabaseViewRowChange: Move indexPath(%lu, %lu) newIndexPath(%lu, %lu) group(%@ -> %@) key(%@)",
					(unsigned long)originalSection, (unsigned long)originalIndex,
					(unsigned long)finalSection,    (unsigned long)finalIndex,
					originalGroup, finalGroup, key];
		}
	}
	else // if (type == YapDatabaseViewChangeUpdate)
	{
		if (originalSection == NSNotFound && finalSection == NSNotFound)
		{
			// Internal style (for debugging the processAndConsolidateOperations method)
			return [NSString stringWithFormat:
				@"<YapDatabaseViewRowChange: Update pre(%lu) post(%lu -> %lu) group(%@ -> %@) key(%@)",
					(unsigned long)opOriginalIndex,
					(unsigned long)originalIndex,   (unsigned long)finalIndex,
					originalGroup, finalGroup, key];
		}
		else
		{
			// External style (for debugging UITableView & UICollectionView updates)
			return [NSString stringWithFormat:
				@"<YapDatabaseViewRowChange: Update indexPath(%lu, %lu) group(%@ -> %@) key(%@)",
					(unsigned long)originalSection, (unsigned long)originalIndex,
					originalGroup, finalGroup, key];
		}
	}
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation YapDatabaseViewChange

/**
 * During a read-write transaction, every modification to the view results in one or more
 * YapDatabaseViewSectionChange or YapDatabaseViewRowChange objects being appended to an internal array.
 * 
 * At the end of the read-write transaction we have a big list of changes that have occurred.
 * 
 * This method takes a list of YapDatabaseViewRowChange objects and processes them:
 *
 * - properly calculates the original & final index of each change
 * - properly consolidates multiple changes to the same item into a single change
**/
+ (void)processAndConsolidateRowChanges:(NSMutableArray *)changes
{
	// Each YapDatabaseViewRowChange object is one of:
	// 
	// - Row insert
	// - Row delete
	// - Row update
	//
	// If a row is moved, then it is represented in the given array as a delete followed by an insert.
	//
	// Each YapDatabaseViewRowChange represents the change state AT THE MOMENT THE CHANGE TOOK PLACE.
	// This is critically important to understand.
	//
	// For example, imagine the following array:
	//
	// [0] = <RowInsert group=fruit index=0 key=apple>
	// [0] = <RowDelete group=fruit index=7 key=carrot>
	// [1] = <RowInsert group=fruit index=2 key=blueberry>
	// [2] = <RowInsert group=fruit index=2 key=banana>
	//
	// What was the original index of 'carrot'?
	// What is the final index of 'blueberry'?
	//
	// The original index of 'carrot' was 6, because the earlier insert of 'apple' pushed its index upward.
	// The final index of 'blueberry' is 3, because a later insert of 'banana' pushed its index upward.
	//
	// As you might guess, there are a number of edge cases to watch out for.
	// Ultimately, the algorithm is fairly straight-forward, but the code gets a little verbose.
	//
	// There are are crap ton of unit tests for this code...
	// 
	// Please see the unit tests for a bunch of examples that will shed additional light on the setup and algorithm:
	// TestViewChangeLogic.m
	
	NSUInteger i;
	NSUInteger j;
	
	//
	// PROCESSING
	//
	
	// First we enumerate the items BACKWARDS,
	// and update the ORIGINAL values.
	
	NSUInteger count = [changes count];
	
	for (i = count; i > 0; i--)
	{
		YapDatabaseViewRowChange *change = [changes objectAtIndex:(i-1)];
		
		if (change->type == YapDatabaseViewChangeDelete)
		{
			// A DELETE operation may affect the ORIGINAL index value of operations that occurred AFTER it,
			//  IF the later operation occurs at a greater or equal index value.  ( +1 )
			
			for (j = i; j < count; j++)
			{
				YapDatabaseViewRowChange *laterChange = [changes objectAtIndex:j];
				
				if (laterChange->type == YapDatabaseViewChangeDelete ||
					laterChange->type == YapDatabaseViewChangeUpdate)
				{
					if (laterChange->originalIndex >= change->opOriginalIndex &&
					   [laterChange->originalGroup isEqualToString:change->originalGroup])
					{
						laterChange->originalIndex += 1;
					}
				}
			}
		}
		else if (change->type == YapDatabaseViewChangeInsert)
		{
			// An INSERT operation may affect the ORIGINAL index value of operations that occurred AFTER it,
			//   IF the later operation occurs at a greater or equal index value. ( -1 )
			
			for (j = i; j < count; j++)
			{
				YapDatabaseViewRowChange *laterChange = [changes objectAtIndex:j];
				
				if (laterChange->type == YapDatabaseViewChangeDelete ||
				    laterChange->type == YapDatabaseViewChangeUpdate)
				{
					if (laterChange->originalIndex >= change->opFinalIndex &&
					   [laterChange->originalGroup isEqualToString:change->finalGroup])
					{
						laterChange->originalIndex -= 1;
					}
				}
			}
		}
	}
	
	// Next we enumerate the items FORWARDS,
	// and update the FINAL values.
	
	for (i = 1; i < count; i++)
	{
		YapDatabaseViewRowChange *change = [changes objectAtIndex:i];
		
		if (change->type == YapDatabaseViewChangeDelete)
		{
			// A DELETE operation may affect the FINAL index value of operations that occurred BEFORE it,
			//  IF the earlier operation occurs at a greater (but not equal) index value. ( -1 )
			
			for (j = i; j > 0; j--)
			{
				YapDatabaseViewRowChange *earlierChange = [changes objectAtIndex:(j-1)];
				
				if (earlierChange->type == YapDatabaseViewChangeInsert ||
				    earlierChange->type == YapDatabaseViewChangeUpdate  )
				{
					if (earlierChange->finalIndex > change->opOriginalIndex &&
					   [earlierChange->finalGroup isEqualToString:change->originalGroup])
					{
						earlierChange->finalIndex -= 1;
					}
				}
			}
		}
		else if (change->type == YapDatabaseViewChangeInsert)
		{
			// An INSERT operation may affect the FINAL index value of operations that occurred BEFORE it,
			//   IF the earlier operation occurs at a greater index value ( +1 )
			
			for (j = i; j > 0; j--)
			{
				YapDatabaseViewRowChange *earlierChange = [changes objectAtIndex:(j-1)];
				
				if (earlierChange->type == YapDatabaseViewChangeInsert ||
				    earlierChange->type == YapDatabaseViewChangeUpdate)
				{
					if (earlierChange->finalIndex >= change->opFinalIndex &&
					   [earlierChange->finalGroup isEqualToString:change->finalGroup])
					{
						earlierChange->finalIndex += 1;
					}
				}
			}
		}
	}
	
	//
	// CONSOLIDATION
	//
	
	NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
	
	i = 0;
	while (i < [changes count])
	{
		YapDatabaseViewRowChange *firstChangeForKey = [changes objectAtIndex:i];
		
		// Find later operations with the same key
		
		for (j = i+1; j < [changes count]; j++)
		{
			YapDatabaseViewRowChange *laterChange = [changes objectAtIndex:j];
			
			if ([laterChange->key isEqual:firstChangeForKey->key])
			{
				firstChangeForKey->columns |= laterChange->columns;
				[indexSet addIndex:j];
			}
		}
		
		if ([indexSet count] == 0)
		{
			// Check to see if an Update turned into a Move
			
			if (firstChangeForKey->type == YapDatabaseViewChangeUpdate)
			{
				if (firstChangeForKey->originalIndex != firstChangeForKey->finalIndex ||
				    firstChangeForKey->originalSection != firstChangeForKey->finalSection)
				{
					firstChangeForKey->type = YapDatabaseViewChangeMove;
				}
			}
			
			i++; // continue;
		}
		else
		{
			YapDatabaseViewRowChange *lastChangeForKey = [changes objectAtIndex:[indexSet lastIndex]];
			
			if (firstChangeForKey->type == YapDatabaseViewChangeDelete)
			{
				if (lastChangeForKey->type == YapDatabaseViewChangeDelete)
				{
					// Delete + Insert + ... + Delete
					//
					// All operations except the first are no-ops
					
					[changes removeObjectsAtIndexes:indexSet];
					i++;
				}
				else if (lastChangeForKey->type == YapDatabaseViewChangeInsert)
				{
					// Delete + Insert = Move
					//
					// This is always a move operation.
					// Even if the final location hasn't ultimately changed, we still want to treat it as a move.
					// Only a true update, where the index never budged, can be emitted as an update.
					//
					// If we attempt to consolidate this into an update,
					// then the tableView/collectionView will offset the update's index
					// based on insertions & deletions at smaller indexes,
					// and may ultimately update the wrong cell.
					
					firstChangeForKey->type = YapDatabaseViewChangeMove;
					firstChangeForKey->finalIndex = lastChangeForKey->finalIndex;
					firstChangeForKey->finalGroup = lastChangeForKey->finalGroup;
					firstChangeForKey->finalSection = lastChangeForKey->finalSection;
					
					[changes removeObjectsAtIndexes:indexSet];
					i++;
				}
				else if (lastChangeForKey->type == YapDatabaseViewChangeUpdate)
				{
					// Delete + Insert + ... + Update = Move
					//
					// This is always a move operation.
					// Even if the final location hasn't ultimately changed, we still want to treat it as a move.
					// Only a true update, where the index never budged, can be emitted as an update.
					//
					// If we attempt to consolidate this into an update,
					// then the tableView/collectionView will offset the update's index
					// based on insertions & deletions at smaller indexes,
					// and may ultimately update the wrong cell.
					
					firstChangeForKey->type = YapDatabaseViewChangeMove;
					firstChangeForKey->finalIndex = lastChangeForKey->finalIndex;
					firstChangeForKey->finalGroup = lastChangeForKey->finalGroup;
					firstChangeForKey->finalSection = lastChangeForKey->finalSection;
					
					[changes removeObjectsAtIndexes:indexSet];
					i++;
				}
			}
			else if (firstChangeForKey->type == YapDatabaseViewChangeInsert)
			{
				if (lastChangeForKey->type == YapDatabaseViewChangeDelete)
				{
					// Insert + Delete
					//
					// All operations are no-ops (& i remains the same)
					
					[changes removeObjectsAtIndexes:indexSet];
					[changes removeObjectAtIndex:i];
					
				}
				else if (lastChangeForKey->type == YapDatabaseViewChangeInsert)
				{
					// Insert + Delete + ... + Insert
					//
					// All operations except the last are no-ops.
					
					firstChangeForKey->finalIndex = lastChangeForKey->finalIndex;
					firstChangeForKey->finalGroup = lastChangeForKey->finalGroup;
					firstChangeForKey->finalSection = lastChangeForKey->finalSection;
					
					[changes removeObjectsAtIndexes:indexSet];
					i++;
				}
				else // if (lastChangeForKey->type == YapDatabaseViewChangeUpdate)
				{
					// Insert + Update
					//
					// This is still an insert, but the final location may have changed.
					
					firstChangeForKey->finalIndex = lastChangeForKey->finalIndex;
					firstChangeForKey->finalGroup = lastChangeForKey->finalGroup;
					firstChangeForKey->finalSection = lastChangeForKey->finalSection;
					
					[changes removeObjectsAtIndexes:indexSet];
					i++;
				}
			}
			else if (firstChangeForKey->type == YapDatabaseViewChangeUpdate)
			{
				if (lastChangeForKey->type == YapDatabaseViewChangeDelete)
				{
					// Update + Delete
					//
					// This is ultimately a Delete.
					// We need to be sure to use the original original index.
					
					firstChangeForKey->type = YapDatabaseViewChangeDelete;
					
					[changes removeObjectsAtIndexes:indexSet];
					i++;
				}
				else if (lastChangeForKey->type == YapDatabaseViewChangeInsert)
				{
					// Update + Delete + ... + Insert = Move
					//
					// This is always a move operation.
					// Even if the final location hasn't ultimately changed, we still want to treat it as a move.
					// Only a true update, where the index never budged, can be emitted as an update.
					//
					// If we attempt to consolidate this into an update,
					// then the tableView/collectionView will offset the update's index
					// based on insertions & deletions at smaller indexes,
					// and may ultimately update the wrong cell.
					
					firstChangeForKey->type = YapDatabaseViewChangeMove;
					firstChangeForKey->finalIndex = lastChangeForKey->finalIndex;
					firstChangeForKey->finalGroup = lastChangeForKey->finalGroup;
					firstChangeForKey->finalSection = lastChangeForKey->finalSection;
					
					[changes removeObjectsAtIndexes:indexSet];
					i++;
				}
				else // if (lastChangeForKey->type == YapDatabaseViewChangeUpdate)
				{
					// Update + ... + Update
					//
					// This is either an Update or a Move.
					// Only a true update, where the index never budged, can be emitted as an update.
					//
					// So we scan all the changes, and if every single one is an update, then we can emit an update.
					
					__block BOOL isTrueUpdate = YES;
					
					[indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
						
						YapDatabaseViewRowChange *changeForKey = [changes objectAtIndex:idx];
						
						if (changeForKey->type != YapDatabaseViewChangeUpdate)
						{
							isTrueUpdate = NO;
							*stop = YES;
						}
					}];
					
					if (isTrueUpdate)
					{
						// = Update
						
						[changes removeObjectsAtIndexes:indexSet];
						i++;
					}
					else
					{
						// = Move
						//
						// The final location comes from the last update
						
						firstChangeForKey->type = YapDatabaseViewChangeMove;
						firstChangeForKey->finalIndex = lastChangeForKey->finalIndex;
						firstChangeForKey->finalGroup = lastChangeForKey->finalGroup;
						firstChangeForKey->finalSection = lastChangeForKey->finalSection;
						
						[changes removeObjectsAtIndexes:indexSet];
						i++;
					}
				}
			}
			
			[indexSet removeAllIndexes];
			
		} // ([indexSet count] > 0)
		
	} // while (i < [changes count])
}

/**
 * During a read-write transaction, every modification to the view results in one or more
 * YapDatabaseViewSectionChange or YapDatabaseViewRowChange objects being appended to an internal array.
 *
 * At the end of the read-write transaction we have a big list of changes that have occurred.
 *
 * This method takes a list of YapDatabaseViewSectionChange objects and processes them.
**/
+ (void)processAndConsolidateSectionChanges:(NSMutableArray *)changes
{
	NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
	
	NSUInteger i = 0;
	while (i < [changes count])
	{
		YapDatabaseViewSectionChange *firstSectionChangeForGroup = [changes objectAtIndex:i];
		
		// Find later operations with the same group
		
		for (NSUInteger j = i+1; j < [changes count]; j++)
		{
			YapDatabaseViewSectionChange *laterSectionChange = [changes objectAtIndex:j];
			
			if ([laterSectionChange->group isEqualToString:firstSectionChangeForGroup->group])
			{
				[indexSet addIndex:j];
			}
		}
		
		if ([indexSet count] == 0)
		{
			i++;
		}
		else
		{
			YapDatabaseViewSectionChange *lastSectionChangeForGroup = [changes objectAtIndex:[indexSet lastIndex]];
			
			if (firstSectionChangeForGroup->type == YapDatabaseViewChangeDelete)
			{
				if (lastSectionChangeForGroup->type == YapDatabaseViewChangeDelete)
				{
					// Delete + Insert + ... + Delete
					//
					// All operations except the first are no-ops
					
					[changes removeObjectsAtIndexes:indexSet];
					i++;
				}
				else // if (lastSectionChangeForGroup->type == YapDatabaseViewChangeInsert)
				{
					// Delete + Insert
					//
					// All operations are no-ops (& i remains the same)
					
					[changes removeObjectsAtIndexes:indexSet];
					[changes removeObjectAtIndex:i];
				}
			}
			else if (firstSectionChangeForGroup->type == YapDatabaseViewChangeInsert)
			{
				if (lastSectionChangeForGroup->type == YapDatabaseViewChangeDelete)
				{
					// Insert + Delete
					//
					// All operations are no-ops (& i remains the same)
					
					[changes removeObjectsAtIndexes:indexSet];
					[changes removeObjectAtIndex:i];
				}
				else if (lastSectionChangeForGroup->type == YapDatabaseViewChangeInsert)
				{
					// Insert + Delete + ... + Insert
					//
					// All operations except the first are no-ops.
					
					[changes removeObjectsAtIndexes:indexSet];
					i++;
				}
			}
		}
	}
}

/**
 * This method applies the given mappings to the processed list of row changes.
 * Based upon the configuration of the mappings, it will
 * 
 * - filter items that are excluded based on per-group range configurations
 * - alter indexes based on per-group range configurations
 * - reverse indexes based on per-group reversal settings
**/
+ (void)postProcessAndFilterRowChanges:(NSMutableArray *)rowChanges
                  withOriginalMappings:(YapDatabaseViewMappings *)originalMappings
                         finalMappings:(YapDatabaseViewMappings *)finalMappings
{
	
	// The user may have various range options set for each section/group.
	// For example:
	//
	// The user has a hard range on group "fiction" in the "bookSalesRank" view in order to display the top 20.
	// So any items outside of that range must be filtered.
	
	NSDictionary *rangeOptions = [finalMappings rangeOptions];
	
	// Note: The rangeOptions are the same between originalMappings & finalMappings.
	
	for (NSString *group in rangeOptions)
	{
		YapDatabaseViewRangeOptions *rangeOpts = [rangeOptions objectForKey:group];
		
		NSUInteger originalGroupCount = [originalMappings numberOfItemsInGroup:group];
		NSUInteger finalGroupCount = [finalMappings numberOfItemsInGroup:group];
		
		YapDatabaseViewPin pin = rangeOpts.pin;
		
		//
		// STEP 1 : Calculate the originalRange & finalRange
		//
		
		NSUInteger originalRangeLength = rangeOpts.length;
		NSUInteger originalRangeOffset = rangeOpts.offset;
		
		NSUInteger originalRangeMin;
		NSUInteger originalRangeMax;
		
		if (pin == YapDatabaseViewBeginning)
		{
			originalRangeMin = originalRangeOffset;
			originalRangeMax = originalRangeOffset + originalRangeLength;
		}
		else // if (pin == YapDatabaseViewEnd)
		{
			if (originalRangeOffset < originalGroupCount) {
				originalRangeMax = originalGroupCount - originalRangeOffset;
				originalRangeMin = originalRangeMax - originalRangeLength;
			}
			else {
				originalRangeMax = 0;
				originalRangeMin = 0;
			}
		}
		
		NSUInteger finalRangeLength;
		NSUInteger finalRangeOffset;
		
		NSUInteger finalRangeMin;
		NSUInteger finalRangeMax;
		
		NSInteger flexibleRangeForcedDiff = 0;
		
		if (rangeOpts.isFixedRange)
		{
			// FIXED Range:
			//
			// - The length is fixed. It only shrinks if we run out of keys.
			// - The offset never changes.
			//
			// If pinned to the BEGINNING:
			//   The offset represents how far the beginning of the range is from the beginning of the group.
			//
			//   Group : <---------------------------------------->
			//   Range :                  <--------->
			//   Offset: <---------------->                          (pin == YapDatabaseViewBeginning)
			//
			// If pinned to the END:
			//   The offset represents how far the end of the range is from the end of the group.
			//
			//   Group : <---------------------------------------->
			//   Range :                  <--------->
			//   Offset:                            <------------->  (pin == YapDatabaseViewEnd)
			
			finalRangeOffset = originalRangeOffset;
			
			NSUInteger maxFinalRangeLength;
			if (finalGroupCount > finalRangeOffset)
				maxFinalRangeLength = finalGroupCount - finalRangeOffset;
			else
				maxFinalRangeLength = 0;
			
			finalRangeLength = MIN(rangeOpts.maxLength, maxFinalRangeLength);
			
			if (pin == YapDatabaseViewBeginning)
			{
				finalRangeMin = finalRangeOffset;
				finalRangeMax = finalRangeOffset + finalRangeLength;
			}
			else // if (pin == YapDatabaseViewEnd)
			{
				if (finalRangeOffset < finalGroupCount) {
					finalRangeMax = finalGroupCount - finalRangeOffset;
					finalRangeMin = finalRangeMax - finalRangeLength;
				}
				else {
					finalRangeMax = 0;
					finalRangeMin = 0;
				}
			}
		}
		else // if (rangeOpts.isFlexibleRange)
		{
			// FLEXIBLE Range:
			// 
			// The length changes as items are inserted and deleted with the range boundary.
			// The offset changes as items are inserted and deleted between the range and its pinned end.
			
			NSUInteger finalRangeMin = originalRangeMin;
			NSUInteger finalRangeMax = originalRangeMax;
			
			BOOL finalRangeWasEmpty = ((finalRangeMax - finalRangeMin) == 0);
			
			YapDatabaseViewGrowOptions growOptions = rangeOpts.growOptions;
			
			for (YapDatabaseViewRowChange *rowChange in rowChanges)
			{
				if (rowChange->type == YapDatabaseViewChangeDelete || rowChange->type == YapDatabaseViewChangeMove)
				{
					if ([rowChange->originalGroup isEqualToString:group])
					{
						// A DELETE operation can:
						// - decrement the location of the final range
						// - decrease the length of the final range
					
						if (rowChange->opOriginalIndex < finalRangeMin)
						{
							finalRangeMin -= 1;
						}
						if (rowChange->opOriginalIndex < finalRangeMax)
						{
							finalRangeMax -= 1;
						}
					}
				}
				
				if (rowChange->type == YapDatabaseViewChangeInsert || rowChange->type == YapDatabaseViewChangeMove)
				{
					if ([rowChange->finalGroup isEqualToString:group])
					{
						// An INSERT operation can:
						// - increment the location of the final range
						// - increase the length of the final range
						//
						// How do we know if an inserted item should be included in the range?
						// This is based upon the growOptions.
						//
						// Please see the documentation in the header file for the growOptions property.
						// It has an extended discussion.
						
						if (pin == YapDatabaseViewBeginning)
						{
							if ((growOptions & YapDatabaseViewGrowPinSide) || finalRangeWasEmpty)
							{
								if (rowChange->opFinalIndex < finalRangeMin)
									finalRangeMin++;
							}
							else
							{
								if (rowChange->opFinalIndex <= finalRangeMin)
									finalRangeMin++;
							}
							
							if ((growOptions & YapDatabaseViewGrowNonPinSide) || finalRangeWasEmpty)
							{
								if (rowChange->opFinalIndex <= finalRangeMax)
									finalRangeMax++;
							}
							else
							{
								if (rowChange->opFinalIndex < finalRangeMax)
									finalRangeMax++;
							}
						}
						else // if (pin == YapDatabaseViewEnd)
						{
							if ((growOptions & YapDatabaseViewGrowNonPinSide) || finalRangeWasEmpty)
							{
								if (rowChange->opFinalIndex < finalRangeMin)
									finalRangeMin++;
							}
							else
							{
								if (rowChange->opFinalIndex <= finalRangeMin)
									finalRangeMin++;
							}
							
							if ((growOptions & YapDatabaseViewGrowPinSide) || finalRangeWasEmpty)
							{
								if (rowChange->opFinalIndex <= finalRangeMax)
									finalRangeMax++;
							}
							else
							{
								if (rowChange->opFinalIndex < finalRangeMax)
									finalRangeMax++;
							}
						}
						
						// If the range ever becomes empty,
						// then we need to effectively set th growOptions to YapDatabaseViewGrowOnBothSides.
						//
						// With an empty range, there is no different between PinSide and NonPinSide.
						//
						// Notice that this flag, once set, remains set.
						
						finalRangeWasEmpty = finalRangeWasEmpty || ((finalRangeMax - finalRangeMin) == 0);
					}
				}
			}
			
			// Adjust if we exceed max length, or drop below min length
			
			finalRangeLength = finalRangeMax - finalRangeMin;
			
			if (finalRangeLength > rangeOpts.maxLength)
			{
				NSUInteger diff = finalRangeLength - rangeOpts.maxLength;
				flexibleRangeForcedDiff = -1 * diff;
				
				if (pin == YapDatabaseViewBeginning)
				{
					// Prune from non-pin-side (end)
					finalRangeMax -= diff;
				}
				else // if (pin == YapDatabaseViewEnd)
				{
					// Prune from non-pin-side (beginning)
					finalRangeMin += diff;
				}
			}
			else if ((finalRangeLength < rangeOpts.minLength) && (finalRangeLength < finalGroupCount))
			{
				NSUInteger diff = rangeOpts.minLength - finalRangeLength;
				flexibleRangeForcedDiff = diff;
				
				if (pin == YapDatabaseViewBeginning)
				{
					// Append from pin-side first (beginning) (if possible)
					if (finalRangeMin > 0)
					{
						NSUInteger pinSideDiff = MAX(diff, finalRangeMin);
						
						finalRangeMin -= pinSideDiff;
						diff -= pinSideDiff;
					}
					
					// Append from non-pin-side second (end) (if possible) (if still needed)
					if ((finalRangeMax < finalGroupCount) && (diff > 0))
					{
						NSUInteger nonPinSideDiff = MAX(diff, (finalGroupCount - finalRangeMax));
						
						finalRangeMax += nonPinSideDiff;
						//diff -= nonPinSideDiff;
					}
				}
				else // if (pin == YapDatabaseViewEnd)
				{
					// Append from pin-side first (end) (if possible)
					if (finalRangeMax < finalGroupCount)
					{
						NSUInteger pinSideDiff = MAX(diff, (finalGroupCount - finalRangeMax));
						
						finalRangeMax += pinSideDiff;
						diff -= pinSideDiff;
					}
					
					// Append from non-pin-side second (beginning) (if possible) (if still needed)
					if ((finalRangeMin > 0) && (diff > 0))
					{
						NSUInteger nonPinSideDiff = MAX(diff, finalRangeMin);
						
						finalRangeMin -= nonPinSideDiff;
						//diff -= nonPinSideDiff;
					}
				}
			}
			
			// Set finalLength & finalOffset
		
			finalRangeLength = finalRangeMax - finalRangeMin;
			
			if (pin == YapDatabaseViewBeginning)
				finalRangeOffset = finalRangeMin;
			else
				finalRangeOffset = finalGroupCount - finalRangeMax;
		}
		
		//
		// STEP 2 : Filter items that are outside the range, and "map" items that are inside the range.
		//
		// By "map" we mean update the index to match the range, not the entire view.
		// For example, if there is a hard range to display only the last 20 items in the view,
		// then the index of the last item should be 20 (range.length), not 436 (group.length).
		
		NSUInteger deleteCount = 0;
		NSUInteger insertCount = 0;
		
		NSUInteger i = 0;
		while (i < [rowChanges count])
		{
			YapDatabaseViewRowChange *rowChange = [rowChanges objectAtIndex:i];
			
			if (rowChange->type == YapDatabaseViewChangeDelete)
			{
				if ([rowChange->originalGroup isEqualToString:group])
				{
					if (rowChange->originalIndex >= originalRangeMin &&
					    rowChange->originalIndex <  originalRangeMax)
					{
						// Include in changeset
						i++;
						deleteCount++;
						
						// Update index to match range
						rowChange->originalIndex -= originalRangeMin;
					}
					else
					{
						// Exclude from changeset
						[rowChanges removeObjectAtIndex:i];
					}
				}
			}
			else if (rowChange->type == YapDatabaseViewChangeInsert)
			{
				if ([rowChange->finalGroup isEqualToString:group])
				{
					if (rowChange->finalIndex >= finalRangeMin &&
					    rowChange->finalIndex <  finalRangeMax)
					{
						// Include in changeset
						i++;
						insertCount++;
						
						// Update index to match range
						rowChange->finalIndex -= finalRangeMin;
					}
					else
					{
						// Exclude from changeset
						[rowChanges removeObjectAtIndex:i];
					}
				}
			}
			else if (rowChange->type == YapDatabaseViewChangeUpdate)
			{
				if ([rowChange->originalGroup isEqualToString:group])
				{
					if (rowChange->originalIndex >= originalRangeMin &&
					    rowChange->originalIndex <  originalRangeMax)
					{
						// Include in changeset
						i++;
						
						// Update index to match range
						rowChange->originalIndex -= originalRangeMin;
						rowChange->finalIndex    -= finalRangeMin;
					}
					else
					{
						// Exclude from changeset
						[rowChanges removeObjectAtIndex:i];
					}
				}
			}
			else if (rowChange->type == YapDatabaseViewChangeMove)
			{
				// A move is both a delete and an insert.
				// Sometimes both operations apply to this group.
				// Sometimes only one.
				// Sometimes neither.
				
				BOOL filterDelete = NO;
				BOOL filterInsert = NO;
				
				if ([rowChange->originalGroup isEqualToString:group])
				{
					if (rowChange->originalIndex >= originalRangeMin &&
					    rowChange->originalIndex <  originalRangeMax)
					{
						// Include (delete operation) in changeset
						
						// Update index to match range
						rowChange->originalIndex -= originalRangeMin;
					}
					else
					{
						// Exclude (delete operation) from changeset
						filterDelete = YES;
					}
				}
				
				if ([rowChange->finalGroup isEqualToString:group])
				{
					if (rowChange->finalIndex >= finalRangeMin &&
					    rowChange->finalIndex <  finalRangeMax)
					{
						// Include (insert operation) in changeset
						
						// Update index to match range
						rowChange->finalIndex -= finalRangeMin;
					}
					else
					{
						// Exclude (insert operation) from changeset
						filterInsert = YES;
					}
				}
				
				if (filterDelete && filterInsert)
				{
					// Exclude from changeset
					[rowChanges removeObjectAtIndex:i];
				}
				else if (filterDelete && !filterInsert)
				{
					// Move -> Insert
					rowChange->type = YapDatabaseViewChangeInsert;
					i++;
					insertCount++;
				}
				else if (!filterDelete && filterInsert)
				{
					// Move -> Delete
					rowChange->type = YapDatabaseViewChangeDelete;
					i++;
					deleteCount++;
				}
				else
				{
					// Move
					i++;
					insertCount++;
					deleteCount++;
				}
			}
		}
		
		// Fix the final counts by manually adding any needed insertions or deletions
		
		if (rangeOpts.isFixedRange)
		{
			// FIXED Range:
			//
			// For fixed ranges, we need to ensure the changeset reflects the proper count.
			// For example:
			//
			// The fixed range has a lenth of 20.
			// The only changes were 2 insertions.
			// Thus, we need to add 2 delete changes to balance the length.
			
			NSUInteger length = originalRangeLength;
			length += insertCount;
			length -= deleteCount;
			
			if (length > finalRangeLength)
			{
				// Need to add DELETE operations.
				// These operations represent the objects that got pushed out of the hard range
				// due to insertions within the original range.
				// 
				// These go at the end opposite the pin.
				
				NSUInteger numberOfOperationsToAdd = length - finalRangeLength;
				NSUInteger numberOfOperationsAdded = 0;
				
				NSUInteger index;
				if (pin == YapDatabaseViewBeginning)
					index = originalRangeLength - 1;
				else
					index = 0;
				
				while (numberOfOperationsAdded < numberOfOperationsToAdd)
				{
					// We need to be careful not to step on existing rowChanges.
					// If there is an existing delete for this index, we need to continue onto the next index.
					// If there is an existing move from this index, we need to continue onto the next index.
					// If there is an existing update for this index, we need to change it to a delete.
					
					BOOL found = NO;
					
					for (YapDatabaseViewRowChange *rowChange in rowChanges)
					{
						if (rowChange->type == YapDatabaseViewChangeDelete ||
						    rowChange->type == YapDatabaseViewChangeMove)
						{
							if (rowChange->originalIndex == index && [rowChange->originalGroup isEqualToString:group])
							{
								found = YES;
								break;
							}
						}
						else if (rowChange->type == YapDatabaseViewChangeUpdate)
						{
							if (rowChange->originalIndex == index && [rowChange->originalGroup isEqualToString:group])
							{
								rowChange->type = YapDatabaseViewChangeDelete;
								
								numberOfOperationsAdded++;
								found = YES;
								break;
							}
						}
					}
					
					if (!found)
					{
						YapDatabaseViewRowChange *rowChange =
						    [YapDatabaseViewRowChange deleteKey:nil inGroup:group atIndex:index];
						
						rowChange->originalSection = [originalMappings sectionForGroup:group];
						[rowChanges addObject:rowChange];
						
						numberOfOperationsAdded++;
					}
					
					if (pin == YapDatabaseViewBeginning)
						index--;
					else
						index++;
				}
			}
			else if (length < finalRangeLength)
			{
				// Need to add INSERT operations.
				// These operations represent the objects that got pulled into the hard range
				// due to deletions within the original range.
				//
				// These go at the end opposite the pin.
				
				NSUInteger numberOfOperationsToAdd = finalRangeLength - length;
				NSUInteger numberOfOperationsAdded = 0;
				
				NSUInteger index;
				if (pin == YapDatabaseViewBeginning)
					index = finalRangeLength - 1;
				else
					index = 0;
				
				while (numberOfOperationsAdded < numberOfOperationsToAdd)
				{
					// We need to be careful not to step on existing rowChanges.
					// If there is an existing insert for this index, we need to continue onto the next index.
					// If there is an existing move to this index, we need to continue onto the next index.
					// If there is an existing update for this index, we need to change it to an insert.
					//
					// Note: I don't think the update scenario is actually possible.
					
					BOOL found = NO;
					
					for (YapDatabaseViewRowChange *rowChange in rowChanges)
					{
						if (rowChange->type == YapDatabaseViewChangeInsert ||
						    rowChange->type == YapDatabaseViewChangeMove)
						{
							if (rowChange->finalIndex == index && [rowChange->finalGroup isEqualToString:group])
							{
								found = YES;
								break;
							}
						}
						else if (rowChange->type == YapDatabaseViewChangeUpdate)
						{
							if (rowChange->finalIndex == index && [rowChange->finalGroup isEqualToString:group])
							{
								rowChange->type = YapDatabaseViewChangeInsert;
								
								numberOfOperationsAdded++;
								found = YES;
								break;
							}
						}
					}
					
					if (!found)
					{
						YapDatabaseViewRowChange *rowChange =
						    [YapDatabaseViewRowChange insertKey:nil inGroup:group atIndex:index];
						
						rowChange->finalSection = [finalMappings sectionForGroup:group];
						[rowChanges addObject:rowChange];
						
						numberOfOperationsAdded++;
					}
					
					if (pin == YapDatabaseViewBeginning)
						index--;
					else
						index++;
				}
			}
		}
		else if (flexibleRangeForcedDiff != 0)
		{
			// FLEXIBLE Range:
			
			// Todo...
		}
		
		// And finally, update the range within the final mappings (if changed)
		
		if (rangeOpts.isFlexibleRange)
		{
			if ((originalRangeLength != finalRangeLength) || (originalRangeOffset != finalRangeOffset))
			{
				YapDatabaseViewRangeOptions *newRangeOpts =
				    [rangeOpts copyWithNewLength:finalRangeLength newOffset:finalRangeOffset];
				
				[finalMappings setRangeOptions:newRangeOpts forGroup:group];
			}
		}
	
	} // for (NSString *group in rangeOptions)
}

/**
 * This method applies the given mappings to the processed list of section changes.
 * It will filter the sectionChanges array to properly represent the configuration of the mappings.
**/
+ (void)postProcessAndFilterSectionChanges:(NSMutableArray *)sectionChanges
                      withOriginalMappings:(YapDatabaseViewMappings *)originalMappings
                             finalMappings:(YapDatabaseViewMappings *)finalMappings
{
	NSUInteger i = 0;
	while (i < [sectionChanges count])
	{
		YapDatabaseViewSectionChange *sectionChange = [sectionChanges objectAtIndex:i];
		
		if (sectionChange->type == YapDatabaseViewChangeDelete)
		{
			// Although a group was deleted, the user may be allowing empty sections.
			// If so, we shouldn't emit a removeSection change.
			
			if ([finalMappings sectionForGroup:sectionChange->group] == NSNotFound)
			{
				// Emit
				i++;
			}
			else
			{
				// Don't emit
				[sectionChanges removeObjectAtIndex:i];
			}
		}
		else // if (sectionChange->type == YapDatabaseViewChangeInsert)
		{
			// Although a group was inserted, the user may have been allowing empty sections.
			// If so, we shouldn't emit an insertSection change.
			
			if ([originalMappings sectionForGroup:sectionChange->group] == NSNotFound)
			{
				// Emit
				i++;
			}
			else
			{
				// Don't emit
				[sectionChanges removeObjectAtIndex:i];
			}
		}
	}
}

+ (void)getSectionChanges:(NSArray **)sectionChangesPtr
               rowChanges:(NSArray **)rowChangesPtr
	 withOriginalMappings:(YapDatabaseViewMappings *)originalMappings
			finalMappings:(YapDatabaseViewMappings *)finalMappings
			  fromChanges:(NSArray *)changes
{
	// PRE-PROCESSING
	//
	// Remove any items from the changes array that don't concern us.
	// For example, if mappings only contain groupA & groupB,
	// then we can ignore changes in groupC.
	
	NSMutableArray *sectionChanges = [NSMutableArray arrayWithCapacity:[finalMappings numberOfSections]];
	NSMutableArray *rowChanges = [NSMutableArray arrayWithCapacity:[changes count]];
	
	for (id change in changes)
	{
		if ([change isKindOfClass:[YapDatabaseViewSectionChange class]])
		{
			__unsafe_unretained YapDatabaseViewSectionChange *immutableSectionChange =
			    (YapDatabaseViewSectionChange *)change;
			
			if (immutableSectionChange->type == YapDatabaseViewChangeDelete)
			{
				NSUInteger originalSection = [originalMappings sectionForGroup:immutableSectionChange->group];
				
				if (originalSection != NSNotFound)
				{
					YapDatabaseViewSectionChange *sectionChange = [immutableSectionChange copy];
					
					sectionChange->originalSection = originalSection;
					[sectionChanges addObject:sectionChange];
					
					if (sectionChange->isReset)
					{
						// Special case processing.
						//
						// Most of the time, groups are deleted because the last key within the group was removed.
						// Thus a regular section delete is accompanied by all the corresponding row deletes.
						// But if the user invokes:
						//
						// - removeAllObjects                 (YapDatabase)
						// - removeAllObjectsInAllCollections (YapCollectionsDatabase)
						//
						// then we get a section delete that isn't accompanies by the corresponding row deletes.
						// This operation is flagged via isReset.
						//
						// So here's what we do in this situation:
						// - remove any previous row changes within the group
						// - manually inject all the proper row deletes
						
						__unsafe_unretained YapDatabaseViewRowChange *rowChange;
						
						for (NSUInteger i = [rowChanges count]; i > 0; i--)
						{
							rowChange = [rowChanges objectAtIndex:(i-1)];
							
							if (rowChange->type == YapDatabaseViewChangeDelete)
							{
								if ([rowChange->originalGroup isEqualToString:sectionChange->group])
								{
									[rowChanges removeObjectAtIndex:(i-1)];
								}
							}
							else // YapDatabaseViewChangeInsert || YapDatabaseViewChangeUpdate
							{
								if ([rowChange->finalGroup isEqualToString:sectionChange->group])
								{
									[rowChanges removeObjectAtIndex:(i-1)];
								}
							}
						}
						
						NSUInteger prevRowCount = [originalMappings numberOfItemsInGroup:sectionChange->group];
						
						while (prevRowCount > 0)
						{
							YapDatabaseViewRowChange *rowChange =
							    [YapDatabaseViewRowChange deleteKey:nil
							                                inGroup:sectionChange->group
							                                atIndex:(prevRowCount-1)];
							
							rowChange->originalSection = originalSection;
							
							[rowChanges addObject:rowChange];
							prevRowCount--;
						}
					}
				}
			}
			else if (immutableSectionChange->type == YapDatabaseViewChangeInsert)
			{
				NSUInteger finalSection = [finalMappings sectionForGroup:immutableSectionChange->group];
				
				if (finalSection != NSNotFound)
				{
					YapDatabaseViewSectionChange *sectionChange = [immutableSectionChange copy];
					
					sectionChange->finalSection = finalSection;
					[sectionChanges addObject:sectionChange];
				}
			}
		}
		else
		{
			__unsafe_unretained YapDatabaseViewRowChange *immutableRowChange = (YapDatabaseViewRowChange *)change;
			
			if (immutableRowChange->type == YapDatabaseViewChangeDelete)
			{
				NSUInteger originalSection = [originalMappings sectionForGroup:immutableRowChange->originalGroup];
				
				if (originalSection != NSNotFound)
				{
					YapDatabaseViewRowChange *rowChange = [immutableRowChange copy];
					
					rowChange->originalSection = originalSection;
					[rowChanges addObject:rowChange];
				}
			}
			else if (immutableRowChange->type == YapDatabaseViewChangeInsert)
			{
				NSUInteger finalSection = [finalMappings sectionForGroup:immutableRowChange->finalGroup];
				
				if (finalSection != NSNotFound)
				{
					YapDatabaseViewRowChange *rowChange = [immutableRowChange copy];
					
					rowChange->finalSection = finalSection;
					[rowChanges addObject:rowChange];
				}
			}
			else if (immutableRowChange->type == YapDatabaseViewChangeUpdate)
			{
				NSUInteger originalSection = [originalMappings sectionForGroup:immutableRowChange->originalGroup];
				NSUInteger finalSection = [finalMappings sectionForGroup:immutableRowChange->finalGroup];
				
				if ((originalSection != NSNotFound) || (finalSection != NSNotFound))
				{
					YapDatabaseViewRowChange *rowChange = [immutableRowChange copy];
					
					rowChange->originalSection = originalSection;
					rowChange->finalSection = finalSection;
					[rowChanges addObject:rowChange];
				}
			}
		}
	}
	
	//
	// PROCESSING & CONSOLIDATION
	//
	// This is where the magic happens.
	
	[self processAndConsolidateRowChanges:rowChanges];
	
	[self processAndConsolidateSectionChanges:sectionChanges];
	
	//
	// POST-PROCESSING
	//
	// This is where we apply the mappings to filter & alter the changeset.

	[self postProcessAndFilterRowChanges:rowChanges
	                withOriginalMappings:originalMappings
	                       finalMappings:finalMappings];
	
	[self postProcessAndFilterSectionChanges:sectionChanges
	                    withOriginalMappings:originalMappings
	                           finalMappings:finalMappings];
	
	if (sectionChangesPtr) *sectionChangesPtr = sectionChanges;
	if (rowChangesPtr) *rowChangesPtr = rowChanges;
}

@end
