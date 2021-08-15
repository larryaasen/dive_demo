# Dive Demo

Dive is a video recording and streaming platform built on top of Dart and
Flutter with native extensions on macOS. This is just a partial demo and
should not be used in released apps.

This example works on Flutter channel stable versions 2.0.5 and 2.0.6, but does not work
on channel master 2.2.0-11.0.pre.260. The failure is with the texture and
the video does not display. Here is the error message:

      2021-06-20 22:03:00.707 dive_ui_example[16557:15547844] Could not create Metal texture from pixel buffer: CVReturn -6660
      [ERROR:flutter/shell/platform/embedder/embedder_external_texture_metal.mm(59)] External texture callback for ID 140188384787824 did not return a valid texture.

Update (8/15/2021) - this demo now works on channel master 2.4.0-5.0.pre.181.

## Running the Dive Flutter macOS demo

      $ cd dive_ui/example
      $ flutter run -d macos
