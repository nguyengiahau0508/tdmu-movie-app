<?php

namespace App\Http\Controllers;

use App\Models\Transaction;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    public function createPayment(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:1000',
            'package_months' => 'required|integer|min:1',
        ]);

        $user = auth()->user();
        $amount = $request->amount;
        
        $partnerCode = config('momo.partner_code');
        $accessKey = config('momo.access_key');
        $secretKey = config('momo.secret_key');
        $endpoint = config('momo.endpoint');
        
        $orderInfo = "Thanh toan goi VIP $request->package_months thang cho User ID: {$user->id}";
        $amountStr = (string)$amount;
        $orderId = time() . "_" . $user->id;
        $redirectUrl = config('momo.return_url');
        $ipnUrl = config('momo.notify_url');
        $extraData = "user_id={$user->id}&months={$request->package_months}";

        // Prepare raw data for signature
        $requestId = time() . "";
        $requestType = "captureWallet";
        $rawHash = "accessKey=$accessKey&amount=$amountStr&extraData=$extraData&ipnUrl=$ipnUrl&orderId=$orderId&orderInfo=$orderInfo&partnerCode=$partnerCode&redirectUrl=$redirectUrl&requestId=$requestId&requestType=$requestType";
        
        $signature = hash_hmac("sha256", $rawHash, $secretKey);

        $data = [
            'partnerCode' => $partnerCode,
            'partnerName' => "TDMU Movie App",
            'storeId' => "TDMU_STORE",
            'requestId' => $requestId,
            'amount' => $amount,
            'orderId' => $orderId,
            'orderInfo' => $orderInfo,
            'redirectUrl' => $redirectUrl,
            'ipnUrl' => $ipnUrl,
            'lang' => 'vi',
            'extraData' => $extraData,
            'requestType' => $requestType,
            'signature' => $signature
        ];

        // Save transaction to DB
        Transaction::create([
            'user_id' => $user->id,
            'order_id' => $orderId,
            'amount' => $amount,
            'status' => 'pending',
            'order_info' => $orderInfo,
        ]);

        $response = Http::post($endpoint, $data);
        $result = $response->json();

        if (isset($result['payUrl'])) {
            return response()->json([
                'success' => true,
                'payUrl' => $result['payUrl'],
                'orderId' => $orderId,
            ]);
        }

        Log::error('MoMo Create Payment Failed: ' . json_encode($result));
        return response()->json([
            'success' => false,
            'message' => 'Lỗi tạo thanh toán MoMo',
            'error' => $result
        ], 400);
    }

    public function ipn(Request $request)
    {
        Log::info('MoMo IPN Request: ' . json_encode($request->all()));

        $partnerCode = $request->partnerCode;
        $accessKey = config('momo.access_key');
        $orderId = $request->orderId;
        $localMessage = $request->localMessage;
        $message = $request->message;
        $transId = $request->transId;
        $orderInfo = $request->orderInfo;
        $amount = $request->amount;
        $resultCode = $request->resultCode;
        $responseTime = $request->responseTime;
        $requestId = $request->requestId;
        $extraData = $request->extraData;
        $momoSignature = $request->signature;

        $secretKey = config('momo.secret_key');

        $orderType = $request->orderType;
        $payType = $request->payType;

        // Verify signature
        $rawHash = "accessKey=$accessKey&amount=$amount&extraData=$extraData&message=$message&orderId=$orderId&orderInfo=$orderInfo&orderType=$orderType&partnerCode=$partnerCode&payType=$payType&requestId=$requestId&responseTime=$responseTime&resultCode=$resultCode&transId=$transId";
        
        $signature = hash_hmac("sha256", $rawHash, $secretKey);

        if ($momoSignature !== $signature) {
            Log::error("MoMo IPN Signature Verification Failed! Expected: $signature, Got: $momoSignature");
            return response()->json(['message' => 'Invalid signature'], 400);
        }

        $transaction = Transaction::where('order_id', $orderId)->first();
        if (!$transaction) {
            Log::error("MoMo IPN: Transaction not found: $orderId");
            return response()->json(['message' => 'Transaction not found'], 404);
        }

        if ($resultCode == 0) {
            if ($transaction->status !== 'success') {
                $transaction->status = 'success';
                $transaction->trans_id = $transId;
                $transaction->save();

                // Extract extraData to get user_id and months
                parse_str($extraData, $parsedExtra);
                if (isset($parsedExtra['user_id']) && isset($parsedExtra['months'])) {
                    $user = User::find($parsedExtra['user_id']);
                    if ($user) {
                        $user->is_vip = true;
                        $months = (int)$parsedExtra['months'];
                        
                        // If already VIP, extend it, otherwise set from now
                        $currentUntil = $user->vip_until && $user->vip_until->isFuture() 
                            ? $user->vip_until 
                            : now();
                        
                        $user->vip_until = $currentUntil->addMonths($months);
                        $user->save();
                        Log::info("MoMo IPN: Successfully upgraded VIP for user $user->id for $months months");
                    }
                }
            }
        } else {
            $transaction->status = 'failed';
            $transaction->save();
            Log::warning("MoMo IPN: Transaction $orderId failed. Code: $resultCode, Message: $message");
        }

        // Must return 204 No Content to MoMo
        return response()->noContent();
    }
}
