//
//  BBZVideoReaderAction.m
//  BBZVideoEngine
//
//  Created by Hbo on 2020/4/29.
//  Copyright © 2020 BBZ. All rights reserved.
//

#import "BBZVideoReaderAction.h"
#import "BBZAssetReader.h"
#import "BBZVideoAsset.h"
#import "GPUImageColorConversion.h"
#import "GPUImageFramebuffer+BBZ.h"

@interface BBZVideoReaderAction ()
@property (nonatomic, strong) BBZAssetReader *reader;
@property (nonatomic, strong) BBZAssetReaderSequentialAccessVideoOutput *videoOutPut;
@property (nonatomic, strong) BBZInputSourceParam *inputSourceParam;
@property (nonatomic, assign) CMSampleBufferRef sampleBuffer;
@property (nonatomic, assign) CMTime lastTime;
@end


@implementation BBZVideoReaderAction


- (void)buildReader {
    if(!self.reader) {
        BBZVideoAsset *videoAsset = (BBZVideoAsset *)self.asset;
        self.reader = [[BBZAssetReader alloc] initWithAsset:(AVAsset *)videoAsset.asset];
        self.reader.timeRange = videoAsset.playTimeRange;
        self.videoOutPut = [[BBZAssetReaderSequentialAccessVideoOutput alloc] initWithOutputSettings:nil];
        [self.reader addOutput:self.videoOutPut];
    }
}

- (void)updateWithTime:(CMTime)time {
    
}

- (void)newFrameAtTime:(CMTime)time {
    runAsynchronouslyOnVideoProcessingQueue(^{
        CMSampleBufferRef sampleBuffer = self.videoOutPut.currentSampleBuffer;
        if(sampleBuffer) {
            self.sampleBuffer = sampleBuffer;
        }
        if(!sampleBuffer) {
            sampleBuffer = [self.videoOutPut nextSampleBuffer];
            if(sampleBuffer) {
                self.sampleBuffer = sampleBuffer;
                [self buildInputParam];
            }
        } else {
            CMTime lastSamplePresentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            lastSamplePresentationTime = CMTimeSubtract(lastSamplePresentationTime, self.reader.timeRange.start);
            NSTimeInterval nDiff = CMTimeGetSeconds(CMTimeSubtract(lastSamplePresentationTime, time));
            NSTimeInterval minDuration = CMTimeGetSeconds(CMTimeSubtract(time, self.lastTime));
            minDuration = fabs(minDuration / 2.0);
            if(nDiff > minDuration) {
                BBZERROR(@"newFrameAtTime use lastSamplebuffer dif:%f sample time:%@, realtime:%@", nDiff,[NSValue valueWithCMTime:lastSamplePresentationTime], [NSValue valueWithCMTime:time]);
                if(!self.inputSourceParam) {
                    [self buildInputParam];
                }
            } else {
                sampleBuffer = [self.videoOutPut nextSampleBuffer];
                if(sampleBuffer) {
                    self.sampleBuffer = sampleBuffer;
                    [self buildInputParam];
                }
            }
            lastSamplePresentationTime = CMSampleBufferGetPresentationTimeStamp(self.sampleBuffer);
             BBZINFO(@"sample time:%@, realtime:%@", [NSValue valueWithCMTime:lastSamplePresentationTime], [NSValue valueWithCMTime:time]);
        }
        self.lastTime = time;
    });
}


- (void)buildInputParam {
    if(!self.inputSourceParam) {
        self.inputSourceParam = [[BBZInputSourceParam alloc] init];
        self.inputSourceParam.bVideoSource = YES;
    }
    CMSampleBufferRef sampleBuffer = self.videoOutPut.currentSampleBuffer;
    GLfloat *preferredConversion;
    CVPixelBufferRef movieFrame = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    CFTypeRef colorAttachments = CVBufferGetAttachment(movieFrame, kCVImageBufferYCbCrMatrixKey, NULL);
    if (colorAttachments != NULL) {
        if(CFStringCompare(colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_601_4, 0) == kCFCompareEqualTo) {
            preferredConversion = kColorConversion601FullRange;
        } else {
            preferredConversion = kColorConversion709;
        }
    } else {
        
        preferredConversion = kColorConversion601FullRange;
    }
    NSArray *array = [GPUImageFramebuffer BBZ_YUVFrameBufferWithCVPixelBuffer:movieFrame];
    NSAssert(array.count == 2, @"error");
    self.inputSourceParam.arrayFrameBuffer = array;
    self.inputSourceParam.mat33ParamValue = *((GPUMatrix3x3 *)preferredConversion);
}



- (BBZInputSourceParam *)inputSourceAtTime:(CMTime)time {
    return self.inputSourceParam;
}

- (void)lock {
    [super lock];
    if(!self.reader) {
        [self buildReader];
        [self.videoOutPut startProcessing];
    }
}

- (void)setSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if(sampleBuffer &&  _sampleBuffer == sampleBuffer) {
        return;
    }
    if(sampleBuffer) {
        CFRetain(sampleBuffer);
    }
    if(_sampleBuffer) {
        CFRelease(_sampleBuffer);
        _sampleBuffer = nil;
    }
    _sampleBuffer = sampleBuffer;
}

- (void)destroySomething{
    self.sampleBuffer = nil;
    [self.videoOutPut endProcessing];
    [self.reader removeOutput:self.videoOutPut];
    self.videoOutPut = nil;
    self.reader = nil;
}

@end
