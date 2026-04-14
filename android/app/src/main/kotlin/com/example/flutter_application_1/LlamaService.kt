package com.example.flutter_application_1

import android.content.Context
import java.io.File

/**
 * LlamaService: Handles on-device GGUF model inference using llama.cpp
 * Falls back gracefully if native library is not available
 */
class LlamaService(private val context: Context) {
    companion object {
        private var instance: LlamaService? = null
        private var modelLoaded = false
        private var nativeHandle: Long = 0
        private var nativeLibraryAvailable = false

        fun getInstance(context: Context): LlamaService {
            return instance ?: LlamaService(context).also { instance = it }
        }

        init {
            // Try to load the native library if it exists
            try {
                System.loadLibrary("llama")
                nativeLibraryAvailable = true
            } catch (e: UnsatisfiedLinkError) {
                // Native library not available - will use fallback (Ollama)
                nativeLibraryAvailable = false
            }
        }
    }

    // Native methods - only called if library is available
    private external fun llamaLoadModel(modelPath: String): Long
    private external fun llamaPrompt(handle: Long, prompt: String, predictTokens: Int): String
    private external fun llamaUnloadModel(handle: Long): Boolean

    fun loadModel(modelPath: String): Boolean {
        // If native library not available, skip loading
        if (!nativeLibraryAvailable) {
            return false
        }

        return try {
            val file = File(modelPath)
            if (!file.exists()) {
                return false
            }

            nativeHandle = llamaLoadModel(modelPath)
            modelLoaded = nativeHandle > 0

            modelLoaded
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    fun runInference(prompt: String, maxTokens: Int = 256): String? {
        // If native library not available or model not loaded, return null
        if (!nativeLibraryAvailable || !modelLoaded || nativeHandle <= 0) {
            return null
        }

        return try {
            val response = llamaPrompt(nativeHandle, prompt, maxTokens)
            response.trim()
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    fun unloadModel(): Boolean {
        if (!nativeLibraryAvailable) {
            return true
        }

        return try {
            if (modelLoaded && nativeHandle > 0) {
                val result = llamaUnloadModel(nativeHandle)
                modelLoaded = false
                nativeHandle = 0
                result
            } else {
                true
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    fun isModelLoaded(): Boolean = modelLoaded
    fun isNativeLibraryAvailable(): Boolean = nativeLibraryAvailable
}
