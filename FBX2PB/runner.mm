//
//  Runner.m
//  fbxToPBScript
//
//  Created by Kunal Thacker on 21/06/17.
//  Copyright © 2017 Kunal Thacker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "runner.h"
#import "fbxsdk.h"
#import "VerTexCount.h"
#import "Fbxmodel.pbobjc.h"

@interface Runner()
@property (nonatomic, readwrite) FbxTime startTime;
@property (nonatomic, readwrite) NSDate *lastUpdate;
@property (nonatomic, readwrite) long *animationsCount;
@end


@implementation Runner
// MARK: SDK Loader Methods
#ifdef __cplusplus
bool LoadScene(FbxManager* pManager, FbxDocument* pScene, const char* pFilename)
{
	int lFileMajor, lFileMinor, lFileRevision;
	int lSDKMajor,  lSDKMinor,  lSDKRevision;
	//int lFileFormat = -1;
	int i, lAnimStackCount;
	bool lStatus;
	char lPassword[1024];
	
	// Get the file version number generate by the FBX SDK.
	FbxManager::GetFileFormatVersion(lSDKMajor, lSDKMinor, lSDKRevision);
	
	// Create an importer.
	FbxImporter* lImporter = FbxImporter::Create(pManager,"");
	
	// Initialize the importer by providing a filename.
	const bool lImportStatus = lImporter->Initialize(pFilename, -1, pManager->GetIOSettings());
	lImporter->GetFileVersion(lFileMajor, lFileMinor, lFileRevision);
	
	if( !lImportStatus )
	{
		FbxString error = lImporter->GetStatus().GetErrorString();
		
		if (lImporter->GetStatus().GetCode() == FbxStatus::eInvalidFileVersion)
		{
		}
		
		return false;
	}
	
	
	// Import the scene.
	lStatus = lImporter->Import(pScene);
	
	// Destroy the importer.
	lImporter->Destroy();
	
	return lStatus;
}

void InitializeSdkObjects(FbxManager*& pManager, FbxScene*& pScene)
{
	//The first thing to do is to create the FBX Manager which is the object allocator for almost all the classes in the SDK
	pManager = FbxManager::Create();
	if( !pManager )
	{
		exit(1);
	}
	
	//Create an IOSettings object. This object holds all import/export settings.
	FbxIOSettings* ios = FbxIOSettings::Create(pManager, IOSROOT);
	pManager->SetIOSettings(ios);
	
	
	//Create an FBX scene. This object holds most objects imported/exported from/to files.
	pScene = FbxScene::Create(pManager, "My Scene");
	if( !pScene )
	{
		exit(1);
	}
}

#endif

// MARK: Setup Vertices and nodes Methods
-(instancetype)initWithFilename: (NSString *) fileName {
	if ([self init]) {
		[self setupVerticesAndNodes:fileName];
	}
	return self;
}


-(int) setupVertices: (FbxNode *) node
		  lookingFor: (int) nodeNumber {
	int nodeCopy = nodeNumber;
	if (node->GetMesh() != nil) {
		FbxMesh *mesh = node->GetMesh();
		// Currently assumes that there is only one mesh, but extendeable easily
		
		FbxVector4 *rawvertices = mesh->GetControlPoints();
		FbxLayerElementArrayTemplate<FbxVector2> *pTexCoords;
		mesh->GetTextureUV(&pTexCoords);
		
		NSMutableDictionary *vertexmap = [[NSMutableDictionary alloc] init];
		float **finalVertices = (float **)malloc(sizeof(float *) * mesh->GetPolygonCount()*3);
		float **finalCoords = (float **)malloc(sizeof(float *) * mesh->GetPolygonCount()*3);
		int verticesCount = 0;
		NSMutableArray *indices = [[NSMutableArray alloc] init];
		for (int i = 0; i < mesh->GetPolygonCount(); i++) {
			for (int j = 0; j < mesh->GetPolygonSize(i); j++) {
				int index = mesh->GetPolygonVertex(i, j);
				int uvIndex = mesh->GetTextureUVIndex(i, j);
				
				NSString *key = [[NSString alloc] initWithFormat:@"%d/%d", index, uvIndex];
				if ([vertexmap valueForKey:key] == NULL) {
					FbxVector4 vertex = rawvertices[index];
					float *vertexDouble = (float *)malloc(sizeof(double) * 3);
					vertexDouble[0] = (float)vertex.mData[0];
					vertexDouble[1] = (float)vertex.mData[1];
					vertexDouble[2] = (float)vertex.mData[2];
					
					FbxVector2 uv = pTexCoords->GetAt(uvIndex);
					float *uvRaw = (float *)malloc(sizeof(float) * 2);
					uvRaw[0] = (float)uv.mData[0];
					uvRaw[1] = (float)uv.mData[1];
					VerTexCount *value = [[VerTexCount alloc] init];
					value.count = 1;
					value.index = [NSNumber numberWithInt:verticesCount];
					
					[indices addObject:value.index];
					
					[vertexmap setValue:value forKey:key];
					finalVertices[verticesCount] = vertexDouble;
					finalCoords[verticesCount] = uvRaw;
					verticesCount += 1;
				} else {
					VerTexCount *val = [vertexmap valueForKey:key];
					[val increase];
					[indices addObject:val.index];
					[vertexmap setValue:val forKey:key];
				}
			}
		}
		self.indicesCount[nodeNumber] = mesh->GetPolygonVertexCount();
		self.vertices[nodeNumber] = (float *)malloc(sizeof(float) * verticesCount * 3);
		self.textureCoords[nodeNumber] = (float *)malloc(sizeof(float) * verticesCount * 2);
		self.indices[nodeNumber] = (int *)malloc(sizeof(int) * self.indicesCount[nodeNumber]);
		for (int i = 0; i < verticesCount; i++) {
			self.vertices[nodeNumber][i * 3 + 0] = finalVertices[i][0];
			self.vertices[nodeNumber][i * 3 + 1] = finalVertices[i][1];
			self.vertices[nodeNumber][i * 3 + 2] = finalVertices[i][2];
			
			self.textureCoords[nodeNumber][i * 2 + 0] = finalCoords[i][0];
			self.textureCoords[nodeNumber][i * 2 + 1] = 1.0 - finalCoords[i][1];
			
			free(finalVertices[i]);
			free(finalCoords[i]);
		}
		free(finalVertices);
		free(finalCoords);
		
		for (int i = 0; i < self.indicesCount[nodeNumber]; i++) {
			NSNumber *currIndex = [indices objectAtIndex:i];
			self.indices[nodeNumber][i] = currIndex.integerValue;
		}
		
		self.verticesCount[nodeNumber] = verticesCount;
		NSLog(@"Got mesh for node number: %d, with name:", nodeNumber);
		printf(node->GetName());
		printf("\n");
		FbxTimeSpan interval;
		if (node->GetAnimationInterval(interval, nil)) {
			NSLog(@"Got animation matrix for node number: %d, with name:", nodeNumber);
			printf(node->GetName());
			printf("\n");
			FbxTime startTime = (interval.GetStart());
			FbxTime endTime = (interval.GetStop());
			self.animationsCount[nodeNumber] = (endTime.GetMilliSeconds() - startTime.GetMilliSeconds())/25;
			self.animationMatrices[nodeNumber] = (double **)malloc(sizeof(double *) * self.animationsCount[nodeNumber]);
			FbxTime t;
			for (long i = 0; i < self.animationsCount[nodeNumber]; i = i + 1) {
				t.SetMilliSeconds(i*25);
				FbxMatrix transform = node->EvaluateGlobalTransform(t);
				self.animationMatrices[nodeNumber][i] = (double *)malloc(sizeof(double) * 16);
				for (int j = 0; j < 4; j++) {
					for (int k = 0; k < 4; k++) {
						self.animationMatrices[nodeNumber][i][j*4 + k] = transform.mData[j].mData[k];
					}
				}
			}
		} else {
			self.animationsCount[nodeNumber] = 0;
		}
		nodeCopy = nodeCopy + 1;
	}
	int i = 0;
	while (i < node->GetChildCount()) {
		int nextIndex = [self setupVertices:node->GetChild(i) lookingFor:nodeCopy];
		nodeCopy = nextIndex;
		i = i + 1;
	}
	return nodeCopy;
}

- (void)setupVerticesAndNodes:(NSString *) filename {
	
	// Find file
	NSString *filepath = @"/Users/kunalthacker/Downloads/Rain.fbx";
	self.lastUpdate = [[NSDate alloc] init];
	FbxManager *_sdkManager ;
	FbxScene *_scene ;
	InitializeSdkObjects(_sdkManager, _scene);
	FbxString fbxSt ([filepath cStringUsingEncoding:[NSString defaultCStringEncoding]]) ;
	bool bResult =LoadScene(_sdkManager, _scene, fbxSt.Buffer ()) ;
	fbxsdk::FbxNode *node = (_scene->GetRootNode());
	
	self.nodesCount = 7;
	self.vertices = (float **) malloc(sizeof(float *) * self.nodesCount);
	self.indices = (int **) malloc(sizeof(int *) * self.nodesCount);
	self.verticesCount = (int *) malloc(sizeof(int) * self.nodesCount);
	self.indicesCount = (int *) malloc(sizeof(int) * self.nodesCount);
	self.animationsCount = (long *) malloc(sizeof(long) * self.nodesCount);
	self.textureCoords = (float **) malloc(sizeof(float *) * self.nodesCount);
	
	double *identity = (double *)malloc(sizeof(double) * 16);
	identity[0] = 1.0;
	identity[1] = 0.0;
	identity[2] = 0.0;
	identity[3] = 0.0;
	identity[4] = 0.0;
	identity[5] = 1.0;
	identity[6] = 0.0;
	identity[7] = 0.0;
	identity[8] = 0.0;
	identity[9] = 0.0;
	identity[10] = 1.0;
	identity[11] = 0.0;
	identity[12] = 0.0;
	identity[13] = 0.0;
	identity[14] = 0.0;
	identity[15] = 1.0;
	self.identity = identity;
	
	self.animationMatrices = (double ***) malloc(sizeof(double **) * self.nodesCount);
	[self setupVertices:node lookingFor:0];
	FBXModel *model = [[FBXModel alloc] init];
	//	[FBXModel]
	model.nodesArray = [[NSMutableArray alloc] init];
	//	[model set]
	for (int i = 0; i< self.nodesCount; i++) {
		FBXModel_node *node = [[FBXModel_node alloc] init];
		float *vertexValues = self.vertices[i];
		[node.verticesArray addValues:self.vertices[i] count:self.verticesCount[i]];
		[node.uvCoordsArray addValues:self.textureCoords[i] count:self.verticesCount[i]];
		[node.indicesArray addValues:self.indices[i] count:self.indicesCount[i]];
		NSMutableArray<FBXModel_node_animationMatrix *> *animations = [[NSMutableArray<FBXModel_node_animationMatrix *> alloc] init];
		for (int j = 0; j < self.animationsCount[i]; j++) {
			double *animationMatrix = self.animationMatrices[i][j];
			FBXModel_node_animationMatrix *animMatrix = [[FBXModel_node_animationMatrix alloc] init];
			[animMatrix.valuesArray addValues:animationMatrix count:16];
			[animations addObject:animMatrix];
		}
		[node.matricesArray addObjectsFromArray:animations];
		[model.nodesArray addObject:node];
		
	}
	NSData *oldData = [model data];
	[self writeFile: oldData];
	NSData *newData = [self readData];
	FBXModel *retrievedModel = [[FBXModel alloc] initWithData:newData error:NULL];
	//	NSLog(@"Got name: %@", retrievedModel.name);
	//	NSLog(@"Got id: %d", retrievedModel.id_p);
	//	NSLog(@"Got email: %@", retrievedModel.email);
	
}
- (NSData *) readData {
	NSFileHandle *file;
	NSError *error;
	NSString *filePath=[NSString stringWithFormat:@"/Users/kunalthacker/Documents/filewritetest/doc.txt"];
	file = [NSFileHandle fileHandleForReadingAtPath:filePath];
	//assign file path directory
	if (file == nil) { //check file exist or not
		NSLog(@"Failed to open file, creating a new one");
		NSFileManager *fm = [NSFileManager defaultManager];
		[fm createFileAtPath:filePath contents:nil attributes:nil];
		file = [NSFileHandle fileHandleForReadingAtPath:filePath];
	}
	//	[file seekToFileOffset: 6];
	NSData *data = [file readDataToEndOfFile];
	[file closeFile];
	return data;
}
- (void) writeFile: (NSData *)dataToWrite {
	NSFileHandle *file;
	//object for File Handle
	NSError *error;
	//crearing error object for string with file contents format
	//create mutable object for ns data
	NSString *filePath=[NSString stringWithFormat:@"/Users/kunalthacker/Documents/filewritetest/doc.txt"];
	//telling about File Path for Reading for easy of access
	file = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
	//assign file path directory
	if (file == nil) { //check file exist or not
		NSLog(@"Failed to open file, creating a new one");
		NSFileManager *fm = [NSFileManager defaultManager];
		[fm createFileAtPath:filePath contents:nil attributes:nil];
		file = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
	}
	//	[file seekToFileOffset: 6];
	[file writeData: dataToWrite];
	[file closeFile];
}

- (double *) getTimeStepMatrix: (int) nodeNumber {
	NSLog(@"Returning from animations count = %ld", self.animationsCount[nodeNumber]);
	if (self.animationsCount[nodeNumber] == 0) {
		return self.identity;
	}
	NSTimeInterval timeDif = floor([self.lastUpdate timeIntervalSinceNow] * -40);
	while (timeDif >= self.animationsCount[nodeNumber]) {
		timeDif = timeDif - self.animationsCount[nodeNumber];
	}
	NSLog(@"Returning matrix for timestep: %f", timeDif);
	return self.animationMatrices[nodeNumber][NSInteger(timeDif)];
}

- (void)dealloc
{
	for (int j = 0; j < self.nodesCount; j++) {
		for (int i = 0; i< self.animationsCount[j]; i++) {
			if (self.animationMatrices[j][i]) {
				NSLog(@"Deallocating pointer: %p", self.animationMatrices[j][i]);
				free(self.animationMatrices[j][i]);
			}
		}
	}
	NSLog(@"Deallocing animation matrices pointer");
	free(self.animationMatrices);
	free(self.identity);
	NSLog(@"Freeing vertices");
	//	free(vertices);
	NSLog(@"Freeing texture coordinates");
	//	free(textureCoords);
	NSLog(@"Freeing indices");
	//	free(indices);
}

-(void) run {
	[self setupVerticesAndNodes:@"Rain"];
}

@end

