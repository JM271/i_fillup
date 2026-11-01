package com.example.i_fillup

import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.os.Bundle
import com.google.android.libraries.places.api.Places
import com.google.android.libraries.places.api.model.Place
import com.google.android.libraries.places.api.net.FetchPlaceRequest
import com.google.android.libraries.places.widget.PlaceAutocomplete
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingAddress: MethodChannel.Result? = null
    private val addressRequest = 7201

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Request notifications play a sound and pop up, also while the app is
        // in the background. The Cloud Functions send to this channel.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(
                    "refill_requests",
                    getString(R.string.requests_channel_name),
                    NotificationManager.IMPORTANCE_HIGH,
                )
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "i_fillup/google_places")
            .setMethodCallHandler { call, result ->
                if (call.method != "chooseAddress") {
                    result.notImplemented()
                } else if (pendingAddress != null) {
                    result.error("busy", "Address search is already open.", null)
                } else if (BuildConfig.PLACES_API_KEY.isBlank()) {
                    result.error("missing_key", "Google address search is not configured on this build.", null)
                } else {
                    try {
                        if (!Places.isInitialized()) {
                            Places.initializeWithNewPlacesApiEnabled(applicationContext, BuildConfig.PLACES_API_KEY)
                        }
                        val intent = PlaceAutocomplete.IntentBuilder()
                            .setInitialQuery(call.argument<String>("query") ?: "")
                            .build(this)
                        pendingAddress = result
                        @Suppress("DEPRECATION")
                        startActivityForResult(intent, addressRequest)
                    } catch (_: Exception) {
                        pendingAddress = null
                        result.error("search_failed", "Could not open Google address search.", null)
                    }
                }
            }
    }

    @Deprecated("FlutterActivity uses the activity-result callback")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != addressRequest) return
        val reply = pendingAddress ?: return
        if (resultCode != Activity.RESULT_OK || data == null) {
            pendingAddress = null
            if (resultCode == Activity.RESULT_CANCELED) reply.success(null)
            else reply.error("search_failed", "Google address search failed. Check your connection and API configuration.", null)
            return
        }
        val prediction = PlaceAutocomplete.getPredictionFromIntent(data)
        if (prediction == null) {
            pendingAddress = null
            reply.error("no_address", "No address was selected.", null)
            return
        }
        val request = FetchPlaceRequest.builder(prediction.placeId,
            listOf(Place.Field.FORMATTED_ADDRESS, Place.Field.LOCATION))
            .setSessionToken(PlaceAutocomplete.getSessionTokenFromIntent(data)).build()
        Places.createClient(this).fetchPlace(request)
            .addOnSuccessListener { response ->
                pendingAddress = null
                val point = response.place.location
                val label = response.place.formattedAddress
                if (point == null || label.isNullOrBlank()) {
                    reply.error("no_address", "This place has no usable address. Choose another result.", null)
                } else {
                    reply.success(mapOf("address" to label, "latitude" to point.latitude, "longitude" to point.longitude))
                }
            }
            .addOnFailureListener {
                pendingAddress = null
                reply.error("details_failed", "Could not load the selected address. Check Places API access and billing, then retry.", null)
            }
    }
}
