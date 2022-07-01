import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:livekit_client/livekit_client.dart';

abstract class ParticipantView extends StatefulWidget {
  // Convenience method to return relevant widget for participant
  static ParticipantView widgetFor(Participant participant) {
    if (participant is LocalParticipant) {
      return _LocalParticipantView(participant);
    } else if (participant is RemoteParticipant) {
      return _RemoteParticipantView(participant);
    }
    throw UnimplementedError('Unknown participant type');
  }

  // Must be implemented by child class
  abstract final Participant participant;
  final VideoQuality quality;

  const ParticipantView({
    Key? key,
    this.quality = VideoQuality.MEDIUM,
  }) : super(key: key);
}

abstract class _ParticipantViewState<T extends ParticipantView>
    extends State<T> {
  VideoTrack? get activeVideoTrack;

  TrackPublication? get firstVideoPublication;

  TrackPublication? get firstAudioPublication;

  @override
  void initState() {
    widget.participant.addListener(_onParticipantChanged);
    _onParticipantChanged();
    super.initState();
  }

  @override
  void dispose() {
    widget.participant.removeListener(_onParticipantChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    oldWidget.participant.removeListener(_onParticipantChanged);
    widget.participant.addListener(_onParticipantChanged);
    _onParticipantChanged();
    super.didUpdateWidget(oldWidget);
  }

  // Notify Flutter that UI re-build is required, but we don't set anything here
  // since the updated values are computed properties.
  void _onParticipantChanged() => setState(() {
        _parseMetadata();
      });
  Map? groupMemberInfo;
  Map? groupInfo;
  Map? userInfo;

  // widget.participant.name.isNotEmpty
  // ? '${widget.participant.name} (${widget.participant.identity})'
  //     : widget.participant.identity
  String get name => userInfo?['nickname'] ?? widget.participant.identity;

  String? get faceURL => userInfo?['faceURL'];

  void _parseMetadata() {
    /*try {
      print('-----------_parseMetadata-------${widget.participant.metadata}');
      if (widget.participant.metadata == null) return;
      var data = json.decode(widget.participant.metadata!);
      groupInfo = data['groupInfo'];
      groupMemberInfo = data['groupMemberInfo'];
      userInfo = data['userInfo'];
    } catch (_) {}*/
  }
}

class _LocalParticipantView extends ParticipantView {
  const _LocalParticipantView(this.participant, {Key? key}) : super(key: key);

  @override
  final LocalParticipant participant;

  @override
  _LocalParticipantViewState createState() => _LocalParticipantViewState();
}

class _LocalParticipantViewState
    extends _ParticipantViewState<_LocalParticipantView> {
  @override
  LocalTrackPublication<LocalVideoTrack>? get firstVideoPublication =>
      widget.participant.videoTracks.firstOrNull;

  @override
  LocalTrackPublication<LocalAudioTrack>? get firstAudioPublication =>
      widget.participant.audioTracks.firstOrNull;

  @override
  VideoTrack? get activeVideoTrack {
    if (firstVideoPublication?.subscribed == true &&
        firstVideoPublication?.muted == false) {
      return firstVideoPublication?.track;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: activeVideoTrack != null
          ? VideoTrackRenderer(
              activeVideoTrack!,
              fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          : null,
    );
  }
}

class _RemoteParticipantView extends ParticipantView {
  const _RemoteParticipantView(this.participant, {Key? key}) : super(key: key);

  @override
  final RemoteParticipant participant;

  @override
  _RemoteParticipantViewState createState() => _RemoteParticipantViewState();
}

class _RemoteParticipantViewState
    extends _ParticipantViewState<_RemoteParticipantView> {
  @override
  RemoteTrackPublication<RemoteVideoTrack>? get firstVideoPublication =>
      widget.participant.videoTracks.firstOrNull;

  @override
  RemoteTrackPublication<RemoteAudioTrack>? get firstAudioPublication =>
      widget.participant.audioTracks.firstOrNull;

  @override
  VideoTrack? get activeVideoTrack {
    for (final trackPublication in widget.participant.videoTracks) {
      print(
          'video track ${trackPublication.sid} subscribed ${trackPublication.subscribed} muted ${trackPublication.muted}');
      if (trackPublication.subscribed && !trackPublication.muted) {
        return trackPublication.track;
      }
    }
    return null;
  }

  /// RTCVideoViewObjectFitContain
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: activeVideoTrack != null
          ? VideoTrackRenderer(
              activeVideoTrack!,
              fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          : null,
    );
  }
}
