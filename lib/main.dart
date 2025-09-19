import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

Future<void> main() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.calculadora.my.radio',
    androidNotificationChannelName: 'Rádio Tropical',
    androidNotificationChannelDescription: 'Reprodução de áudio em background',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rádio Tropical',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AudioServiceWidget(child: RadioApp()),
    );
  }
}

class RadioApp extends StatefulWidget {
  @override
  _RadioAppState createState() => _RadioAppState();
}

class _RadioAppState extends State<RadioApp> {
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _checkPlayingStatus();
  }

  Future<void> _checkPlayingStatus() async {
    final isPlaying = await AudioService.isRunning();
    setState(() {
      _isPlaying = isPlaying;
    });
  }

  Future<void> _play() async {
    try {
      await AudioService.start(
        backgroundTaskEntrypoint: _audioPlayerTaskEntrypoint,
        androidNotificationChannelName: 'Rádio Tropical',
        androidNotificationColor: Colors.blue.value,
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidEnableQueue: false,
        params: {'url': 'https://tropical.jmvstream.com/stream'},
      );
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      print("Error starting audio service: $e");
    }
  }

  Future<void> _stop() async {
    await AudioService.stop();
    setState(() {
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rádio Tropical'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.radio,
              size: 100,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              'Rádio Tropical',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Transmitindo ao vivo',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isPlaying ? null : _play,
                  child: Icon(Icons.play_arrow, size: 30),
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(20),
                    primary: Colors.blue,
                    onPrimary: Colors.white,
                  ),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _isPlaying ? _stop : null,
                  child: Icon(Icons.stop, size: 30),
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(20),
                    primary: Colors.red,
                    onPrimary: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            StreamBuilder<PlaybackState>(
              stream: AudioService.playbackStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                if (state?.processingState == AudioProcessingState.buffering) {
                  return CircularProgressIndicator();
                }
                return SizedBox();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Background task entrypoint
void _audioPlayerTaskEntrypoint() async {
  AudioServiceBackground.run(() => AudioPlayerTask());
}

class AudioPlayerTask extends BackgroundAudioTask {
  final _player = AudioPlayer();
  MediaItem? _mediaItem;

  @override
  Future<void> onStart(Map<String, dynamic>? params) async {
    final url = params?['url'] ?? 'https://tropical.jmvstream.com/stream';
    
    _mediaItem = MediaItem(
      id: url,
      album: "Rádio Tropical",
      title: "Rádio Tropical - Ao Vivo",
      artist: "Tropical Hits",
      artUri: Uri.parse('https://tropicalradio.com/logo.png'), // Substitua por uma imagem real
    );
    
    AudioServiceBackground.setMediaItem(_mediaItem!);
    
    try {
      await _player.setAudioSource(AudioSource.uri(
        Uri.parse(url),
        tag: _mediaItem,
      ));
      
      AudioServiceBackground.setState(
        controls: [
          MediaControl(androidIcon: 'drawable/ic_action_play', label: 'Play', action: MediaAction.play),
          MediaControl(androidIcon: 'drawable/ic_action_stop', label: 'Stop', action: MediaAction.stop),
        ],
        processingState: AudioProcessingState.ready,
        playing: true,
      );
      
      _player.playbackEventStream.listen((event) {
        final state = _player.processingState;
        if (state == ProcessingState.completed) {
          AudioServiceBackground.setState(
            processingState: AudioProcessingState.completed,
            playing: false,
          );
        }
      });
      
      await _player.play();
    } catch (e) {
      print("Error playing audio: $e");
      AudioServiceBackground.setState(
        processingState: AudioProcessingState.error,
        playing: false,
      );
    }
  }

  @override
  Future<void> onPlay() async {
    await _player.play();
    AudioServiceBackground.setState(playing: true);
  }

  @override
  Future<void> onPause() async {
    await _player.pause();
    AudioServiceBackground.setState(playing: false);
  }

  @override
  Future<void> onStop() async {
    await _player.stop();
    await _player.dispose();
    AudioServiceBackground.setState(
      processingState: AudioProcessingState.stopped,
      playing: false,
    );
    await super.onStop();
  }

  @override
  Future<void> onSeekTo(Duration position) async {
    await _player.seek(position);
  }
}