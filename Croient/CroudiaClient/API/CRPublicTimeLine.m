//  Copyright 2013 happy_ryo
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "CRPublicTimeLine.h"


@implementation CRPublicTimeLine {
    NSString *_maxId;
    BOOL _trimUser;
    BOOL _includeEntities;

    void (^LoadFinished)(NSArray *statusArray);
}

- (id)initWithTrimUser:(BOOL)trimUser includeEntities:(BOOL)includeEntities LoadFinished:(void (^)(NSArray *))aLoadFinished {
    self = [super init];
    if (self) {
        _trimUser = trimUser;
        _includeEntities = includeEntities;
        LoadFinished = aLoadFinished;
    }

    return self;
}


- (NSString *)path {
    return @"statuses/public_timeline.json";
}

- (enum CR_REQUEST_METHOD)HTTPMethod {
    return GET;
}

- (NSDictionary *)requestParams {
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionary];
    if (_maxId != nil) {
        [mutableDictionary setValue:_maxId forKey:@"since_id"];
    }

    if (_trimUser) {
        [mutableDictionary setValue:@"true" forKey:@"trim_user"];
    }

    if (_includeEntities) {
        [mutableDictionary setValue:@"true" forKey:@"include_entities"];
    }

    return mutableDictionary;
}

- (void)parseResponse:(NSData *)data error:(NSError *)error {
    [super parseResponse:data error:error];
    if (data != nil) {
        id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        if ([obj isKindOfClass:[NSArray class]]) {
            NSArray *statusArray = obj;
            _maxId = [[statusArray objectAtIndex:0] valueForKey:@"id"];
            LoadFinished(statusArray);
            return;
        }
    }
    LoadFinished(@[]);
}

- (NSURLRequestCachePolicy)cachePolicy {
    return [super cachePolicy];
}

@end