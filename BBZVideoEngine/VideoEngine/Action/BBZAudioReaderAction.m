//
//  BBZAudioReaderAction.m
//  BBZVideoEngine
//
//  Created by bob on 2020/6/10.
//  Copyright © 2020年 BBZ. All rights reserved.
//

#import "BBZAudioReaderAction.h"
#import "BBZAssetReader.h"
#import "BBZVideoAsset.h"
#import "GPUImageOutput.h"

@interface BBZAudioReaderAction ()
@property (nonatomic, strong) BBZAssetReader *reader;
@property (nonatomic, strong) BBZAssetReaderAudioOutput *audioOutPut;
@property (nonatomic, strong) BBZInputAudioParam *inputAudioParam;
@property (nonatomic, assign) CMSampleBufferRef sampleBuffer;
@end


@implementation BBZAudioReaderAction

- (void)buildReader {
    if(!self.reader) {
        self.reader = [[BBZAssetReader alloc] initWithAsset:self.audioCompostion.asset videoComposition:nil audioMix:self.audioCompostion.audioMix];
        self.reader.timeRange = self.audioCompostion.playTimeRange;
        self.audioOutPut = [[BBZAssetReaderAudioOutput alloc] initWithOutputSettings:self.audioCompostion.audioSetting];
        [self.reader addOutput:self.audioOutPut];
        self.inputAudioParam = [[BBZInputAudioParam alloc] init];
    }
}

- (void)updateWithTime:(CMTime)time {
    
}

- (void)newFrameAtTime:(CMTime)time {
    runAsynchronouslyOnVideoProcessingQueue(^{
        CMSampleBufferRef sampleBuffer = self.sampleBuffer;
        if(!sampleBuffer) {
            sampleBuffer = [self.audioOutPut nextSampleBuffer];
        }
        if(!sampleBuffer) {
            self.inputAudioParam.sampleBuffer = nil;
            self.inputAudioParam.time = time;
            return ;
        }
        CMTime lastSamplePresentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        lastSamplePresentationTime = CMTimeSubtract(lastSamplePresentationTime, self.reader.timeRange.start);
        NSTimeInterval nDiff = CMTimeGetSeconds(CMTimeSubtract(lastSamplePresentationTime, time));
        NSTimeInterval minDuration = 0.3;
        if(nDiff > minDuration) {
            BBZERROR(@"newFrameAtTime skip dif:%f sample time:%@, realtime:%@", nDiff,[NSValue valueWithCMTime:lastSamplePresentationTime], [NSValue valueWithCMTime:time]);
            self.sampleBuffer = sampleBuffer;
            self.inputAudioParam.sampleBuffer = nil;
            self.inputAudioParam.time = time;
            return;
            
        }
        self.inputAudioParam.sampleBuffer = [self adjustTime:sampleBuffer by:self.reader.timeRange.start];
        self.inputAudioParam.time = time;
        self.sampleBuffer = nil;
        lastSamplePresentationTime = CMSampleBufferGetPresentationTimeStamp(self.inputAudioParam.sampleBuffer);
        BBZINFO(@"audio sample time:%@, realtime:%@", [NSValue valueWithCMTime:lastSamplePresentationTime], [NSValue valueWithCMTime:time]);
    
        
    });
}

- (CMSampleBufferRef)adjustTime:(CMSampleBufferRef) sample by:(CMTime) offset {
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    
    for (CMItemCount i = 0; i < count; i++) {
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    
    return sout;
}


- (BBZInputAudioParam *)inputAudioAtTime:(CMTime)time {
    return self.inputAudioParam;
}
- (void)lock {
    [super lock];
    if(!self.reader) {
        [self buildReader];
        [self.audioOutPut startProcessing];
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
    [self.audioOutPut endProcessing];
    self.inputAudioParam.sampleBuffer = nil;
    [self.reader removeOutput:self.audioOutPut];
    self.audioOutPut = nil;
    self.reader = nil;
}


@end