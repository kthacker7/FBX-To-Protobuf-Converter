//
//  Runner.h
//  fbxToPBScript
//
//  Created by Kunal Thacker on 21/06/17.
//  Copyright © 2017 Kunal Thacker. All rights reserved.
//

#ifndef Runner_h
#define Runner_h


#endif /* Runner_h */

@interface Runner : NSObject
@property (nonatomic, readwrite) int *verticesCount;
@property (nonatomic, readwrite) float **vertices;
@property (nonatomic, readwrite) int *indicesCount;
@property (nonatomic, readwrite) int **indices;
@property (nonatomic, readwrite) float **textureCoords;
@property (nonatomic, readwrite) double ***animationMatrices;
@property (nonatomic, readwrite) int nodesCount;
@property (nonatomic, readwrite) double *identity;

-(void) run;
@end


