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

@class DungeonModel;
@class DungeonView;

// HelloWorldLayer
@interface DungeonLayer : CCLayer
{
    DungeonView *dungeon_view;
    DungeonModel *dungeon;
    
    int offset_y;
}

+(CCScene *) scene;

@end
