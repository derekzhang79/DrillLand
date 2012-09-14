//
//  HelloWorldLayer.m
//  Dri
//
//  Created by  on 12/08/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


// Import the interfaces
#import "DL.h"
#import "DungeonScene.h"
#import "DungeonModel.h"
#import "DungeonView.h"
#import "BlockView.h"
#import "BasicNotifierView.h"
#import "DamageNumView.h"

#pragma mark - HelloWorldLayer

#define DISP_H 9

// HelloWorldLayer implementation
@implementation DungeonScene

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
	CCLayer *layer = [DungeonScene node];
	[scene addChild: layer];
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	if( (self=[super init]) ) {
        
        // initialize variables
        offset_y = 0;
        
        //
        self->events = [[NSMutableArray array] retain];
     
        // setup dungeon view
        dungeon_view = [DungeonView node];
        [dungeon_view setDelegate:self];
        [self addChild:dungeon_view];
        
        // calc curring
        [self update_curring_range];
        
        // setup dungeon model
        dungeon_model = [[DungeonModel alloc] init:NULL];
        //[dungeon_model add_observer:dungeon_view];
        [dungeon_model add_observer:self];
        [dungeon_model load_from_file:@"floor001.json"];

        // setup player
        BlockView* player = [BlockView create:dungeon_model.player ctx:dungeon_model];  
        player.scale = 2.0;
        [dungeon_view add_block:player];
        dungeon_view.player = player;
        [player release];

        // 勇者を初期位置に
        [dungeon_view update_view:dungeon_model];
        //CGPoint p_pos = [dungeon_view model_to_local:dungeon_model.player.pos];
        CGPoint p_pos = [dungeon_view model_to_local:cdp(5,1)];
        player.position = p_pos;

        // fade 用のレイヤー
        self->fade_layer = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 255)];
        [self addChild:self->fade_layer z:10];
	}
	return self;
}

- (void) dealloc
{
    [dungeon_model release];
    [super dealloc];
}

- (void)onEnter
{
    [super onEnter];
    
    // enable touch
    self.isTouchEnabled = YES;
    
    // シーン遷移後のアニメーション
    CCFiniteTimeAction* fi = [CCFadeOut actionWithDuration:2.0];
    [self->fade_layer runAction:fi];

    self->large_notify = [[LargeNotifierView alloc] init];
    [self addChild:self->large_notify];
    
    CCActionInterval* nl = [CCDelayTime actionWithDuration:2.5];

    CGPoint p_pos = [dungeon_view model_to_local:cdp(2,1)];
    CCAction* action_1 = [CCMoveTo actionWithDuration:2.0 position:p_pos];
    
    [dungeon_view.player runAction:[CCSequence actions:nl, action_1, nil]];
    
    [dungeon_view update_view:self->dungeon_model];
}


//===============================================================
//
// タップ後のアニメーション
//
//===============================================================

// helper
- (DLPoint)screen_to_view_pos:(NSSet *)touches
{
    // スクリーン座標からビューの座標へ変換
    UITouch *touch =[touches anyObject];
    CGPoint location =[touch locationInView:[touch view]];
    location =[[CCDirector sharedDirector] convertToGL:location];
    int x = (int)(location.x / BLOCK_WIDTH);
    int y = (int)((480 - location.y + offset_y) / BLOCK_WIDTH);
    return cdp(x, y);
}

- (void)do_scroll
{
    // TODO: スクロールも一連のアクションシーケンスのひとつにしたい
    DLPoint ppos = self->dungeon_model.player.pos;
    DLPoint under_pos = cdp(ppos.x, ppos.y + 1);
    BlockModel* b = [self->dungeon_model get_x:under_pos.x y:under_pos.y];
    if (b.type == ID_EMPTY) {
        // スクロールの offset 更新
        self->offset_y = [self get_offset_y_by_player_pos];
        [self scroll_to];
    }
}

- (void)update_dungeon_view
{
    // 更新
    // スクロール後
    // 画面外を削って
    // 次に必要なブロックを描画
    //[self->dungeon_view update_view:self->dungeon_model];
    // TODO: これって DungeonView 側に書くべきじゃない？
    [self->dungeon_view remove_block_view_line:self->dungeon_view.curring_top _model:self->dungeon_model];
    [self->dungeon_view update_view_line:self->dungeon_view.curring_bottom-1 _model:self->dungeon_model];
}
    

//===============================================================
//
// タッチのハンドラ
//
//===============================================================

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
{
    // TODO: ここからタップ禁止 タップ禁止というかブロックのタップ禁止
    // アイテムとか討伐終了のボタンは押せないといけないから

    DLPoint view_pos = [self screen_to_view_pos:touches];
    
    // モデルへ通知
    [self->dungeon_model on_hit:view_pos];
    
    // カリングの幅を更新
    [self update_curring_range];

    // タップ後のシーケンス再生
    [self run_sequence];
}


//===============================================================
//
// スクロール関係
// TODO: dungeon_view 移動
// カリングの機能は view が持つべき
//
//===============================================================

- (float)get_offset_y_by_player_pos
{
    // 一番現在移動できるポイントが中央にくるまでスクロール？
    // プレイヤーの位置が４段目ぐらいにくるよまでスクロール
    // 一度いった時は引き返せない
    int by = (int)(offset_y / BLOCK_WIDTH);
    int diff = self->dungeon_model.player.pos.y - by;
    int hoge = 3;
    if (diff - hoge > 0) {
        offset_y += BLOCK_WIDTH * (diff - hoge);
    }
    
    // ここらへんはフロアの情報によって決まる
    // current_floor_max_rows * block_height + margin
    int max_scroll = (HEIGHT - DISP_H) * BLOCK_WIDTH + 30;
    if (offset_y > max_scroll) offset_y = max_scroll;
    
    return offset_y;
}

-(void)scroll_to
{
    // 実際の処理
    CCMoveTo *act_move = [CCMoveTo actionWithDuration: 0.4 position:ccp(0, offset_y)];
    CCEaseInOut *ease = [CCEaseInOut actionWithAction:act_move rate:2];
    [dungeon_view runAction:ease];
}

- (void)update_curring_range
{
    // カリング
    int visible_y = (int)(self->offset_y / BLOCK_WIDTH);
    int curring_var = -1;
    self->dungeon_view.curring_top    = visible_y - curring_var < 0 ? 0 : visible_y - curring_var;
    self->dungeon_view.curring_bottom = visible_y + DISP_H + curring_var > HEIGHT ? HEIGHT : visible_y + DISP_H + curring_var;
}


//===============================================================
//
// イベントハンドラ
//
//===============================================================

-(void)notify:(DungeonModel *)dungeon_ event:(DLEvent *)event
{
    NSLog(@"[EVENT] type:%d", event.type);
    [self->events addObject:event];
}


//===============================================================
//
// タッチ後のシーケンス
//
//===============================================================

- (void)run_sequence
{
    // アクションのシーケンスを作成
    NSMutableArray* action_list = [NSMutableArray arrayWithCapacity:10];
    
    // 
    self.isTouchEnabled = NO;
    
    
    // -------------------------------------------------------------------------------
    // プレイヤーの移動フェイズ(ブロックの移動フェイズ)
    CCAction* act_player_move = [self->dungeon_view.player get_action_update_player_pos:self->dungeon_model view:self->dungeon_view];
    if (act_player_move) {
        [action_list addObject:act_player_move];
        
        [BasicNotifierView notify:@"MESSAGE MESSAGE" target:self];
    }
    
    // アニメーション開始
    CCAction *act_animate = [self animate];
    NSLog(@"act_animate %@", act_animate);
    [action_list addObject:act_animate];
    
    // -------------------------------------------------------------------------------    
    // プレイヤーアタックフェイズ(ブロックアタックフェイズ)
    // アニメーション開始
    
    // -------------------------------------------------------------------------------
    // エネミー被アタックフェイズ(相手のブロックアタックフェイズ)
    //    CCDelayTime *act_delay = [CCDelayTime actionWithDuration:1.0];
    //    [action_list addObject:act_delay];
//    CCAction *act_defense = [CCCallFuncO actionWithTarget:self selector:@selector(animate_defense)];
//    [action_list addObject:act_defense];
    
    // -------------------------------------------------------------------------------
    // エネミー死亡エフェクトフェイズ(相手のブロックの死亡フェイズ)
    
    
    // -------------------------------------------------------------------------------
    // スクロールフェイズ
    CCAction *act_scroll = [CCCallFuncO actionWithTarget:self selector:@selector(do_scroll)];
    [action_list addObject:act_scroll];
    
    // -------------------------------------------------------------------------------
    // 画面の描画
    CCAction* act_update_view = [CCCallFuncO actionWithTarget:self selector:@selector(update_dungeon_view)];
    [action_list addObject:act_update_view];
    
    
    // -------------------------------------------------------------------------------
    // タッチをオンに
    CCAction* act_to_touchable = [CCCallBlockO actionWithBlock:^(DungeonScene* this) {
        this.isTouchEnabled = YES;
    } object:self];
    [action_list addObject:act_to_touchable];
    
    // 実行
    [self->dungeon_view.player runAction:[CCSequence actionWithArray:action_list]];
}

- (CCAction*)_animate
{
    // ガード
    if (![self->events count]) {
        return nil;
    }
    
    NSMutableArray *actions = [NSMutableArray array];
    DLEvent *e = (DLEvent*)[self->events objectAtIndex:0];
    while (e) {
        
        NSLog(@"[EVENT_N] type:%d", e.type);
        CCAction *act = [self->dungeon_view notify:self->dungeon_model event:e];
        if (!act) {
            break;
        }
        [actions addObject:act];
        [self->events removeObjectAtIndex:0];
        
        if (![self->events count]) {
            break;
        }
        e = (DLEvent*)[self->events objectAtIndex:0];
        if( e.type == DL_ON_HIT ) {
            break;
        }
    }
    if ([actions count]) {
        CCAction *delay = [CCDelayTime actionWithDuration:1.0];
        [actions addObject:delay];
    }
    return [CCSpawn actionWithArray:actions];
}

- (CCAction*)animate
{
    // ガード
    if (![self->events count]) {
        return nil;
    }
    
    NSMutableArray *actions = [NSMutableArray array];

    DLEvent *e = (DLEvent*)[self->events objectAtIndex:0];
    while (e) {
        
        CCAction *action = [self _animate];
        if (!action) {
            break;
        }
        [actions addObject:action];
        
        if (![self->events count]) {
            break;
        }
        e = (DLEvent*)[self->events objectAtIndex:0];
    }
    return [CCSequence actionWithArray:actions];
}

//- (void)animate
//{
//    [dungeon_view update_presentation:self->dungeon_model phase:DL_ETC];
//}

- (void)animate_defense
{
    [dungeon_view update_presentation:self->dungeon_model phase:DL_DEFENSE];
}

@end
