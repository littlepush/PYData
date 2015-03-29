//
//  PYGlobalDataCache+List.h
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

#import "PYGlobalDataCache.h"

@interface PYGlobalDataCache (List)

// Manage a list in the cache
/*!
 create a list with specified key.
 if the `key` is existed, just return.
 */
- (void)createListForKey:(NSString *)key;
/*!
 append new object to the end of the list.
 the object will be inserted to the cache.
 */
- (void)appendObject:(id<NSCoding>)value forKey:(NSString *)key tolist:(NSString *)listKey;
/*!
 insert new object at the head of the list.
 */
- (void)insertObjectAtHead:(id<NSCoding>)value forKey:(NSString *)key tolist:(NSString *)listKey;
/*!
 insert the object before specified object, if 'objKey' is empty, means insert a root node.
 */
- (void)insertObject:(id<NSCoding>)value forKey:(NSString *)key before:(NSString *)objKey tolist:(NSString *)listKey;
/*!
 insert the object after specified object, if 'objKey' is empty, means append to the last.
 */
- (void)insertObject:(id<NSCoding>)value forKey:(NSString *)key after:(NSString *)objKey tolist:(NSString *)listKey;
/*!
 remove the object from the list, but not remove the object from the cache.
 */
- (void)removeObject:(NSString *)key oflist:(NSString *)listkey;
/*!
 remove the object from the list and the cache.
 */
- (void)removeAndEraseObject:(NSString *)key oflist:(NSString *)listkey;
/*!
 clear all index in the list, not remove any object
 */
- (void)clearListForKey:(NSString *)key;
/*!
 remove all object from the list, and erase the objects from cache.
 */
- (void)eraseListForKey:(NSString *)key;
/*!
 delete the list key from the cache, leave the objects untouched.
 */
- (void)destroyListForKey:(NSString *)key;
/*!
 get all objects in the list.
 */
- (NSArray *)listObjectsForKey:(NSString *)key;

@end

// @littlepush
// littlepush@gmail.com
// PYLab
