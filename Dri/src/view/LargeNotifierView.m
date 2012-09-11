//
//  LargeNotifierView.m
//  Dri
//
//  Created by  on 12/09/10.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "LargeNotifierView.h"


@implementation LargeNotifierView

-(id) init
{
	if(self=[super init]) {
        
        self.position = ccp(160, 240);
        
        self->base_layer = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 255) width:320 height:100];
        self->base_layer.position = ccp(-160, -50);
        [self addChild:self->base_layer];
        
        self->content_text = [[CCLabelTTF labelWithString:@"The Beginning Cave" fontName:@"AppleGothic" fontSize:30] retain];
        self->content_text.color = ccc3(255, 255, 255);
        self->content_text.opacity = 0.0;
        [self addChild:self->content_text];
        

        CCFiniteTimeAction* fi = [CCFadeIn actionWithDuration:1.0];
        CCFiniteTimeAction* fo= [CCFadeOut actionWithDuration:1.0];
        CCActionInterval* nl = [CCActionInterval actionWithDuration:2.0];
        CCSequence* seq = [CCSequence actions:fi, nl, fo, nil];
        [self->content_text runAction:seq];
        [self->base_layer runAction:[seq copy]];
        
        CCFiniteTimeAction* mb = [CCMoveBy actionWithDuration:4.0 position:ccp(0, 50)];
        [self runAction:mb];
    }
	return self;
}

@end