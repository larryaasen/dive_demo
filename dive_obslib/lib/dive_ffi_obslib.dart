import 'package:dive_obslib/dive_obslib.dart';

import 'dive_obs_ffi.dart';
import 'dive_ffi_load.dart';

import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

/// The FFI loaded libobs library.
DiveObslibFFI _lib;

/// Tracks the first scene being created, and sets the output source if first
bool _isFirstScene = true;

/// The streaming service output.
var _streamOutput;

/// Connects to obslib using FFI. Will load the obslib library, load modules,
/// reset video and audio, and create the streaming service.
extension DiveFFIObslib on DiveBaseObslib {
  // FYI: Don't call obs_startup because it must run on the main thread
  // and FFI does not run on the main thread.

  static void initialize() {
    assert(_lib == null, 'initialize() has already been called once.');
    // _lib = DiveObslibFFILoad.loadLib();
  }

  bool loadAllModules() {
    print("dive_obslib: load_all_modules");
    print("dive_obslib: post_load_modules");
    return true;
  }

  bool resetVideo(int width, int height) {
    final ovi = calloc<obs_video_info>();
    ovi.ref
      ..adapter = 0
      ..fps_num = 30000
      ..fps_den = 1001
      ..graphics_module = 'libobs-opengl'.toInt8() //DL_OPENGL
      ..output_format = video_format.VIDEO_FORMAT_RGBA
      ..base_width = width
      ..base_height = height
      ..output_width = width
      ..output_height = height
      ..colorspace = video_colorspace.VIDEO_CS_DEFAULT;

    return true;
  }

  bool resetAudio() {
    final ai = calloc<obs_audio_info>();
    ai.ref
      ..samples_per_sec = 48000
      ..speakers = speaker_layout.SPEAKERS_STEREO;
    return true;
  }

  bool createService() {
    return true;
  }

  Future<DivePointer> createScene(String trackingUUID, String sceneName) {
    return Future.value(DivePointer(trackingUUID, null));
  }

  DivePointer createImageSource(String sourceUuid, String file) {
    return _createSourceInternal(sourceUuid, "image_source", "image", null);
  }

  DivePointer createMediaSource(String sourceUuid, String localFile) {
    return _createSourceInternal(
        sourceUuid, "ffmpeg_source", "video file", null);
  }

  DivePointer createVideoSource(
      String sourceUuid, String deviceName, String deviceUid) {
    return _createSourceInternal(
        sourceUuid, "av_capture_input", "camera", null);
  }

  DivePointer createSource(String sourceUuid, String sourceId, String name) {
    return DivePointer(sourceUuid, null);
  }

  // static const except = -1;

  /// If you see this message: The method 'FfiTrampoline' was called on null
  /// make sure to use nullptr instead of null.
  /// https://github.com/dart-lang/sdk/issues/39804#

  DivePointer _createSourceInternal(
    String sourceUuid,
    String sourceId,
    String name,
    ffi.Pointer<obs_data> settings,
  ) {
    return DivePointer(sourceUuid, null);
  }

  /// Add an existing source to an existing scene, and return sceneitem id.
  int addSource(DivePointer scene, DivePointer source) {
    return 1;
  }

  /// Get the transform info for a scene item.
  /// TODO: this does not work because of FFI struct issues.
  Map sceneitemGetInfo(DivePointer scene, int itemId) {
    if (itemId < 1) {
      print("invalid item id $itemId");
      return null;
    }

    return null; // _convert_transform_info_to_dict(info);
  }

  /// Stream Controls

  /// Start the stream output.
  bool streamOutputStart() {
    return true;
  }

  /// Stop the stream output.
  void streamOutputStop() {}

  /// Get the output state: 1 (active), 2 (paused), or 3 (reconnecting)
  int outputGetState() {
    return 0;
  }

  /// Media Controls
  /// TODO: implement signals from media source: obs_source_get_signal_handler

  /// Media control: play_pause
  void mediaSourcePlayPause(DivePointer source, bool pause) {}

  /// Media control: restart
  void mediaSourceRestart(DivePointer source) {}

  /// Media control: stop
  void mediaSourceStop(DivePointer source) {}

  /// Media control: get time
  int mediaSourceGetDuration(DivePointer source) {
    return 0;
  }

  /// Media control: get time
  int mediaSourceGetTime(DivePointer source) {
    return _lib.obs_source_media_get_time(source.pointer);
  }

  /// Media control: set time
  void mediaSourceSetTime(DivePointer source, int ms) {
    _lib.obs_source_media_set_time(source.pointer, ms);
  }

  /// Media control: get state
  int mediaSourceGetState(DivePointer source) {
    return _lib.obs_source_media_get_state(source.pointer);
  }

  /// Create a volume meter.
  DivePointer volumeMeterCreate({
    int faderType = obs_fader_type.OBS_FADER_LOG,
  }) {
    final volmeter = _lib.obs_volmeter_create(faderType);
    return DivePointer(null, volmeter);
  }

  /// Attache a source to a volume meter.
  bool volumeMeterAttachSource(DivePointer volumeMeter, DivePointer source) {
    final rv =
        _lib.obs_volmeter_attach_source(volumeMeter.pointer, source.pointer);
    return rv == 1;
  }

  /// Set the peak meter type for the volume meter.
  void volumeMeterSetPeakMeterType(DivePointer volumeMeter,
      {int meterType = obs_peak_meter_type.SAMPLE_PEAK_METER}) {
    _lib.obs_volmeter_set_peak_meter_type(volumeMeter.pointer, meterType);
  }

  /// Get the number of channels which are configured for this source.
  int volumeMeterGetNumberChannels(DivePointer volumeMeter) {
    return _lib.obs_volmeter_get_nr_channels(volumeMeter.pointer);
  }

  /// Destroy a volume meter.
  void volumeMeterDestroy(DivePointer volumeMeter) {
    _lib.obs_volmeter_destroy(volumeMeter.pointer);
  }

  /// Get a list of input types.
  /// Returns array of dictionaries with keys `id` and `name`.
  List<Map<String, String>> inputTypes() {
    int idx = 0;
    final List<Map<String, String>> list = [];

    ffi.Pointer<ffi.Pointer<ffi.Int8>> typeId = calloc();
    ffi.Pointer<ffi.Pointer<ffi.Int8>> unversionedTypeId = calloc();

    while (_lib.obs_enum_input_types2(idx++, typeId, unversionedTypeId) != 0) {
      final name = _lib.obs_source_get_display_name(typeId.value);
      final caps = _lib.obs_get_source_output_flags(typeId.value);

      if ((caps & OBS_SOURCE_CAP_DISABLED) != 0) continue;

      bool deprecated = (caps & OBS_SOURCE_DEPRECATED) != 0;
      if (deprecated) {
      } else {}

      list.add({
        "id": StringExtensions.fromInt8(unversionedTypeId.value),
        "name": StringExtensions.fromInt8(name)
      });
    }
    return list;
  }

  /// Get a list of inputs from input type.
  /// Returns an array of maps with keys `id` and `name`.
  List<Map<String, String>> inputsFromType(String inputTypeId) {
    final List<Map<String, String>> list = [];

    final sourceProps = _lib.obs_get_source_properties(inputTypeId.int8());

    if (sourceProps != null) {
      ffi.Pointer<ffi.Pointer<obs_property>> propertyOut = calloc();

      var property = _lib.obs_properties_first(sourceProps);
      while (property != null) {
        final type = _lib.obs_property_get_type(property);
        if (type == obs_property_type.OBS_PROPERTY_LIST) {
          final count = _lib.obs_property_list_item_count(property);
          for (int index = 0; index < count; index++) {
            final disabled =
                _lib.obs_property_list_item_disabled(property, index);
            final name = _lib.obs_property_list_item_name(property, index);
            final uid = _lib.obs_property_list_item_string(property, index);
            if (disabled == 0 &&
                name.address != 0 &&
                uid.address != 0 &&
                StringExtensions.fromInt8(name).isNotEmpty &&
                StringExtensions.fromInt8(uid).isNotEmpty) {
              list.add({
                "id": StringExtensions.fromInt8(uid),
                "name": StringExtensions.fromInt8(name),
                "type_id": inputTypeId
              });
            }
          }
        }
        propertyOut.value = property;
        final rv = _lib.obs_property_next(propertyOut);
        property = rv == 1 ? propertyOut.value : null;
      }
      _lib.obs_properties_destroy(sourceProps);
    }
    StringExtensions.freeInt8s();

    return list;
  }

  /// Get a list of video capture inputs from input type `coreaudio_input_capture`.
  /// @return array of dictionaries with keys `id` and `name`.
  List<Map<String, String>> audioInputs() {
    return inputsFromType(DiveObsAudioSourceType.INPUT_AUDIO_SOURCE);
  }

  /// Get a list of video capture inputs from input type `av_capture_input`.
  /// Returns an array of maps with keys `id` and `name`.
  List<Map<String, String>> videoInputs() {
    return inputsFromType("av_capture_input");
  }
}
