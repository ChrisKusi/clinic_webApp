importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

try {
  firebase.initializeApp({
    apiKey: "AIzaSyDWj0DM8fBB00c5FvuTLCvDDiIQbRhnDOU",
    authDomain: "pentecost-clinic.firebaseapp.com",
    projectId: "pentecost-clinic",
    storageBucket: "pentecost-clinic.appspot.com",
    messagingSenderId: "272709137362",
    appId: "1:272709137362:web:93b6bc3f76e5191827ce0b"
  });

  const messaging = firebase.messaging();

  // Handle background notifications
  messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message:', payload);

    const notificationTitle = payload.notification?.title || 'New Notification';
    const notificationOptions = {
      body: payload.notification?.body || 'You have a new message from the clinic.',
      icon: '/favicon.ico', // Optional: Add your app's icon
      data: payload.data // Store data for click handling
    };

    // Show notification
    self.registration.showNotification(notificationTitle, notificationOptions);
  });

  // Handle notification clicks
  self.addEventListener('notificationclick', (event) => {
    console.log('[firebase-messaging-sw.js] Notification clicked:', event.notification.data);
    event.notification.close();

    const urlToOpen = event.notification.data?.route || '/';
    const promiseChain = clients.matchAll({
      type: 'window',
      includeUncontrolled: true
    }).then((clientList) => {
      // Focus on existing window if available
      for (const client of clientList) {
        if (client.url.includes(urlToOpen) && 'focus' in client) {
          return client.focus();
        }
      }
      // Open new window if no matching client
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen);
      }
    });

    event.waitUntil(promiseChain);
  });

} catch (error) {
  console.error('[firebase-messaging-sw.js] Error in service worker:', error);
}