import 'package:cloud_functions/cloud_functions.dart';

/// Regiunea trebuie să coincidă cu `setGlobalOptions({ region })` din `functions/src/index.ts`.
class NabourFunctions {
  NabourFunctions._();

  static final FirebaseFunctions instance =
      FirebaseFunctions.instanceFor(region: 'europe-west1');
}
