/// Centralized order status constants to eliminate magic strings and typos.
///
/// Status flow:
///   Order Placed → Preparing → Ready → Delivery in Progress → Delivered
///
/// Customer confirms receipt by setting status to [received].
class OrderStatus {
  OrderStatus._();

  static const String placed = 'Order Placed';
  static const String preparing = 'Preparing';
  static const String ready = 'Ready';
  static const String deliveryInProgress = 'Delivery in Progress';
  static const String delivered = 'Delivered';
  static const String received = 'Order Received';

  /// All statuses available in the chef's dropdown (excludes [received]).
  static const List<String> chefStatusOptions = [
    placed,
    preparing,
    ready,
    deliveryInProgress,
    delivered,
  ];

  /// Returns true if the order has been received by the customer.
  static bool isReceived(String status) => status == received;

  /// Returns true if the order is still active (not yet received).
  static bool isActive(String status) => status != received;
}
