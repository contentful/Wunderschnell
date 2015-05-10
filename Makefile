.PHONY: all pod

all:
	xcodebuild -workspace WatchButton.xcworkspace \
		-scheme WatchButton -sdk iphonesimulator build CODE_SIGN_IDENTITY=-

pod:
	bundle install
	bundle exec pod install --no-repo-update
