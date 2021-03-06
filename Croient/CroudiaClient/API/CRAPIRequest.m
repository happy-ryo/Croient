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


#import "CRAPIRequest.h"
#import "NSDictionary+CRURLParams.h"
#import "CROAuth.h"
#import "CROAuthParams.h"
#import "CRHTTPLoader.h"

#define API_DOMAIN @"https://api.croudia.com/"

@implementation CRAPIRequest {
    CROAuth *_oAuth;
}

- (id)init {
    self = [super init];
    if (self) {
        _oAuth = [[CROAuth alloc] init];
    }

    return self;
}

- (void)load {
    [CRHTTPLoader loadRequest:self.createURLRequest complete:^(NSData *data) {
        [self parseResponse:data error:nil];
    }                    fail:^(NSError *error) {
        [self parseResponse:nil error:error];
    }];
}

- (NSURLRequest *)createURLRequest {
    NSMutableURLRequest *mutableURLRequest = [[NSMutableURLRequest alloc] init];
    NSString *stringURL;

    if (self.requestParams.count > 0) {
        if (self.HTTPMethod == GET) {
            stringURL = [NSString stringWithFormat:@"%@?%@", self.requestURL, self.requestParams.paramsString];
            [mutableURLRequest setHTTPMethod:@"GET"];
        } else if (self.HTTPMethod == POST) {
            stringURL = [self requestURL];
            [mutableURLRequest setHTTPBody:self.requestParams.serializeParams];
            [mutableURLRequest setHTTPMethod:@"POST"];
        }
    } else {
        stringURL = [NSString stringWithFormat:@"%@", self.requestURL];
        if (self.HTTPMethod == GET) {
            [mutableURLRequest setHTTPMethod:@"GET"];
        } else if (self.HTTPMethod == POST) {
            [mutableURLRequest setHTTPMethod:@"POST"];
        }
    }

    NSURL *url = [NSURL URLWithString:stringURL];
    [mutableURLRequest setURL:url];
    [mutableURLRequest setCachePolicy:self.cachePolicy];


    if (_oAuth.authorized) {
        NSString *authHeaderString = [NSString stringWithFormat:@"%@ %@", _oAuth.oAuthParams.tokenType, _oAuth.oAuthParams.accessToken];
        [mutableURLRequest addValue:authHeaderString forHTTPHeaderField:@"Authorization"];
    }

    return mutableURLRequest;
}

- (NSString *)requestURL {
    return [NSString stringWithFormat:@"%@%@", API_DOMAIN, self.path];
}

- (NSString *)path {
    return nil;
}

- (enum CR_REQUEST_METHOD)HTTPMethod {
    return GET;
}

- (NSDictionary *)requestParams {
    return @{};
}

- (void)parseResponse:(NSData *)data error:(NSError *)error {
    NSError *jsonError;
    if (error == nil && data != nil) {
        id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dictionary = obj;
            NSString *errorMessage = [dictionary valueForKey:@"error"];
            if ([errorMessage isEqualToString:@"invalid_client"]) {
                [self refreshToken];
                return;
            }
        }
    }

}

- (void)refreshToken {
    __weak CRAPIRequest *weakSelf = self;
    [_oAuth refreshToken:^(BOOL result) {
        if (result) {
            [weakSelf load];
        } else {
            [_oAuth authorize:^(BOOL authResult) {
                if (authResult) {
                    [weakSelf load];
                } else {
                    NSError *error = [[NSError alloc] initWithDomain:@"Croient" code:401 userInfo:@{@"info" : @"auth error."}];
                    [self parseResponse:nil error:error];
                }
            }];
        }
    }];
}

- (NSURLRequestCachePolicy)cachePolicy {
    return NSURLRequestUseProtocolCachePolicy;
}

@end