// Service Worker for Offline Functionality - Constitutional Compliance Framework
// T059: Implement service worker for offline functionality
//
// Core Principles:
// 1. Constitutional compliance - No analytics or tracking
// 2. Performance first - Aggressive caching with smart invalidation
// 3. Privacy first - All data stays local
// 4. Graceful degradation - Enhanced experience when available
// 5. Zero external dependencies - Self-contained offline functionality

const CACHE_NAME = 'ghostty-config-v1';
const STATIC_CACHE = 'ghostty-static-v1';
const DYNAMIC_CACHE = 'ghostty-dynamic-v1';

// Constitutional compliance: Only cache essential resources
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/config.html',
  '/themes.html',
  '/keybindings.html',
  '/about.html',
  '/favicon.ico',
  '/manifest.json',
  // Core CSS (constitutional requirement: <50KB total)
  '/assets/css/main.css',
  '/assets/css/themes.css',
  // Core JS (constitutional requirement: <100KB total)
  '/assets/js/app.js',
  '/assets/js/config.js',
  // Essential fonts (only system fallbacks)
  '/assets/fonts/system-ui.woff2',
  // Core images (optimized, <500KB total)
  '/assets/images/logo.svg',
  '/assets/images/ghostty-icon.png'
];

// Constitutional compliance: Cache only user-generated content
const DYNAMIC_ASSETS = [
  '/api/config',
  '/api/themes',
  '/api/keybindings',
  '/api/export',
  '/api/import'
];

// Network-first resources (constitutional requirement: always fresh when online)
const NETWORK_FIRST = [
  '/api/version',
  '/api/health',
  '/api/updates'
];

// Cache-first resources (constitutional requirement: fast offline access)
const CACHE_FIRST = [
  '/assets/',
  '/images/',
  '/fonts/',
  '/css/',
  '/js/'
];

// Constitutional compliance: No analytics, no tracking, no external requests
const BLOCKED_DOMAINS = [
  'google-analytics.com',
  'googletagmanager.com',
  'facebook.com',
  'twitter.com',
  'linkedin.com',
  'mixpanel.com',
  'amplitude.com',
  'segment.com'
];

// Service Worker Installation
self.addEventListener('install', (event) => {
  console.log('[SW] Installing service worker...');

  event.waitUntil(
    Promise.all([
      // Cache static assets
      caches.open(STATIC_CACHE).then((cache) => {
        console.log('[SW] Caching static assets...');
        return cache.addAll(STATIC_ASSETS);
      }),

      // Initialize dynamic cache
      caches.open(DYNAMIC_CACHE).then((cache) => {
        console.log('[SW] Initializing dynamic cache...');
        return Promise.resolve();
      })
    ]).then(() => {
      console.log('[SW] Installation complete');
      // Constitutional compliance: Immediate activation for better UX
      return self.skipWaiting();
    }).catch((error) => {
      console.error('[SW] Installation failed:', error);
    })
  );
});

// Service Worker Activation
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating service worker...');

  event.waitUntil(
    Promise.all([
      // Clean up old caches
      caches.keys().then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            if (cacheName !== STATIC_CACHE &&
                cacheName !== DYNAMIC_CACHE &&
                cacheName !== CACHE_NAME) {
              console.log('[SW] Deleting old cache:', cacheName);
              return caches.delete(cacheName);
            }
          })
        );
      }),

      // Take control of all clients immediately
      self.clients.claim()
    ]).then(() => {
      console.log('[SW] Activation complete');

      // Notify all clients of successful activation
      self.clients.matchAll().then(clients => {
        clients.forEach(client => {
          client.postMessage({
            type: 'SW_ACTIVATED',
            timestamp: Date.now()
          });
        });
      });
    }).catch((error) => {
      console.error('[SW] Activation failed:', error);
    })
  );
});

// Fetch Event Handler - Core offline functionality
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);

  // Constitutional compliance: Block tracking domains
  if (BLOCKED_DOMAINS.some(domain => url.hostname.includes(domain))) {
    console.log('[SW] Blocked tracking request:', url.href);
    event.respondWith(new Response('', { status: 204 }));
    return;
  }

  // Constitutional compliance: Only handle same-origin requests
  if (url.origin !== location.origin) {
    return;
  }

  // Handle different caching strategies based on resource type
  if (request.method === 'GET') {
    event.respondWith(handleGetRequest(request));
  } else if (request.method === 'POST') {
    event.respondWith(handlePostRequest(request));
  } else {
    // Pass through other methods
    event.respondWith(fetch(request));
  }
});

// Handle GET requests with appropriate caching strategy
async function handleGetRequest(request) {
  const url = new URL(request.url);
  const pathname = url.pathname;

  try {
    // Network-first strategy for API endpoints that need fresh data
    if (NETWORK_FIRST.some(pattern => pathname.startsWith(pattern))) {
      return await networkFirst(request);
    }

    // Cache-first strategy for static assets
    if (CACHE_FIRST.some(pattern => pathname.startsWith(pattern))) {
      return await cacheFirst(request);
    }

    // Stale-while-revalidate for HTML pages
    if (pathname.endsWith('.html') || pathname === '/') {
      return await staleWhileRevalidate(request);
    }

    // Default: Network-first with cache fallback
    return await networkFirst(request);

  } catch (error) {
    console.error('[SW] Request failed:', error);
    return await getOfflineFallback(request);
  }
}

// Handle POST requests (for configuration updates)
async function handlePostRequest(request) {
  try {
    // Constitutional compliance: Always try network first for data modifications
    const response = await fetch(request);

    // If successful, update relevant caches
    if (response.ok) {
      const url = new URL(request.url);

      // Invalidate related cache entries
      if (url.pathname.includes('/api/config')) {
        await invalidateCache('/api/config');
      } else if (url.pathname.includes('/api/themes')) {
        await invalidateCache('/api/themes');
      } else if (url.pathname.includes('/api/keybindings')) {
        await invalidateCache('/api/keybindings');
      }
    }

    return response;

  } catch (error) {
    console.error('[SW] POST request failed:', error);

    // Constitutional compliance: Store failed requests for later sync
    await storeFailedRequest(request);

    return new Response(JSON.stringify({
      error: 'Offline - Request queued for sync',
      queued: true,
      timestamp: Date.now()
    }), {
      status: 202,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

// Network-first strategy
async function networkFirst(request) {
  try {
    const response = await fetch(request);

    // Cache successful responses
    if (response.ok) {
      const cache = await caches.open(DYNAMIC_CACHE);
      cache.put(request, response.clone());
    }

    return response;
  } catch (error) {
    // Fallback to cache
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    throw error;
  }
}

// Cache-first strategy
async function cacheFirst(request) {
  const cachedResponse = await caches.match(request);

  if (cachedResponse) {
    // Update cache in background if resource is old
    updateCacheInBackground(request);
    return cachedResponse;
  }

  // Fetch from network if not in cache
  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(STATIC_CACHE);
      cache.put(request, response.clone());
    }
    return response;
  } catch (error) {
    return await getOfflineFallback(request);
  }
}

// Stale-while-revalidate strategy
async function staleWhileRevalidate(request) {
  const cachedResponse = await caches.match(request);

  // Always try to fetch fresh version in background
  const networkPromise = fetch(request).then(response => {
    if (response.ok) {
      const cache = caches.open(STATIC_CACHE);
      cache.then(c => c.put(request, response.clone()));
    }
    return response;
  }).catch(() => {
    // Network failed, ignore for this strategy
  });

  // Return cached version immediately if available
  if (cachedResponse) {
    return cachedResponse;
  }

  // Wait for network if no cached version
  try {
    return await networkPromise;
  } catch (error) {
    return await getOfflineFallback(request);
  }
}

// Update cache in background
async function updateCacheInBackground(request) {
  try {
    const response = await fetch(request);
    if (response.ok) {
      const cache = await caches.open(STATIC_CACHE);
      await cache.put(request, response);
    }
  } catch (error) {
    // Ignore background update failures
    console.log('[SW] Background update failed for:', request.url);
  }
}

// Get offline fallback response
async function getOfflineFallback(request) {
  const url = new URL(request.url);

  // Return appropriate offline page based on request type
  if (request.headers.get('accept')?.includes('text/html')) {
    const offlinePage = await caches.match('/offline.html');
    if (offlinePage) {
      return offlinePage;
    }

    // Constitutional compliance: Basic offline HTML without external dependencies
    return new Response(`
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Offline - Ghostty Config</title>
        <style>
          body {
            font-family: system-ui, -apple-system, sans-serif;
            max-width: 600px;
            margin: 2rem auto;
            padding: 2rem;
            text-align: center;
            line-height: 1.6;
          }
          .offline-icon {
            font-size: 4rem;
            margin-bottom: 1rem;
          }
          .retry-btn {
            background: #3b82f6;
            color: white;
            border: none;
            padding: 0.75rem 1.5rem;
            border-radius: 0.5rem;
            font-size: 1rem;
            cursor: pointer;
            margin-top: 1rem;
          }
          .retry-btn:hover {
            background: #2563eb;
          }
        </style>
      </head>
      <body>
        <div class="offline-icon">📡</div>
        <h1>You're Offline</h1>
        <p>
          The requested page is not available offline.
          Please check your internet connection and try again.
        </p>
        <p>
          <strong>Available offline:</strong><br>
          • Configuration editor<br>
          • Theme browser<br>
          • Keybinding editor<br>
          • Previously viewed content
        </p>
        <button class="retry-btn" onclick="window.location.reload()">
          Try Again
        </button>
        <script>
          // Constitutional compliance: No analytics, minimal JS
          window.addEventListener('online', () => {
            window.location.reload();
          });
        </script>
      </body>
      </html>
    `, {
      headers: { 'Content-Type': 'text/html' },
      status: 503
    });
  }

  // JSON API fallback
  if (request.headers.get('accept')?.includes('application/json')) {
    return new Response(JSON.stringify({
      error: 'Offline',
      message: 'This resource is not available offline',
      offline: true,
      timestamp: Date.now()
    }), {
      status: 503,
      headers: { 'Content-Type': 'application/json' }
    });
  }

  // Generic fallback
  return new Response('Offline', { status: 503 });
}

// Store failed requests for background sync
async function storeFailedRequest(request) {
  try {
    const requestData = {
      url: request.url,
      method: request.method,
      headers: [...request.headers.entries()],
      body: await request.text(),
      timestamp: Date.now()
    };

    // Constitutional compliance: Store locally only
    const cache = await caches.open('failed-requests');
    const failedRequest = new Request('/failed-requests/' + Date.now(), {
      method: 'POST',
      body: JSON.stringify(requestData)
    });

    await cache.put(failedRequest, new Response(JSON.stringify(requestData)));

    console.log('[SW] Stored failed request for later sync');
  } catch (error) {
    console.error('[SW] Failed to store request:', error);
  }
}

// Invalidate cache entries
async function invalidateCache(pattern) {
  try {
    const cache = await caches.open(DYNAMIC_CACHE);
    const requests = await cache.keys();

    const deletePromises = requests
      .filter(request => request.url.includes(pattern))
      .map(request => cache.delete(request));

    await Promise.all(deletePromises);
    console.log('[SW] Invalidated cache for pattern:', pattern);
  } catch (error) {
    console.error('[SW] Cache invalidation failed:', error);
  }
}

// Background sync for failed requests
self.addEventListener('sync', (event) => {
  if (event.tag === 'background-sync') {
    event.waitUntil(syncFailedRequests());
  }
});

// Sync failed requests when online
async function syncFailedRequests() {
  try {
    const cache = await caches.open('failed-requests');
    const requests = await cache.keys();

    for (const request of requests) {
      try {
        const response = await cache.match(request);
        const requestData = await response.json();

        // Retry the original request
        const retryResponse = await fetch(requestData.url, {
          method: requestData.method,
          headers: requestData.headers,
          body: requestData.body
        });

        if (retryResponse.ok) {
          // Remove from failed requests cache
          await cache.delete(request);
          console.log('[SW] Successfully synced failed request:', requestData.url);
        }
      } catch (error) {
        console.error('[SW] Failed to sync request:', error);
      }
    }
  } catch (error) {
    console.error('[SW] Background sync failed:', error);
  }
}

// Message handling for client communication
self.addEventListener('message', (event) => {
  const { type, data } = event.data;

  switch (type) {
    case 'GET_CACHE_STATUS':
      getCacheStatus().then(status => {
        event.ports[0].postMessage({ type: 'CACHE_STATUS', data: status });
      });
      break;

    case 'CLEAR_CACHE':
      clearAllCaches().then(() => {
        event.ports[0].postMessage({ type: 'CACHE_CLEARED' });
      });
      break;

    case 'UPDATE_CACHE':
      updateAllCaches().then(() => {
        event.ports[0].postMessage({ type: 'CACHE_UPDATED' });
      });
      break;

    case 'GET_OFFLINE_STATUS':
      getOfflineCapabilities().then(capabilities => {
        event.ports[0].postMessage({
          type: 'OFFLINE_STATUS',
          data: capabilities
        });
      });
      break;

    default:
      console.log('[SW] Unknown message type:', type);
  }
});

// Get cache status for diagnostics
async function getCacheStatus() {
  try {
    const cacheNames = await caches.keys();
    const status = {};

    for (const cacheName of cacheNames) {
      const cache = await caches.open(cacheName);
      const requests = await cache.keys();
      status[cacheName] = {
        count: requests.length,
        size: await getCacheSize(cache, requests)
      };
    }

    return {
      caches: status,
      timestamp: Date.now(),
      version: CACHE_NAME
    };
  } catch (error) {
    console.error('[SW] Failed to get cache status:', error);
    return { error: error.message };
  }
}

// Calculate cache size
async function getCacheSize(cache, requests) {
  let totalSize = 0;

  for (const request of requests.slice(0, 10)) { // Sample first 10 for performance
    try {
      const response = await cache.match(request);
      if (response) {
        const blob = await response.blob();
        totalSize += blob.size;
      }
    } catch (error) {
      // Ignore individual size calculation errors
    }
  }

  return Math.round(totalSize / 1024); // Return KB
}

// Clear all caches
async function clearAllCaches() {
  try {
    const cacheNames = await caches.keys();
    await Promise.all(cacheNames.map(name => caches.delete(name)));
    console.log('[SW] All caches cleared');
  } catch (error) {
    console.error('[SW] Failed to clear caches:', error);
  }
}

// Update all caches
async function updateAllCaches() {
  try {
    // Re-cache static assets
    const staticCache = await caches.open(STATIC_CACHE);
    await staticCache.addAll(STATIC_ASSETS);

    // Clear dynamic cache to force fresh requests
    await caches.delete(DYNAMIC_CACHE);
    await caches.open(DYNAMIC_CACHE);

    console.log('[SW] All caches updated');
  } catch (error) {
    console.error('[SW] Failed to update caches:', error);
  }
}

// Get offline capabilities summary
async function getOfflineCapabilities() {
  const capabilities = {
    staticAssets: STATIC_ASSETS.length,
    dynamicCaching: true,
    backgroundSync: 'serviceWorker' in navigator && 'sync' in window.ServiceWorkerRegistration.prototype,
    offlinePages: [
      '/',
      '/config.html',
      '/themes.html',
      '/keybindings.html'
    ],
    features: {
      configEditor: true,
      themeSelector: true,
      keybindingEditor: true,
      exportImport: true,
      offlineStorage: true
    },
    constitutional: {
      noTracking: true,
      noAnalytics: true,
      localOnly: true,
      performanceFirst: true
    }
  };

  return capabilities;
}

console.log('[SW] Service worker script loaded - Constitutional compliance enabled');