import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sw1/src/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> allQuestions = [];
  List<Map<String, dynamic>> currentQuizQuestions = [];
  int currentQuestionIndex = 0;
  int score = 0;
  int lastScore = 0;
  bool isLoading = true;
  bool showResult = false;
  bool showLevelSelection = false;
  int? selectedAnswer;
  bool showExplanation = false;
  List<int> userAnswers = [];
  String? selectedLevel;
  late AnimationController _cardAnimationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  static const int questionsPerQuiz = 5;
  static const List<String> difficultyLevels = ['basico', 'intermedio', 'avanzado'];
  static const Map<String, String> levelNames = {
    'basico': 'Básico',
    'intermedio': 'Intermedio',
    'avanzado': 'Avanzado'
  };

  @override
  void initState() {
    super.initState();
    _cardAnimationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeInOut,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeInOut,
    ));
    loadQuestions();
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> loadQuestions() async {
    try {
      final String response = await rootBundle.loadString('assets/quiz_questions.json');
      final data = await json.decode(response);
      allQuestions = List<Map<String, dynamic>>.from(data['questions']);
      
      await loadLastScore();
      await loadSavedProgress();
      
      setState(() {
        isLoading = false;
      });
      
      _cardAnimationController.forward();
    } catch (e) {
      print('Error loading questions: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadLastScore() async {
    final prefs = await SharedPreferences.getInstance();
    lastScore = prefs.getInt('last_quiz_score') ?? 0;
  }

  Future<void> saveLastScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_quiz_score', score);
  }

  Future<void> loadSavedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedQuestions = prefs.getStringList('current_quiz_questions');
    final savedIndex = prefs.getInt('current_question_index') ?? 0;
    final savedScore = prefs.getInt('current_quiz_score') ?? 0;
    final savedLevel = prefs.getString('current_quiz_level');
    
    if (savedQuestions != null && savedQuestions.isNotEmpty && savedLevel != null) {
      // Restaurar progreso guardado
      currentQuizQuestions = savedQuestions.map((q) => json.decode(q) as Map<String, dynamic>).toList();
      currentQuestionIndex = savedIndex;
      score = savedScore;
      selectedLevel = savedLevel;
      userAnswers = List.filled(currentQuizQuestions.length, -1);
    } else {
      // Mostrar selección de nivel
      setState(() {
        showLevelSelection = true;
      });
    }
  }

  void startNewQuiz(String level) {
    final random = Random();
    
    // Filtrar preguntas por nivel
    final questionsForLevel = allQuestions.where((q) => q['level'] == level).toList();
    
    if (questionsForLevel.length < questionsPerQuiz) {
      // Si no hay suficientes preguntas del nivel seleccionado, mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay suficientes preguntas para el nivel $level'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    questionsForLevel.shuffle(random);
    
    currentQuizQuestions = questionsForLevel.take(questionsPerQuiz).toList();
    selectedLevel = level;
    currentQuestionIndex = 0;
    score = 0;
    showResult = false;
    showLevelSelection = false;
    showExplanation = false;
    selectedAnswer = null;
    userAnswers = List.filled(currentQuizQuestions.length, -1);
    
    saveProgress();
  }

  Future<void> saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final questionsJson = currentQuizQuestions.map((q) => json.encode(q)).toList();
    
    await prefs.setStringList('current_quiz_questions', questionsJson);
    await prefs.setInt('current_question_index', currentQuestionIndex);
    await prefs.setInt('current_quiz_score', score);
    if (selectedLevel != null) {
      await prefs.setString('current_quiz_level', selectedLevel!);
    }
  }

  Future<void> clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_quiz_questions');
    await prefs.remove('current_question_index');
    await prefs.remove('current_quiz_score');
    await prefs.remove('current_quiz_level');
  }

  void selectAnswer(int answerIndex) {
    setState(() {
      selectedAnswer = answerIndex;
    });
  }

  void nextQuestion() {
    if (selectedAnswer == null) return;

    // Guardar respuesta del usuario
    userAnswers[currentQuestionIndex] = selectedAnswer!;

    // Verificar si la respuesta es correcta
    final currentQuestion = currentQuizQuestions[currentQuestionIndex];
    bool isCorrect = false;
    
    if (currentQuestion['type'] == 'true_false') {
      isCorrect = (selectedAnswer == 0 && currentQuestion['correct_answer'] == true) ||
                 (selectedAnswer == 1 && currentQuestion['correct_answer'] == false);
    } else {
      isCorrect = selectedAnswer == currentQuestion['correct_answer'];
    }

    if (isCorrect) {
      score++;
    }

    setState(() {
      showExplanation = true;
    });
  }

  void continueToNext() {
    if (currentQuestionIndex < currentQuizQuestions.length - 1) {
      _cardAnimationController.reset();
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
        showExplanation = false;
      });
      saveProgress();
      _cardAnimationController.forward();
    } else {
      setState(() {
        showResult = true;
      });
      saveLastScore();
      clearProgress();
    }
  }

  void restartQuiz() {
    _cardAnimationController.reset();
    setState(() {
      showLevelSelection = true;
      showResult = false;
    });
    clearProgress();
    _cardAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Quiz de Tránsito'),
          backgroundColor: AppColors.primary,
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (showResult) {
      return _buildResultScreen();
    }

    if (allQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Quiz de Tránsito'),
          backgroundColor: AppColors.primary,
        ),
        body: Center(
          child: Text(
            'Error al cargar las preguntas',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    if (showLevelSelection || currentQuizQuestions.isEmpty) {
      return _buildLevelSelectionScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz de Tránsito'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _buildQuestionScreen(),
        ),
      ),
    );
  }

  Widget _buildQuestionScreen() {
    final question = currentQuizQuestions[currentQuestionIndex];
    
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progreso
          LinearProgressIndicator(
            value: (currentQuestionIndex + 1) / currentQuizQuestions.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 10),
          Text(
            'Pregunta ${currentQuestionIndex + 1} de ${currentQuizQuestions.length}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 20),
          
          // Pregunta
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    question['question'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  // Mostrar imagen si es pregunta de identificación
                  if (question['type'] == 'image_identification') ...[
                    SizedBox(height: 20),
                    Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _buildTrafficSignImage(question['image_path']),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          SizedBox(height: 20),
          
          // Opciones de respuesta
          Expanded(
            child: _buildAnswerOptions(question),
          ),
          
          // Explicación (si se muestra)
          if (showExplanation) ...[
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  children: [
                    Icon(
                      selectedAnswer == question['correct_answer'] || 
                      (question['type'] == 'true_false' && 
                       ((selectedAnswer == 0 && question['correct_answer'] == true) ||
                        (selectedAnswer == 1 && question['correct_answer'] == false)))
                        ? Icons.check_circle
                        : Icons.cancel,
                      color: selectedAnswer == question['correct_answer'] || 
                             (question['type'] == 'true_false' && 
                              ((selectedAnswer == 0 && question['correct_answer'] == true) ||
                               (selectedAnswer == 1 && question['correct_answer'] == false)))
                        ? Colors.green
                        : Colors.red,
                      size: 30,
                    ),
                    SizedBox(height: 10),
                    Text(
                      question['explanation'],
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
          
          // Botones
          if (!showExplanation)
            ElevatedButton(
              onPressed: selectedAnswer != null ? nextQuestion : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                'Confirmar Respuesta',
                style: TextStyle(fontSize: 16),
              ),
            )
          else
            ElevatedButton(
              onPressed: continueToNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                currentQuestionIndex < currentQuizQuestions.length - 1 ? 'Siguiente Pregunta' : 'Ver Resultados',
                style: TextStyle(fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions(Map<String, dynamic> question) {
    if (question['type'] == 'true_false') {
      return Column(
        children: [
          _buildAnswerCard(0, 'Verdadero', question),
          SizedBox(height: 10),
          _buildAnswerCard(1, 'Falso', question),
        ],
      );
    } else {
      return ListView.builder(
        itemCount: question['options'].length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: _buildAnswerCard(index, question['options'][index], question),
          );
        },
      );
    }
  }

  Widget _buildAnswerCard(int index, String text, Map<String, dynamic> question) {
    bool isSelected = selectedAnswer == index;
    bool isCorrect = false;
    bool showCorrectAnswer = showExplanation;
    
    if (showCorrectAnswer) {
      if (question['type'] == 'true_false') {
        isCorrect = (index == 0 && question['correct_answer'] == true) ||
                   (index == 1 && question['correct_answer'] == false);
      } else {
        isCorrect = index == question['correct_answer'];
      }
    }
    
    Color cardColor = Colors.white;
    Color borderColor = Colors.grey[300]!;
    
    if (showCorrectAnswer) {
      if (isCorrect) {
        cardColor = Colors.green[50]!;
        borderColor = Colors.green;
      } else if (isSelected && !isCorrect) {
        cardColor = Colors.red[50]!;
        borderColor = Colors.red;
      }
    } else if (isSelected) {
      cardColor = AppColors.primary.withOpacity(0.1);
      borderColor = AppColors.primary;
    }
    
    return GestureDetector(
      onTap: showExplanation ? null : () => selectAnswer(index),
      child: Card(
        color: cardColor,
        elevation: isSelected ? 4 : 2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 2),
          ),
          padding: EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                  color: isSelected ? borderColor : Colors.transparent,
                ),
                child: isSelected
                    ? Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              SizedBox(width: 15),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (showCorrectAnswer && isCorrect)
                Icon(Icons.check_circle, color: Colors.green),
              if (showCorrectAnswer && isSelected && !isCorrect)
                Icon(Icons.cancel, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelSelectionScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seleccionar Nivel'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (lastScore > 0) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 40,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Último Resultado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '$lastScore/$questionsPerQuiz preguntas correctas',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
            ],
            Text(
              'Selecciona el nivel de dificultad',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'Elige el nivel que mejor se adapte a tu conocimiento',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ...difficultyLevels.map((level) => _buildLevelCard(level)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(String level) {
    IconData levelIcon;
    Color levelColor;
    String description;
    
    switch (level) {
      case 'basico':
        levelIcon = Icons.school;
        levelColor = Colors.green;
        description = 'Preguntas fundamentales y básicas';
        break;
      case 'intermedio':
        levelIcon = Icons.trending_up;
        levelColor = Colors.orange;
        description = 'Preguntas de dificultad media';
        break;
      case 'avanzado':
        levelIcon = Icons.emoji_events;
        levelColor = Colors.red;
        description = 'Preguntas complejas y específicas';
        break;
      default:
        levelIcon = Icons.help;
        levelColor = Colors.grey;
        description = 'Nivel desconocido';
    }
    
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: Card(
        elevation: 4,
        child: InkWell(
          onTap: () {
            startNewQuiz(level);
            setState(() {});
            _cardAnimationController.forward();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: levelColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    levelIcon,
                    color: levelColor,
                    size: 30,
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        levelNames[level] ?? level,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: levelColor,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrafficSignImage(String imagePath) {
    // Convertir la ruta de PNG a SVG
    String svgPath = imagePath.replaceAll('.png', '.svg');
    
    return SvgPicture.asset(
      svgPath,
      fit: BoxFit.contain,
      placeholderBuilder: (BuildContext context) => Container(
        color: Colors.grey[200],
        child: Icon(
          Icons.image,
          color: Colors.grey[400],
          size: 40,
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    double percentage = (score / questionsPerQuiz) * 100;
    String resultMessage;
    Color resultColor;
    IconData resultIcon;
    
    if (percentage >= 80) {
      resultMessage = '¡Excelente! Tienes un buen conocimiento del código de tránsito.';
      resultColor = Colors.green;
      resultIcon = Icons.emoji_events;
    } else if (percentage >= 60) {
      resultMessage = 'Bien hecho, pero puedes mejorar estudiando más.';
      resultColor = Colors.orange;
      resultIcon = Icons.thumb_up;
    } else {
      resultMessage = 'Necesitas estudiar más el código de tránsito boliviano.';
      resultColor = Colors.red;
      resultIcon = Icons.school;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Resultados del Quiz'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              resultIcon,
              size: 80,
              color: resultColor,
            ),
            SizedBox(height: 20),
            Text(
              'Quiz Completado',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Tu Puntuación',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                  '$score/$questionsPerQuiz',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: resultColor,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: resultColor,
                  ),
                ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              resultMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: restartQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text('Reintentar Quiz'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text('Volver al Inicio'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}