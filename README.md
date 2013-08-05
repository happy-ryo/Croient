Croient
=======

Croudia の API を叩くための物


## 使い方

### Croudia へのアプリケーション登録

まずは Croudia の開発者ページで、アプリケーションの登録をします。
[アプリケーション管理](https://developer.croudia.com/apps)

Redirect URI にはアプリケーション側の認証用 URLScheme として登録予定の文字列を設定してください。（hogecroudia:// 等）


### プロジェクト側で必要な設定

1. 認証用 URLScheme に Redirect URI で指定した文字列と同じ物を登録する。
2. [ここから](https://github.com/happy-ryo/Croient)ソースを取得してプロジェクトに追加する。
3. CROAuth.m 内の CONSUMER_KEY と CONSUMER_SECRET に Croudia 側から払い出された Consumer key と Consumer secret をそれぞれ設定する。

### 認証

CROAuth を UIApplicationDelegate を採用したクラスにプロパティとして持ち、起動時にインスタンスを生成しておきます。同時に URLScheme からの起動時に実行されるメソッド内で CROAuth の URLHandler: が呼ばれるようにしておきます。

```

#import <UIKit/UIKit.h>

@class CROAuth;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property(nonatomic, strong) CROAuth *oAuth;
@end


@implementation AppDelegate {
    CROAuth *_oAuth;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    _oAuth = [[CROAuth alloc] init];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [_oAuth URLHandler:url];
    return YES;
}

@end

```

OAuth 認証したい場所で以下のように書きます。

```

AppDelegate *appDelegate = (AppDelegate *) [UIApplication sharedApplication].delegate;
// 認証されているかどうかのチェック
if (appDelegate.oAuth.authorized) {
    // 認証されていた場合の処理
} else {
    // 認証を実行する
    [appDelegate.oAuth authorize:^(BOOL result) {
        // 認証後の処理
    }];
}

```

該当部分が実行されると、 Safari が立ち上がり、Croudia のログイン認証とアプリケーション連携を行うページが表示されます。 連携を承認することで URLScheme を介して必要な条件がアプリケーション側に引き渡され、 OAuth の認証情報が行われます。

### APIリクエスト

サンプルとしてあげているソースでは、とりあえず Public Timeline が取得できる例をあげました。
基本的には CRAPIRequest を継承し、 CRPath を実装して、インスタンス化したクラスの ``` load``` メソッドを実行することで ``` -(void)parseResponse:(NSData *)data error:(NSError *)error{};  ``` でAPI問い合わせの結果を受け取ることが出来ます。

```

@interface CRPublicTimeLine : CRAPIRequest
- (id)initWithTrimUser:(BOOL)trimUser includeEntities:(BOOL)includeEntities LoadFinished:(void (^)(NSArray *))aLoadFinished;


@end


@implementation CRPublicTimeLine {
    NSString *_maxId;
    BOOL _trimUser;
    BOOL _includeEntities;

    void (^LoadFinished)(NSArray *statusArray);
}

// APIへ渡す引数は自分で定義した init から渡す。
- (id)initWithTrimUser:(BOOL)trimUser includeEntities:(BOOL)includeEntities LoadFinished:(void (^)(NSArray *))aLoadFinished {
    self = [super init];
    if (self) {
        _trimUser = trimUser;
        _includeEntities = includeEntities;
        LoadFinished = aLoadFinished;
    }

    return self;
}

// APIのパスを返す
- (NSString *)path {
    return @"statuses/public_timeline.json";
}

// GETかPOSTか
- (enum CR_REQUEST_METHOD)HTTPMethod {
    return GET;
}

// APIに渡す引数を NSDictionary で返す。
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

// APIからのレスポンスを処理する。
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

// キャッシュポリシーを設定する
- (NSURLRequestCachePolicy)cachePolicy {
    return [super cachePolicy];
}

@end

```
