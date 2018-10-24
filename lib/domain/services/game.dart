// Copyright (C) 2018 Alberto Varela Sánchez <alberto@berriart.com>
// Use of this source code is governed by the version 3 of the
// GNU General Public License that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import '../model/index.dart';
import '../collections/index.dart';
import 'game_timer.dart';

const colors = Color.values;
const numbers = Number.values;

class Game {
  Game();

  StreamController<Null> _gameOverStreamer;
  StreamController<Reply> _replyStreamer;
  List<Answer> _answers;
  Question _question;
  int _score;
  GameTimer _timer;

  Stream get gameoverStream => _gameOverStreamer.stream;
  Stream<Reply> get replyStream => _replyStreamer.stream;
  List<Answer> get answers => _answers;
  Question get question => _question;
  int get score => _score;

  void start(GameTimer timer) {
    _gameOverStreamer?.close();
    _replyStreamer?.close();
    _gameOverStreamer = StreamController.broadcast();
    _replyStreamer = StreamController.broadcast();
    _answers = _RandomGenerator.generateAnswers();
    _question = _RandomGenerator.generateQuestion(_answers);
    _score = 0;
    _timer = timer;
    _timer.gameoverStream.listen((_) => _gameover());
    _timer.start();
  }

  bool reply(Answer answer) {
    var isAnswerOk = _question.color == answer.color && _question.number == answer.number;
    if (isAnswerOk) {
      var remainingInMilliseconds = _timer.remainingInMilliseconds;
      var maxTimeInMilliseconds = _timer.maxTimeInMilliseconds;
      _timer.success();
      _nextQuestion(answer, remainingInMilliseconds, maxTimeInMilliseconds);
    } else {
      var isGameOver = _timer.fail();
      if (isGameOver) {
        _gameOverStreamer.add(null);
        return false;
      }
    }

    _replyStreamer.add(Reply(isAnswerOk, answer));

    return isAnswerOk;
  }

  void _nextQuestion(Answer answer, int remainingTime, int timeLimit) {
    var index = _answers.indexOf(answer);
    _answers[index] = _RandomGenerator.generateAnswer(index);
    _question = _RandomGenerator.generateQuestion(_answers);
    _addPoints(remainingTime, timeLimit);
  }

  void _addPoints(int remainingTime, int timeLimit) {
    _score += (remainingTime * 100 / timeLimit).floor();
  }

  void _gameover() {
    _gameOverStreamer.add(null);
    _gameOverStreamer.close();
    _replyStreamer.close();
  }
}

class _RandomGenerator {
  static final _random = Random();

  static Answer generateAnswer(int id) {
    return Answer(id, _randomColour(), _randomNumber());
  }

  static List<Answer> generateAnswers() {
    var questions = List<Answer>();

    for (var i = 0; i < 36; i++) {
      questions.add(generateAnswer(i));
    }

    return questions;
  }

  static Question generateQuestion(List<Answer> answers) {
    var randomAnswer = answers[_random.nextInt(answers.length)];
    return Question(randomAnswer);
  }

  static Number _randomNumber() {
    return numbers[_random.nextInt(numbers.length)];
  }

  static Color _randomColour() {
    return colors[_random.nextInt(colors.length)];
  }
}
