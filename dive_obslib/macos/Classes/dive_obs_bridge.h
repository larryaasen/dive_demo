//
//  dive_obs_bridge.h
//
//  Created by Larry Aasen on 11/23/20.
//

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

NS_ASSUME_NONNULL_BEGIN

@class TextureSource;
void addFrameCapture(TextureSource *textureSource);
void removeFrameCapture(TextureSource *textureSource);

bool bridge_obs_startup(void);

bool load_obs(void);

#pragma mark - Bridge functions

bool    bridge_add_videomix(const char *tracking_uuid);
bool    bridge_remove_videomix(const char *tracking_uuid);

NS_ASSUME_NONNULL_END

#ifdef __cplusplus
}
#endif
