import '../../core/utils/phone_utils.dart';
import '../../domain/entities/customer.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/reminder_enums.dart';
import '../repositories/customer_repository.dart';
import '../repositories/payment_reminder_repository.dart';
import 'factory_display_service.dart';
import 'payment_reminder_message_service.dart';
import 'whatsapp_launch_service.dart';

class PaymentReminderService {
  PaymentReminderService({
    required CustomerRepository customerRepository,
    required PaymentReminderRepository reminderRepository,
    required PaymentReminderMessageService messageService,
    required WhatsAppLaunchService whatsAppLaunchService,
    required FactoryDisplayService factoryDisplayService,
  })  : _customerRepository = customerRepository,
        _reminderRepository = reminderRepository,
        _messageService = messageService,
        _whatsAppLaunchService = whatsAppLaunchService,
        _factoryDisplayService = factoryDisplayService;

  final CustomerRepository _customerRepository;
  final PaymentReminderRepository _reminderRepository;
  final PaymentReminderMessageService _messageService;
  final WhatsAppLaunchService _whatsAppLaunchService;
  final FactoryDisplayService _factoryDisplayService;

  Future<bool> sendWhatsAppReminder({
    required String factoryId,
    required String sentByUserId,
    required String customerId,
    required String customerName,
    required String invoiceId,
    required String invoiceNumber,
    required InvoiceType invoiceType,
    required double amountDue,
    DateTime? dueDate,
    bool isOverdue = false,
  }) async {
    final customer = await _customerRepository.getCustomer(customerId);
    final resolvedName = customer?.name ?? customerName;
    final phone = _resolvePhone(customer);
    if (phone == null) {
      throw StateError('Customer has no valid WhatsApp or phone number');
    }

    final factoryName = await _factoryDisplayService.resolveName(factoryId);
    final message = _messageService.build(
      customerName: resolvedName,
      invoiceNumber: invoiceNumber,
      amountDue: amountDue,
      dueDate: dueDate,
      invoiceType: invoiceType,
      factoryName: factoryName,
      isOverdue: isOverdue,
    );

    final launched = await _whatsAppLaunchService.sendMessage(
      phoneNumber: phone,
      message: message,
    );
    if (!launched) {
      throw StateError('Could not open WhatsApp');
    }

    await _reminderRepository.logReminder(
      factoryId: factoryId,
      invoiceId: invoiceId,
      invoiceType: invoiceType,
      customerId: customerId,
      customerName: resolvedName,
      invoiceNumber: invoiceNumber,
      amountDue: amountDue,
      sentBy: sentByUserId,
      channel: ReminderChannel.whatsapp,
      dueDate: dueDate,
      messagePreview: message.length > 180 ? '${message.substring(0, 177)}...' : message,
    );

    return true;
  }

  String? _resolvePhone(Customer? customer) {
    if (customer == null) return null;
    return PhoneUtils.pickWhatsAppNumber(
      whatsApp: customer.whatsApp,
      phone: customer.phone,
      phoneSecondary: customer.phoneSecondary,
    );
  }
}
