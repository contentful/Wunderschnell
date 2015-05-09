.PHONY: all pod

all:
	xcodebuild -workspace WatchButton.xcworkspace \
		-scheme WatchButton -sdk iphonesimulator build CODE_SIGN_IDENTITY=-

pod:
	pod install --no-repo-update
