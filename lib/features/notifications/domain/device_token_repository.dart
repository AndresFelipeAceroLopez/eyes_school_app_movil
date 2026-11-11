/// Where the app tells the API which device should receive push notifications
/// for the signed-in user (APP-08 · BE-18).
abstract interface class DeviceTokenRepository {
  /// Links [token] to the signed-in user (`POST /dispositivos`).
  Future<void> register(String token);

  /// Unlinks [token] (`DELETE /dispositivos/{token}`), on sign-out.
  Future<void> unregister(String token);
}
