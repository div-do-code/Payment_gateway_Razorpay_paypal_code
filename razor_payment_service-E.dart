import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:organic_store_app/models/order.dart';
import 'package:organic_store_app/provider/cart_provider.dart';
import 'package:organic_store_app/widgets/widget_order_success.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorPaymentService {
  Razorpay _razorpay;
  BuildContext _buildContext;

  //initialize payment gateway
  initPaymentGateway(BuildContext buildContext) {
    this._buildContext = buildContext;
    _razorpay = new Razorpay();
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, externalWallet);
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, paymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, paymentError);
  }

  void externalWallet(ExternalWalletResponse response) {
    // print(response.walletName);
  }

  void paymentSuccess(PaymentSuccessResponse response) {
    print("SUCCESS:-" + response.paymentId.toString());
    var orderProvider = Provider.of<CartProvider>(_buildContext, listen: false);
    OrderModel orderModel = new OrderModel();
    orderModel.paymentMethod = "razorpay";
    orderModel.paymentMethodTitle = "RazorPay";
    orderModel.setPaid = true;
    orderModel.transactionId = response.paymentId.toString();

    orderProvider.processOrder(orderModel);
    Navigator.pushAndRemoveUntil(
        _buildContext,
        MaterialPageRoute(builder: (context) => OrderSuccessWidget()),
        ModalRoute.withName("/OrderSuccess"));
  }

  void paymentError(PaymentFailureResponse response) {
    print("Fail/Error-" +
        response.message.toString() +
        "-" +
        response.code.toString());
  }

  getPayment(BuildContext context) {
    var cartItems = Provider.of<CartProvider>(context, listen: false);
    cartItems.fetchCartItems();

    var options = {
      'key': 'YOUR - KEY - HERE',
      // into by 100 is rule of razor pay..don't know why
      'amount': cartItems.totalAmount * 100,
      'name': 'Organic Store',
      'description': 'Yor are paying to Organic Store.. ',
      'prefill': {'contact': '888XXXXXXX', 'email': 'abcd@gmail.com'},
      // 'external': {
      //   'wallets': ['paytm']
      // }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint(e);
    }
  }
}
