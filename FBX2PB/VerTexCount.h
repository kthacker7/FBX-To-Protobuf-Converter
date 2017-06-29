//
//  VerTexCount.h
//  FBX Integration
//
//  Created by Kunal Thacker on 12/06/17.
//  Copyright © 2017 Kunal Thacker. All rights reserved.
//

@interface VerTexCount : NSObject

@property (atomic, readwrite) int count;
@property (nonatomic, readwrite) NSNumber *index;

-(void)increase;

@end

