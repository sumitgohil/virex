import 'scheduler.dart';

void batch(void Function() action) {
  VirexScheduler.instance.batch(action);
}
