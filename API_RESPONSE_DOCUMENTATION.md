# API Response Documentation - Attendance System

## Struktur Response yang Direkomendasikan

### 1. **Success Response - Check-In**
```json
{
  "status": "success",
  "attendance_type": "check-in",
  "match": true,
  "distance": 0.45,
  "message": "Check-in berhasil",
  "attendance": {
    "id": 1,
    "user_id": 5,
    "date": "2025-01-06",
    "check_in": "2025-01-06T07:15:30.000000Z",
    "check_out": null,
    "status": "success",
    "match": true,
    "distance": 0.45,
    "created_at": "2025-01-06T07:15:30.000000Z",
    "updated_at": "2025-01-06T07:15:30.000000Z"
  },
  "timestamp": "2025-01-06T07:15:30.000000Z"
}
```

### 2. **Success Response - Check-Out**
```json
{
  "status": "success",
  "attendance_type": "check-out",
  "match": true,
  "distance": 0.42,
  "message": "Check-out berhasil",
  "attendance": {
    "id": 1,
    "user_id": 5,
    "date": "2025-01-06",
    "check_in": "2025-01-06T07:15:30.000000Z",
    "check_out": "2025-01-06T17:05:45.000000Z",
    "status": "completed",
    "match": true,
    "distance": 0.42,
    "created_at": "2025-01-06T07:15:30.000000Z",
    "updated_at": "2025-01-06T17:05:45.000000Z"
  },
  "timestamp": "2025-01-06T17:05:45.000000Z"
}
```

### 3. **Success Response - Face Doesn't Match**
```json
{
  "status": "success",
  "attendance_type": "check-in",
  "match": false,
  "distance": 1.2,
  "message": "Wajah tidak sesuai dengan data terdaftar",
  "attendance": null,
  "timestamp": "2025-01-06T07:20:00.000000Z"
}
```

---

## Error Responses

### 4. **Error - Schedule Invalid (Check-In)**
```json
{
  "status": "error",
  "type": "schedule_invalid",
  "code": "CHECK_IN_OUT_OF_HOURS",
  "message": "Check-in hanya bisa dilakukan antara 06:30 - 07:30",
  "details": {
    "allowed_start": "06:30",
    "allowed_end": "07:30",
    "current_time": "08:15"
  },
  "timestamp": "2025-01-06T08:15:00.000000Z"
}
```

### 5. **Error - Schedule Invalid (Check-Out)**
```json
{
  "status": "error",
  "type": "schedule_invalid",
  "code": "CHECK_OUT_OUT_OF_HOURS",
  "message": "Check-out baru bisa dilakukan setelah 17:00",
  "details": {
    "allowed_start": "17:00",
    "current_time": "16:45"
  },
  "timestamp": "2025-01-06T16:45:00.000000Z"
}
```

### 6. **Error - Face Not Registered**
```json
{
  "status": "error",
  "type": "face_not_registered",
  "code": "FACE_NOT_FOUND",
  "message": "Wajah Anda tidak terdaftar dalam sistem",
  "details": {
    "user_id": 5,
    "required_action": "Daftar wajah terlebih dahulu"
  },
  "timestamp": "2025-01-06T07:20:00.000000Z"
}
```

### 7. **Error - Face Recognition Service Error**
```json
{
  "status": "error",
  "type": "service_error",
  "code": "FACE_RECOGNITION_FAILED",
  "message": "Layanan pengenalan wajah sedang bermasalah. Silakan coba lagi",
  "details": {
    "service": "face_recognition_api",
    "retry_after": 5
  },
  "timestamp": "2025-01-06T07:25:00.000000Z"
}
```

### 8. **Error - Network Error**
```json
{
  "status": "error",
  "type": "network_error",
  "code": "SERVICE_UNAVAILABLE",
  "message": "Gangguan jaringan. Silakan periksa koneksi internet Anda",
  "timestamp": "2025-01-06T07:30:00.000000Z"
}
```

### 9. **Error - Unauthorized**
```json
{
  "status": "error",
  "type": "unauthorized",
  "code": "INVALID_TOKEN",
  "message": "Token tidak valid atau sudah kadaluarsa. Silakan login kembali",
  "timestamp": "2025-01-06T08:00:00.000000Z"
}
```

---

## Error Type Reference

| Type | Code | Use Case |
|------|------|----------|
| `schedule_invalid` | CHECK_IN_OUT_OF_HOURS, CHECK_OUT_OUT_OF_HOURS | Check-in/out di luar jam yang ditentukan |
| `face_not_registered` | FACE_NOT_FOUND | Wajah belum didaftarkan dalam sistem |
| `face_not_matched` | FACE_MISMATCH | Wajah yang ditangkap tidak sesuai data |
| `service_error` | FACE_RECOGNITION_FAILED, SERVICE_ERROR | Layanan face recognition bermasalah |
| `network_error` | SERVICE_UNAVAILABLE, TIMEOUT | Gangguan jaringan atau timeout |
| `unauthorized` | INVALID_TOKEN, UNAUTHORIZED | Token invalid atau user tidak authenticated |
| `unknown` | UNKNOWN_ERROR | Error yang tidak terdefinisi |

---

## Response Fields Explanation

### Success Response Fields
- **status** (string): Selalu "success" untuk response sukses
- **attendance_type** (string): "check-in" atau "check-out"
- **match** (boolean): Apakah wajah cocok dengan data terdaftar (0.0-0.5 = match, >0.5 = no match)
- **distance** (number): Face recognition distance score (semakin kecil semakin cocok)
- **message** (string, optional): Pesan informasi tambahan
- **attendance** (object, optional): Data absen yang berhasil dibuat
- **timestamp** (string): ISO 8601 datetime ketika response dikirim

### Error Response Fields
- **status** (string): Selalu "error"
- **type** (string): Jenis error (schedule_invalid, face_not_registered, dll)
- **code** (string): Kode error yang spesifik untuk handling
- **message** (string): Pesan error yang user-friendly
- **details** (object, optional): Detail tambahan terkait error
- **timestamp** (string): ISO 8601 datetime

---

## Implementation Best Practices

### 1. **Face Matching Threshold**
```
distance < 0.5  → Face matches ✓
distance >= 0.5 → Face doesn't match ✗
```

### 2. **HTTP Status Codes**
- 200 OK: Attendance recorded (baik success maupun face mismatch)
- 400 Bad Request: Schedule invalid, validation error
- 401 Unauthorized: Invalid token
- 503 Service Unavailable: Face recognition service error

### 3. **Client-Side Handling**

```dart
// Success case
if (response.status == 'success' && response.match) {
  // Show success message
  showToast('${response.attendance_type} berhasil');
}

// Face mismatch case
if (response.status == 'success' && !response.match) {
  // Show warning: distance is ${response.distance}
  showWarning('Wajah tidak sesuai. Coba lagi');
}

// Error case
if (response.status == 'error') {
  switch(response.type) {
    case 'schedule_invalid':
      // Show schedule info from details
      break;
    case 'face_not_registered':
      // Redirect to face registration
      break;
    // ... handle other errors
  }
}
```

### 4. **Log Message Examples**
- Success: "✓ Check-in sukses pada 07:15 (distance: 0.45)"
- Warning: "⚠ Wajah tidak sesuai (distance: 1.2), coba lagi"
- Error: "✗ Layanan face recognition sedang bermasalah"

---

## Migration dari Response Lama

### Lama → Baru

```json
// LAMA
{
  "status": "error",
  "message": "Face not registered"
}

// BARU
{
  "status": "error",
  "type": "face_not_registered",
  "code": "FACE_NOT_FOUND",
  "message": "Wajah Anda tidak terdaftar dalam sistem",
  "timestamp": "2025-01-06T07:20:00.000000Z"
}
```

---

## Testing Examples

### Curl Test - Check-In Success
```bash
curl -X POST http://localhost:8000/api/attendance/checkin \
  -H "Content-Type: multipart/form-data" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "image=@/path/to/face.jpg"
```

### Curl Test - Check-In Out of Schedule
```bash
curl -X POST http://localhost:8000/api/attendance/checkin \
  -H "Content-Type: multipart/form-data" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "image=@/path/to/face.jpg"

# Response:
# HTTP 400 Bad Request
```
