# project.yml → seep-ios.xcodeproj (GH-112). 프로젝트 파일은 직접 고치지 않는다
project:
	scripts/xcodegen.sh

lint:
	swiftlint lint --quiet
	scripts/check-db-schema.sh

lint-fix:
	swiftlint --fix --quiet

# baseline: 키가 가리키는 파일이 없으면 SwiftLint가 먼저 실패하므로 키를 뺀 임시 설정으로 생성한다
lint-baseline:
	sed '/^baseline:/d' .swiftlint.yml > .swiftlint.tmp.yml
	swiftlint lint --quiet --config .swiftlint.tmp.yml --write-baseline .swiftlint-baseline.json || true
	rm -f .swiftlint.tmp.yml

# 문구는 String Catalog(.xcstrings)라 SwiftGen 이 직접 못 읽어 스크립트가 넘겨 준다 (GH-100 R-5). 이미지는 그대로 SwiftGen
swiftgen:
	scripts/generate-strings.py
	swiftgen config run --config swiftgen.yml

test:
	scripts/run-tests.sh
