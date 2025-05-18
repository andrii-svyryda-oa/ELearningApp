import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:e_learning_app/core/models/test_model.dart';
import 'package:e_learning_app/features/tests/controllers/tests_controller.dart';

class TestScreen extends ConsumerStatefulWidget {
  final String testId;

  const TestScreen({
    super.key,
    required this.testId,
  });

  @override
  ConsumerState<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends ConsumerState<TestScreen> {
  late Timer? _timer;
  int _remainingSeconds = 0;
  bool _isSubmitting = false;
  bool _isLoading = true;
  TestModel? _test;

  @override
  void initState() {
    super.initState();
    _loadTest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTest() async {
    final testAsync = await ref.read(testDetailsProvider(widget.testId).future);
    
    if (mounted) {
      setState(() {
        _test = testAsync;
        _isLoading = false;
        
        if (_test != null) {
          _startTest(_test!);
          _startTimer();
        }
      });
    }
  }

  void _startTest(TestModel test) {
    ref.read(activeTestProvider.notifier).startTest(test);
    _remainingSeconds = test.timeLimit * 60;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _submitTest();
        }
      });
    });
  }

  String get _formattedTime {
    final minutes = (_remainingSeconds / 60).floor();
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _submitTest() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final results = await ref.read(activeTestProvider.notifier).completeTest();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TestResultsScreen(results: results),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting test: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final testSession = ref.watch(activeTestProvider);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.loading),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_test == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.error),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.error),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      );
    }
    
    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.exitTest),
            content: Text(l10n.exitTestConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () {
                  ref.read(activeTestProvider.notifier).resetTest();
                  Navigator.of(context).pop(true);
                },
                child: Text(l10n.exit),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_test!.title),
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: _remainingSeconds < 60
                    ? Colors.red
                    : _remainingSeconds < 300
                        ? Colors.orange
                        : Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    _formattedTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: testSession.when(
          data: (session) {
            if (session == null) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final currentQuestion = session.test.questions[session.currentQuestionIndex];
            
            return Column(
              children: [
                LinearProgressIndicator(
                  value: (session.currentQuestionIndex + 1) / session.totalQuestions,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${l10n.question} ${session.currentQuestionIndex + 1}/${session.totalQuestions}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${l10n.points}: ${currentQuestion.points}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentQuestion.text,
                          style: Theme.of(context).textTheme.titleLarge,
                        ).animate().fadeIn(duration: 300.ms),
                        const SizedBox(height: 24),
                        _buildAnswerOptions(currentQuestion, session),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(context, session),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Error: ${error.toString()}'),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerOptions(QuestionModel question, TestSession session) {
    final selectedAnswers = session.userAnswers[question.id] ?? [];
    
    switch (question.type) {
      case QuestionType.singleChoice:
        return Column(
          children: question.answers.asMap().entries.map((entry) {
            final index = entry.key;
            final answer = entry.value;
            final isSelected = selectedAnswers.contains(answer.id);
            
            return RadioListTile<String>(
              title: Text(answer.text),
              value: answer.id,
              groupValue: selectedAnswers.isNotEmpty ? selectedAnswers.first : null,
              onChanged: (value) {
                if (value != null) {
                  ref.read(activeTestProvider.notifier).answerQuestion(
                    question.id,
                    [value],
                  );
                }
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
          }).toList(),
        );
      
      case QuestionType.multipleChoice:
        return Column(
          children: question.answers.asMap().entries.map((entry) {
            final index = entry.key;
            final answer = entry.value;
            final isSelected = selectedAnswers.contains(answer.id);
            
            return CheckboxListTile(
              title: Text(answer.text),
              value: isSelected,
              onChanged: (value) {
                if (value == true) {
                  ref.read(activeTestProvider.notifier).answerQuestion(
                    question.id,
                    [...selectedAnswers, answer.id],
                  );
                } else {
                  ref.read(activeTestProvider.notifier).answerQuestion(
                    question.id,
                    selectedAnswers.where((id) => id != answer.id).toList(),
                  );
                }
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ).animate().fadeIn(delay: Duration(milliseconds: 100 * index));
          }).toList(),
        );
      
      case QuestionType.trueFalse:
        return Column(
          children: [
            RadioListTile<String>(
              title: const Text('True'),
              value: question.answers.firstWhere((a) => a.text.toLowerCase() == 'true').id,
              groupValue: selectedAnswers.isNotEmpty ? selectedAnswers.first : null,
              onChanged: (value) {
                if (value != null) {
                  ref.read(activeTestProvider.notifier).answerQuestion(
                    question.id,
                    [value],
                  );
                }
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ).animate().fadeIn(delay: 100.ms),
            RadioListTile<String>(
              title: const Text('False'),
              value: question.answers.firstWhere((a) => a.text.toLowerCase() == 'false').id,
              groupValue: selectedAnswers.isNotEmpty ? selectedAnswers.first : null,
              onChanged: (value) {
                if (value != null) {
                  ref.read(activeTestProvider.notifier).answerQuestion(
                    question.id,
                    [value],
                  );
                }
              },
              activeColor: Theme.of(context).colorScheme.primary,
            ).animate().fadeIn(delay: 200.ms),
          ],
        );
    }
  }

  Widget _buildBottomBar(BuildContext context, TestSession session) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!session.isFirstQuestion)
            ElevatedButton.icon(
              onPressed: () {
                ref.read(activeTestProvider.notifier).previousQuestion();
              },
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.previousQuestion),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black87,
              ),
            )
          else
            const SizedBox.shrink(),
          if (session.isLastQuestion)
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(l10n.submitTest),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                ref.read(activeTestProvider.notifier).nextQuestion();
              },
              icon: const Icon(Icons.arrow_forward),
              label: Text(l10n.nextQuestion),
            ),
        ],
      ),
    );
  }
}

class TestResultsScreen extends StatelessWidget {
  final Map<String, dynamic> results;

  const TestResultsScreen({
    super.key,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPassed = results['isPassed'] as bool;
    final percentage = (results['percentage'] as double).toStringAsFixed(1);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.testResults),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPassed ? Icons.check_circle : Icons.cancel,
                size: 100,
                color: isPassed ? Colors.green : Colors.red,
              ).animate().scale(duration: 600.ms),
              const SizedBox(height: 24),
              Text(
                isPassed ? l10n.testPassed : l10n.testFailed,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: isPassed ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 48),
              _buildResultItem(
                context,
                l10n.score,
                '$percentage%',
                Icons.score,
              ),
              _buildResultItem(
                context,
                l10n.correctAnswers,
                '${results['correctAnswers']}/${results['totalQuestions']}',
                Icons.check,
              ),
              _buildResultItem(
                context,
                l10n.earnedPoints,
                '${results['earnedPoints']}/${results['totalPoints']}',
                Icons.star,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(l10n.backToCourses),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 400 + (100 * _buildResultItem.hashCode % 3)));
  }
}
