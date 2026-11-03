extends SceneTree

func _initialize() -> void:
    var settings := EditorInterface.get_editor_settings()
    settings.set_setting("export/android/android_sdk_path", OS.get_environment("ANDROID_HOME"))
    settings.set_setting("export/android/java_sdk_path", OS.get_environment("JAVA_HOME"))
    settings.save()
    print("ONIROAI_ANDROID_SDK_CONFIGURED")
    quit()
