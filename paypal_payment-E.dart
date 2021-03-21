import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:organic_store_app/provider/paypal_service.dart';

class PaypalPaymentScreen extends StatefulWidget {
  @override
  _PaypalPaymentScreenState createState() => _PaypalPaymentScreenState();
}

class _PaypalPaymentScreenState extends State<PaypalPaymentScreen> {
  InAppWebViewController webView;
  String url = "";
  double progress = 0;
  GlobalKey<ScaffoldState> scaffoldKey;

  String checkoutURL;
  String executeURL;
  String accessToken;

  PaypalService paypalService;

  @override
  void initState() {
    super.initState();
    paypalService = new PaypalService();
    this.scaffoldKey = new GlobalKey<ScaffoldState>();
    Future.delayed(Duration.zero, () async {
      try {
        accessToken = await paypalService.getAccessToken();

        final transactions = paypalService.getOrderParams(context);
        final res =
            await paypalService.createPaypalPayment(transactions, accessToken);
        if (res != null) {
          setState(() {
            checkoutURL = res["approvalUrl"];
            executeURL = res["executeUrl"];
          });
        }
      } catch (e) {
        print('exception: ' + e.toString());
        final snackBar = SnackBar(
          content: Text(e.toString()),
          duration: Duration(seconds: 10),
          action: SnackBarAction(
            label: 'Close',
            onPressed: () {},
          ),
        );
        scaffoldKey.currentState.showSnackBar(snackBar);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (checkoutURL != null){
      return Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          centerTitle: true,
          title: Text(
            "PayPal Payment",
            style: TextStyle(
              letterSpacing: 1.3,
              fontSize: 20,
            ),
          ),
        ),
        body: Stack(
          children: [
            InAppWebView(
              initialUrl: checkoutURL,
              initialOptions: new InAppWebViewGroupOptions(
                android: AndroidInAppWebViewOptions(
                  textZoom: 120,
                ),
              ),
              onWebViewCreated: (InAppWebViewController controller) {
                webView = controller;
              },
              ////////////changed in last
              onLoadStart:
                  (InAppWebViewController controller, String requestURL) async {
                // Success/ Error
                if (requestURL.contains(paypalService.returnURL)) {
                  final uri = Uri.parse(requestURL);
                  // i did a mistake..wrote PayerID -> payerID..
                  // that's why PAYID was not generated (today date - 11/02/2021)
                  final payerId = uri.queryParameters['PayerID'];
                  if (payerId != null) {
                    await paypalService
                        .executePayment(executeURL, payerId, accessToken)
                        .then(
                          (id) {
                        print(id);
                        Navigator.of(context).pop();
                      },
                    );
                  } else {
                    Navigator.of(context).pop();
                  }
                  Navigator.of(context).pop();
                }
                if (requestURL.contains(paypalService.cancelURL)) {
                  Navigator.of(context).pop();
                }
              },
              ///////////////////////
              onProgressChanged:
                  (InAppWebViewController controller, int progress) {
                setState(() {
                  this.progress = progress / 100;
                });
              },
            ),
            progress < 1
                ? SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.blue.withOpacity(0.3),
              ),
            )
                : SizedBox(),
          ],
        ),
      );
  }
  
    else {
      return Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          centerTitle: true,
          title: Text(
            "PayPal Payment",
            style: TextStyle(
              letterSpacing: 1.3,
              fontSize: 20,
            ),
          ),
        ),
        body: Center(
          child: Container(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
  }
}
