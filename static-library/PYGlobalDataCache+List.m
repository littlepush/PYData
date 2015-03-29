//
//  PYGlobalDataCache+List.m
//  PYData
//
//  Created by ChenPush on 3/29/15.
//  Copyright (c) 2015 Push Lab. All rights reserved.
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

#import "PYGlobalDataCache+List.h"

@implementation PYGlobalDataCache (List)

/*!
 create a list with specified key.
 if the `key` is existed, just return.
 */
- (void)createListForKey:(NSString *)key
{
    PYSingletonLock
    NSString *_internal_list_key = [NSString stringWithFormat:@"%@#^list", key];
    if ( [self containsKey:_internal_list_key] ) return;
    
    // Set count
    [self setObject:@(0) forKey:_internal_list_key];
    // Set root key
    NSString *_list_first_key = [_internal_list_key stringByAppendingString:@"^first"];
    [self setObject:@"" forKey:_list_first_key];
    // Set last key
    NSString *_list_last_key = [_internal_list_key stringByAppendingString:@"^last"];
    [self setObject:@"" forKey:_list_last_key];
    PYSingletonUnLock
}
- (NSInteger)countOfList:(NSString *)key
{
    PYSingletonLock
    NSString *_internal_list_key = [NSString stringWithFormat:@"%@#^list", key];
    return [[self objectForKey:_internal_list_key] integerValue];
    PYSingletonUnLock
}
/*!
 append new object to the end of the list.
 the object will be update to the cache.
 */
- (void)appendObject:(id<NSCoding>)value forKey:(NSString *)key tolist:(NSString *)listKey
{
    PYSingletonLock
    NSString *_internal_list_key = [NSString stringWithFormat:@"%@#^list", listKey];
    
    // Update list count
    int _count = [[self objectForKey:_internal_list_key] intValue];
    _count += 1;
    [self setObject:@(_count) forKey:_internal_list_key];
    
    // Update old last object
    NSString *_list_last_key = [_internal_list_key stringByAppendingString:@"^last"];
    NSString *_lastNodeKey = [self objectForKey:_list_last_key];
    if ( [_lastNodeKey length] == 0 ) {
        // empty list, update first key
        NSString *_list_first_key = [_internal_list_key stringByAppendingString:@"^first"];
        [self setObject:key forKey:_list_first_key];
    }
    // Update or insert the object
    [self setObject:value forKey:key];
    // Update last node info
    NSString *_prev_key = [_internal_list_key stringByAppendingFormat:@"^prev^%@", key];
    [self setObject:_lastNodeKey forKey:_prev_key];
    NSString *_next_key = [_internal_list_key stringByAppendingFormat:@"^next^%@", key];
    [self setObject:@"" forKey:_next_key];
    
    // Update old last node
    if ( [_lastNodeKey length] > 0 ) {
        NSString *_old_next_key = [_internal_list_key stringByAppendingFormat:@"^next^%@", _lastNodeKey];
        [self setObject:key forKey:_old_next_key];
    }
    // Update last key
    [self setObject:key forKey:_list_last_key];
    PYSingletonUnLock
}
/*!
 insert new object at the head of the list.
 */
- (void)insertObjectAtHead:(id<NSCoding>)value forKey:(NSString *)key tolist:(NSString *)listKey
{
    PYSingletonLock
    NSString *_internal_list_key = [NSString stringWithFormat:@"%@#^list", listKey];
    
    // Update list count
    int _count = [[self objectForKey:_internal_list_key] intValue];
    _count += 1;
    [self setObject:@(_count) forKey:_internal_list_key];
    
    // Update the old first object
    NSString *_list_first_key = [_internal_list_key stringByAppendingString:@"^first"];
    NSString *_firstNodeKey = [self objectForKey:_list_first_key];
    if ( [_firstNodeKey length] == 0 ) {
        // empty list, update the last key
        NSString *_list_last_key = [_internal_list_key stringByAppendingString:@"^last"];
        [self setObject:key forKey:_list_last_key];
    }
    // Update or insert the object
    [self setObject:value forKey:key];
    
    // Update last node info
    NSString *_prev_key = [_internal_list_key stringByAppendingFormat:@"^prev^%@", key];
    [self setObject:@"" forKey:_prev_key];
    NSString *_next_key = [_internal_list_key stringByAppendingFormat:@"^next^%@", key];
    [self setObject:_firstNodeKey forKey:_next_key];
    
    // Update old first node
    if ( [_firstNodeKey length] > 0 ) {
        NSString *_old_first_key = [_internal_list_key stringByAppendingFormat:@"^prev^%@", _firstNodeKey];
        [self setObject:key forKey:_old_first_key];
    }
    // Update first key
    [self setObject:key forKey:_list_first_key];
    PYSingletonUnLock
}
/*!
 insert the object before specified object, if 'objKey' is empty, means insert a root node.
 */
- (void)insertObject:(id<NSCoding>)value forKey:(NSString *)key before:(NSString *)objKey tolist:(NSString *)listKey
{
    PYSingletonLock
    if ( [objKey length] == 0 ) {
        [self insertObjectAtHead:value forKey:key tolist:listKey];
        return;
    }
    
    NSString *_internal_list_key = [NSString stringWithFormat:@"%@#^list", listKey];
    
    // Update list count
    int _count = [[self objectForKey:_internal_list_key] intValue];
    _count += 1;
    [self setObject:@(_count) forKey:_internal_list_key];
    
    // Update or insert the object
    [self setObject:value forKey:key];
    
    // Update keys
    NSString *_obj_prev_key = [_internal_list_key stringByAppendingFormat:@"^prev^%@", objKey];
    NSString *_old_prev = [self objectForKey:_obj_prev_key];
    [self setObject:key forKey:_obj_prev_key];
    NSString *_obj_prev_next_key = [_internal_list_key stringByAppendingFormat:@"^next^%@", _old_prev];
    [self setObject:key forKey:_obj_prev_next_key];
    
    NSString *_prev_key = [_internal_list_key stringByAppendingFormat:@"^prev^%@", key];
    [self setObject:_old_prev forKey:_prev_key];
    NSString *_next_key = [_internal_list_key stringByAppendingFormat:@"^next^%@", key];
    [self setObject:objKey forKey:_next_key];
    PYSingletonUnLock
}
/*!
 insert the object after specified object, if 'objKey' is empty, means append to the last.
 */
- (void)insertObject:(id<NSCoding>)value forKey:(NSString *)key after:(NSString *)objKey tolist:(NSString *)listKey
{
    PYSingletonLock
    NSString *_internal_list_key = [NSString stringWithFormat:@"%@#^list", listKey];
    
    // Update list count
    int _count = [[self objectForKey:_internal_list_key] intValue];
    _count += 1;
    [self setObject:@(_count) forKey:_internal_list_key];
    
    // Update or insert the object
    [self setObject:value forKey:key];
    
    // Update keys
    NSString *_obj_next_key = [_internal_list_key stringByAppendingFormat:@"^next^%@", objKey];
    NSString *_old_next = [self objectForKey:_obj_next_key];
    [self setObject:key forKey:_obj_next_key];
    NSString *_obj_next_prev_key = [_internal_list_key stringByAppendingFormat:@"^prev^%@", _old_next];
    [self setObject:key forKey:_obj_next_prev_key];
    
    NSString *_prev_key = [_internal_list_key stringByAppendingFormat:@"^prev^%@", key];
    [self setObject:objKey forKey:_prev_key];
    NSString *_next_key = [_internal_list_key stringByAppendingFormat:@"^next^%@", key];
    [self setObject:_old_next forKey:_next_key];
    PYSingletonUnLock
}
/*!
 remove the object from the list, but not remove the object from the cache.
 */
- (void)removeObject:(NSString *)key oflist:(NSString *)listkey
{
    PYSingletonLock
    NSString *_internal_list_key = [NSString stringWithFormat:@"%@#^list", listkey];
    
    // Update list count
    int _count = [[self objectForKey:_internal_list_key] intValue];
    _count -= 1;
    [self setObject:@(_count) forKey:_internal_list_key];
    
    NSString *_prev_key = [_internal_list_key stringByAppendingFormat:@"^prev^%@", key];
    NSString *_prev = [self objectForKey:_prev_key];
    NSString *_next_key = [_internal_list_key stringByAppendingFormat:@"^next^%@", key];
    NSString *_next = [self objectForKey:_next_key];
    if ( [_prev length] == 0 ) {
        // This is the root object
        NSString *_first_key = [_internal_list_key stringByAppendingString:@"^first"];
        [self setObject:_next forKey:_first_key];
    } else {
        NSString *_prev_next_key = [_internal_list_key stringByAppendingFormat:@"^next^%@", _prev];
        [self setObject:_next forKey:_prev_next_key];
    }
    
    if ( [_next length] == 0 ) {
        // This is the last object
        NSString *_last_key = [_internal_list_key stringByAppendingString:@"^last"];
        [self setObject:_prev forKey:_last_key];
    } else {
        NSString *_next_prev_key = [_internal_list_key stringByAppendingFormat:@"^prev^%@", _next];
        [self setObject:_prev forKey:_next_prev_key];
    }
    PYSingletonUnLock
}
/*!
 remove the object from the list and the cache.
 */
- (void)removeAndEraseObject:(NSString *)key oflist:(NSString *)listkey
{
    [self removeObject:key oflist:listkey];
    [self setObject:nil forKey:key];
}
/*!
 clear all index in the list, not remove any object
 */
- (void)clearListForKey:(NSString *)key
{
    PYSingletonLock
    NSString *_internal_list_key = [NSString stringWithFormat:@"%@#^list", key];
    NSArray *_node_keys = [self keysWithPattern:[_internal_list_key stringByAppendingFormat:@"^____^%%"]];
    
    // Clear all keys
    for ( NSString *_key in _node_keys ) {
        [self setObject:nil forKey:_key];
    }
    // Update list count
    [self setObject:@(0) forKey:_internal_list_key];
    // Set root key
    NSString *_list_first_key = [_internal_list_key stringByAppendingString:@"^first"];
    [self setObject:@"" forKey:_list_first_key];
    // Set last key
    NSString *_list_last_key = [_internal_list_key stringByAppendingString:@"^last"];
    [self setObject:@"" forKey:_list_last_key];
    PYSingletonUnLock
}
/*!
 remove all object from the list, and erase the objects from cache.
 */
- (void)eraseListForKey:(NSString *)key
{
    PYSingletonLock
    NSString *_internal_list_key = [NSString stringWithFormat:@"%@#^list", key];

    NSString *_list_first_key = [_internal_list_key stringByAppendingString:@"^first"];
    NSString *_list_last_key = [_internal_list_key stringByAppendingString:@"^last"];
    
    NSString *_node = [self objectForKey:_list_first_key];
    while ( [_node length] > 0 ) {
        [self setObject:nil forKey:_node];
        NSString *_prev_key = [_internal_list_key stringByAppendingFormat:@"^prev^%@", _node];
        [self setObject:nil forKey:_prev_key];
        NSString *_next_key = [_internal_list_key stringByAppendingFormat:@"^next^%@", _node];
        _node = [self objectForKey:_next_key];
        [self setObject:nil forKey:_next_key];
    }
    
    // Update list count
    [self setObject:@(0) forKey:_internal_list_key];
    // Set root key
    [self setObject:@"" forKey:_list_first_key];
    // Set last key
    [self setObject:@"" forKey:_list_last_key];
    PYSingletonUnLock
}
/*!
 delete the list key from the cache, leave the objects untouched.
 */
- (void)destroyListForKey:(NSString *)key
{
    [self clearListForKey:key];
    PYSingletonLock
    NSString *_internal_list_key = [NSString stringWithFormat:@"%@#^list", key];
    [self setObject:nil forKey:_internal_list_key];
    NSString *_list_first_key = [_internal_list_key stringByAppendingString:@"^first"];
    [self setObject:nil forKey:_list_first_key];
    NSString *_list_last_key = [_internal_list_key stringByAppendingString:@"^last"];
    [self setObject:nil forKey:_list_last_key];
    PYSingletonUnLock
}
/*!
 get all objects in the list.
 */
- (NSArray *)listObjectsForKey:(NSString *)key
{
    PYSingletonLock
    NSMutableArray *_array = [NSMutableArray array];
    NSString *_internal_list_key = [NSString stringWithFormat:@"%@#^list", key];
    NSString *_list_first_key = [_internal_list_key stringByAppendingString:@"^first"];
    NSString *_node = [self objectForKey:_list_first_key];
    while ( [_node length] > 0 ) {
        [_array addObject:[self objectForKey:_node]];
        NSString *_next_key = [_internal_list_key stringByAppendingFormat:@"^next^%@", _node];
        _node = [self objectForKey:_next_key];
    }
    return _array;
    PYSingletonUnLock
}

@end

// @littlepush
// littlepush@gmail.com
// PYLab
