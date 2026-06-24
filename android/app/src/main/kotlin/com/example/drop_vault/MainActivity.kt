package com.example.drop_vault

import android.accounts.AccountManager
import android.app.Activity
import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.drop_vault/google_sign_in"
    private var pendingResult: MethodChannel.Result? = null
    private val REQUEST_CODE_PICK_ACCOUNT = 1001

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "pickGoogleAccount") {
                pendingResult = result
                try {
                    val intent = AccountManager.newChooseAccountIntent(
                        null,
                        null,
                        arrayOf("com.google"),
                        null,
                        null,
                        null,
                        null
                    )
                    startActivityForResult(intent, REQUEST_CODE_PICK_ACCOUNT)
                } catch (e: Exception) {
                    result.error("ACCOUNT_PICKER_ERROR", e.message, null)
                    pendingResult = null
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_PICK_ACCOUNT) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val accountName = data.getStringExtra(AccountManager.KEY_ACCOUNT_NAME)
                pendingResult?.success(accountName)
            } else if (resultCode == Activity.RESULT_CANCELED) {
                pendingResult?.error("CANCELLED", "User cancelled account picking", null)
            } else {
                pendingResult?.error("ERROR", "Failed to pick account", null)
            }
            pendingResult = null
        }
    }
}

