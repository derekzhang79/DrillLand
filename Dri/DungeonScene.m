//
//  HelloWorldLayer.m
//  Dri
//
//  Created by  on 12/08/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


// Import the interfaces
#import "DungeonScene.h"
#import "DungeonModel.h"
#import "DungeonView.h"

#pragma mark - HelloWorldLayer

// HelloWorldLayer implementation
@implementation DungeonScene

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
	DungeonScene *layer = [DungeonScene node];
	[scene addChild: layer];
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	if( (self=[super init]) ) {
 
        offset_y = 0;
        
        // setup dungeon view
        dungeon_view = [DungeonView node];
        [dungeon_view setDelegate:self];
        [self addChild:dungeon_view];
        
        // setup dungeon model
        dungeon = [[DungeonModel alloc] init:NULL];
        [dungeon add_observer:dungeon_view];

        // 更新
        BlockModel* b = [[BlockModel alloc] init];
        b.type = 1;
        [dungeon set:ccp(1,0) block:b];
        
		// enable touch
        self.isTouchEnabled = YES;
	}
	return self;
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
{
    // Choose one of the touches to work with
    UITouch *touch =[touches anyObject];
    CGPoint location =[touch locationInView:[touch view]];
    location =[[CCDirector sharedDirector] convertToGL:location];
    int x = (int)(location.x / 60);
    int y = (int)((480 - location.y + offset_y) / 60);

    [self->dungeon hit:ccp(x, y)];

    NSLog(@"touched %d, %d offset_y %d", x, y, offset_y / 60);

    // ここでタップ禁止にしてたいね
    offset_y += 30;

    CCAction* act_move = [CCMoveTo actionWithDuration: 0.3 position:ccp(0, offset_y)];
    [dungeon_view runAction: act_move];
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
    [super dealloc];
}

@end
