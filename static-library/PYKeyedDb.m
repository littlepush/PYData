//
//  PYKeyedDb.m
//  PYData
//
//  Created by Push Chen on 1/19/13.
//  Copyright (c) 2013 Push Lab. All rights reserved.
//

/*
 LGPL V3 Lisence
 This file is part of cleandns.
 
 PYData is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 PYData is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with cleandns.  If not, see <http://www.gnu.org/licenses/>.
 */

/*
 LISENCE FOR IPY
 COPYRIGHT (c) 2013, Push Chen.
 ALL RIGHTS RESERVED.
 
 REDISTRIBUTION AND USE IN SOURCE AND BINARY
 FORMS, WITH OR WITHOUT MODIFICATION, ARE
 PERMITTED PROVIDED THAT THE FOLLOWING CONDITIONS
 ARE MET:
 
 YOU USE IT, AND YOU JUST USE IT!.
 WHY NOT USE THIS LIBRARY IN YOUR CODE TO MAKE
 THE DEVELOPMENT HAPPIER!
 ENJOY YOUR LIFE AND BE FAR AWAY FROM BUGS.
 */

#import "PYKeyedDb.h"
#include <sqlite3.h>
#import "PYDataPredefination.h"

static NSMutableDictionary			*_gPYKeyedDBCache;
static Class                        _keyedDbDateClass;

// The Row
@implementation PYKeyedDbRow
@synthesize value, expire;
@end

@interface PYKeyedDb ()
{
    sqlite3				*_innerDb;
    NSString            *_dbPath;
    
    PYSqlStatement      *_insertStat;
    PYSqlStatement      *_updateStat;
    PYSqlStatement      *_deleteStat;
    PYSqlStatement      *_countStat;
    PYSqlStatement      *_selectStat;
    PYSqlStatement      *_checkStat;
    
    PYSqlStatement      *_selectKeys;
    PYSqlStatement      *_searchKeys;
    
    NSString            *_cacheTbName;
}

- (BOOL)initializeDbWithPath:(NSString *)dbPath cacheTableName:(NSString *)cacheTbname;
- (BOOL)initializeDbWithPath:(NSString *)dbPath;

// Create the db at specified path if the database is not existed.
- (BOOL)createDbWithPath:(NSString *)dbPath cacheTableName:(NSString *)cacheTbname;
- (BOOL)createDbWithPath:(NSString *)dbPath;

@end

@implementation PYKeyedDb

+ (void)initialize
{
	// Initialize the global cache
	_gPYKeyedDBCache = [NSMutableDictionary dictionary];
    _keyedDbDateClass = [PYDate class];
}

+ (void)setKeyedDbDateClass:(Class)dateClass
{
    _keyedDbDateClass = dateClass;
}

+ (PYKeyedDb *)keyedDbWithPath:(NSString *)dbPath cacheTableName:(NSString *)cacheTbname
{
	NSString *_dbKey = [dbPath md5sum];
	if ( [_gPYKeyedDBCache objectForKey:_dbKey] != nil ) {
		return [_gPYKeyedDBCache objectForKey:_dbKey];
	}
	
	PYKeyedDb *_newDb = [[PYKeyedDb alloc] init];
	if ( [_newDb initializeDbWithPath:dbPath cacheTableName:cacheTbname] == NO ) {
		if ( [_newDb createDbWithPath:dbPath cacheTableName:cacheTbname] == NO ) return nil;
	}
    _newDb->_cacheTbName = [cacheTbname copy];
	[_gPYKeyedDBCache setObject:_newDb forKey:_dbKey];
	return _newDb;
}

+ (PYKeyedDb *)keyedDbWithPath:(NSString *)dbPath
{
    return [PYKeyedDb keyedDbWithPath:dbPath cacheTableName:kKeyedDBTableName];
}

// 
- (id)init
{
	self = [super init];
	if ( self ) {
		// Do something if needed.
	}
	return self;
}

- (void)dealloc
{
	if ( _innerDb != NULL ) sqlite3_close(_innerDb);
}

- (BOOL)initializeDbWithPath:(NSString *)dbPath cacheTableName:(NSString *)cacheTbname
{
    _dbPath = dbPath;
	NSFileManager *fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:dbPath] ) {
		return NO;
	}
    
	if (sqlite3_open([dbPath UTF8String], &_innerDb) == SQLITE_OK) {
        char *_errorMsg = NULL;
        sqlite3_exec(_innerDb, "PRAGMA synchronous = OFF", NULL, NULL, &_errorMsg);
        if ( _errorMsg != NULL ) {
            NSLog(@"Failed to set the sqlite to be async mode: %s", _errorMsg);
            _errorMsg = NULL;
        }
        sqlite3_exec(_innerDb, "PRAGMA journal_mode = MEMORY", NULL, NULL, &_errorMsg);
        if ( _errorMsg != NULL ) {
            NSLog(@"Failed to set the journal_mode to memory: %s", _errorMsg);
            _errorMsg = NULL;
        }
        
        // Initialize the sql statements
        
        // Insert
        NSString *_insertSql = [NSString stringWithFormat:
                                @"INSERT INTO %@ VALUES(?, ?, ?);", cacheTbname];
        _insertStat = [PYSqlStatement sqlStatementWithSQL:_insertSql];
        if ( ![_insertStat prepareStatementWithDB:(void *)(_innerDb)] ) return NO;

        // Update
        NSString *_updateSql = [NSString stringWithFormat:
                                @"UPDATE %@ set dbValue=?, dbExpire=? WHERE dbKey=?", cacheTbname];
        _updateStat = [PYSqlStatement sqlStatementWithSQL:_updateSql];
        if ( ![_updateStat prepareStatementWithDB:(void *)(_innerDb)] ) return NO;
        
        // Delete
        NSString *_deleteSql = [NSString stringWithFormat:
                                @"DELETE FROM %@ WHERE dbKey=?", cacheTbname];
        _deleteStat = [PYSqlStatement sqlStatementWithSQL:_deleteSql];
        if ( ![_deleteStat prepareStatementWithDB:(void *)(_innerDb)] ) return NO;
        
        // Check
        NSString *_checkSql = [NSString stringWithFormat:
                               @"SELECT dbKey FROM %@ WHERE dbKey=?", cacheTbname];
        _checkStat = [PYSqlStatement sqlStatementWithSQL:_checkSql];
        if ( ![_checkStat prepareStatementWithDB:(void *)(_innerDb)] ) return NO;
        
        // Select
        NSString *_selectSql = [NSString stringWithFormat:
                                @"SELECT dbValue, dbExpire FROM %@ WHERE dbKey=?", cacheTbname];
        _selectStat = [PYSqlStatement sqlStatementWithSQL:_selectSql];
        if ( ![_selectStat prepareStatementWithDB:(void *)(_innerDb)] ) return NO;
        
        // Count
        NSString *_countSql = [NSString stringWithFormat:
                               @"SELECT COUNT(dbKey) FROM %@", cacheTbname];
        _countStat = [PYSqlStatement sqlStatementWithSQL:_countSql];
        if ( ![_countStat prepareStatementWithDB:(void *)(_innerDb)] ) return NO;
        
        // Select Keys
        NSString *_selectKeySql = [NSString stringWithFormat:
                                   @"SELECT dbKey FROM %@", cacheTbname];
        _selectKeys = [PYSqlStatement sqlStatementWithSQL:_selectKeySql];
        if ( ![_selectKeys prepareStatementWithDB:(void *)(_innerDb)] ) return NO;
        
        // Search keys
        NSString *_searchKeySql = [NSString stringWithFormat:
                                   @"SELECT dbKey FROM %@ WHERE dbKey LIKE \'?\'", cacheTbname];
        _searchKeys = [PYSqlStatement sqlStatementWithSQL:_searchKeySql];
        if ( ![_searchKeys prepareStatementWithDB:(void *)(_innerDb)] ) return NO;
		return YES;
	} else {
        NSLog(@"Failed to open sqlite at path: %@, error: %s", dbPath, sqlite3_errmsg(_innerDb));
    }
	return NO;
}

- (BOOL)initializeDbWithPath:(NSString *)dbPath
{
    return [self initializeDbWithPath:dbPath cacheTableName:kKeyedDBTableName];
}

// Create the db at specified path if the database is not existed.
- (BOOL)createDbWithPath:(NSString *)dbPath cacheTableName:(NSString *)cacheTbname
{
    _dbPath = dbPath;
	NSFileManager *fm = [NSFileManager defaultManager];
	if ( [fm fileExistsAtPath:dbPath] ) return NO;
	// Create the empty file
	[fm createFileAtPath:dbPath contents:nil attributes:nil];
	if ( sqlite3_open([dbPath UTF8String], &_innerDb) != SQLITE_OK )
		return NO;
		
	// Create the table
    NSString *_ctsql = [NSString stringWithFormat:
                        @"CREATE TABLE %@("             \
                        @"dbKey TEXT PRIMARY KEY,"		\
                        @"dbValue BLOB,"                \
                        @"dbExpire INT);", cacheTbname];
	char *_error;
	if( sqlite3_exec(_innerDb, [_ctsql UTF8String], nil, nil, &_error) != SQLITE_OK ) {
		sqlite3_close(_innerDb);
		_innerDb = NULL;
		[fm removeItemAtPath:dbPath error:nil];
		return NO;
	}
	
	sqlite3_close(_innerDb);
	return [self initializeDbWithPath:dbPath cacheTableName:cacheTbname];
}
- (BOOL)createDbWithPath:(NSString *)dbPath
{
    return [self createDbWithPath:dbPath cacheTableName:kKeyedDBTableName];
}

- (BOOL)beginBatchOperation
{
    char *_errorMsg = NULL;
    sqlite3_exec(_innerDb, "BEGIN TRANSACTION", NULL, NULL, &_errorMsg);
    if ( _errorMsg != NULL ) {
        PYLog(@"Failed to begin transaction");
        return NO;
    }
    return YES;
}

- (BOOL)endBatchOperation
{
    char *_errorMsg = NULL;
    sqlite3_exec(_innerDb, "END TRANSACTION", NULL, NULL, &_errorMsg);
    if ( _errorMsg != NULL ) {
        PYLog(@"Failed to end transaction");
        return NO;
    }
    return YES;
}

- (BOOL)addValue:(NSData *)formatedValue forKey:(NSString *)key expireOn:(id<PYDate>)expire
{
    PYSingletonLock
    [_insertStat resetBinding];
	BOOL _statue = NO;
    [_insertStat bindInOrderText:key];
    [_insertStat bindInOrderData:formatedValue];
    [_insertStat bindInOrderInt:(int)expire.timestamp];
    if ( [_insertStat step] == SQLITE_DONE ) {
//    if (sqlite3_step(_insertStat.statement) == SQLITE_DONE ) {
        _statue = YES;
    }
	return _statue;
    PYSingletonUnLock
}

- (BOOL)updateValue:(NSData *)formatedValue forKey:(NSString *)key expireOn:(id<PYDate>)expire
{
    PYSingletonLock
    [_updateStat resetBinding];
	BOOL _statue = NO;
    [_updateStat bindInOrderData:formatedValue];
    [_updateStat bindInOrderInt:(int)expire.timestamp];
    [_updateStat bindInOrderText:key];
    if ( [_updateStat step] == SQLITE_DONE ) {
//    if (sqlite3_step(_updateStat.statement) == SQLITE_DONE ) {
        _statue = YES;
    }
	return _statue;
    PYSingletonUnLock
}

- (int)deleteValueForKey:(NSString *)key
{
	// Delete
    PYSingletonLock
    [_deleteStat resetBinding];
    [_deleteStat bindInOrderText:key];
//    sqlite3_step(_deleteStat.statement);
    [_deleteStat step];
    return sqlite3_changes(_innerDb);
    PYSingletonUnLock
}

- (BOOL)containsKey:(NSString *)key
{
	// Select
    PYSingletonLock
    [_checkStat resetBinding];
	BOOL _statue = NO;
    [_checkStat bindInOrderText:key];
    if ( [_checkStat step] == SQLITE_ROW ) {
//    if (sqlite3_step(_checkStat.statement) == SQLITE_ROW ) {
        _statue = YES;
    }
	return _statue;
    PYSingletonUnLock
}

- (PYKeyedDbRow *)valueForKey:(NSString *)key
{
    PYSingletonLock
    [_selectStat resetBinding];
    [_selectStat bindInOrderText:key];
    if ( [_selectStat step] == SQLITE_ROW )
//    if (sqlite3_step(_selectStat.statement) == SQLITE_ROW )
    {
        [_selectStat prepareForReading];
        NSData *_value = [_selectStat getInOrderData];
        id<PYDate> _expire = [_keyedDbDateClass dateWithTimestamp:[_selectStat getInOrderInt]];
        PYKeyedDbRow *_row = [PYKeyedDbRow object];
        _row.value = _value;
        _row.expire = _expire;
        return _row;
    }
	return nil;
    PYSingletonUnLock
}

- (NSArray *)keysLike:(NSString *)pattern
{
    PYSingletonLock
    [_searchKeys resetBinding];
    [_searchKeys bindInOrderText:pattern];
    NSMutableArray *_result = [NSMutableArray array];
    while ( [_searchKeys step] == SQLITE_ROW ) {
//    while ( sqlite3_step(_searchKeys.statement) == SQLITE_ROW ) {
        [_searchKeys prepareForReading];
        [_result addObject:[_searchKeys getInOrderText]];
    }
    return _result;
    PYSingletonUnLock
}

- (int)count
{
    PYSingletonLock
    [_countStat resetBinding];
    if ( [_countStat step] == SQLITE_ROW )
//    if (sqlite3_step(_countStat.statement) == SQLITE_ROW )
    {
        [_countStat prepareForReading];
        return [_countStat getInOrderInt];
    }
	return -1;
    PYSingletonUnLock
}

@dynamic allKeys;
- (NSArray *)allKeys
{
    PYSingletonLock
    [_selectKeys resetBinding];
    NSMutableArray *_result = [NSMutableArray array];
    while ( [_selectKeys step] == SQLITE_ROW ) {
//    while ( sqlite3_step(_selectKeys.statement) == SQLITE_ROW ) {
        [_selectKeys prepareForReading];
        [_result addObject:[_selectKeys getInOrderText]];
    }
    return _result;
    PYSingletonUnLock
}

- (void)clearDBData
{
	if ( _innerDb != NULL ) sqlite3_close(_innerDb);
    _innerDb = NULL;
    NSError *_error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:_dbPath error:&_error];
    if ( _error ) @throw _error;
    [self createDbWithPath:_dbPath cacheTableName:_cacheTbName];
}

@end

// @littlepush
// littlepush@gmail.com
// PYLab
