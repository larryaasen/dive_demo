#include <stdio.h>
#include <string.h>
#include <time.h>
#include <functional>
#include <map>
#include <memory>

#include "dive_obs_bridge.h"
#include "TextureSource.h"
#include <dive_obslib/dive_obslib-Swift.h>


struct key_cmp_str
{
   bool operator()(char const *a, char const *b) const
   {
      return std::strcmp(a, b) < 0;
   }
};

static std::map<unsigned int, const char *> videomix_uuid_list;

/// Map of all texture sources where the key is a source UUID and the value is a texture source pointer
static std::map<const char *, TextureSource *, key_cmp_str> _textureSourceMap;
/// A duplicate map of all texture source that provides Objective-C reference counting
static NSMutableDictionary *_textureSources = [NSMutableDictionary new];

static bool useSampleFrame = true;
static NSData *theData = NULL;

static void videomix_callback(void *param, struct video_data *frame);

void addFrameCapture(TextureSource *textureSource) {
    if (textureSource == NULL) {
        printf("addFrameCapture: missing textureSource\n");
        return;
    }
    
    if (textureSource.trackingUUID == NULL || textureSource.trackingUUID.length == 0) {
        printf("addFrameCapture: missing sourceUUID\n");
        return;
    }

    const char *uuid_str = textureSource.trackingUUID.UTF8String;

    @synchronized (_textureSources) {
        TextureSource *source = _textureSources[textureSource.trackingUUID];
        if (source != NULL) {
            printf("addFrameCapture: duplicate texture source: %s\n", uuid_str);
            return;
        }
        [_textureSources setObject:textureSource forKey:textureSource.trackingUUID];
        _textureSourceMap[uuid_str] = textureSource;
    }

    printf("addFrameCapture: added texture source: %s\n", uuid_str);
}

void removeFrameCapture(TextureSource *textureSource) {
    if (textureSource == NULL) {
        printf("removeFrameCapture: missing textureSource\n");
        return;
    }
    
    if (textureSource.trackingUUID == NULL || textureSource.trackingUUID.length == 0) {
        printf("removeFrameCapture: missing sourceUUID\n");
        return;
    }

    const char *uuid_str = textureSource.trackingUUID.UTF8String;

    @synchronized (_textureSources) {
        TextureSource *source = _textureSources[textureSource.trackingUUID];
        if (source == NULL) {
            printf("removeFrameCapture: unknown texture source: %s\n", uuid_str);
            return;
        }

        [_textureSources removeObjectForKey:textureSource.trackingUUID];
        _textureSourceMap.erase(uuid_str);
    }
}

static void add_videomix_callback(const char *tracking_uuid) {
    const char *tracking_uuid_str = strdup(tracking_uuid);
    
    unsigned int index = 0;
    videomix_uuid_list[index] = tracking_uuid_str;
    
    if (useSampleFrame) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            videomix_callback(NULL, NULL);
        });
        return;
    }
}

static void remove_videomix_callback(const char *tracking_uuid) {
}

bool load_obs(void)
{
    return true;
}

bool bridge_obs_startup(void)
{
    return true;
}

void BufferReleaseBytesCallback(void *releaseRefCon, const void *baseAddress) {
    free((void *)baseAddress);
    return;
}

static void copy_frame_to_texture(size_t width, size_t height, OSType pixelFormatType, size_t linesize, uint8_t *data,
                                  TextureSource *textureSource, bool shouldSwapRedBlue=false)
{
    if (useSampleFrame) {
        if (theData == NULL) {
            NSString *path =
              [[NSBundle mainBundle] pathForResource:@"demo_frame"
                                              ofType:@""];
            theData = [NSData dataWithContentsOfFile:path];
        }
        data = (uint8_t *)[theData bytes];
        width=1280;
        height=720;
        pixelFormatType=kCVPixelFormatType_32BGRA;
        linesize=width*4;
    }

    NSDictionary *attributes = @{
        (NSString *)kCVPixelBufferMetalCompatibilityKey : @YES
    };

    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, pixelFormatType, (__bridge CFDictionaryRef)attributes, &pxbuffer);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);

    void *copyBaseAddress = CVPixelBufferGetBaseAddress(pxbuffer);
    memcpy(copyBaseAddress, data, linesize*height);

    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    if (status != kCVReturnSuccess || pxbuffer == NULL) {
        NSLog(@"copy_frame_to_source: Operation failed");
        return;
    }

    [textureSource captureSample: pxbuffer];
//    CFRelease(pxbuffer);
    
    // -6660: An otherwise undefined error occurred.
    
    /*
     https://developer.apple.com/library/archive/qa/qa1781/_index.html
     Important: You cannot use CVPixelBufferCreateWithBytes() or CVPixelBufferCreateWithPlanarBytes() with
     kCVPixelBufferIOSurfacePropertiesKey. Calling CVPixelBufferCreateWithBytes() or CVPixelBufferCreateWithPlanarBytes()
     will result in CVPixelBuffers that are not IOSurface-backed and thus failure in creating CVOpenGLESTextures from
     these pixel buffers. Must use CVPixelBufferCreate().
     */
}

static void copy_frame_to_texture_ORIGINAL(size_t width, size_t height, OSType pixelFormatType, size_t linesize, uint8_t *data,
                                  TextureSource *textureSource, bool shouldSwapRedBlue=false)
{
    if (useSampleFrame) {
        if (theData == NULL) {
            NSString *path =
              [[NSBundle mainBundle] pathForResource:@"demo_frame"
                                              ofType:@""];
            theData = [NSData dataWithContentsOfFile:path];
        }
        data = (uint8_t *)[theData bytes];
        width=1280;
        height=720;
        pixelFormatType=kCVPixelFormatType_32BGRA;
        linesize=5120;
    }

    CVPixelBufferRef pxbuffer = NULL;
    CVPixelBufferReleaseBytesCallback releaseCallback = shouldSwapRedBlue && !useSampleFrame ? BufferReleaseBytesCallback : NULL;
    NSDictionary* attributes = @{
        (id)kCVPixelBufferPixelFormatTypeKey : @(pixelFormatType),
        (id)kCVPixelBufferOpenGLCompatibilityKey : @YES,
        (NSString*)kCVPixelBufferMetalCompatibilityKey : @YES
    };
    
    CVReturn status = CVPixelBufferCreateWithBytes(kCFAllocatorDefault,
                                                   width,
                                                   height,
                                                   pixelFormatType,
                                                   data,
                                                   linesize,
                                                   releaseCallback,
                                                   NULL,
                                                   (__bridge CFDictionaryRef)attributes,
                                                   &pxbuffer);
    if (status != kCVReturnSuccess || pxbuffer == NULL) {
        NSLog(@"copy_frame_to_source: Operation failed");
        return;
    }

    [textureSource captureSample: pxbuffer];
    CFRelease(pxbuffer);
}

static void videomix_callback(void *param, struct video_data *frame) {
//    printf("%s linesize[0] %d\n", __func__, frame->linesize[0]);

    unsigned int index = 0;
    const char *uuid_str = videomix_uuid_list[index];
    if (uuid_str == NULL) {
        printf("%s: no texture source for videomix[0]\n", __func__);
        return;
    }
    @synchronized (_textureSources) {
        TextureSource *textureSource = _textureSourceMap[uuid_str];
        if (textureSource != NULL) {
            copy_frame_to_texture(0, 0, kCVPixelFormatType_32BGRA, 0, NULL, textureSource, true);
        } else {
            printf("%s: no texture source for %s\n", __func__, uuid_str);
        }
    }
}

bool bridge_add_videomix(const char *tracking_uuid) {
    add_videomix_callback(tracking_uuid);
    return true;
}

bool bridge_remove_videomix(const char *tracking_uuid) {
    remove_videomix_callback(tracking_uuid);
    return true;
}
