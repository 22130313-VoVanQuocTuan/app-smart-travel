package com.example.smart_travel_FE;

import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;

import androidx.annotation.NonNull;
import androidx.core.content.FileProvider;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "smart_travel/pdf";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "savePdfToDownloads":
                            try {
                                byte[] bytes = call.argument("bytes");
                                String fileName = call.argument("fileName");

                                if (bytes == null || fileName == null || fileName.trim().isEmpty()) {
                                    result.error("INVALID_ARGS", "Missing PDF bytes or file name.", null);
                                    return;
                                }

                                result.success(savePdfToDownloads(bytes, fileName));
                            } catch (Exception e) {
                                result.error("SAVE_FAILED", e.getMessage(), null);
                            }
                            break;
                        case "openDocument":
                            try {
                                String location = call.argument("location");
                                if (location == null || location.trim().isEmpty()) {
                                    result.success(false);
                                    return;
                                }
                                result.success(openDocument(location));
                            } catch (Exception e) {
                                result.error("OPEN_FAILED", e.getMessage(), null);
                            }
                            break;
                        default:
                            result.notImplemented();
                            break;
                    }
                });
    }

    private String savePdfToDownloads(byte[] bytes, String fileName) throws IOException {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContentResolver resolver = getContentResolver();
            ContentValues values = new ContentValues();
            values.put(MediaStore.MediaColumns.DISPLAY_NAME, fileName);
            values.put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf");
            values.put(
                    MediaStore.MediaColumns.RELATIVE_PATH,
                    Environment.DIRECTORY_DOWNLOADS + "/SmartTravelReports"
            );
            values.put(MediaStore.MediaColumns.IS_PENDING, 1);

            Uri uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values);
            if (uri == null) {
                throw new IOException("Could not create PDF in Downloads.");
            }

            try (OutputStream outputStream = resolver.openOutputStream(uri)) {
                if (outputStream == null) {
                    throw new IOException("Could not open output stream.");
                }
                outputStream.write(bytes);
                outputStream.flush();
            }

            ContentValues completed = new ContentValues();
            completed.put(MediaStore.MediaColumns.IS_PENDING, 0);
            resolver.update(uri, completed, null, null);
            return uri.toString();
        }

        File downloadDir = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS
        );
        File saveDir = new File(downloadDir, "SmartTravelReports");
        if (!saveDir.exists() && !saveDir.mkdirs()) {
            throw new IOException("Could not create SmartTravelReports directory.");
        }

        File file = new File(saveDir, fileName);
        try (FileOutputStream outputStream = new FileOutputStream(file)) {
            outputStream.write(bytes);
            outputStream.flush();
        }
        return file.getAbsolutePath();
    }

    private boolean openDocument(String location) {
        try {
            Uri uri;

            if (location.startsWith("content://")) {
                uri = Uri.parse(location);
            } else {
                File file = new File(location);
                uri = FileProvider.getUriForFile(
                        this,
                        getPackageName() + ".fileprovider",
                        file
                );
            }

            Intent intent = new Intent(Intent.ACTION_VIEW);
            intent.setDataAndType(uri, "application/pdf");
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);

            if (intent.resolveActivity(getPackageManager()) == null) {
                return false;
            }

            startActivity(Intent.createChooser(intent, "Open PDF"));
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}
