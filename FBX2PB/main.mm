//
//  main.m
//  FBX2PB
//
//  Created by Kunal Thacker on 27/06/17.
//  Copyright © 2017 Kunal Thacker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Runner.h"
int main(int argc, const char * argv[]) {
	@autoreleasepool {
		// insert code here...
		Runner *r = [[Runner alloc] init];
		[r run];
		NSLog(@"Hello, World!");
	}
	return 0;
}

