'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "8d2e8840e882da48d3348f2284fc2889",
"assets/AssetManifest.bin.json": "45e3ea2f5240a5091ad1cc08ae1540b3",
"assets/AssetManifest.json": "62914ff5d215bb4c88c45d2bea283a97",
"assets/assets/fonts/Montserrat-Regular.ttf": "203d753a80557746c23ce95191fbf013",
"assets/assets/images/become_provider.png": "0cb7ebf850e4a70f30d68f11b739beec",
"assets/assets/images/botanical.png": "67308c7e0ca8ef15211551d9f15c1e92",
"assets/assets/images/botanical1.png": "2ca7d9b6291d331cd9964b14e4eb1045",
"assets/assets/images/categories/accessories.png": "f94239521db4ee7b0783de15504e0062",
"assets/assets/images/categories/cake.png": "f97a93e668cba7ff20f2942d3b8e1995",
"assets/assets/images/categories/card_printing.png": "ca4eb04f01ca03126c398d23986aa030",
"assets/assets/images/categories/car_rental.png": "eff13a314cb7f33982097d8957f31d87",
"assets/assets/images/categories/catering.png": "ae23ad57237f766a6ae0dc5d849f656e",
"assets/assets/images/categories/decor_lighting.png": "23c0da8aaa23b12fc33705fd32ab661d",
"assets/assets/images/categories/flower_shops.png": "cdb97fa8e39ccdb2a90d7d77d66de47d",
"assets/assets/images/categories/gifts.png": "8cadf972a091da0012391a084c2a5b60",
"assets/assets/images/categories/music.png": "6b413b92060ba497e6d4704f3b485b5a",
"assets/assets/images/categories/photographers.png": "91e07d43d319408520a07cf05006f0e3",
"assets/assets/images/categories/venues.png": "880d5acc5ce47ac25b34bbad8888a29e",
"assets/assets/images/categories/wedding_planner.png": "d09e1c6a64031f0e04163a0249a69214",
"assets/assets/images/classic.png": "2f624f147137e6c60160d1cddb1eccb6",
"assets/assets/images/classic1.png": "c31b1c074fae625b9407263a0a3d2ea8",
"assets/assets/images/classic2.png": "d7c2a1c51e01c2c09ef1011bd061718a",
"assets/assets/images/customer.png": "2b9fbf75135699d6a898569844bfdb01",
"assets/assets/images/minimal.png": "72332af0b5ff9492db01545fbcd06e2f",
"assets/assets/images/minimal1.png": "d895d65bcbf3c48969b0ac0cfe044a02",
"assets/assets/images/pic1.png": "d28611d5fdd1d4e9254517f978bcb8af",
"assets/assets/images/pic2.png": "1d9c1da2746ab9b72295fbb0ecbdc2c6",
"assets/assets/images/pic3.png": "8c65174c260e1afdec8377fd6dd98956",
"assets/assets/images/plan.jpg": "3481b61ed62643b0513e2798b0eaabc5",
"assets/assets/images/provider.png": "af91291697735a812ba00ef25b81fcc3",
"assets/assets/images/providers.png": "5dbc262710030f38be23a72653c1de3d",
"assets/assets/images/romantic.png": "e500dd76b5a27549b88ab564063d8ab0",
"assets/assets/images/romantic1.png": "a1fa65e109d4b6c7c3ed4c5834d54b38",
"assets/assets/images/romantic2.png": "fc42cd14ef02c29409f0c5ea1e9a2cc0",
"assets/assets/images/table.png": "357f4a55de8a68a4df1b827700675c6d",
"assets/FontManifest.json": "87e56832fcaeed20b0e57efb1f9ffa57",
"assets/fonts/MaterialIcons-Regular.otf": "67305a8db4dbd2f13397c7519d24078e",
"assets/NOTICES": "dcb66746fe9b884600d03c42622570c8",
"assets/packages/flutter_map/lib/assets/flutter_map_logo.png": "208d63cc917af9713fc9572bd5c09362",
"assets/packages/lucide_icons/assets/lucide.ttf": "03f254a55085ec6fe9a7ae1861fda9fd",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "643de6964d2c717664b382737f20fecf",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "acfffd1a083ede0eda1ab3d5f3f26ff8",
"/": "acfffd1a083ede0eda1ab3d5f3f26ff8",
"main.dart.js": "a190c0c2b27a400fe55fd229d46fa389",
"manifest.json": "bf24c84c3bf99672a631c4f84464e793",
"version.json": "15235b5108d6a877ef74fe3317a96bf7"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
