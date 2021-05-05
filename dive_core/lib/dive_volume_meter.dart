import 'dart:async';
import 'package:dive_core/dive_core.dart';
import 'package:dive_obslib/dive_obslib.dart';
import 'package:riverpod/riverpod.dart';

/// The state model for a volume meter.
class DiveVolumeMeterState {
  final int channelCount;
  final List<dynamic> inputPeak;
  final List<dynamic> magnitude;
  final List<dynamic> peak;
  final List<dynamic> peakDecayed;
  final DateTime lastUpdateTime;
  final bool noSignal;

  DiveVolumeMeterState({
    this.channelCount,
    this.inputPeak,
    this.magnitude,
    this.peak,
    this.peakDecayed,
    this.lastUpdateTime,
    this.noSignal,
  });

  DiveVolumeMeterState copyWith({
    channelCount,
    inputPeak,
    magnitude,
    peak,
    peakDecayed,
    lastUpdateTime,
    noSignal,
  }) {
    return DiveVolumeMeterState(
      channelCount: channelCount ?? this.channelCount,
      inputPeak: inputPeak ?? this.inputPeak,
      magnitude: magnitude ?? this.magnitude,
      peak: peak ?? this.peak,
      peakDecayed: peakDecayed ?? this.peakDecayed,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      noSignal: noSignal ?? this.noSignal,
    );
  }

  @override
  String toString() {
    return "DiveVolumeMeterState: channelCount=$channelCount";
  }
}

class DiveVolumeMeterStateNotifier extends StateNotifier<DiveVolumeMeterState> {
  DiveVolumeMeterState get stateModel => state;

  DiveVolumeMeterStateNotifier(DiveVolumeMeterState stateModel)
      : super(stateModel ?? DiveVolumeMeterState());

  void updateState(DiveVolumeMeterState stateModel) {
    state = stateModel;
  }
}

class DiveVolumeMeter {
  DivePointer _pointer;
  DivePointer get pointer => _pointer;
  Timer _noSignalTimer;
  Stopwatch _stopwatch;

  final stateProvider = StateNotifierProvider<DiveVolumeMeterStateNotifier>(
      (ref) => DiveVolumeMeterStateNotifier(null));

  void dispose() {
    obslib.volumeMeterDestroy(_pointer);
    _pointer = null;
    if (_noSignalTimer != null) {
      _noSignalTimer.cancel();
    }
  }

  Future<DiveVolumeMeter> create({DiveSource source}) async {
    _pointer = obslib.volumeMeterCreate();
    final rv = obslib.volumeMeterAttachSource(_pointer, source.pointer);
    if (!rv) {
      dispose();
      return null;
    }

    int channelCount =
        await obslib.addVolumeMeterCallback(_pointer.address, _callback);

    DiveCore.notifierFor(stateProvider)
        .updateState(DiveVolumeMeterState(channelCount: channelCount));

    return this;
  }

  void _callback(int volumeMeterPointer, List<dynamic> magnitude,
      List<dynamic> peak, List<dynamic> inputPeak) {
    assert(magnitude.length == peak.length && peak.length == inputPeak.length);
    if (_pointer.toInt() != volumeMeterPointer) return;

    // Determine the elapsed time since the last update
    double elapsedTime;
    if (_stopwatch == null) {
      _stopwatch = Stopwatch()..start();
      elapsedTime = 0.0;
    } else {
      elapsedTime = _stopwatch.elapsedMilliseconds / 1000.0;
      _stopwatch
        ..stop()
        ..start();
    }

    final currentState = DiveCore.notifierFor(stateProvider).stateModel;

    // Determine decay of audio since last update (seconds).
    const double peakDecayRate = 20.0 / 1.7;
    final peakDecay = peakDecayRate * elapsedTime;

    // For each channel
    final peakDecayed = currentState.peakDecayed == null
        ? List.filled(currentState.channelCount, -1000.0)
        : currentState.peakDecayed;

    for (var channel = 0; channel < currentState.channelCount; channel++) {
      if (peak[channel] >= peakDecayed[channel]) {
        peakDecayed[channel] = peak[channel];
      } else {
        peakDecayed[channel] =
            (peakDecayed[channel] - peakDecay).clamp(peak[channel], 0.0);
      }
    }

    // Update the state and notify
    final newState = currentState.copyWith(
      magnitude: magnitude,
      peak: peak,
      inputPeak: inputPeak,
      lastUpdateTime: DateTime.now(),
      noSignal: false,
    );
    DiveCore.notifierFor(stateProvider).updateState(newState);

    // Start the no signal timer
    if (_noSignalTimer != null) {
      _noSignalTimer.cancel();
    }
    _noSignalTimer = Timer(Duration(milliseconds: 500), noSignalTimeout);
  }

  void noSignalTimeout() {
    _noSignalTimer.cancel();
    _noSignalTimer = null;

    final currentState = DiveCore.notifierFor(stateProvider).stateModel;
    // Update the state and notify
    final newState = currentState.copyWith(
      noSignal: true,
    );
    DiveCore.notifierFor(stateProvider).updateState(newState);
  }
}
