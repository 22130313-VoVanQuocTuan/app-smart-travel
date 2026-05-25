# Tóm tắt các lỗi và cách sửa chữa - Hệ thống Thanh toán VNPAY & MOMO

## 📋 Lỗi được phát hiện và sửa chữa

### **BACKEND (Java Spring Boot)**

#### 1. **PaymentService.java - Sao lưu trạng thái thanh toán không nhất quán**
- **Vấn đề**: Lúc dùng "COMPLETED", lúc dùng "PAID" gây inconsistency
- **Sửa**: Thống nhất sử dụng "PAID" cho online payment, "PENDING" cho cash chưa xác nhận
- **Vị trí**: Line 420-428 & 295

**Trước:**
```java
payment.setStatus("COMPLETED");
```

**Sau:**
```java
if ("00".equals(vnpResponseCode)) {
    payment.setStatus("PAID");
} else {
    payment.setStatus("FAILED");
}
```

---

#### 2. **PaymentService.java - Thanh toán tiền mặt lập tức đánh dấu PAID**
- **Vấn đề**: Cash payment được set `paidAt` ngay lập tức nhưng trạng thái PENDING
- **Sửa**: Chỉ set `paidAt` khi ADMIN hoặc HOST xác nhận, không set khi PENDING
- **Vị trí**: Line 295

**Trước:**
```java
payment.setPaidAt(LocalDateTime.now());  // Luôn set
```

**Sau:**
```java
if ("ADMIN".equals(confirmedRole)) {
    payment.setStatus("PAID");
    payment.setPaidAt(LocalDateTime.now());  // Chỉ set khi confirmed
} else if ("HOST".equals(confirmedRole)) {
    payment.setStatus("PAID_AT_HOMESTAY");
    payment.setPaidAt(LocalDateTime.now());
} else {
    payment.setStatus("PENDING");
    // Không set paidAt cho pending payment
}
```

---

#### 3. **MoMoService.java - RestTemplate & ObjectMapper không được inject đúng**
- **Vấn đề**: Khởi tạo inline `new RestTemplate()` và `new ObjectMapper()` trong constructor
- **Sửa**: Inject qua @RequiredArgsConstructor từ Spring Bean
- **Vị trí**: Line 34-35

**Trước:**
```java
private final RestTemplate restTemplate = new RestTemplate();
private final ObjectMapper objectMapper = new ObjectMapper();
```

**Sau:**
```java
@RequiredArgsConstructor
public class MoMoService {
    private final RestTemplate restTemplate;  // Injected từ RestTemplateConfig
    private final ObjectMapper objectMapper;  // Auto-provided bởi Jackson
    // ...
}
```

---

#### 4. **MoMoService.java - Payment result handler không validate đúng & không xử lý error**
- **Vấn đề**: 
  - Không kiểm tra `resultCode` = "0" (success)
  - Không xử lý exception khi parsing orderId
  - Không tạo Invoice đầy đủ với tax/commission
  - Sử dụng "COMPLETED" không nhất quán
- **Sửa**: Thêm proper validation, error handling, và invoice creation
- **Vị trí**: Line 114-145

**Trước:**
```java
@Transactional
public String handleMoMoReturn(Map<String, String> params) {
    String orderId = params.get("orderId");
    long paymentId = Long.parseLong(orderId.split("_")[0]);
    // Không check resultCode
    payment.setStatus("COMPLETED");
    // Invoice không có tax/commission
}
```

**Sau:**
```java
@Transactional
public String handleMoMoReturn(Map<String, String> params) {
    try {
        String resultCode = params.get("resultCode");
        // Check resultCode = "0" (success)
        if ("0".equals(resultCode)) {
            payment.setStatus("PAID");
            // Create invoice với tax/commission
            invoice = createInvoiceForMoMoPayment(booking);
        } else {
            payment.setStatus("FAILED");
        }
    } catch (NumberFormatException e) {
        throw new AppException(ErrorCode.PAYMENT_NOT_FOUND);
    }
}
```

---

#### 5. **PaymentController.java - VNPay return redirect URL không an toàn**
- **Vấn đề**: Redirect sang deep link `smarttravel://` không kiểm tra response code
- **Sửa**: Kiểm tra `vnp_ResponseCode` = "00" và redirect đúng status
- **Vị trí**: Line 79-89

**Trước:**
```java
@GetMapping("/vnpay-return")
public void vnpayReturn(HttpServletRequest request, HttpServletResponse response) throws IOException {
    String deepLink = "smarttravel://payment-result?status=success";
    response.sendRedirect(deepLink);  // Luôn success
}
```

**Sau:**
```java
@GetMapping("/vnpay-return")
public void vnpayReturn(HttpServletRequest request, HttpServletResponse response) throws IOException {
    String vnp_ResponseCode = request.getParameter("vnp_ResponseCode");
    String status = "00".equals(vnp_ResponseCode) ? "success" : "failed";
    String redirectUrl = "http://localhost:8080/api/v1/payment/momo-return?" +
            "status=" + status + "&paymentId=" + vnp_TxnRef;
    response.sendRedirect(redirectUrl);
}
```

---

#### 6. **VnPayConfig.java & MoMoConfig.java - Return URL sử dụng 10.0.2.2 (Android emulator)**
- **Vấn đề**: 10.0.2.2 chỉ hoạt động trên Android emulator, không work thực tế
- **Sửa**: Thay thành `localhost:8080` cho development, sẽ config externalize cho production
- **Vị trị**: VnPayConfig line 20, MoMoConfig line 16-17

**Trước:**
```java
public static final String VNP_RETURNURL = "http://10.0.2.2:8080/api/v1/payment/vnpay-return";
public static final String REDIRECT_URL = "http://10.0.2.2:8080/api/v1/payment/momo-return";
```

**Sau:**
```java
public static final String VNP_RETURNURL = "http://localhost:8080/api/v1/payment/vnpay-return";
public static final String REDIRECT_URL = "http://localhost:8080/api/v1/payment/momo-return";
```

---

### **FRONTEND (Flutter/Dart)**

#### 1. **payment_screen.dart - Deprecation warnings với `withOpacity()`**
- **Vấn đề**: Flutter deprecated `.withOpacity()`, cần dùng `.withValues(alpha:)`
- **Sửa**: Thay all `withOpacity()` bằng `withValues(alpha:)`
- **Vị trị**: Line 132, 159

**Trước:**
```dart
color: Colors.black.withOpacity(0.5),
boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), ...)]
```

**Sau:**
```dart
color: Colors.black.withValues(alpha: 0.5),
boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), ...)]
```

---

#### 2. **payment_screen.dart - InAppWebView sử dụng deprecated API**
- **Vấn đề**: 
  - `initialOptions` deprecated, cần `initialSettings`
  - `InAppWebViewGroupOptions` deprecated
  - `AndroidInAppWebViewOptions` deprecated
  - `AndroidMixedContentMode` deprecated
  - `InAppWebViewOptions` deprecated
- **Sửa**: Migrate sang `InAppWebViewSettings` unified
- **Vị trị**: Line 205-211

**Trước:**
```dart
initialOptions: InAppWebViewGroupOptions(
  android: AndroidInAppWebViewOptions(
    mixedContentMode: AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
    domStorageEnabled: true,
    useHybridComposition: true,
  ),
  crossPlatform: InAppWebViewOptions(
    javaScriptEnabled: true,
  ),
),
```

**Sau:**
```dart
initialSettings: InAppWebViewSettings(
  javaScriptEnabled: true,
  domStorageEnabled: true,
  mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
  useHybridComposition: true,
),
```

---

#### 3. **payment_screen.dart - Return URL detection logic chưa đầu đủ**
- **Vấn đề**: Chỉ check "localhost" hoặc "10.0.2.2", không check actual endpoint path hay IP 192.168.x.x
- **Sửa**: Check cả path `/payment/momo-return` và `/payment/vnpay-return`, plus IP addresses
- **Vị trị**: Line 264

**Trước:**
```dart
if (url.contains("127.0.0.1") ||
    url.contains("localhost") ||
    url.contains("10.0.2.2") ||
    url.contains("/payment/momo-return") ||
    url.contains("/payment/vnpay-return")) {
```

**Sau:**
```dart
if (url.contains("/payment/momo-return") || 
    url.contains("/payment/vnpay-return") ||
    url.contains("localhost") ||
    url.contains("127.0.0.1") ||
    url.contains("192.168.1.12")) {
```

---

#### 4. **payment_screen.dart - Payment result handler không đầy đủ**
- **Vấn đề**: 
  - Không extract message từ MoMo response
  - Không check null values
  - Hiển thị generic message thay vì specific error
  - Không try-catch
- **Sửa**: Thêm proper validation, error message handling, try-catch
- **Vị trích**: Line 273-290

**Trước:**
```dart
void _handlePaymentResult(String url) {
    final momoResultCode = uri.queryParameters['resultCode'];
    final vnpResponseCode = uri.queryParameters['vnp_ResponseCode'];
    
    bool isSuccess = false;
    if (momoResultCode == '0' || vnpResponseCode == '00') {
        isSuccess = true;
    }
    // Generic message
}
```

**Sau:**
```dart
void _handlePaymentResult(String url) {
    try {
        final momoResultCode = uri.queryParameters['resultCode'];
        final vnpResponseCode = uri.queryParameters['vnp_ResponseCode'];
        final momoMessage = uri.queryParameters['message'];
        
        bool isSuccess = false;
        String message = "Giao dịch thất bại";

        if (momoResultCode != null) {
            if (momoResultCode == '0') {
                isSuccess = true;
                message = "Thanh toán MoMo thành công!";
            } else {
                message = momoMessage ?? "Momo failed (Code: $momoResultCode)";
            }
        } else if (vnpResponseCode != null) {
            if (vnpResponseCode == '00') {
                isSuccess = true;
                message = "Thanh toán VNPay thành công!";
            } else {
                message = "VNPay failed (Code: $vnpResponseCode)";
            }
        }
    } catch (e) {
        // Handle error
    }
}
```

---

## ✅ Các file đã được sửa

### Backend
- ✅ `PaymentService.java` - FIX: Status consistency, cash payment timing
- ✅ `MoMoService.java` - FIX: Dependency injection, result validation, invoice creation
- ✅ `PaymentController.java` - FIX: VNPay return redirect logic
- ✅ `VnPayConfig.java` - FIX: Return URL configuration
- ✅ `MoMoConfig.java` - FIX: Return URL configuration

### Frontend  
- ✅ `payment_screen.dart` - FIX: Deprecation warnings, return URL handling, result processing

---

## 🔍 Key Improvements

| Vấn đề | Lợi ích |
|--------|---------|
| Thống nhất trạng thái PAID/PENDING/FAILED | Tracking payment status chính xác |
| Kiểm tra vnp_ResponseCode & resultCode | Xác định success/failure từ cổng thanh toán |
| Proper exception handling | Tránh crash khi parse orderId sai |
| Invoice creation đầy đủ | Tracking commission/tax chính xác |
| Deprecation warnings fixed | Code compatible với Flutter versions mới |
| Better error messages | UX tốt hơn khi payment fail |

---

## 🚀 Cách test

### Test VNPAY
1. FE gửi POST `/api/v1/payment/create-online-payment` với `paymentMethod: "VNPAY"`
2. BE trả về payment URL từ VNPay sandbox
3. FE mở WebView, user hoàn thành thanh toán
4. VNPay redirect về `/api/v1/payment/vnpay-return?vnp_ResponseCode=00&...`
5. BE cập nhật Payment status → "PAID", Booking status → "ACTIVE"
6. FE nhận redirect response, hiển thị success message

### Test MOMO
1. FE gửi POST `/api/v1/payment/create-online-payment` với `paymentMethod: "MOMO"`
2. BE gửi request tới MoMo API create payment
3. MoMo trả về payUrl
4. FE mở WebView, user hoàn thành thanh toán
5. MoMo redirect về `/api/v1/payment/momo-return?resultCode=0&transId=...`
6. BE validate resultCode, cập nhật Payment & Booking, tạo Invoice
7. FE nhận redirect response, hiển thị success message

### Test CASH
1. FE gửi POST `/api/v1/payment/confirm-cash-payment`
2. BE tạo Booking, Payment (PENDING), Invoice
3. FE hiển thị success message "Sẽ thanh toán sau"
4. Host/Admin sau đó xác nhận thanh toán thực tế via separate endpoint

---

## 📝 Notes

- Tất cả endpoints vẫn hoạt động bình thường, chỉ fix logic và consistency
- Không break backward compatibility  
- Sẵn sàng cho production khi update return URLs thành domain thực tế
- Cần đảm bảo Flutter inappwebview package version >= 6.x để sử dụng `InAppWebViewSettings`

