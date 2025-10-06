# 🚀 Flutter App URL Update Guide

## 📱 After Deploying to Render.com

Once you deploy your signaling server to Render.com, you'll get a URL like:
`https://your-p2p-server.onrender.com`

## 🔧 Update Flutter App

### **Step 1: Open the file**
Open: `lib/main.dart`

### **Step 2: Find this line (around line 17):**
```dart
const SIGNALING_SERVER = 'http://localhost:3000';
```

### **Step 3: Replace with your Render URL:**
```dart
const SIGNALING_SERVER = 'https://your-p2p-server.onrender.com';
```

**Example:**
```dart
const SIGNALING_SERVER = 'https://p2p-signaling-server.onrender.com';
```

### **Step 4: Save and test**
1. Save the file
2. Run: `flutter run -d chrome`
3. Test P2P connection!

## 🎯 What This Does

- ✅ **Connects to your deployed server** instead of localhost
- ✅ **Works from anywhere** on the internet
- ✅ **No computer needed** 24/7
- ✅ **True P2P messaging** between devices

## 📋 Quick Checklist

- [ ] Deploy server to Render.com
- [ ] Get your Render URL
- [ ] Update `SIGNALING_SERVER` in `lib/main.dart`
- [ ] Test on two devices
- [ ] Send messages P2P!

**Your Flutter app is ready to connect to the deployed server!** 🚀
