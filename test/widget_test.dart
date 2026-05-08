import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:airplugapp/app/app.dart';
import 'package:airplugapp/core/auth/app_session_service.dart';
import 'package:airplugapp/features/airtime/data/airtime_api_service.dart';
import 'package:airplugapp/features/auth/data/auth_api_service.dart';
import 'package:airplugapp/features/bills/data/bill_payment_api_service.dart';
import 'package:airplugapp/features/cashback/data/cashback_api_service.dart';
import 'package:airplugapp/features/cards/data/cards_api_service.dart';
import 'package:airplugapp/features/data/data/data_api_service.dart';
import 'package:airplugapp/features/dashboard/data/dashboard_api_service.dart';
import 'package:airplugapp/features/me/data/profile_api_service.dart';
import 'package:airplugapp/features/news/data/news_api_service.dart';
import 'package:airplugapp/features/notifications/data/notification_api_service.dart';
import 'package:airplugapp/features/referrals/data/referrals_api_service.dart';
import 'package:airplugapp/features/transfer/data/transfer_api_service.dart';
import 'package:airplugapp/features/transactions/data/transaction_history_api_service.dart';
import 'package:airplugapp/features/tv/data/tv_subscription_api_service.dart';
import 'package:airplugapp/features/virtual_accounts/data/virtual_accounts_api_service.dart';
import 'package:airplugapp/features/wallet/data/fund_wallet_api_service.dart';

Future<void> _pumpPhoneApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const PtsDataApp());
}

Future<void> _loginToDashboard(WidgetTester tester) async {
  await _pumpPhoneApp(tester);
  await tester.tap(find.text('Log In'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(EditableText).at(0), 'admin@ptsdata.ng');
  await tester.enterText(find.byType(EditableText).at(1), 'password123');
  await tester.ensureVisible(find.text('Sign In'));
  await tester.tap(find.text('Sign In'));
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AirtimeApiService.resetDebugHandlers();
    AuthApiService.resetDebugHandlers();
    BillPaymentApiService.resetDebugHandlers();
    CashbackApiService.resetDebugHandlers();
    CardsApiService.resetDebugHandlers();
    DataApiService.resetDebugHandlers();
    DashboardApiService.resetDebugHandlers();
    FundWalletApiService.resetDebugHandlers();
    ProfileApiService.resetDebugHandlers();
    NewsApiService.resetDebugHandlers();
    NotificationApiService.resetDebugHandlers();
    ReferralsApiService.resetDebugHandlers();
    TransferApiService.resetDebugHandlers();
    TransactionHistoryApiService.resetDebugHandlers();
    TvSubscriptionApiService.resetDebugHandlers();
    VirtualAccountsApiService.resetDebugHandlers();
    AuthApiService.debugLoginHandler = ({
      required String login,
      required String password,
      required bool remember,
    }) async {
      return LoginApiResult.success(
        session: MobileAuthSession(
          token: 'test-token',
          displayName: 'ABUBAKAR',
          identifier: login,
          hasTransactionPin: true,
        ),
        message: 'Login successful.',
      );
    };
    AuthApiService.debugQuickUnlockHandler = ({
      required String identifier,
      required String pin,
    }) async {
      return QuickUnlockApiResult.success(
        session: MobileAuthSession(
          token: 'quick-token',
          displayName: 'ABUBAKAR',
          identifier: identifier,
          hasTransactionPin: true,
        ),
        message: 'Quick login successful.',
      );
    };
    AuthApiService.debugVerifyTransactionPinHandler = ({
      required String token,
      required String pin,
    }) async {
      if (pin == '0000') {
        return const VerifyTransactionPinApiResult.validation(
          fieldErrors: <String, String>{
            'pin': 'The transaction PIN is incorrect.',
          },
          message: 'Please confirm your transaction PIN and try again.',
        );
      }

      return const VerifyTransactionPinApiResult.success(
        'Transaction PIN verified successfully.',
      );
    };
    AuthApiService.debugForgotPasswordHandler = ({
      required String email,
    }) async {
      return const ForgotPasswordApiResult.success(
        'We have emailed your password reset link.',
      );
    };
    AuthApiService.debugResetPasswordHandler = ({
      required String token,
      required String email,
      required String password,
      required String passwordConfirmation,
    }) async {
      if (token.isEmpty) {
        return const ResetPasswordApiResult.validation(
          fieldErrors: <String, String>{'token': 'Reset token is required.'},
          message: 'Reset token is required.',
        );
      }

      return const ResetPasswordApiResult.success('Password reset successful.');
    };
    CardsApiService.debugOverviewHandler = ({
      required String token,
      required int historyLimit,
    }) async {
      return CardsOverviewApiResult.success(
        walletBalance: 248500,
        modes: <CardsApiMode>[
          CardsApiMode(
            id: 'airtime',
            label: 'Airtime Card',
            options: const <CardsApiOption>[
              CardsApiOption(
                id: '13',
                label: 'MTN ₦100',
                amount: 99,
                meta: <String, dynamic>{'network_id': '1'},
              ),
              CardsApiOption(
                id: '3',
                label: 'MTN ₦500',
                amount: 495,
                meta: <String, dynamic>{'network_id': '1'},
              ),
            ],
          ),
          CardsApiMode(
            id: 'data',
            label: 'Data Card',
            options: const <CardsApiOption>[
              CardsApiOption(
                id: '7',
                label: 'MTN 1GB',
                amount: 247,
                meta: <String, dynamic>{'network': '1'},
              ),
            ],
          ),
          CardsApiMode(
            id: 'epin',
            label: 'E-PIN',
            options: const <CardsApiOption>[
              CardsApiOption(
                id: 'WAEC Result Checker',
                label: 'WAEC Result Checker',
                amount: 3400,
                meta: <String, dynamic>{'max_quantity': 5},
              ),
            ],
          ),
        ],
        history: <CardsApiHistoryItem>[
          CardsApiHistoryItem(
            id: 1,
            title: 'MTN ₦500',
            quantity: 10,
            amount: 4950,
            category: 'Airtime Card',
            businessName: 'PTS DATA Store',
            reference: 'ACR-TEST-1',
            status: 'successful',
            createdAt: DateTime(2026, 3, 24, 10, 0),
          ),
        ],
      );
    };
    CardsApiService.debugGenerateHandler = ({
      required String token,
      required String mode,
      required String optionId,
      required int quantity,
      required String businessName,
      required String pin,
    }) async {
      if (pin == '0000') {
        return const CardsGenerateApiResult.validation(
          message: 'The transaction PIN is incorrect.',
          fieldErrors: <String, String>{
            'pin': 'The transaction PIN is incorrect.',
          },
        );
      }

      return CardsGenerateApiResult.success(
        message: 'Card generation completed successfully.',
        walletBalance: 243550,
        historyItem: CardsApiHistoryItem(
          id: 2,
          title: 'MTN ₦100',
          quantity: quantity,
          amount: (99 * quantity).toDouble(),
          category: 'Airtime Card',
          businessName: businessName,
          reference: 'ACR-NEW-1',
          status: 'successful',
          createdAt: DateTime(2026, 3, 25, 10, 0),
        ),
      );
    };
    AirtimeApiService.debugRecipientsHandler = ({
      required String token,
      required int limit,
    }) async {
      return AirtimeRecipientsApiResult.success(
        recipients: <AirtimeSavedRecipient>[
          const AirtimeSavedRecipient(
            id: 1,
            phoneNumber: '08031234567',
            networkId: '1',
            networkName: 'MTN',
            usageCount: 4,
            lastUsedAt: '2026-03-24T10:00:00Z',
          ),
          const AirtimeSavedRecipient(
            id: 2,
            phoneNumber: '07041234567',
            networkId: '2',
            networkName: 'GLO',
            usageCount: 2,
            lastUsedAt: '2026-03-23T08:30:00Z',
          ),
        ],
        message: 'Recipients loaded successfully.',
      );
    };
    AirtimeApiService.debugPurchaseHandler = ({
      required String token,
      required String networkId,
      required String phoneNumber,
      required int amount,
      required bool saveRecipient,
      required String pin,
    }) async {
      if (pin == '0000') {
        return const AirtimePurchaseApiResult.failure('Incorrect PIN.');
      }

      return AirtimePurchaseApiResult.success(
        message: 'You have topped up successfully.',
        reference: 'AIR-TEST-001',
        recentRecipients: <AirtimeSavedRecipient>[
          AirtimeSavedRecipient(
            id: 9,
            phoneNumber: phoneNumber,
            networkId: networkId,
            networkName: 'MTN',
            usageCount: 1,
            lastUsedAt: '2026-03-24T11:00:00Z',
          ),
        ],
      );
    };
    DataApiService.debugCatalogHandler = ({
      required String token,
      required int recipientLimit,
    }) async {
      return DataCatalogApiResult.success(
        providerChannel: 'primary',
        networks: <DataApiNetwork>[
          DataApiNetwork(
            key: 'MTN_PLAN',
            networkId: '1',
            networkName: 'MTN',
            purchaseNetworkId: '1',
            types: <DataApiType>[
              DataApiType(
                key: 'SME',
                label: 'SME',
                plans: <DataApiPlan>[
                  const DataApiPlan(
                    id: 'mtn-plan-1',
                    dataPlanId: '101',
                    name: '1GB',
                    validity: '30 days',
                    amount: 950,
                    networkId: '1',
                    providerNetworkId: '1',
                  ),
                ],
              ),
            ],
          ),
          DataApiNetwork(
            key: 'GLO_PLAN',
            networkId: '2',
            networkName: 'GLO',
            purchaseNetworkId: '2',
            types: <DataApiType>[
              DataApiType(
                key: 'SME',
                label: 'SME',
                plans: <DataApiPlan>[
                  const DataApiPlan(
                    id: 'glo-plan-1',
                    dataPlanId: '201',
                    name: '1GB',
                    validity: '30 days',
                    amount: 980,
                    networkId: '2',
                    providerNetworkId: '2',
                  ),
                ],
              ),
            ],
          ),
          DataApiNetwork(
            key: '9MOBILE_PLAN',
            networkId: '3',
            networkName: '9MOBILE',
            purchaseNetworkId: '3',
            types: <DataApiType>[
              DataApiType(
                key: 'SME',
                label: 'SME',
                plans: <DataApiPlan>[
                  const DataApiPlan(
                    id: '9m-plan-1',
                    dataPlanId: '301',
                    name: '500MB',
                    validity: '30 days',
                    amount: 500,
                    networkId: '3',
                    providerNetworkId: '3',
                  ),
                ],
              ),
            ],
          ),
          DataApiNetwork(
            key: 'AIRTEL_PLAN',
            networkId: '4',
            networkName: 'AIRTEL',
            purchaseNetworkId: '4',
            types: <DataApiType>[
              DataApiType(
                key: 'SME',
                label: 'SME',
                plans: <DataApiPlan>[
                  const DataApiPlan(
                    id: 'air-plan-1',
                    dataPlanId: '401',
                    name: '1GB',
                    validity: '30 days',
                    amount: 980,
                    networkId: '4',
                    providerNetworkId: '4',
                  ),
                ],
              ),
            ],
          ),
        ],
        recentRecipients: <DataSavedRecipient>[
          const DataSavedRecipient(
            id: 1,
            phoneNumber: '08031234567',
            networkId: '1',
            networkName: 'MTN',
            usageCount: 4,
            lastUsedAt: '2026-03-24T10:00:00Z',
          ),
          const DataSavedRecipient(
            id: 2,
            phoneNumber: '07041234567',
            networkId: '2',
            networkName: 'GLO',
            usageCount: 2,
            lastUsedAt: '2026-03-23T08:30:00Z',
          ),
        ],
      );
    };
    DataApiService.debugRecipientsHandler = ({
      required String token,
      required int limit,
    }) async {
      return DataRecipientsApiResult.success(
        recipients: <DataSavedRecipient>[
          const DataSavedRecipient(
            id: 1,
            phoneNumber: '08031234567',
            networkId: '1',
            networkName: 'MTN',
            usageCount: 4,
            lastUsedAt: '2026-03-24T10:00:00Z',
          ),
          const DataSavedRecipient(
            id: 2,
            phoneNumber: '07041234567',
            networkId: '2',
            networkName: 'GLO',
            usageCount: 2,
            lastUsedAt: '2026-03-23T08:30:00Z',
          ),
        ],
      );
    };
    DataApiService.debugPurchaseHandler = ({
      required String token,
      required String networkId,
      required String dataType,
      required String dataPlanId,
      required String phoneNumber,
      required double amount,
      required String validity,
      required bool saveRecipient,
      required String pin,
    }) async {
      if (pin == '0000') {
        return const DataPurchaseApiResult.failure('Incorrect PIN.');
      }

      return DataPurchaseApiResult.success(
        message: 'Your data purchase was completed successfully.',
        reference: 'DAT-TEST-001',
        recentRecipients: <DataSavedRecipient>[
          DataSavedRecipient(
            id: 8,
            phoneNumber: phoneNumber,
            networkId: networkId,
            networkName: 'MTN',
            usageCount: 1,
            lastUsedAt: '2026-03-24T11:00:00Z',
          ),
        ],
      );
    };
    TvSubscriptionApiService.debugCatalogHandler = ({
      required String token,
      required int limit,
    }) async {
      return TvCatalogApiResult.success(
        serviceCharge: 100,
        providers: <TvApiProvider>[
          const TvApiProvider(
            id: 'dstv',
            name: 'DSTV',
            serviceId: 'dstv',
            meterTypes: <String>['prepaid', 'postpaid'],
            image: '',
          ),
          const TvApiProvider(
            id: 'gotv',
            name: 'GOTV',
            serviceId: 'gotv',
            meterTypes: <String>['prepaid'],
            image: '',
          ),
          const TvApiProvider(
            id: 'startimes',
            name: 'Startimes',
            serviceId: 'startimes',
            meterTypes: <String>['prepaid'],
            image: '',
          ),
        ],
        history: <TvApiHistoryItem>[
          const TvApiHistoryItem(
            id: 1,
            provider: 'dstv',
            plan: 'Compact',
            smartCardNumber: '4508123490',
            amount: 15800,
            status: 'Successful',
            reference: 'TV-001',
            createdAt: '2026-03-24T10:00:00Z',
          ),
        ],
      );
    };
    TvSubscriptionApiService.debugPlansHandler = ({
      required String token,
      required String serviceId,
    }) async {
      return TvPlansApiResult.success(
        plans: <TvApiPlan>[
          const TvApiPlan(
            id: 'compact',
            variationCode: 'compact',
            name: 'Compact',
            amount: 15700,
          ),
          const TvApiPlan(
            id: 'confam',
            variationCode: 'confam',
            name: 'Confam',
            amount: 9300,
          ),
        ],
      );
    };
    TvSubscriptionApiService.debugValidationHandler = ({
      required String token,
      required String serviceId,
      required String smartCardNumber,
      required String meterType,
    }) async {
      return const TvValidationApiResult.success(
        customerName: 'PTS DATA TV USER',
        message: 'Customer validated successfully.',
      );
    };
    TvSubscriptionApiService.debugPurchaseHandler = ({
      required String token,
      required String serviceId,
      required String smartCardNumber,
      required String meterType,
      required double amount,
      required String phoneNumber,
      required String pin,
      required String variationCode,
      required String planName,
    }) async {
      if (pin == '0000') {
        return const TvPurchaseApiResult.validation(
          fieldErrors: <String, String>{
            'pin': 'The transaction PIN is incorrect.',
          },
          message: 'Please confirm your transaction PIN and try again.',
        );
      }

      return TvPurchaseApiResult.success(
        message: 'TV subscription successful.',
        reference: 'TV-TEST-001',
        providerToken: 'TOKEN1234',
        historyItem: TvApiHistoryItem(
          id: 2,
          provider: serviceId,
          plan: planName,
          smartCardNumber: smartCardNumber,
          amount: amount + 100,
          status: 'Successful',
          reference: 'TV-TEST-001',
          createdAt: '2026-03-25T00:00:00Z',
        ),
      );
    };
    BillPaymentApiService.debugCatalogHandler = ({
      required String token,
      required int limit,
    }) async {
      return BillCatalogApiResult.success(
        serviceCharge: 100,
        minAmount: 100,
        maxAmount: 500000,
        providers: <BillApiProvider>[
          const BillApiProvider(
            id: '1',
            name: 'Ikeja Electric',
            serviceId: '1',
            meterTypes: <String>['prepaid', 'postpaid'],
          ),
          const BillApiProvider(
            id: '2',
            name: 'Eko Electric',
            serviceId: '2',
            meterTypes: <String>['prepaid', 'postpaid'],
          ),
        ],
        history: <BillApiHistoryItem>[
          const BillApiHistoryItem(
            id: 1,
            provider: 'Ikeja Electric',
            meterNumber: '1234567890',
            meterType: 'Prepaid',
            amount: 5100,
            billAmount: 5000,
            charges: 100,
            status: 'successful',
            phoneNumber: '08031234567',
            reference: 'EBL-001',
            createdAt: '2026-03-24T10:00:00Z',
          ),
        ],
      );
    };
    BillPaymentApiService.debugValidateMeterHandler = ({
      required String token,
      required String serviceId,
      required String meterNumber,
      required String meterType,
    }) async {
      return const BillValidateMeterApiResult.success(
        customerName: 'PTS DATA POWER USER',
        address: '12 Example Street, Lagos',
        message: 'Meter validated successfully.',
      );
    };
    BillPaymentApiService.debugPurchaseHandler = ({
      required String token,
      required String serviceId,
      required String meterNumber,
      required String meterType,
      required double amount,
      required String phoneNumber,
      required String pin,
    }) async {
      if (pin == '0000') {
        return const BillPurchaseApiResult.validation(
          fieldErrors: <String, String>{
            'pin': 'The transaction PIN is incorrect.',
          },
          message: 'Please confirm your transaction PIN and try again.',
        );
      }

      return BillPurchaseApiResult.success(
        status: BillPurchaseStatus.successful,
        message: 'Electricity bill successful.',
        reference: 'EBL-TEST-001',
        historyItem: BillApiHistoryItem(
          id: 2,
          provider: serviceId == '1' ? 'Ikeja Electric' : 'Eko Electric',
          meterNumber: meterNumber,
          meterType: meterType == 'prepaid' ? 'Prepaid' : 'Postpaid',
          amount: amount + 100,
          billAmount: amount,
          charges: 100,
          status: 'successful',
          phoneNumber: phoneNumber,
          reference: 'EBL-TEST-001',
          createdAt: '2026-03-25T00:00:00Z',
        ),
      );
    };
    DashboardApiService.debugOverviewHandler = ({required String token}) async {
      return const DashboardOverviewApiResult.success(
        overview: DashboardOverview(
          userName: 'ABUBAKAR',
          walletBalance: 248500,
          cashbackBalance: 12750,
          totalCashbackEarned: 38100,
          monthlySpend: 186200,
          recentTransactions: <DashboardRecentTransaction>[
            DashboardRecentTransaction(
              id: 'DATA-1',
              type: 'data',
              amount: 1500,
              status: 'successful',
              direction: 'outgoing',
              description: 'Data purchase - MTN',
              reference: 'DATA-REF-1',
            ),
            DashboardRecentTransaction(
              id: 'FUND-1',
              type: 'funding',
              amount: 5000,
              status: 'successful',
              direction: 'incoming',
              description: 'Wallet Funding - Bank Transfer',
              reference: 'FUND-REF-1',
            ),
          ],
          virtualAccounts: <DashboardVirtualAccount>[
            DashboardVirtualAccount(
              id: 1,
              accountNumber: '1029384756',
              accountName: 'PTS DATA ABUBAKAR',
              bankName: 'Wema Bank',
              bankSlug: 'wema-bank',
              isActive: true,
            ),
            DashboardVirtualAccount(
              id: 2,
              accountNumber: '3094857612',
              accountName: 'PTS DATA ABUBAKAR',
              bankName: 'Moniepoint',
              bankSlug: 'moniepoint',
              isActive: true,
            ),
          ],
        ),
        message: 'Dashboard loaded successfully.',
      );
    };
    FundWalletApiService.debugOverviewHandler = ({
      required String token,
    }) async {
      return FundWalletOverviewApiResult.success(
        overview: FundWalletOverview(
          walletBalance: 248500,
          receivingAccounts: const <FundWalletReceivingAccount>[
            FundWalletReceivingAccount(
              id: '1',
              accountNumber: '1029384756',
              accountName: 'PTS DATA ABUBAKAR',
              bankName: 'Wema Bank',
            ),
            FundWalletReceivingAccount(
              id: '2',
              accountNumber: '3094857612',
              accountName: 'PTS DATA ABUBAKAR',
              bankName: 'Moniepoint',
            ),
          ],
          history: <FundWalletHistoryItem>[
            FundWalletHistoryItem(
              id: 'manual-1',
              reference: 'FUND-001',
              amount: 5000,
              status: 'approved',
              statusLabel: 'Approved',
              type: 'manual',
              typeLabel: 'Manual Transfer',
              paymentMethod: 'Access Bank',
              createdAt: DateTime(2026, 3, 24, 10, 0),
              createdLabel: 'Mar 24, 2026 10:00 AM',
            ),
          ],
          hasReceivingAccounts: true,
        ),
        message: 'Fund wallet overview loaded successfully.',
      );
    };
    NewsApiService.debugFetchHandler = ({
      required String token,
      required int limit,
    }) async {
      return NewsApiResult.success(
        items: <NewsItem>[
          NewsItem(
            id: 1,
            message: 'Airtime discounts have been refreshed for today.',
            createdAt: DateTime(2026, 3, 25, 9, 0),
            createdLabel: 'Mar 25, 2026 09:00 AM',
          ),
          NewsItem(
            id: 2,
            message:
                'Virtual account funding remains active across supported banks.',
            createdAt: DateTime(2026, 3, 24, 12, 30),
            createdLabel: 'Mar 24, 2026 12:30 PM',
          ),
        ],
        message: 'News loaded successfully.',
      );
    };
    NotificationApiService.debugFetchHandler = ({required String token}) async {
      return NotificationsApiResult.success(
        notifications: <NotificationApiItem>[
          NotificationApiItem(
            id: 'ntf-1',
            title: 'Airtime purchase successful',
            message:
                'Your MTN airtime purchase of ₦1,960.00 was delivered instantly to 08031234567.',
            category: 'transaction',
            createdAt: DateTime(2026, 3, 14, 8, 12),
            isRead: false,
          ),
          NotificationApiItem(
            id: 'ntf-2',
            title: 'Support ticket updated',
            message:
                'Your wallet funding issue has been reviewed by our support team.',
            category: 'support',
            createdAt: DateTime(2026, 3, 11, 16, 20),
            isRead: true,
          ),
        ],
        unreadCount: 1,
        message: 'Notifications loaded successfully.',
      );
    };
    NotificationApiService.debugMarkReadHandler = ({
      required String token,
      required String notificationId,
    }) async {
      return const NotificationMutationApiResult.success(
        unreadCount: 0,
        message: 'Notification marked as read.',
      );
    };
    NotificationApiService.debugMarkAllReadHandler = ({
      required String token,
    }) async {
      return const NotificationMutationApiResult.success(
        unreadCount: 0,
        message: 'All notifications marked as read.',
      );
    };
    VirtualAccountsApiService.debugFetchHandler = ({
      required String token,
    }) async {
      return VirtualAccountsApiResult.success(
        accounts: <VirtualAccountItem>[
          VirtualAccountItem(
            id: 1,
            accountNumber: '1029384756',
            accountName: 'PTS DATA ABUBAKAR',
            bankName: 'Wema Bank',
            bankSlug: 'wema-bank',
            isActive: true,
            createdAt: DateTime(2026, 3, 20, 8, 0),
            createdLabel: 'Mar 20, 2026',
          ),
          VirtualAccountItem(
            id: 2,
            accountNumber: '3094857612',
            accountName: 'PTS DATA ABUBAKAR',
            bankName: 'Moniepoint',
            bankSlug: 'moniepoint',
            isActive: true,
            createdAt: DateTime(2026, 3, 20, 8, 0),
            createdLabel: 'Mar 20, 2026',
          ),
        ],
        hasAccounts: true,
        customerCode: 'CUS_123456',
        customerEmail: 'admin@ptsdata.ng',
        message: 'Virtual accounts loaded successfully.',
      );
    };
    TransferApiService.debugOverviewHandler = ({
      required String token,
      required int limit,
    }) async {
      return TransferOverviewApiResult.success(
        overview: TransferOverview(
          walletBalance: 248500,
          minAmount: 100,
          history: <TransferApiHistoryItem>[
            TransferApiHistoryItem(
              id: 1,
              username: 'favour_data',
              recipientName: 'Favour Johnson',
              amount: 5000,
              status: 'Successful',
              reference: 'TRF-001',
              createdAt: DateTime(2026, 3, 20, 12, 8),
            ),
            TransferApiHistoryItem(
              id: 2,
              username: 'jideplug',
              recipientName: 'Jide Hassan',
              amount: 1500,
              status: 'Successful',
              reference: 'TRF-002',
              createdAt: DateTime(2026, 3, 19, 19, 16),
            ),
          ],
        ),
        message: 'Transfer overview loaded successfully.',
      );
    };
    TransferApiService.debugValidateRecipientHandler = ({
      required String token,
      required String username,
    }) async {
      if (username == 'selfuser') {
        return const TransferValidateRecipientApiResult.validation(
          fieldErrors: <String, String>{
            'username': 'You cannot transfer funds to yourself.',
          },
          message: 'You cannot transfer funds to yourself.',
        );
      }

      return TransferValidateRecipientApiResult.success(
        recipientName: 'Favour Johnson',
        username: username,
        message: 'Recipient validated successfully.',
      );
    };
    TransferApiService.debugSubmitHandler = ({
      required String token,
      required String username,
      required double amount,
      required String pin,
      required String note,
    }) async {
      if (pin == '0000') {
        return const TransferSubmitApiResult.validation(
          fieldErrors: <String, String>{
            'pin': 'The transaction PIN is incorrect.',
          },
          message: 'Please confirm your transaction PIN and try again.',
        );
      }

      return TransferSubmitApiResult.success(
        walletBalance: 248500 - amount,
        reference: 'TRF-TEST-001',
        recipientName: 'Favour Johnson',
        note: note,
        historyItem: TransferApiHistoryItem(
          id: 3,
          username: username,
          recipientName: 'Favour Johnson',
          amount: amount,
          status: 'Successful',
          reference: 'TRF-TEST-001',
          createdAt: DateTime(2026, 3, 25, 10, 0),
        ),
        message: 'Transfer completed successfully.',
      );
    };
    CashbackApiService.debugOverviewHandler = ({required String token}) async {
      return CashbackOverviewApiResult.success(
        overview: CashbackOverview(
          balance: 12750,
          totalEarned: 38100,
          totalConverted: 25350,
          walletBalance: 248500,
          recentTransactions: <CashbackApiTransaction>[
            CashbackApiTransaction(
              id: 1,
              type: 'earned',
              amount: 10,
              description: 'MTN 10GB direct gifting',
              transactionType: 'data',
              reference: 'CBK-001',
              createdAt: DateTime(2026, 2, 20, 17, 25),
              balanceBefore: 12740,
              balanceAfter: 12750,
            ),
            CashbackApiTransaction(
              id: 2,
              type: 'converted',
              amount: 5000,
              description: 'Converted to wallet balance',
              transactionType: '',
              reference: 'CBK-002',
              createdAt: DateTime(2026, 2, 18, 9, 14),
              balanceBefore: 17750,
              balanceAfter: 12750,
            ),
          ],
        ),
        message: 'Cashback loaded successfully.',
      );
    };
    CashbackApiService.debugConvertHandler = ({
      required String token,
      required double amount,
      required String pin,
    }) async {
      if (pin == '0000') {
        return const CashbackConvertApiResult.failure(
          'The transaction PIN is incorrect.',
        );
      }

      return CashbackConvertApiResult.success(
        overview: CashbackOverview(
          balance: 12750 - amount,
          totalEarned: 38100,
          totalConverted: 25350 + amount,
          walletBalance: 248500 + amount,
          recentTransactions: <CashbackApiTransaction>[
            CashbackApiTransaction(
              id: 3,
              type: 'converted',
              amount: amount,
              description: 'Converted to wallet balance',
              transactionType: '',
              reference: 'CBK-NEW',
              createdAt: DateTime(2026, 3, 24, 11, 0),
              balanceBefore: 12750,
              balanceAfter: 12750 - amount,
            ),
          ],
        ),
        reference: 'CBK-NEW',
        convertedAmount: amount,
        message: 'Cashback converted successfully.',
      );
    };
    ReferralsApiService.debugOverviewHandler = ({required String token}) async {
      return ReferralsOverviewApiResult.success(
        overview: ReferralsOverview(
          referralCode: 'ABUBAKAR',
          inviteLink: 'https://ptsdata.ng/register?referal=ABUBAKAR',
          rewardPerReferral: 50,
          totalReferrals: 3,
          claimableCount: 1,
          claimedCount: 1,
          totalEarned: 100,
          claimableAmount: 50,
          walletBalance: 248500,
          items: <ReferralApiItem>[
            ReferralApiItem(
              id: 'ref-1',
              index: 1,
              referralType: 'user',
              name: 'Favour Johnson',
              reward: 50,
              status: 1,
              statusLabel: 'Unused',
              createdAt: DateTime(2026, 3, 20, 13, 5),
              createdLabel: 'Mar 20, 2026 01:05 PM',
            ),
            ReferralApiItem(
              id: 'ref-2',
              index: 2,
              referralType: 'user',
              name: 'Jide Hassan',
              reward: 50,
              status: 2,
              statusLabel: 'Used',
              createdAt: DateTime(2026, 3, 17, 11, 26),
              createdLabel: 'Mar 17, 2026 11:26 AM',
            ),
          ],
        ),
        message: 'Referrals loaded successfully.',
      );
    };
    ReferralsApiService.debugClaimHandler = ({
      required String token,
      required String referralId,
    }) async {
      return ReferralsClaimApiResult.success(
        claimedAmount: 50,
        walletBalance: 248550,
        overview: ReferralsOverview(
          referralCode: 'ABUBAKAR',
          inviteLink: 'https://ptsdata.ng/register?referal=ABUBAKAR',
          rewardPerReferral: 50,
          totalReferrals: 3,
          claimableCount: 0,
          claimedCount: 2,
          totalEarned: 100,
          claimableAmount: 0,
          walletBalance: 248550,
          items: <ReferralApiItem>[
            ReferralApiItem(
              id: referralId,
              index: 1,
              referralType: 'user',
              name: 'Favour Johnson',
              reward: 50,
              status: 2,
              statusLabel: 'Used',
              createdAt: DateTime(2026, 3, 20, 13, 5),
              createdLabel: 'Mar 20, 2026 01:05 PM',
            ),
            ReferralApiItem(
              id: 'ref-2',
              index: 2,
              referralType: 'user',
              name: 'Jide Hassan',
              reward: 50,
              status: 2,
              statusLabel: 'Used',
              createdAt: DateTime(2026, 3, 17, 11, 26),
              createdLabel: 'Mar 17, 2026 11:26 AM',
            ),
          ],
        ),
        message: 'Referral reward claimed successfully.',
      );
    };
    ProfileApiService.debugProfileHandler = ({required String token}) async {
      return ProfileApiResult.success(
        profile: const ProfileDetails(
          name: 'Abubakar Bello',
          email: 'abubakar@ptsdata.ng',
          mobileNumber: '08012345678',
          username: 'abubakar',
          referralCode: 'abubakar',
          referralUsername: '',
          role: 'user',
          roleLabel: 'Standard',
          accountType: '2',
          tierLabel: 'Tier 2',
          status: 'active',
          statusLabel: 'Active',
          verificationLabel: 'Verified',
          pinStatusLabel: 'Enabled',
          profileCompleted: true,
          isEmailVerified: true,
          hasTransactionPin: true,
          walletBalance: 248500,
          cashbackBalance: 12750,
          joinedAt: null,
          joinedLabel: 'Joined Feb 10, 2026',
        ),
        message: 'Profile loaded successfully.',
      );
    };
    TransactionHistoryApiService.debugFetchHandler = ({
      required String token,
      required int page,
      required String type,
      required String status,
      required String dateRange,
      required String search,
    }) async {
      return TransactionHistoryApiResult.success(
        page: TransactionHistoryPagePayload(
          data: <TransactionHistoryApiItem>[
            TransactionHistoryApiItem(
              id: 'TRANS-20',
              type: 'transfer',
              amount: 5000,
              status: 'success',
              direction: 'outgoing',
              date: DateTime(2026, 3, 14, 8, 12),
              description: 'Transfer to abubakar',
              recipient: 'abubakar',
              reference: 'TRF-001',
            ),
            TransactionHistoryApiItem(
              id: 'FUND-21',
              type: 'funding',
              amount: 12000,
              status: 'pending',
              direction: 'incoming',
              date: DateTime(2026, 3, 13, 18, 2),
              description: 'Wallet Funding - Bank Transfer',
              reference: 'FUND-001',
            ),
          ],
          currentPage: page,
          perPage: 20,
          total: 2,
          lastPage: 1,
        ),
        message: 'Transactions loaded successfully.',
      );
    };
    TransactionHistoryApiService.debugExportHandler = ({
      required String token,
      required String format,
      required String type,
      required String status,
      required String dateRange,
      required String search,
    }) async {
      return const TransactionHistoryExportApiResult.success(
        bytes: <int>[82, 101, 102, 44, 84, 121, 112, 101],
        fileName: 'transactions.csv',
        mimeType: 'text/csv',
        message: 'Transactions exported successfully.',
      );
    };
  });

  testWidgets('renders the native PTS DATA welcome page on a standard phone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PtsDataApp());

    expect(find.text('PTS DATA'), findsOneWidget);
    expect(find.text('Welcome to PTS DATA'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);
  });

  testWidgets('renders without scroll on a short mobile screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PtsDataApp());

    expect(find.text('PTS DATA'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);
  });

  testWidgets('navigates from welcome to login screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PtsDataApp());
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(find.text('Email or Username'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('forgot password submits and shows success status', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PtsDataApp());
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).first, 'jane@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.text('We have emailed your password reset link.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'returning user opens quick login and 4-digit PIN unlocks dashboard',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final DateTime now = DateTime.now();
      SharedPreferences.setMockInitialValues(<String, Object>{
        'session.display_name': 'ABUBAKAR',
        'session.identifier': 'ptsdata@wallet.ng',
        'session.has_transaction_pin': true,
        'session.last_full_auth_at':
            now.subtract(const Duration(hours: 2)).toIso8601String(),
        'session.last_unlock_at':
            now.subtract(const Duration(hours: 2)).toIso8601String(),
      });

      await tester.pumpWidget(const PtsDataApp());
      await tester.pumpAndSettle();

      expect(find.text('Welcome back, ABUBAKAR'), findsOneWidget);
      expect(find.text('Use Fingerprint'), findsNothing);

      for (final String digit in <String>['1', '2', '3', '4']) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('Hi, ABUBAKAR'), findsOneWidget);
      expect(find.text('Wallet balance'), findsOneWidget);
    },
  );

  test('sign out clears remembered session', () async {
    final DateTime now = DateTime.now();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'session.display_name': 'ABUBAKAR',
      'session.identifier': 'ptsdata@wallet.ng',
      'session.has_transaction_pin': true,
      'session.last_full_auth_at':
          now.subtract(const Duration(hours: 2)).toIso8601String(),
      'session.last_unlock_at':
          now.subtract(const Duration(hours: 2)).toIso8601String(),
    });

    await AppSessionService.instance.signOut();

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('session.display_name'), isNull);
    expect(preferences.getString('session.identifier'), isNull);
    expect(preferences.getString('session.api_token'), isNull);
  });

  testWidgets('navigates from welcome to register screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PtsDataApp());
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.text('Personal details'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('register flow moves to the next step', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PtsDataApp());
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'Jane Doe');
    await tester.enterText(find.byType(EditableText).at(1), 'jane@example.com');
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text('Account identity'), findsOneWidget);
    expect(find.text('Referral Username (Optional)'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('sign in opens the dashboard screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PtsDataApp());
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'admin@ptsdata.ng');
    await tester.enterText(find.byType(EditableText).at(1), 'password123');
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.text('Hi, ABUBAKAR'), findsOneWidget);
    expect(find.text('Wallet balance'), findsOneWidget);
    expect(find.text('Services'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
  });

  testWidgets('dashboard airtime entry opens the buy airtime page', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PtsDataApp());
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'admin@ptsdata.ng');
    await tester.enterText(find.byType(EditableText).at(1), 'password123');
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Airtime').first);
    await tester.pumpAndSettle();

    expect(find.text('Buy Airtime'), findsOneWidget);
    expect(find.text('Select Network *'), findsOneWidget);
    expect(find.text('Buy Airtime Now'), findsOneWidget);
  });

  testWidgets('dashboard data entry opens the buy data page', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PtsDataApp());
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'admin@ptsdata.ng');
    await tester.enterText(find.byType(EditableText).at(1), 'password123');
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Data').first);
    await tester.pumpAndSettle();

    expect(find.text('Buy Data'), findsOneWidget);
    expect(find.text('Select Network *'), findsOneWidget);
    expect(find.text('Buy Data Now'), findsOneWidget);
  });

  testWidgets('dashboard fund wallet entry opens the fund wallet page', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PtsDataApp());
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'admin@ptsdata.ng');
    await tester.enterText(find.byType(EditableText).at(1), 'password123');
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fund Wallet'));
    await tester.pumpAndSettle();

    expect(find.text('Fund Wallet'), findsOneWidget);
    expect(find.text('Receive With These Accounts'), findsOneWidget);
    expect(find.text('Funding Guide'), findsOneWidget);
    expect(find.text('Submit Transfer Details'), findsNothing);
  });

  testWidgets('dashboard history entry opens the transaction history page', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PtsDataApp());
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'admin@ptsdata.ng');
    await tester.enterText(find.byType(EditableText).at(1), 'password123');
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    await tester.tap(find.text('History').first);
    await tester.pumpAndSettle();

    expect(find.text('Transaction History'), findsWidgets);
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(find.text('Statement'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
  });

  testWidgets('dashboard cable tv entry opens the tv subscription page', (
    WidgetTester tester,
  ) async {
    await _loginToDashboard(tester);

    await tester.tap(find.text('Cable TV'));
    await tester.pumpAndSettle();

    expect(find.text('Cable Bill'), findsWidgets);
    expect(find.text('Cable Bill Payment'), findsOneWidget);
    expect(find.text('Validate Decoder'), findsOneWidget);
  });

  testWidgets('dashboard electricity entry opens the bill payment page', (
    WidgetTester tester,
  ) async {
    await _loginToDashboard(tester);

    await tester.tap(find.text('Electricity'));
    await tester.pumpAndSettle();

    expect(find.text('Bill Payment'), findsWidgets);
    expect(find.text('Electricity Bill Payment'), findsOneWidget);
    expect(find.text('Validate Meter'), findsOneWidget);
  });

  testWidgets('dashboard transfer entry opens the transfer page', (
    WidgetTester tester,
  ) async {
    await _loginToDashboard(tester);

    await tester.tap(find.text('Transfer'));
    await tester.pumpAndSettle();

    expect(find.text('Transfer'), findsWidgets);
    expect(find.text('User to User Transfer'), findsOneWidget);
    expect(find.text('Validate User'), findsOneWidget);
  });

  testWidgets('dashboard cashback quick action opens the cashback page', (
    WidgetTester tester,
  ) async {
    await _loginToDashboard(tester);

    await tester.tap(find.text('Cashback'));
    await tester.pumpAndSettle();

    expect(find.text('Available Cashback'), findsOneWidget);
    expect(find.text('Convert to Wallet'), findsWidgets);
    expect(find.text('How Cashback Works'), findsOneWidget);
  });

  testWidgets('dashboard cards quick action opens the cards page', (
    WidgetTester tester,
  ) async {
    await _loginToDashboard(tester);

    await tester.tap(find.text('Cards'));
    await tester.pumpAndSettle();

    expect(find.text('Cards & E-PIN'), findsWidgets);
    expect(find.text('Generate Cards'), findsOneWidget);
    expect(find.text('Generate Now'), findsOneWidget);
  });

  testWidgets('dashboard more entry opens the more services page', (
    WidgetTester tester,
  ) async {
    await _loginToDashboard(tester);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('My Service'), findsOneWidget);
    expect(find.text('Recommend'), findsOneWidget);
    expect(find.text('Rewards & Tools'), findsOneWidget);
    expect(find.text('Bill Payments'), findsOneWidget);
    expect(find.text('Support'), findsWidgets);
  });

  testWidgets('dashboard notifications icon opens the notifications page', (
    WidgetTester tester,
  ) async {
    await _loginToDashboard(tester);

    expect(find.text('67'), findsNothing);
    expect(find.text('1'), findsWidgets);

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsWidgets);
    expect(find.text('Recent Alerts'), findsOneWidget);
    expect(find.text('Mark all read'), findsOneWidget);
  });

  testWidgets('dashboard support icon opens the support page', (
    WidgetTester tester,
  ) async {
    await _loginToDashboard(tester);

    await tester.tap(find.byIcon(Icons.headset_mic_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Support Center'), findsWidgets);
    expect(find.text('Quick Help Channels'), findsOneWidget);
    expect(find.text('Send Support Request'), findsOneWidget);
  });

  testWidgets('dashboard me bottom navigation opens the profile page', (
    WidgetTester tester,
  ) async {
    await _loginToDashboard(tester);

    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();

    expect(find.text('Me'), findsWidgets);
    expect(find.text('Referral Code'), findsOneWidget);
    expect(find.text('Abubakar Bello'), findsOneWidget);
    expect(find.text('@abubakar'), findsOneWidget);
    expect(find.text('Account & Security'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
  });

  testWidgets('me settings entry opens the settings page', (
    WidgetTester tester,
  ) async {
    await _loginToDashboard(tester);

    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Settings'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Account Preferences'), findsOneWidget);
    expect(find.text('Fingerprint Login'), findsOneWidget);
    expect(find.text('Quick Login with PIN'), findsOneWidget);
  });

  testWidgets('settings fingerprint toggle asks for transaction pin', (
    WidgetTester tester,
  ) async {
    await _loginToDashboard(tester);

    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Settings'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(find.text('Enable Fingerprint Login'), findsOneWidget);

    for (final String digit in <String>['1', '2', '3', '4']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }

    await tester.pumpAndSettle();

    expect(find.text('Enable Fingerprint Login'), findsNothing);
  });

  testWidgets('dashboard refer and earn entry opens the referrals page', (
    WidgetTester tester,
  ) async {
    await _loginToDashboard(tester);

    await tester.tap(find.text('Refer & Earn'));
    await tester.pumpAndSettle();

    expect(find.text('Referrals'), findsWidgets);
    expect(find.text('Referral Activity'), findsOneWidget);
    expect(find.text('Copy Code'), findsOneWidget);
  });

  testWidgets('more page opens the virtual accounts page', (
    WidgetTester tester,
  ) async {
    await _loginToDashboard(tester);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Virtual Accounts'),
      140,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Virtual Accounts'));
    await tester.pumpAndSettle();

    expect(find.text('Virtual Accounts'), findsWidgets);
    expect(find.text('Assigned Accounts'), findsOneWidget);
    expect(find.text('1029384756'), findsOneWidget);
  });

  testWidgets('me page opens the news page', (WidgetTester tester) async {
    await _loginToDashboard(tester);

    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('News & Updates'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('News & Updates'));
    await tester.pumpAndSettle();

    expect(find.text('News & Updates'), findsWidgets);
    expect(find.text('Latest News'), findsOneWidget);
    expect(
      find.text('Airtime discounts have been refreshed for today.'),
      findsOneWidget,
    );
  });
}
