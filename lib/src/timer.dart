import 'dart:async' as ay;

class Timer {
  ay.Timer? _timer;
  int count = 0;

  Timer(int count, {Function()? onFinished}) {
    _timer = ay.Timer.periodic(const Duration(seconds: 1), (timer) {
      if (count == 0) {
        cancel();
        onFinished?.call();
        return;
      }
      count--;
    });
  }

  Timer.periodic(
    Duration duration,
    void Function(ay.Timer timer, int count) callback,
  ) {
    _timer = ay.Timer.periodic(duration, (timer) {
      count++;
      callback(timer, count);
    });
  }

  cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
