import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sw1/src/controllers/speech_to_text.dart';
import 'package:flutter_sw1/src/controllers/text_to_speech.dart';
import 'package:flutter_sw1/src/models/message.dart';
import 'package:flutter_sw1/src/models/user.dart';
import 'package:flutter_sw1/src/providers/user_provider.dart';
import 'package:flutter_sw1/src/services/chat_ia_service.dart';
import 'package:flutter_sw1/src/theme/app_colors.dart';
import 'package:flutter_sw1/src/widgets/appbar.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends ConsumerState<ChatPage> {
  bool isMicOn = false;
  String _response = '';
  String _lastWords = '';
  double _micOffset = 0.0;
  bool _isSpeaking = false;
  List<Message> messages = [
    Message('Hola, ¿en qué puedo ayudarte hoy?', DateTime.now(), false),
    Message('Hola', DateTime.now(), false),
    Message('¿Tienes alguna pregunta específica?', DateTime.now(), false),
    Message('Que fue', DateTime.now(), false),
    Message(
      'Estoy aquí para ayudarte con cualquier duda.',
      DateTime.now(),
      false,
    ),
    Message('Hola', DateTime.now(), true),
    Message(
      '¿Te gustaría saber más sobre nuestros servicios?',
      DateTime.now(),
      false,
    ),
    Message('Como etas', DateTime.now(), false),
    Message(
      'Recuerda que puedes preguntarme cualquier cosa.',
      DateTime.now(),
      true,
    ),
    Message('¿Qué servicios ofrecen?', DateTime.now(), true),
  ];
  String? _speakingMessageText;
  final TTSController _ttsService = TTSController();
  final STTController _speechService = STTController();
  final GptService _gptChatService = GptService();
  final ValueNotifier<String> _inputNotifier = ValueNotifier('');
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speechService.initSpeech();
    _ttsService.onSpeakingStateChanged = (isSpeaking) {
      setState(() {
        _isSpeaking = isSpeaking;

        if (!isSpeaking) _speakingMessageText = null;
      });
    };
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      _controller.text = _lastWords;
    });
  }

  void _sendMessageVoice(String text) async {
    _controller.clear();
    _micOffset = 0.0;
    setState(() {
      isMicOn = false;
    });
    Message message = Message(text, DateTime.now(), true);
    setState(() {
      messages.add(message);
      messages.add(Message('...', DateTime.now(), false));
    });

    final response = await _gptChatService.getChatResponse(text);
    print(response);
    message = Message(response, DateTime.now(), false);
    setState(() {
      _response = response;
      messages.removeLast();
      messages.add(message);
    });
    _controller.clear();
    _ttsService.speak(_response);
    _speakingMessageText = _response;
  }

  void _sendMessageText() async {
    if (_controller.text.trim().isEmpty) return;
    Message message = Message(_controller.text, DateTime.now(), true);
    setState(() {
      messages.add(message);
      messages.add(Message('...', DateTime.now(), false));
    });
    final response = await _gptChatService.getChatResponse(_controller.text);
    message = Message(response, DateTime.now(), false);
    setState(() {
      messages.removeLast();
      messages.add(message);
    });
    _ttsService.speak(message.text);
    _controller.clear();
    _speakingMessageText = message.text;
  }

  @override
  Widget build(BuildContext context) {
    User user = ref.watch(userProvider);
    return Scaffold(
      appBar: appBar(user.name!, context),
      // drawer: drawer(theme, context),
      body: Column(
        children: [
          Expanded(
            child: GroupedListView<Message, DateTime>(
              padding: const EdgeInsets.all(8),
              reverse: true,
              order: GroupedListOrder.DESC,
              useStickyGroupSeparators: true,
              floatingHeader: true,
              elements: messages,
              groupBy:
                  (message) => DateTime(
                    message.date.year,
                    message.date.month,
                    message.date.day,
                  ),
              groupHeaderBuilder: (Message message) => dateBubble(message),
              itemBuilder:
                  (context, Message message) => chatContainer(message, context),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
            height: 110,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              color: AppColors.primary,
            ),
            child: formField(),
          ),
        ],
      ),
    );
  }

  Column formField() {
    return Column(
      children: [
        TextField(
          style: TextStyle(color: Colors.white, fontSize: 18),
          minLines: 1,
          maxLines: 5,
          onChanged: (text) {
            _inputNotifier.value = text;
          },
          controller: _controller,
          onTap: () {},
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.primary,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(style: BorderStyle.none),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(style: BorderStyle.none),
            ),

            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            hintText: 'Pregunta lo que quieras',
            hintStyle: TextStyle(color: Colors.grey.shade200, fontSize: 18),
          ),
        ),
        ValueListenableBuilder(
          valueListenable: _inputNotifier,
          builder: (context, value, child) {
            return !isMicOn ? rowSendText() : rowSendVoice();
          },
        ),
      ],
    );
  }

  Row rowSendVoice() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              isMicOn = false;
              _micOffset = 0.0;
              _controller.clear();
            });
          },
          icon: Icon(Icons.close, color: Colors.white, size: 32),
        ),
        Lottie.asset('assets/voice.json', width: 50, height: 50, repeat: true),
        IconButton(
          onPressed: () async {
            _speechService.stopListening;
            _sendMessageVoice(_lastWords);
            setState(() {
              isMicOn = false;
            });
          },
          icon: Icon(Icons.check, color: Colors.white, size: 32),
        ),
      ],
    );
  }

  Row rowSendText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.add, color: Colors.white, size: 32),
        ),
        _inputNotifier.value.isEmpty
            ? GestureDetector(
              onVerticalDragUpdate: (details) {
                setState(() {
                  _micOffset += details.delta.dy;
                  if (_micOffset < -100) {
                    _speechService.startListening(_onSpeechResult);
                    setState(() {
                      isMicOn = true;
                    });
                  }
                });
              },
              child: Transform.translate(
                offset: Offset(0, _micOffset),
                child: Icon(Icons.mic, color: Colors.white, size: 32),
              ),
            )
            : IconButton(
              onPressed: () {
                _sendMessageText();
                setState(() {
                  _controller.clear();
                });
                _inputNotifier.value = '';
              },
              icon: Icon(Icons.send, color: Colors.white, size: 26),
            ),
      ],
    );
  }

  Widget chatContainer(Message message, BuildContext context) {
    return Row(
      mainAxisAlignment:
          message.isSendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Card(
          margin: EdgeInsets.only(top: 15, left: 15, right: 15),
          color: Colors.transparent,
          elevation: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color:
                        message.isSendByMe
                            ? Colors.deepPurpleAccent.shade200.withAlpha(60)
                            : Colors.grey.shade200,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft:
                          message.isSendByMe
                              ? Radius.circular(20)
                              : Radius.circular(0),
                      bottomRight:
                          message.isSendByMe
                              ? Radius.circular(0)
                              : Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 10),
                  child:
                      message.text != '...'
                          ? Text(message.text, textAlign: TextAlign.left)
                          : CircularProgressIndicator(),
                ),
                if (!message.isSendByMe && message.text != '...')
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_isSpeaking) {
                            _ttsService.stop();
                            setState(() {
                              _speakingMessageText = null;
                            });
                          } else {
                            setState(() {
                              _speakingMessageText = message.text;
                            });
                            _ttsService.speak(message.text);
                          }
                        },
                        icon: Icon(
                          _isSpeaking && _speakingMessageText == message.text
                              ? Icons.stop
                              : Icons.volume_up_outlined,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.copy),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget dateBubble(Message message) {
    return SizedBox(
      height: 42,
      child: Center(
        child: Card(
          color: AppColors.primary.withAlpha(210),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              DateFormat('E, MMMM d', 'es_ES').format(message.date),
              style: TextStyle(color: Colors.grey.shade100),
            ),
          ),
        ),
      ),
    );
  }
}
