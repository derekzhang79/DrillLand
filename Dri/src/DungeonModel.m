//
//  DungeonModel.m
//  Dri
//
//  Created by  on 12/08/15.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DungeonModel.h"
#import "BlockModel.h"
#import "PlayerModel.h"

@implementation DungeonModel

@synthesize route_map;
@synthesize player;

-(id) init:(NSArray*)initial
{
    if (self = [super init]) {
        self->player = [[PlayerModel alloc]init];
        self->done_map = [[XDMap alloc] init];
        self->route_map = [[XDMap alloc] init];

        self->map = [[TileMap2 alloc] init];
        [self _fill_blocks];
        
        [self _setup];
    }
    return self;
}

-(void) add_observer:(id<DungenModelObserver>)_observer
{
    self->observer = _observer;
}

-(void) hit:(CGPoint)pos
{
    int x = (int)pos.x;
    int y = (int)pos.y;
    
    // -- プレイヤーの移動フェイズ
    [self update_route_map:cdp(x, y) target:player.pos];
    DLPoint next_pos = [self get_player_pos:player.pos];
    self->player.pos = next_pos;
    // TODO: ここで notify すべき
    NSLog(@"next_pos %d %d", next_pos.x, next_pos.y);
    
    // -- ブロックのヒット処理フェイズ
    BlockModel* b = [self get_x:x y:y];
    if (b.can_tap == NO) {
        // TODO: notify
        return;
    }

    if (b.group_info) {
        for (id block in b.group_info) {
            [self _hit:block];
        }
    } else {
        [self _hit:b];
    }
    
    // -- アップデートフェイズ
    // ブロックのターン！
    // 全ブロックに対して
    // update 呼ぶ
    // for (block in 可視範囲のブロック) {
    //     block.update(context);
    // }
}

-(void) _hit:(BlockModel*)b
{
    [b on_hit];
    
    [self update_group_info:ccp(b.x, b.y) group_id:b.group_id];
    [self update_can_tap:ccp(self->player.pos.x, self->player.pos.y)]; // TODO: プレイヤーの座標を指定しないといけない
    
    // このふたつがおかしい
    // どのオブジェクトがタップされたか？
    // それだけで良い
    // しかもここじゃなくモデルにかくべき
    [self->observer notify_particle:b];
    [self->observer notify:self];
}

// TODO: set は最初だけにしよう、置き換えるんじゃなくて、作成済みのデータを変更しよう
-(void) set:(CGPoint)pos block:(BlockModel*)block
{
    int x = (int)pos.x;
    int y = (int)pos.y;
    
    block.x = x;
    block.y = y;
    
    [self->map set_x:x y:y value:block];
    [self update_group_info:pos group_id:block.group_id];
    [self update_can_tap:ccp(self->player.pos.x, self->player.pos.y)]; // TODO: プレイヤーの座標を指定しないといけない
    [self->observer notify:self];
}

-(void) update_can_tap:(CGPoint)pos
{
    int x = (int)pos.x;
    int y = (int)pos.y;
    
    // 起点は 0 でなければならない
    BlockModel* b = [self->map get_x:x y:y]; 
    if ( b.type > 0 ) return;
    
    // 操作済み判別テーブルを初期化
    [done_map clear];
    
    // タップ可能かどうかを初期化
    [self _clear_can_tap];
    
    // チェック処理本体
    [self update_can_tap_r:pos];
}

-(void) update_can_tap_r:(CGPoint)pos
{
    int x = (int)pos.x;
    int y = (int)pos.y;
    
    if ([self->done_map get_x:x y:y] != 0) return;
    
    BlockModel* b = [self->map get_x:x y:y];
    if (!b) return;
    
    [done_map set_x:x y:y value:1];
    if (b.type > 0) {
        b.can_tap = YES;
    } else if (b.type == 0) {
        b.can_tap = NO;
        [self update_can_tap_r:ccp(x + 0, y + 1)];
        [self update_can_tap_r:ccp(x + 0, y - 1)];
        [self update_can_tap_r:ccp(x + 1, y + 0)];
        [self update_can_tap_r:ccp(x - 1, y + 0)];
    } else {
        // マイナスの時は？？
    }
}

-(void) update_group_info:(CGPoint)pos group_id:(unsigned int)_group_id
{
    // group_id=0 の時はグループ化しない
    if (_group_id == 0) return;
    [self->done_map clear];
    NSMutableArray* group_info = [[NSMutableArray alloc] init];
    [self update_group_info_r:pos group_id:_group_id group_info:group_info];
    NSLog(@"group_info %d %@", _group_id, group_info);
}

-(void) update_group_info_r:(CGPoint)pos group_id:(unsigned int)_group_id group_info:(NSMutableArray*)_group_info
{
    int x = (int)pos.x;
    int y = (int)pos.y;

    // もうみた
    if ([done_map get_x:x y:y] != 0) return;

    // おかしい
    BlockModel* b = [map get_x:x y:y];
    if (b == NULL) return;

    // みたよ
    [done_map set_x:x y:y value:1];
    
    // 同じじゃないならなにもしない
    if (b.group_id != _group_id) return;
    
    //
    if(b.group_info != NULL) {
        // TODO:メモリリーク
        //[b.group_info release];
    }
    [_group_info addObject:b];
    b.group_info = _group_info;
    
    [self update_group_info_r:ccp(x + 0, y + 1) group_id:_group_id group_info:_group_info];
    [self update_group_info_r:ccp(x + 0, y - 1) group_id:_group_id group_info:_group_info];
    [self update_group_info_r:ccp(x + 1, y + 0) group_id:_group_id group_info:_group_info];
    [self update_group_info_r:ccp(x - 1, y + 0) group_id:_group_id group_info:_group_info];
}

-(void) update_route_map:(DLPoint)pos target:(DLPoint)target
{
    [self->route_map fill:999];
    [self update_route_map_r:pos target:target level:0];
}

-(void) update_route_map_r:(DLPoint)pos target:(DLPoint)target level:(int)level
{
    // ゴール以降は探索しない
//    if (pos.x == target.x && pos.y == target.y) {
//        [self->route_map set_x:pos.x y:pos.y value:level];
//        return;
//    }
    
    // ブロックの場合はそれ以上探索しない
    // ただし level = 0 （最初の一回目は）例外
    BlockModel* b = [self->map get_x:pos.x y:pos.y];
    if (b.type != 0 && level != 0) return;

    int cost = [self->route_map get_x:pos.x y:pos.y];

    // 画面外は -1 が返る
    // 画面外なら、それ以上探索しない
    if (cost < 0) return;
    
    // 計算済みの cost が同じか小さい場合探索しない
    if (cost <= level) return;

    [self->route_map set_x:pos.x y:pos.y value:level];

    [self update_route_map_r:cdp(pos.x + 0, pos.y - 1) target:target level: level + 1];
    [self update_route_map_r:cdp(pos.x + 0, pos.y + 1) target:target level: level + 1];
    [self update_route_map_r:cdp(pos.x - 1, pos.y + 0) target:target level: level + 1];
    [self update_route_map_r:cdp(pos.x + 1, pos.y + 0) target:target level: level + 1];
}

//# かならず 1 に辿り着けることを期待してるね
-(DLPoint) get_player_pos:(DLPoint)pos
{
    //# ゴールなので座標を返す
    int cost = [self->route_map get:pos];
    if (cost == 1) return pos;
    // 移動なし
    // TODO: マジックナンバー(>_<)
    if (cost == 999) return pos;

    DLPoint u_pos = cdp(pos.x + 0, pos.y - 1);
    DLPoint d_pos = cdp(pos.x + 0, pos.y + 1);
    DLPoint l_pos = cdp(pos.x - 1, pos.y + 0);
    DLPoint r_pos = cdp(pos.x + 1, pos.y + 0);
    int u_cost = [self->route_map get:u_pos];
    int d_cost = [self->route_map get:d_pos];
    int l_cost = [self->route_map get:l_pos];
    int r_cost = [self->route_map get:r_pos];
    u_cost = u_cost < 0 ? 999 : u_cost;
    d_cost = d_cost < 0 ? 999 : d_cost;
    l_cost = l_cost < 0 ? 999 : l_cost;
    r_cost = r_cost < 0 ? 999 : r_cost;

    NSArray *cost_list = [NSArray arrayWithObjects:
                          [NSNumber numberWithInt:l_cost],
                          [NSNumber numberWithInt:r_cost],
                          [NSNumber numberWithInt:d_cost],
                          [NSNumber numberWithInt:u_cost],
                          nil];
    
    int min_cost = l_cost;
    int index = 0;
    for (int i = 1; i < 4; i++) {
        int cost = [[cost_list objectAtIndex:i] intValue];
        if (cost < min_cost) {
            min_cost = cost;
            index = i;
        }
    }

    DLPoint out_pos;
    switch (index) {
        case 0:
            out_pos = l_pos;
            break;
        case 1:
            out_pos = r_pos;
            break;
        case 2:
            out_pos = d_pos;
            break;
        case 3:
            out_pos = u_pos;
            break;
        default:
            break;
    }
    
    return [self get_player_pos:out_pos];
}


//---------------------------------------------------

-(BlockModel*) get_x:(int)_x y:(int)_y
{
    return [self->map get_x:_x y:_y];
}

-(int) can_tap_x:(int)_x y:(int)_y
{
    BlockModel* b = [self->map get_x:_x y:_y];
    return b.can_tap;
}

-(void) dealloc
{
    [self->player release];
    [self->route_map release];
    [self->map release];
    [self->done_map release];
    [super dealloc];
}


//---------------------------------------------------

- (void)_setup
{
    // dummy
    BlockModel* b;
    
    // 消えない
    b = [[BlockModel alloc] init];
    b.type = 99;
    b.hp = -1;
    [self set:ccp(0, 7) block:(id)b];
    b = [[BlockModel alloc] init];
    b.type = 99;
    b.hp = -1;
    [self set:ccp(1, 7) block:(id)b];
    
    b = [[BlockModel alloc] init];
    b.type = 99;
    b.hp = -1;
    [self set:ccp(2, 7) block:(id)b];
    
    // 隙間
    b = [[BlockModel alloc] init];
    b.type = 0;
    [self set:ccp(2, 0) block:(id)b];
    
    // グループ0
    b = [[BlockModel alloc] init];
    b.type = 4;
    b.group_id = 2;
    [self set:ccp(2, 1) block:(id)b];
    
    b = [[BlockModel alloc] init];
    b.type = 4;
    b.group_id = 2;
    [self set:ccp(1, 1) block:(id)b];

    b = [[BlockModel alloc] init];
    b.type = 4;
    b.group_id = 2;
    [self set:ccp(0, 1) block:(id)b];
    
    b = [[BlockModel alloc] init];
    b.type = 4;
    b.group_id = 2;
    [self set:ccp(0, 2) block:(id)b];

    b = [[BlockModel alloc] init];
    b.type = 4;
    b.group_id = 2;
    [self set:ccp(0, 3) block:(id)b];
    
    b = [[BlockModel alloc] init];
    b.type = 4;
    b.group_id = 2;
    [self set:ccp(1, 3) block:(id)b];
    
    b = [[BlockModel alloc] init];
    b.type = 4;
    b.group_id = 2;
    [self set:ccp(0, 4) block:(id)b];
    
    b = [[BlockModel alloc] init];
    b.type = 4;
    b.group_id = 2;
    [self set:ccp(1, 4) block:(id)b];
    
    b = [[BlockModel alloc] init];
    b.type = 4;
    b.group_id = 2;
    [self set:ccp(2, 4) block:(id)b];
    
    
    // グループ消しサンプル
    b = [[BlockModel alloc] init];
    b.type = 2;
    b.group_id = 1;
    [self set:ccp(1, 2) block:(id)b];
    
    b = [[BlockModel alloc] init];
    b.type = 2;
    b.group_id = 1;
    [self set:ccp(2, 2) block:(id)b];
    
    b = [[BlockModel alloc] init];
    b.type = 2;
    b.group_id = 1;
    [self set:ccp(2, 3) block:(id)b];
    
    // グループ消しサンプル2
    b = [[BlockModel alloc] init];
    b.type = 3;
    b.group_id = 1;
    [self set:ccp(3, 4) block:(id)b];
    
    b = [[BlockModel alloc] init];
    b.type = 3;
    b.group_id = 1;
    [self set:ccp(3, 5) block:(id)b];
    
    b = [[BlockModel alloc] init];
    b.type = 3;
    b.group_id = 1;
    [self set:ccp(3, 6) block:(id)b];
    
    b = [[BlockModel alloc] init];
    b.type = 3;
    b.group_id = 1;
    [self set:ccp(3, 7) block:(id)b];
    
    // グループ消しサンプル3
    b = [[BlockModel alloc] init];
    b.type = 4;
    b.group_id = 2;
    [self set:ccp(0, 8) block:(id)b];
    
    b = [[BlockModel alloc] init];
    b.type = 4;
    b.group_id = 2;
    [self set:ccp(1, 8) block:(id)b];
    
    b = [[BlockModel alloc] init];
    b.type = 4;
    b.group_id = 2;
    [self set:ccp(2, 8) block:(id)b];
    
    b = [[BlockModel alloc] init];
    b.type = 4;
    b.group_id = 2;
    b.hp = 2;
    [self set:ccp(3, 8) block:(id)b];
    
    b = [[BlockModel alloc] init];
    b.type = 4;
    b.group_id = 2;
    [self set:ccp(4, 8) block:(id)b];
    
    // slime1
    b = [[BlockModel alloc] init];
    b.type = 5;
    b.hp = 3;
    [self set:ccp(2, 9) block:(id)b];
    
    // slime2
    b = [[BlockModel alloc] init];
    b.type = 5;
    b.hp = 3;
    [self set:ccp(1, 13) block:(id)b];
    
    //slime2
    b = [[BlockModel alloc] init];
    b.type = 6;
    b.hp = 10;
    [self set:ccp(4, 15) block:(id)b];
    
    
    b = [[BlockModel alloc] init];
    b.type = 99;
    b.hp = -1;
    [self set:ccp(0, 16) block:(id)b];
    
    b = [[BlockModel alloc] init];
    b.type = 99;
    b.hp = -1;
    [self set:ccp(1, 16) block:(id)b];
    
    b = [[BlockModel alloc] init];
    b.type = 99;
    b.hp = -1;
    [self set:ccp(2, 16) block:(id)b];
    
    b = [[BlockModel alloc] init];
    b.type = 99;
    b.hp = -1;
    [self set:ccp(3, 16) block:(id)b];
    
    b = [[BlockModel alloc] init];
    b.type = 99;
    b.hp = -1;
    [self set:ccp(4, 16) block:(id)b];
}

-(void)_fill_blocks
{
    int disp_w = WIDTH;
    int disp_h = HEIGHT;
    for (int j = 0; j < disp_h; j++) {
        for (int i = 0; i < disp_w; i++) {
            BlockModel* b = [[BlockModel alloc] init];
            b.type = 1;
            [self set:ccp(i, j) block:b];
        }
    }
}

-(void)_clear_can_tap
{
    int disp_w = WIDTH;
    int disp_h = HEIGHT;
    for (int j = 0; j < disp_h; j++) {
        for (int i = 0; i < disp_w; i++) {
            BlockModel* b = [self->map get_x:i y:j];
            b.can_tap = NO;
        }
    }   
}

@end