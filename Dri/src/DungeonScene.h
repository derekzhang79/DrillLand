//
//  HelloWorldLayer.h
//  Dri
//
//  Created by  on 12/08/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "LargeNotifierView.h"
#import "DungeonModel.h"

@class DungeonView;

@interface DungeonScene : CCLayerColor<DungenModelObserver>
{
    int offset_y;

    DungeonModel *dungeon_model;
    
    CCLayerColor      *fade_layer;
    DungeonView       *dungeon_view;
    LargeNotifierView *large_notify;
    
    NSMutableArray *events;
}

+ (CCScene *)scene;
- (void)run_sequence;
- (void)update_curring_range;

// TODO: スクロール関係は別クラスに
- (float)get_offset_y_by_player_pos;
- (void)scroll_to;

// animate
- (void)animate;
- (void)animate_defense;

@end
