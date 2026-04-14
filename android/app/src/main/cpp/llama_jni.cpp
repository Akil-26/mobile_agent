#include <jni.h>
#include <string>
#include <android/log.h>

#define TAG "LlamaJNI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

// Forward declarations from llama.cpp
extern "C" {
    struct llama_context;
    struct llama_model;

    llama_model * llama_load_model_from_file(const char * fname, int n_ctx);
    llama_context * llama_new_context_with_model(llama_model * model, int n_threads);
    void llama_free(llama_context * ctx);
    void llama_free_model(llama_model * model);
    int llama_tokenize(llama_model * model, const char * text, int tokens[], int n_max_tokens, int add_bos);
    int llama_generate(llama_context * ctx, const int * tokens, int n_tokens, int n_predict);
    const char * llama_token_to_str(llama_context * ctx, int token);
}

static llama_model * g_model = nullptr;
static llama_context * g_ctx = nullptr;

extern "C" JNIEXPORT jlong JNICALL
Java_com_example_flutter_1application_11_LlamaService_llamaLoadModel(
    JNIEnv * env,
    jobject thiz,
    jstring model_path) {

    const char * path = env->GetStringUTFChars(model_path, nullptr);
    LOGI("Loading model from: %s", path);

    try {
        g_model = llama_load_model_from_file(path, 512);
        if (g_model == nullptr) {
            LOGE("Failed to load model");
            env->ReleaseStringUTFChars(model_path, path);
            return 0;
        }

        g_ctx = llama_new_context_with_model(g_model, 4);
        if (g_ctx == nullptr) {
            LOGE("Failed to create context");
            llama_free_model(g_model);
            g_model = nullptr;
            env->ReleaseStringUTFChars(model_path, path);
            return 0;
        }

        LOGI("Model loaded successfully");
        env->ReleaseStringUTFChars(model_path, path);
        return (jlong)g_ctx;
    } catch (const std::exception & e) {
        LOGE("Exception: %s", e.what());
        env->ReleaseStringUTFChars(model_path, path);
        return 0;
    }
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_example_flutter_1application_11_LlamaService_llamaPrompt(
    JNIEnv * env,
    jobject thiz,
    jlong handle,
    jstring prompt,
    jint predict_tokens) {

    if (g_ctx == nullptr) {
        return env->NewStringUTF("Model not loaded");
    }

    const char * prompt_str = env->GetStringUTFChars(prompt, nullptr);
    std::string response;

    try {
        // Tokenize
        int tokens[256];
        int n_tokens = llama_tokenize(g_model, prompt_str, tokens, 256, 1);

        // Generate
        int n_predict = (int)predict_tokens;
        llama_generate(g_ctx, tokens, n_tokens, n_predict);

        // Collect output
        for (int i = 0; i < n_predict; i++) {
            const char * token_str = llama_token_to_str(g_ctx, tokens[n_tokens + i]);
            if (token_str) {
                response += token_str;
            }
        }

        env->ReleaseStringUTFChars(prompt, prompt_str);
        return env->NewStringUTF(response.c_str());
    } catch (const std::exception & e) {
        LOGE("Exception: %s", e.what());
        env->ReleaseStringUTFChars(prompt, prompt_str);
        return env->NewStringUTF("Error during inference");
    }
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_example_flutter_1application_11_LlamaService_llamaUnloadModel(
    JNIEnv * env,
    jobject thiz,
    jlong handle) {

    try {
        if (g_ctx != nullptr) {
            llama_free(g_ctx);
            g_ctx = nullptr;
        }
        if (g_model != nullptr) {
            llama_free_model(g_model);
            g_model = nullptr;
        }
        LOGI("Model unloaded successfully");
        return true;
    } catch (const std::exception & e) {
        LOGE("Exception: %s", e.what());
        return false;
    }
}
