//
//  DungeonResultScene.m
//  Dri
//
//  Created by  on 12/08/29.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "DungeonResultScene.h"


@implementation DungeonResultScene

+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
	CCLayer *layer = [DungeonResultScene node];
	[scene addChild:layer];
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	if( (self=[super init]) ) {
        CCLabelTTF *label = [CCLabelTTF labelWithString:@"GAMEOVER" fontName:@"AppleGothic" fontSize:20];
        label.position =  ccp(160, 240);
        [self addChild:label];
	}
	return self;
}

@end
