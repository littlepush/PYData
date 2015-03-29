//
//  PYObject.m
//  PYData
//
//  Created by Push Chen on 8/19/13.
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

#import "PYObject.h"
#import "PYCore.h"
#import "PYGlobalDataCache+List.h"

static NSString *_keyObjectId = @"id";
static NSString *_keyName = @"name";
static NSString *_keyUpdateTime = @"updateAt";

@implementation PYObject

+ (void)setKeyForObjectId:(NSString *)key
{
    _keyObjectId = [key copy];
}
+ (void)setKeyForName:(NSString *)key
{
    _keyName = [key copy];
}
+ (void)setKeyForUpdateTime:(NSString *)key
{
    _keyUpdateTime = [key copy];
}

@synthesize objectId, updateTime, name, type;
@dynamic objectIdentify;
@dynamic objectClass;
- (NSString *)objectIdentify
{
    return [NSString stringWithFormat:@"%@+%@",
            NSStringFromClass([self objectClass]), self.objectId];
}

- (Class)objectClass
{
    return [self class];
}

- (id)init
{
    self = [super init];
    if ( self ) {
        self.objectId = @"";
        self.updateTime = [PYDate date];
        self.name = @"";
        self.type = NSStringFromClass([self class]);
    }
    return self;
}
#pragma mark --
#pragma mark Object

+ (NSString *)identifyOfId:(NSString *)objectId
{
    return [NSString stringWithFormat:@"%@+%@", [self class], objectId];
}

// Equal
- (BOOL)isEqual:(id)object
{
    if ( ![object isKindOfClass:[PYObject class]] ) return NO;
    PYObject *_otherObject = (PYObject *)object;
    if ( ![_otherObject.type isEqualToString:self.type] ) return NO;
    return [_otherObject.objectId isEqualToString:self.objectId];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{objectId:%@; name:%@; type:%@}",
            self.objectId, self.name, self.type];
}

#pragma mark --
#pragma mark Override

- (void)objectFromJsonDict:(NSDictionary *)jsonDict
{
    self.objectId = [jsonDict stringObjectForKey:_keyObjectId withDefaultValue:@""];
    if ( [self.objectId length] == 0 ) {
        self.objectId = PYIntToString([jsonDict tryIntObjectForKey:_keyObjectId withDefaultValue:0]);
    }
    
    if ( [jsonDict objectForKey:@"updatedAt"] ) {
        self.updateTime = [PYDate dateWithDate:[jsonDict jsDateObjectForKey:@"updatedAt"]];
    } else {
        NSDate *_time = [jsonDict utcDateObjectForKey:_keyUpdateTime];
        if ( _time.timeIntervalSince1970 == 0.f ) {
            _time = [jsonDict snsDateObjectForKey:_keyUpdateTime];
            if ( _time.timeIntervalSince1970 == 0.f ) {
                _time = [jsonDict mDateObjectForKey:_keyUpdateTime];
            }
        }
    }
    self.name       = [jsonDict stringObjectForKey:_keyName withDefaultValue:@""];
    self.type       = NSStringFromClass([self class]);
}

- (NSDictionary *)objectToJsonDict
{
    // Return an empty dictionary.
    return @{
             _keyObjectId           :([self.objectId length] ? self.objectId : @""),
             _keyName               :([self.name length] ? self.name : @""),
             @"type"                :([self.type length] ? self.type : @""),
             _keyUpdateTime         :PYIntToString((int)[self.updateTime timestamp])
             };
}

@end

@implementation PYGlobalDataCache (PYObject)

- (void)setPYObject:(PYObject *)value forKey:(NSString *)key
{
    [self setObject:[value objectToJsonDict] forKey:key];
}

- (void)setPYObject:(PYObject *)value forKey:(NSString *)key expire:(id<PYDate>)expire
{
    [self setObject:[value objectToJsonDict] forKey:key expire:expire];
}

- (PYObject *)PYObjectForKey:(NSString *)key
{
    NSDictionary *_result = (NSDictionary *)[self objectForKey:key];
    if ( [_result isKindOfClass:[NSDictionary class]] == NO ) return nil;
    NSString *_type = [_result stringObjectForKey:@"type" withDefaultValue:@""];
    if ( [_type length] == 0 ) return nil;  // not support type
    Class _cls = NSClassFromString(_type);
    if ( _cls == NULL ) return nil;     // cannot find the object's type
    PYObject *_object = [_cls new];
    @try {
        [_object objectFromJsonDict:_result];
        return _object;
    } @catch( NSException *ex ) {
        return nil;
    }
}
/*!
 append new object to the end of the list.
 the object will be inserted to the cache.
 */
- (void)appendPYObject:(PYObject *)value forKey:(NSString *)key tolist:(NSString *)listKey
{
    [self appendObject:[value objectToJsonDict] forKey:key tolist:listKey];
}
/*!
 insert new object at the head of the list.
 */
- (void)insertPYObjectAtHead:(PYObject *)value forKey:(NSString *)key tolist:(NSString *)listKey
{
    [self insertObjectAtHead:[value objectToJsonDict] forKey:key tolist:listKey];
}
/*!
 insert the object before specified object, if 'objKey' is empty, means insert a root node.
 */
- (void)insertPYObject:(PYObject *)value forKey:(NSString *)key before:(NSString *)objKey tolist:(NSString *)listKey
{
    [self insertObject:[value objectToJsonDict] forKey:key before:objKey tolist:listKey];
}
/*!
 insert the object after specified object, if 'objKey' is empty, means append to the last.
 */
- (void)insertPYObject:(PYObject *)value forKey:(NSString *)key after:(NSString *)objKey tolist:(NSString *)listKey
{
    [self insertObject:[value objectToJsonDict] forKey:key after:objKey tolist:listKey];
}
/*!
 get all objects in the list.
 */
- (NSArray *)listPYObjectsForKey:(NSString *)key
{
    NSArray *_objectList = [self listObjectsForKey:key];
    NSMutableArray *_pyobjList = [NSMutableArray array];
    for ( NSDictionary *_result in _objectList ) {
        if ( [_result isKindOfClass:[NSDictionary class]] == NO ) continue;
        NSString *_type = [_result stringObjectForKey:@"type" withDefaultValue:@""];
        if ( [_type length] == 0 ) continue;    // not support type
        Class _cls = NSClassFromString(_type);
        if ( _cls == NULL ) continue;           // cannot find the object's type
        PYObject *_object = [_cls new];
        @try {
            [_object objectFromJsonDict:_result];
            [_pyobjList addObject:_object];
        } @catch( NSException *ex ) {
            continue;
        }
    }
    return _pyobjList;
}

@end

// @littlepush
// littlepush@gmail.com
// PYLab
