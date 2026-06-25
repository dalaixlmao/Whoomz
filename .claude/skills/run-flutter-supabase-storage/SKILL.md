---
name: run-flutter-supabase-storage
description: Reference and code-generation skill for Supabase Storage in Flutter — bucket operations, file upload/download, signed URLs, public URLs, image caching with cached_network_image. Use when uploading user avatars or workout media, downloading files, generating signed URLs, or displaying cached remote images.
---

Requires `supabase_flutter ^2.x` and `cached_network_image ^3.x`. Neither is in this project's pubspec — add before coding:

```bash
~/flutter/bin/flutter pub add supabase_flutter cached_network_image
```

## Upload a file

```dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

final storage = Supabase.instance.client.storage;

// Upload bytes
Future<String> uploadAvatar(File file, String userId) async {
  final path = 'avatars/$userId.jpg';
  await storage.from('profiles').upload(
    path,
    file,
    fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
  );
  return path;
}

// Upload from Uint8List (e.g. from image_picker)
await storage.from('profiles').uploadBinary(
  'avatars/$userId.jpg',
  bytes,
  fileOptions: const FileOptions(contentType: 'image/jpeg'),
);
```

## Download a file

```dart
final Uint8List bytes = await storage.from('profiles').download('avatars/$userId.jpg');
```

## Public URL (bucket must be public)

```dart
final url = storage.from('profiles').getPublicUrl('avatars/$userId.jpg');
// → "https://xxxx.supabase.co/storage/v1/object/public/profiles/avatars/uid.jpg"
```

## Signed URL (private buckets)

```dart
final signedUrl = await storage.from('private-docs').createSignedUrl(
  'reports/q1.pdf',
  expiresIn: 3600, // seconds
);
```

## List files in a bucket folder

```dart
final files = await storage.from('workouts').list(path: userId);
for (final f in files) print(f.name);
```

## Delete a file

```dart
await storage.from('profiles').remove(['avatars/$userId.jpg']);
```

## Display with cached_network_image

```dart
import 'package:cached_network_image/cached_network_image.dart';

CachedNetworkImage(
  imageUrl: storage.from('profiles').getPublicUrl('avatars/$userId.jpg'),
  placeholder: (_, __) => const CircularProgressIndicator(),
  errorWidget: (_, __, ___) => const Icon(Icons.person),
  // Cache images for 7 days
  cacheKey: 'avatar-$userId',
)
```

## Full upload + display pattern (user avatar)

```dart
class AvatarRepository {
  final _storage = Supabase.instance.client.storage;
  static const _bucket = 'profiles';

  Future<String> uploadAvatar(String userId, Uint8List bytes) async {
    final path = 'avatars/$userId.jpg';
    await _storage.from(_bucket).uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
    );
    return _storage.from(_bucket).getPublicUrl(path);
  }

  String getAvatarUrl(String userId) =>
      _storage.from(_bucket).getPublicUrl('avatars/$userId.jpg');
}
```

## Error handling

```dart
try {
  await storage.from('profiles').upload(path, file);
} on StorageException catch (e) {
  print('Storage error ${e.statusCode}: ${e.message}');
  // e.statusCode == '23505' → duplicate file (use upsert: true)
  // e.statusCode == '403'   → RLS policy denied
}
```

## Gotchas

- **Public vs private buckets** — `getPublicUrl` only works for public buckets. For private buckets always use `createSignedUrl`. Check bucket visibility on the Supabase dashboard under Storage → Policies.
- `upload` throws a `StorageException` with status `400` if the file already exists. Pass `FileOptions(upsert: true)` to overwrite silently.
- `cached_network_image` caches by URL. If you re-upload the same path, the old cached image is served until the cache expires. Append a cache-busting query param or use `cacheKey` tied to an upload timestamp.
- Signed URLs expire. Never store them in the database — regenerate on each request.
- Large uploads may time out on slow connections. Use `storage.from(bucket).uploadBinary` with a progress callback (not yet in stable v2 API) or break large files into chunks.
- Storage RLS is separate from the database RLS. Configure storage policies under Storage → Policies in the Supabase dashboard.
