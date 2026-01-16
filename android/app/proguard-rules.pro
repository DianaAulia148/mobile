# TensorFlow Lite ProGuard Rules
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.support.** { *; }
-keep class org.tensorflow.lite.task.** { *; }

# Keep model classes
-keep class * implements org.tensorflow.lite.support.model.Model { *; }

# Keep TensorFlow Lite Interpreter
-keep class org.tensorflow.lite.Interpreter { *; }

# Keep TensorFlow Lite Support classes
-keep class org.tensorflow.lite.support.common.FileUtil { *; }
-keep class org.tensorflow.lite.support.common.TensorProcessor { *; }
-keep class org.tensorflow.lite.support.label.TensorLabel { *; }
-keep class org.tensorflow.lite.support.tensorbuffer.TensorBuffer { *; }

# Google ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Camera
-keep class androidx.camera.** { *; }

# Model files
-keep class **.tflite
-keep class **.tfile
-keep class **.lite