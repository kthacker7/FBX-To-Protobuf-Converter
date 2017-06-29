# FBX-to-ProtoBuf-Converter
An ObjC script which reads any FBX model and outputs a protobuf file with vertices, uv coordinates, indices and animation 
matrices for each bone

To use this script, firstly download and install FBX SDK by Maya from: 
http://usa.autodesk.com/adsk/servlet/pc/item?siteID=123112&id=26416130

Make sure the installation location is /Applications/Autodesk/FBX\ SDK/2018.1.1/include. If you have installed it somewhere 
else, please update the fields 'Other Linker Flags' and 'User Header Search Paths' in the xcodeproject to avoid errors.

Update line 21-23 in the file runner.mm to the number of bones(nodes) in the fbx model, your choice of output and 
input file paths respectively.

This project uses FBX SDK 2018.1.1 and Google Protobuf version 3.3.0. Protobuf provides both forward and backward compatibity
and reduces the size of fbx models by 20-50% which is ideal for apps that are targetted at audiences who do not have access
to infinite data users/users with lower bandwidth.

Finally, in order to generate the parser, download your choice of Google Protobuf from https://github.com/google/protobuf.

Install protoc and generate the reader files using the following .proto file:

    message FBXModel

    { 	
    	message node {

		    message animationMatrix {

    			repeated double values = 1;

		    }

    		repeated float vertices = 1;
	
		    repeated float uvCoords = 2;
	
    		repeated int32 indices = 3;

		    repeated animationMatrix matrices = 4;
    	}

    	repeated node nodes = 1;
	  }


Use the generated files in your projects to get back vertices, texture coordinates, indices and animation matrices for each 
node(bone) in your FBX model.
