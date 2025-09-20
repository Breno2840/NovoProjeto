import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

// URL da sua rádio
const String streamUrl = 'https://tropical.jmvstream.com/stream';

// Ponto de entrada principal para o serviço de áudio
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa o serviço de áudio e o conecta ao nosso manipulador de áudio
  final audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.calculadora.my.channel.audio',
      androidNotificationChannelName: 'Reprodução de Áudio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
  runApp(MyApp(audioHandler: audioHandler));
}

// O manipulador de áudio que conecta o serviço de áudio ao nosso player (just_audio)
class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  AudioPlayerHandler() {
    // Configura a URL da rádio quando o manipulador é criado
    _init();
    
    // Propaga o estado de reprodução do player para o serviço de áudio
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  Future<void> _init() async {
    try {
      // Define a MediaItem que será exibida na notificação e tela de bloqueio
      final mediaItem = const MediaItem(
        id: streamUrl,
        album: 'Rádio Ao Vivo',
        title: 'Tropical FM',
        artist: 'JMV Stream',
        // artUri: Uri.parse('URL_DA_IMAGEM_DA_RADIO'), // Descomente para por uma imagem
      );

      // Define a URL do áudio no player
      await _player.setAudioSource(AudioSource.uri(Uri.parse(streamUrl)));
      // Informa ao serviço de áudio qual mídia está pronta
      this.mediaItem.add(mediaItem);

    } catch (e) {
      print("Erro ao carregar a fonte de áudio: $e");
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }
  
  // Transforma os eventos do just_audio no modelo de estado do audio_service
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0],
      processingState: _getProcessingState(event),
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  // Mapeia o estado do player para o estado do serviço de áudio
  AudioProcessingState _getProcessingState(PlaybackEvent event) {
    switch (event.processingState) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      default:
        // CORREÇÃO AQUI: Trocado 'unknown' por 'error'
        return AudioProcessingState.error;
    }
  }
}

// A interface do usuário do nosso aplicativo
class MyApp extends StatelessWidget {
  final AudioPlayerHandler audioHandler;

  const MyApp({super.key, required this.audioHandler});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minha Rádio',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Rádio Tropical FM'),
          backgroundColor: Colors.black87,
        ),
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.blueGrey],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StreamBuilder<MediaItem?>(
                stream: audioHandler.mediaItem,
                builder: (context, snapshot) {
                  final mediaItem = snapshot.data;
                  return Text(
                    mediaItem?.title ?? 'Carregando...',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  );
                },
              ),
              const SizedBox(height: 20),
              StreamBuilder<PlaybackState>(
                stream: audioHandler.playbackState,
                builder: (context, snapshot) {
                  final playbackState = snapshot.data;
                  final processingState = playbackState?.processingState;
                  final playing = playbackState?.playing ?? false;

                  if (processingState == AudioProcessingState.loading ||
                      processingState == AudioProcessingState.buffering) {
                    return const SizedBox(
                      width: 64.0,
                      height: 64.0,
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  } else if (!playing) {
                    return IconButton(
                      icon: const Icon(Icons.play_circle_fill),
                      iconSize: 80.0,
                      color: Colors.white,
                      onPressed: audioHandler.play,
                    );
                  } else {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          // CORREÇÃO AQUI: Trocado 'pause_circle_fill' por 'pause_circle_filled'
                          icon: const Icon(Icons.pause_circle_filled),
                          iconSize: 80.0,
                          color: Colors.white,
                          onPressed: audioHandler.pause,
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: const Icon(Icons.stop_circle_outlined),
                          iconSize: 80.0,
                          color: Colors.white70,
                          onPressed: audioHandler.stop,
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
