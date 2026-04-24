importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js");

firebase.initializeApp({
    apiKey: "AIzaSyCycBjiRYqj6uzzgmba6MbP1zaAfswup9U",
    authDomain: "fireguard-ai.firebaseapp.com",
    projectId: "fireguard-ai",
    storageBucket: "fireguard-ai.firebasestorage.app",
    messagingSenderId: "594007996995",
    appId: "1:594007996995:web:b06092e9bf761018e2b2f6"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/icons/icon-192x192.png'
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});
