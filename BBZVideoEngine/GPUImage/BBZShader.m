//
//  BBZShader.m
//  BBZVideoEngine
//
//  Created by Hbo on 2020/5/28.
//  Copyright © 2020 BBZ. All rights reserved.
//

#import "BBZShader.h"
#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

NSString *const kNodeVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );


NSString *const kNodeTransformVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 uniform mat4 matParam441;
 uniform mat4 matParam442;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = matParam441 * vec4(position.xy, 1.0, 1.0) * matParam442;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );

NSString *const kNodeYUV420FTransformFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform mediump mat3 matParam;

 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(inputImageTexture, textureCoordinate).r;
     yuv.yz = texture2D(inputImageTexture2, textureCoordinate).ra - vec2(0.5, 0.5);
     rgb = matParam * yuv;
     
     gl_FragColor = vec4(rgb, 1.0);
 }
 );

NSString *const kNodePassthroughFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
 );

NSString *const kNodeRGBTransformFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;

 uniform sampler2D inputImageTexture;

 void main()
 {
     mediump vec4 rgb = texture2D(inputImageTexture, textureCoordinate);

     gl_FragColor = rgb;
 }
 );


NSString *const kNodeFBFectchYUV420FTransformFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform mediump mat3 matParam;
 uniform mediump vec4 v4Param1;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     mediump vec4 bgColor = gl_LastFragData[0];
     yuv.x = texture2D(inputImageTexture, textureCoordinate).r;
     yuv.yz = texture2D(inputImageTexture2, textureCoordinate).ra - vec2(0.5, 0.5);
     rgb = matParam * yuv;
     
     highp float width = v4Param1.x;
     if(width > 0.0007) {
         highp vec2 uv = (textureCoordinate - vec2(width, width)) / (1.0 - width * 2.0);
         if(uv.x < 0.0 ) {
             if(uv.y < 0.0) {
                 uv.x = max(abs(uv.x), abs(uv.y));
             } else if(uv.y > 1.0) {
                 uv.x = max(abs(uv.x), abs(uv.y-1.0));
             }
             rgb = mix(rgb, bgColor.rgb, smoothstep(0.0, width, abs(uv.x)));
         }else if(uv.x > 1.0) {
             uv.x = abs(uv.x - 1.0);
             if(uv.y < 0.0) {
                 uv.x = max(uv.x, abs(uv.y));
             } else if(uv.y > 1.0) {
                 uv.x = max(uv.x, abs(uv.y-1.0));
             }
             rgb = mix(rgb, bgColor.rgb, smoothstep(0.0, width, abs(uv.x)));
         } else if(uv.y < 0.0) {
             rgb = mix(rgb, bgColor.rgb, smoothstep(0.0, width, abs(uv.y)));
         } else if(uv.y > 1.0) {
             rgb = mix(rgb, bgColor.rgb, smoothstep(0.0, width, abs(uv.y - 1.0)));
         }
     }
     
     gl_FragColor = vec4(rgb, 1.0);
 }
 );

NSString *const kNodeFBFectchRGBTransformFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform mediump vec4 v4Param1;
 
 
 void main()
 {
     mediump vec3 rgb = texture2D(inputImageTexture, textureCoordinate).rgb;
     mediump vec4 bgColor = gl_LastFragData[0];
     
     highp float width = v4Param1.x;
     if(width > 0.0007) {
         highp vec2 uv = (textureCoordinate - vec2(width, width)) / (1.0 - width * 2.0);
         if(uv.x < 0.0 ) {
             if(uv.y < 0.0) {
                 uv.x = max(abs(uv.x), abs(uv.y));
             } else if(uv.y > 1.0) {
                 uv.x = max(abs(uv.x), abs(uv.y-1.0));
             }
             rgb = mix(rgb, bgColor.rgb, smoothstep(0.0, width, abs(uv.x)));
         }else if(uv.x > 1.0) {
             uv.x = abs(uv.x - 1.0);
             if(uv.y < 0.0) {
                 uv.x = max(uv.x, abs(uv.y));
             } else if(uv.y > 1.0) {
                 uv.x = max(uv.x, abs(uv.y-1.0));
             }
             rgb = mix(rgb, bgColor.rgb, smoothstep(0.0, width, abs(uv.x)));
         } else if(uv.y < 0.0) {
             rgb = mix(rgb, bgColor.rgb, smoothstep(0.0, width, abs(uv.y)));
         } else if(uv.y > 1.0) {
             rgb = mix(rgb, bgColor.rgb, smoothstep(0.0, width, abs(uv.y - 1.0)));
         }
     }
     
     gl_FragColor = vec4(rgb, 1.0);
 }
 );


NSString *const kNodeMaskBlendFragmentShaderString = SHADER_STRING
(
 precision highp float;
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 uniform vec4 v4Param1;
 
 vec4 blendColor(in highp vec4 dstColor, in highp vec4 srcColor)
 {
     vec3 vOne = vec3(1.0, 1.0, 1.0);
     vec3 vZero = vec3(0.0, 0.0, 0.0);
     vec3 resultFore = srcColor.rgb + dstColor.rgb * (1.0 - srcColor.a);
     return vec4(resultFore.rgb, 1.0);
 }
 
 void main()
 {
     vec4 bgColor = texture2D(inputImageTexture, textureCoordinate);
     vec2 maskSize = v4Param1.zw;
     vec2 maskPostion = v4Param1.xy;
     float width = maskSize.x;
     float height = maskSize.y;
     if(textureCoordinate.x > maskPostion.x && textureCoordinate.x < maskPostion.x + width && textureCoordinate.y > maskPostion.y && textureCoordinate.y < maskPostion.y + height) {
         vec2 uv = textureCoordinate - vec2(maskPostion.x,maskPostion.y);
         vec4 srcColor = texture2D(inputImageTexture2, vec2(uv.x / width , uv.y / height));
         bgColor = blendColor(bgColor, srcColor);
     }
     gl_FragColor = bgColor;
 }
 );


@implementation BBZShader

+ (NSString *)vertextShader {
    return kNodeVertexShaderString;
}

+ (NSString *)vertextTransfromShader {
    /*
     matParam441 : transformMatrix
     matParam442 : orthographicMatrix
     */
    return kNodeTransformVertexShaderString;
}

+ (NSString *)fragmentPassthroughShader {
    return  kNodePassthroughFragmentShaderString;
}


+ (NSString *)fragmentYUV420FTransfromShader {
    return  kNodeYUV420FTransformFragmentShaderString;
}

+ (NSString *)fragmentRGBTransfromShader {
    return  kNodeRGBTransformFragmentShaderString;
}

+ (NSString *)fragmentFBFectchYUV420FTransfromShader {
    /*
     matParam : yuvConversionMatrix
     v4Param1 : x:羽化参数
     */
    NSString *fragmentShaderToUse = [NSString stringWithFormat:@"#extension GL_EXT_shader_framebuffer_fetch : require\n %@",kNodeFBFectchYUV420FTransformFragmentShaderString];
    return fragmentShaderToUse;
}

+ (NSString *)fragmentFBFectchRGBTransfromShader {
    /*
     v4Param1 : x:羽化参数
     */
    NSString *fragmentShaderToUse = [NSString stringWithFormat:@"#extension GL_EXT_shader_framebuffer_fetch : require\n %@",kNodeFBFectchRGBTransformFragmentShaderString];
    return fragmentShaderToUse;
}


+ (NSString *)fragmentMaskBlendShader {
    /*
     v4Param1 : maskPostion,maskSize
     */
     return  kNodeMaskBlendFragmentShaderString;
}

@end